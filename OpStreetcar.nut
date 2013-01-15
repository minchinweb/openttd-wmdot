/*	Operation Streetcar v.1, [2013-01-14],  
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
	function GetRevision()		{ return 130114; }
	function GetDate()          { return "2013-01-14"; }
	function GetName()          { return "Operation Streetcar"; }

	_NextRun = null;
	_RoadType = null;
	_tiles = null;
	_StartTile = null;
	_PaxCargo = null;

	Log = null;
	Money = null;
	Pathfinder = null;

	constructor()
	{
		this._NextRun = 1;
		this._RoadType = AIRoad.ROADTYPE_TRAM;
		this._PaxCargo = Helper.GetPAXCargo();
		
		// this.Settings = this.Settings(this);
		this.State = this.State(this);
		
		Log = OpLog();
		Money = OpMoney();
		Pathfinder = StreetcarPathfinder();
		Pathfinder.PresetStreetcar() ;
	}

}

class OpStreetcar.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			case "StartTile":		return this._main._StartTile; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	function _set(idx, val)
	{
		switch (idx) {
			case "NextRun":				this._main._NextRun = val; break;
			case "StartTile":			this._main._StartTile = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function OpStreetcar::LinkUp() 
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	// this.Pathfinder = WmDOT.DLS;
	Log.Note(this.GetName() + " linked up!", 3);
}

function OpStreetcar::Run()
{
	local RatedTiles = RateTiles(this._StartTile);
	RatedTiles = DiscountForAllStations(RatedTiles);
	local NewStations = BuildStations(RatedTiles);
	AddRoutes(NewStations);

	this._NextRun = AIController.GetTick() + 6500 / 4;	// run every three months

}

function OpStreetcar::RatedTiles(StartTile)
{
	//	Given a starting tile, this returns an array of tiles connected to that
	//	tile that will accept passengers
	local AllTiles = AIList();
	AllTiles.AddItem(StartTile, AITile.GetCargoAcceptance(StartTile, this._PaxCargo, 1, 1, 3));
	local AddedCheck = true;
	do {
		AddedCheck = false;
		local NewTiles = AIList();
		//	Generate a list of all tiles within 3 tiles of the enteries on "AllTiles"
		foreach (Tile in AllTiles) {
			local BaseX = AIMap.GetTileX(Tile);
			local BaseY = AIMap.GetTileY(Tile);

			for (local ix = -3; ix <= 3; ix++) {
				for (local iy = -3; iy <=3; iy++) {
					if (!AllTiles.HasItem(AIMap.GetTileIndex(ix + BaseX, iy + BaseY)) && !NewTiles.HasItem(AIMap.GetTileIndex(ix + BaseX, iy + BaseY))) {
						NewTiles.AddItem(AIMap.GetTileIndex(ix + BaseX, iy + BaseY));
					}
				}
			}
		}

		foreach (Tile in NewTiles) {
			local Score = AITile.GetCargoAcceptance(Tile, this._PaxCargo, 1, 1, 3);
			if (Score >= 8) {
				AllTiles.AddItem(Tile, Score);
				AddedCheck = true;
			}
		}
	} while (AddedCheck == true)

	return AllTiles;
}

function OpStreetcar::DiscountForAllStations(AllTiles)
{
	//	takes a list of tiles
	//	for every tiles that falls within the catchment area of a station, the score is cut in half

	local AllStations;
	if (this._PaxCargo = Helper.GetPAXCargo()) {
		AllStations = AIStationList(AIStation.STATION_BUS_STOP);
	} else {
		AllStations = AIStationList(AIStation.STATION_TRUCK_STOP); 
	}

	foreach (TestStation in AllStations) {
		AllTiles = DiscountForStation(AllTiles, AIBaseStation.GetLocation(TestStation));
	}

	return AllTiles;
}

function OpStreetcar::DiscountForStation(AllTiles, StationLocation)
{
	//	takes a list of tiles
	//	for every tiles that falls within the catchment area of the 'Station Location', the score is cut in half

	local BaseX = AIMap.GetTileX(AIBaseStation.GetLocation(TestStation));
	local BaseY = AIMap.GetTileY(AIBaseStation.GetLocation(TestStation));

	for (local ix = -3; ix <= 3; ix++) {
		for (local iy = -3; iy <= 3; iy++) {
			if (AllTiles.HasItem(AIMap.GetTileIndex(ix + BaseX, iy + BaseY))) {
				AllTiles.SetValue(TestStation, AllTiles.GetValue(TestStation)/2);
			}
		}
	}

	return AllTiles;
}

function OpStreetcar::BuildStations(AllTiles)
{
	//	Accepts a list of tiles
	//	Builds stations on the best rated tiles
	//	After a station is built, it cuts the tiles in the station's catchment area in half
	//	Keeps going until there are no more tiles with a score better than 8 (full acceptance)

	local TryAgain = true;
	local NewStations = AIList();
	while (TryAgain) {
		TryAgain = false;
		AllTiles.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		AllTiles.KeepAboveValue(7);
		if (AllTiles.Count() > 0) {
			local StationLocation = AllTiles.Begin();
			if (MetaLib.Station.BuildStreetcarStation(StationLocation)) {
				NewStations.AddItem(StationLocation);
				AllTiles = DiscountForStation(AllTiles, StationLocation);
				AllTiles.RemoveItem(StationLocation);
				AllTiles.KeepAboveValue(7);
			}
			TryAgain = true;
		} else {
			TryAgain = false;
		}
	}
	return NewStations;
}

function OpStreetcar::AddRoutes(Stations)
{
	//	Takes a list of Stations and add routes between them
	//	Actaully, it basically does up the pairs and then hands it off
	//		to the route manager
	//	Assumes Stations is an AIList
	
	Stations.Valuate(AITile.GetCargoAcceptance, this._PaxCargo, 1, 1, 3);
	Stations.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	
	//	split the list
	local Delta = Stations.Count() / 2;
	local StationsBottom = AIList();
	StationsBottom.AddList(Stations);
	StationsBottom.RemoveTop(Stations.Count() - Delta);
	Stations.RemoveBottom(Delta);
	
	foreach MyStation in Stations {
		RouteManger.AddRoute(MyStation, StationsBottom.Next(), this._PaxCargo, this.Pathfinder);
	}
	
	return true;
}
	
