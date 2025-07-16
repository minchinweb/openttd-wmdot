/*	Operation Streetcar v.1, [2013-01-22],
 *		part of WmDOT v.12.1
 *	Copyright © 2012-13 by W. Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-wmdot
 *
 *	Permission is granted to you to use, copy, modify, merge, publish,
 *	distribute, sublincense, and/or sell this software, and provide these
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */

/*	Operation Streetcar
 *		This is where WmDOT gets into local public transportation. Operation
 *		Streetcar starts in WmDOT's 'Home town', generates a list of possible
 *		station sites, builds the best ones, makes them into pairs, and then
 *		runs streetcar service. This is liable to have the side effect of
 *		making this town grow rather fast.
 */

//	Requires SuperLib v27

class OpStreetcar {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 130122; }
	function GetDate()          { return "2013-01-22"; }
	function GetName()          { return "Operation Streetcar"; }

	_NextRun = null;
	_RoadType = null;
	_tiles = null;
	_StartTile = null;
	_PaxCargo = null;
	_MinTileScore = null;
	_HQTown = null;		//	HQInWhatTown

	Log = null;
	Money = null;
	Pathfinder = null;
	RouteManager = null;

	constructor() {
		this._NextRun = 1;
		this._RoadType = AIRoad.ROADTYPE_TRAM;
		this._PaxCargo = Helper.GetPAXCargo();
		this._MinTileScore = 17;

		this.Settings = this.Settings(this);
		this.State = this.State(this);

		Log = OpLog();
		Money = OpMoney();
		Pathfinder = StreetcarPathfinder();
		Pathfinder.PresetStreetcar();
	}

}

class OpStreetcar.Settings {
	_main = null;

	function _set(idx, val) {
		switch (idx) {
			case "HQTown":				this._main._HQTown = val; break;
			case "StartTile":			this._main._StartTile = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}

	function _get(idx) {
		switch (idx) {
			case "HQTown":				return this._main._HQTown; break;
			case "StartTile":			return this._main._StartTile; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
}

class OpStreetcar.State {

	_main = null;

	function _get(idx) {
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			case "StartTile":		return this._main._StartTile; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}

	function _set(idx, val) {
		switch (idx) {
			case "NextRun":				this._main._NextRun = val; break;
			case "StartTile":			this._main._StartTile = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}

	constructor(main) {
		this._main = main;
	}
}

function OpStreetcar::LinkUp()
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	// this.Pathfinder = WmDOT.DLS;
	this.RouteManager = WmDOT.Manager_Streetcars;
	Log.Note(this.GetName() + " linked up!", 3);
}

function OpStreetcar::Run() {
	Log.Note("Streetcar Manager running at tick " + AIController.GetTick() + ".",1);

	Log.Note("Rating Tiles...", 2);
	local RatedTiles = RateTiles(this._StartTile);
	Log.Note(RatedTiles.Count() + " tiles rated. Discounting tiles for existing stations...", 2);
	RatedTiles = DiscountForAllStations(RatedTiles);
	Log.Note(RatedTiles.Count() + " tiles still rated.", 3);

	Log.Note("Add new stations...", 2);
	local NewStationsTile = BuildStations(RatedTiles);

	Log.Note(NewStationsTile.Count() + " stations built. Adding Routes...", 2);
	AddRoutes(NewStationsTile);

	this._NextRun = AIController.GetTick() + 6500 / 4;	// run every three months
	Log.Note("Routes added. Next run set to tick " + this._NextRun, 2);

	return;
}

function OpStreetcar::RateTiles(StartTile) {
	//	Given a starting tile, this returns an array of tiles connected to that
	//	tile that will accept passengers
	local AllTiles = AIList();
	local IgnoredTiles = AIList();
	AllTiles.AddItem(StartTile, AITile.GetCargoAcceptance(StartTile, this._PaxCargo, 1, 1, 3));
	Log.Note("Starting at tile:" + Array.ToStringTiles1D([StartTile]) + "  score: " + AITile.GetCargoAcceptance(StartTile, this._PaxCargo, 1, 1, 3) + "/8", 3);
	local AddedCheck = true;
	local i = 0;
	do {
		// Log.Note("do-while loop #1...", 7);
		i++;
		AddedCheck = false;
		local NewTiles = AITileList();
		//	Generate a list of all tiles within 3 tiles of the entries on "AllTiles"
		local FirstLoop = true;
		local j = 0;
		do {
			j++;
			local Tile;
			if (FirstLoop == true) {
				Tile = AllTiles.Begin();
				FirstLoop = false;
			} else {
				Tile = AllTiles.Next();
			}
			local BaseX = AIMap.GetTileX(Tile);
			local BaseY = AIMap.GetTileY(Tile);
			// Log.Note("BaseTile" + Array.ToStringTiles1D([Tile]) + " x=" + BaseX + " y=" + BaseY, 7);

			for (local ix = -3; ix <= 3; ix++) {
				for (local iy = -3; iy <=3; iy++) {
					local NewTile = AIMap.GetTileIndex(ix + BaseX, iy + BaseY);
					if (!AllTiles.HasItem(NewTile) && !NewTiles.HasItem(NewTile) && !IgnoredTiles.HasItem(NewTile)) {
						NewTiles.AddItem(NewTile, 0);
						// Log.Note("Testing Tile " + ix + " " + iy + " = " + Array.ToStringTiles1D([NewTile]) + " added", 6);
						// Log.Sign(NewTile, i + " " + j + " " + ix + " " + iy, 7);
					} else {
						// Log.Note("Testing Tile " + ix + " " + iy + " = " + Array.ToStringTiles1D([NewTile]) + " : " +!AllTiles.HasItem(NewTile) + " && " + !NewTiles.HasItem(NewTile) + " && " + !IgnoredTiles.HasItem(NewTile) + "  :: " + NewTiles.Count(), 7);
						IgnoredTiles.AddItem(NewTile, 0);
					}
				}
			}
		} while (!AllTiles.IsEnd())

		FirstLoop = true;
		do {
			// Log.Note("do-while loop #2...", 7);
			local Tile;
			if (FirstLoop == true) {
				Tile = NewTiles.Begin();
				FirstLoop = false;
			} else {
				Tile = NewTiles.Next();
			}

			local Score = AITile.GetCargoAcceptance(Tile, this._PaxCargo, 1, 1, 3);
			// Log.Note("Checking tile" + Array.ToStringTiles1D([Tile]) + " score: " + Score + " " + (Score >= this._MinTileScore), 4);
			if (Score >= this._MinTileScore) {
				AllTiles.AddItem(Tile, Score);
				AddedCheck = true;
			}
		} while (!NewTiles.IsEnd())
	} while (AddedCheck == true)

	return AllTiles;
}

function OpStreetcar::DiscountForAllStations(AllTiles) {
	//	takes a list of tiles
	//	for every tiles that falls within the catchment area of a station, the score is cut in half

	local AllStations;
	if (this._PaxCargo == Helper.GetPAXCargo()) {
		AllStations = AIStationList(AIStation.STATION_BUS_STOP);
	} else {
		AllStations = AIStationList(AIStation.STATION_TRUCK_STOP);
	}

	foreach (TestStation in AllStations) {
		AllTiles = DiscountForStation(AllTiles, AIBaseStation.GetLocation(TestStation));
	}

	return AllTiles;
}

function OpStreetcar::DiscountForStation(AllTiles, StationLocation) {
	//	takes a list of tiles
	//	for every tiles that falls within the catchment area of the 'Station Location', the score reduced by 8 and then is cut in half
	//	and every tile within 2 tiles is rated zero

	Log.Note("DiscountForStation(): " + AllTiles.Count() + " tiles, at " + Array.ToStringTiles1D([StationLocation]), 7);
	local BaseX = AIMap.GetTileX(StationLocation);
	local BaseY = AIMap.GetTileY(StationLocation);

	//	every tile within 3 tiles is rated zero (actually, we remove them from
	//	the list)
	local zero_dist = 3;
	for (local ix = -zero_dist; ix <= zero_dist; ix++) {
		for (local iy = -zero_dist; iy <= zero_dist; iy++) {
			local Test = AIMap.GetTileIndex(ix + BaseX, iy + BaseY);
			// Log.Note("    ix=" + ix + "; iy=" + iy + "; Test=" + Array.ToStringTiles1D([Test]) + " : " + AllTiles.HasItem(Test), 7);
			if (AllTiles.HasItem(Test)) {
				AllTiles.RemoveItem(Test);
				// Log.Sign(Test, "r", 7);
			}
		}
	}

	//	for every tiles that falls within the catchment area of the 'Station
	//	    Location', the score reduced by 8 and then is cut in half
	local catchment = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP);
	for (local ix = -catchment; ix <= catchment; ix++) {
		for (local iy = -catchment; iy <= catchment; iy++) {
			local Test = AIMap.GetTileIndex(ix + BaseX, iy + BaseY);
			if (AllTiles.HasItem(Test)) {
				AllTiles.SetValue(Test, (AllTiles.GetValue(Test) - 8)/2);
			}
		}
	}

	AllTiles.RemoveItem(StationLocation);
	AllTiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	AllTiles.KeepAboveValue(this._MinTileScore - 1);

	Log.Note("    return: " + AllTiles.Count() + " tiles remaining.", 7);
	return AllTiles;
}

/*	\brief  Build a set of new stations
 *  \param  AllTIles    An AIList of tiles to consider for building stations on
 *  \returns    An AIList of the tiles where a station was built.
 *
 *  Builds stations on the best rated tiles. After a station is built, it cuts
 *  the tiles in the station's catchment area in half. Keeps going until there
 *  are no more tiles with a score better than 8/8 (full acceptance).
 *
 *  \todo   Only build station if it can connect to town core
 */
function OpStreetcar::BuildStations(AllTiles) {
	local TryAgain = true;
	local NewStationsTile = AIList();
	while (TryAgain) {
		TryAgain = false;
		AllTiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		AllTiles.KeepAboveValue(7);  // i.e. 8/8 is required for cargo acceptance
		if (AllTiles.Count() > 0) {
			local StationLocation = AllTiles.Begin();
			// Log.Note("StationLocation" + Array.ToStringTiles1D([StationLocation]), 7);
			if (MetaLib.Station.BuildStreetcarStation(StationLocation)) {
				NewStationsTile.AddItem(StationLocation, 0);
				AllTiles = DiscountForStation(AllTiles, StationLocation);
				Log.Note("Station built at" + Array.ToStringTiles1D([StationLocation]) + " : " + MetaLib.Station.GetName(StationLocation), 3);
			} else {
				AllTiles.RemoveItem(StationLocation);
			}
			TryAgain = true;
		} else {
			TryAgain = false;
		}
	}
	return NewStationsTile;
}

function OpStreetcar::AddRoutes(StationsTiles) {
	//	Takes a list of Stations (tiles) and add routes between them
	//	Actually, it basically does up the pairs and then hands it off
	//		to the route manager.
	//	Pairing is the highest in the top half of the list with the highest in
	//		the bottom half of the list, and then descending down both lists.
	//	Assumes Stations is an AIList of AITiles
	//
	//	TODO: If given an odd number of stations, one will remain unpaired

	StationsTiles.Valuate(AITile.GetCargoAcceptance, this._PaxCargo, 1, 1, 3);
	StationsTiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

	//	split the list
	local Delta = StationsTiles.Count() / 2;
	local StationsBottom = AIList();
	StationsBottom.AddList(StationsTiles);
	StationsBottom.RemoveTop(StationsTiles.Count() - Delta);
	StationsBottom.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	StationsTiles.RemoveList(StationsBottom);

	local station_1_tile = StationsTiles.Begin();
	local station_2_tile = StationsBottom.Begin();
	while ((station_1_tile != 0) && (station_2_tile != 0)) {
		// a returned value of `0` means that we are beyond the end of the
		// AIList

		local station_1 = AIStation.GetStationID(station_1_tile);
		local station_2 = AIStation.GetStationID(station_2_tile);
		
		Log.Note("Stations № " + station_1 + " and " + station_2, 6);
		this.RouteManager.AddRoute(station_1, station_2, this._PaxCargo, this.Pathfinder);

		station_1_tile = StationsTiles.Next();
		station_2_tile = StationsBottom.Next();
	}

	return true;
}

// EOF
