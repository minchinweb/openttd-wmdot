/*	Streetcar Manager v.3, [2013-01-16]
 *		part of WmDOT v.15.1
 *		modified version of Ship Manager v.2
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

/*	Streetcar Manager takes existing streetcar routes and add and deletes
 *		streetcars as needed.
 */

class ManStreetcars {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return 130116; }
	function GetDate()          { return "2013-01-16"; }
	function GetName()          { return "Streetcar Manager"; }
	
	
	_NextRun = null;
	_SleepLength = null;	//	as measured in days
	_AllRoutes = null;
	_StreetcarsToSell = null;	//	Vehicles are actually sold in the Event Manager
	_UseEngineID = null;
	_MaxDepotSpread = null;		//	maximum distance for a depot from a station before we try and build a closer one
	
	Log = null;
	Money = null;
	// Pathfinder = null;
	
	constructor() {
		this._NextRun = 0;
		this._SleepLength = 30;
		this._AllRoutes = [];
		this._StreetcarsToSell = [];
		this._UseEngineID = this.PickEngine(Helper.GetPAXCargo());
		this._MaxDepotSpread = 15;
		
		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
		// Pathfinder = StreetcarPathfinder();
	}
}

class Route {
	_EngineID = null;			// ID of Streetcar (vehicle)
	_Capacity = null;			// in "tons"
	_Cargo = null;				// what do we carry
	_SourceStation = null;		// StationID of where cargo is picked up
	_DestinationStation = null;	// StationID of where cargo is dropped off
	_Depot = null;				// TileID of depot
	_LastUpdate = null;			// last time (in ticks) that the route was updated
	_GroupID = null;			// ID of Group containing Streetcar
}

class ManStreetcars.Settings {

	_main = null;
	
	function _set(idx, val) {
		switch (idx) {
			case "SleepLength":			this._main._SleepLength = val; break;

			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx) {
		switch (idx) {
			case "SleepLength":			return this._main._SleepLength; break;

			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main) {
		this._main = main;
	}
}

class ManStreetcars.State {

	_main = null;
	
	function _get(idx) {
		switch (idx) {
			// case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
			// case "ROI":				return this._main._ROI; break;
			// case "Cost":			return this._main._Cost; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main) {
		this._main = main;
	}
}

function ManStreetcars::LinkUp() {
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;

	Log.Note(this.GetName() + " linked up!",3);
}


function ManStreetcars::Run() {
	Log.Note("Streetcar Manager running at tick " + AIController.GetTick() + ".",1);
	
	this._UseEngineID = this.PickEngine(Helper.GetPAXCargo());
	
	//	reset counter
	this._NextRun = AIController.GetTick() + this._SleepLength * 17;	//	SleepLength in days
	
	for (local i=0; i < this._AllRoutes.len(); i++) {
		//	Add Streetcars
		Log.Note("Considering Route №" + i + "... " + AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) + " > " + this._AllRoutes[i]._Capacity + " ? " +(AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) > this._AllRoutes[i]._Capacity),3);
		if (AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) > this._AllRoutes[i]._Capacity) {
			Money.FundsRequest(AIEngine.GetPrice(AIVehicle.GetEngineType(this._AllRoutes[i]._EngineID)) * 1.1);
			local MyVehicle;
			MyVehicle = AIVehicle.CloneVehicle(this._AllRoutes[i]._Depot, this._AllRoutes[i]._EngineID, true);
			AIVehicle.StartStopVehicle(MyVehicle);
			Log.Note("New Vehicle Added, ID: " + MyVehicle, 4);
			this._AllRoutes[i]._LastUpdate = WmDOT.GetTick();
		} else {
			//  Delete extra streetcars
			//	if there are three streetcars waiting at to fill up, delete them
			local Waiting = AIVehicleList();
			Log.Note(Waiting.Count() + " vehicles...", 6);
			Waiting.Valuate(AIVehicle.GetVehicleType);
			Waiting.KeepValue(AIVehicle.VT_ROAD);
			Log.Note(Waiting.Count() + " road vehicles...", 6);
			Waiting.Valuate(AIVehicle.GetCapacity, this._AllRoutes[i]._Cargo);
			Waiting.KeepAboveValue(0);
			Log.Note(Waiting.Count() + " road vehicles that carry " + AICargo.GetCargoLabel(this._AllRoutes[i]._Cargo) + "...", 6);
			Waiting.Valuate(MetaLib.Station.DistanceFromStation, this._AllRoutes[i]._SourceStation);
			Waiting.KeepBelowValue(4);
			Log.Note(Waiting.Count() + " road vehicles close enough...", 6);
			local FirstCount = Waiting.Count();
			if (FirstCount > 3) {
				Waiting.Valuate(AIVehicle.GetCargoLoad, this._AllRoutes[i]._Cargo);
				Waiting.KeepBelowValue(1);
				Log.Note(Waiting.Count() + " road vehicles empty enough...", 6);
				Waiting.Sort(AIList.SORT_BY_ITEM, AIList.SORT_DESCENDING);
				local SellVehicle;
				SellVehicle = Waiting.Begin();
				//	Skip the first vehicle at least...
				do {
					SellVehicle = Waiting.Next();
					AIVehicle.SendVehicleToDepot(SellVehicle);
					this._StreetcarsToSell.push(SellVehicle);					
					Log.Note("Vehicle №" + SellVehicle + " sent to depot to be sold.", 4);
				} while (!Waiting.IsEnd())
			}
		}
	}
}

/** \brief	Add a streetcar route to be managed.
 * 	\param	StationStation	StationID of starting station.
 * 	\param	EndStation		StationID of ending station.
 *	\param	CargoNo			CargoID of what we are carrying.
 *  \param  Pathfinder      reference to a pathfinder instance we can use to
 *							build connections between stations and to depots.
 *  \note   Will build an initial streetcar for the route as well. Additional
 *			streetcars will need to be built as the route is managed.
 */
function ManStreetcars::AddRoute(StartStation, EndStation, CargoNo, Pathfinder) {
	local _start_station_tile = AIBaseStation.GetLocation(StartStation);
	local _end_station_tile = AIBaseStation.GetLocation(EndStation);
	Log.Note(
		"Adding route from '" + AIBaseStation.GetName(StartStation)
		+ "' (" + Array.ToStringTiles1D([_start_station_tile]) + ")"
		+ " to '" + AIBaseStation.GetName(EndStation)
		+ "' (" + Array.ToStringTiles1D([_end_station_tile]) + ") "
		+ " for " + AICargo.GetCargoLabel(CargoNo),
		3
	);
	
	local TempRoute = Route();
	TempRoute._SourceStation = StartStation;
	TempRoute._DestinationStation = EndStation;
	TempRoute._Cargo = CargoNo;
	
	//	build link between StartStation and EndStation
	Pathfinder.InitializePath([_start_station_tile], [_end_station_tile]);
	Pathfinder.FindPath(10000);
	if (Pathfinder.GetPath() != null) {

		Money.FundsRequest(Pathfinder.GetBuildCost() * 1.1);
		Pathfinder.BuildPath();

		// TempRoute._EngineID = this._UseEngineID;
		TempRoute._Depot = GetDepot(_start_station_tile, Pathfinder);
		
		//	build streetcar
		Money.FundsRequest(AIEngine.GetPrice(this._UseEngineID) * 1.1);
		local RvID = AIVehicle.BuildVehicle(TempRoute._Depot, this._UseEngineID);
		
		//	give orders
		if (AIVehicle.IsValidVehicle(RvID)) {
			TempRoute._EngineID = RvID;

			// TODO: Ask for money to retrofit engine
			AIVehicle.RefitVehicle(RvID, TempRoute._Cargo);
			Log.Note("Added Vehicle № " + RvID + ".", 4);
			
			///	Give Orders!
			//	start station; full load here
			AIOrder.AppendOrder(RvID, _start_station_tile, (AIOrder.OF_FULL_LOAD | AIOrder.OF_NON_STOP_INTERMEDIATE));
			Log.Note("Order (Start): " + RvID + " : " + Array.ToStringTiles1D([_start_station_tile]) + ".", 5);
			
			//	end station
			AIOrder.AppendOrder(RvID, _end_station_tile, AIOrder.OF_NON_STOP_INTERMEDIATE);
			Log.Note("Order (End): " + RvID + " : " + Array.ToStringTiles1D([_end_station_tile]) + ".", 5);
		
			// send it on it's merry way!!!
			AIVehicle.StartStopVehicle(RvID);
		
			TempRoute._Capacity = AIVehicle.GetCapacity(RvID, TempRoute._Cargo);
			
			// Name Streetcar - format: Town_Name Cargo R[Route Number]-[incremented number]
			local temp_name = "";
			temp_name += AITown.GetName(AIStation.GetNearestTown(TempRoute._SourceStation));
			if (temp_name.len() > 19) { temp_name = temp_name.slice(0,19); }	//	limit town name part to 19 characters
			temp_name = temp_name + " " + AICargo.GetCargoLabel(CargoNo) + " R";
			temp_name += (this._AllRoutes.len() + 1) + "-1";
			AIVehicle.SetName(RvID, temp_name);
			
			// Create a Group for the route
			local group_number = AIGroup.CreateGroup(AIVehicle.VT_ROAD, AIGroup.GROUP_INVALID);
			AIGroup.SetName(group_number, "Route " + (this._AllRoutes.len() + 1));
			AIGroup.MoveVehicle(group_number, RvID);
			TempRoute._GroupID = group_number;
			
			TempRoute._LastUpdate = WmDOT.GetTick();
			
			this._AllRoutes.push(TempRoute);
			Log.Note(
				"Route added! Road Vehicle " + TempRoute._EngineID + "; "
				+ TempRoute._Capacity + " tons of "
				+ AICargo.GetCargoLabel(TempRoute._Cargo) + "; starting at "
				+ AIBaseStation.GetName(TempRoute._SourceStation)
				+ "' (" + Array.ToStringTiles1D([AIBaseStation.GetLocation(TempRoute._SourceStation)]) + ")"
				+ "; built at " + Array.ToStringTiles1D([TempRoute._Depot])
				+ "; updated at tick " + TempRoute._LastUpdate + ".",
				4
			);
			return true;
		} else {
			Log.Warning("     Failed to build vehicle...aborting route building.");
			return false;
		}
	} else {
		Log.Warning("     Null path...aborting route building.");
		return false;
	}
}

function ManStreetcars::PickEngine(Cargo)
{
	//	picks the 'engine' to use
	
	//	start with all engines
	local AllEngines = AIEngineList(AIVehicle.VT_ROAD);
	//	only streetcars
	AllEngines.Valuate(AIEngine.GetRoadType);
	AllEngines.KeepValue(AIRoad.ROADTYPE_TRAM);
	//	only ones that can haul passengers
	AllEngines.Valuate(AIEngine.CanRefitCargo, Cargo);
	AllEngines.KeepValue(1);  // `true`
	//	rate the remaining engines
	AllEngines.Valuate(RateEngines);
	
	//	pick highest rated
	AllEngines.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	local _my_engine_id = AllEngines.Begin();
	this._UseEngineID = _my_engine_id;
	return this._UseEngineID;
}

function ManStreetcars::RateEngines(EngineID) {
	//	attempts to find the best rated engine
	//	Note: for a valuator, the returned value must be an integer (or a bool)
	//	TODO: We are actually selecting the lowest rated engine
	//	TODO: Consider monthly station production, or otherwise downrank
	//			exceptionally large capacity vehicles.
	
	local Score = AIEngine.GetCapacity(EngineID).tofloat() * AIEngine.GetMaxSpeed(EngineID).tofloat();
	local Cost = AIEngine.GetPrice(EngineID).tofloat() / AIEngine.GetMaxAge(EngineID).tofloat();
	Cost += AIEngine.GetRunningCost(EngineID).tofloat();
	//	discount articulated??
	Score = Score / Cost;
	Score *= 1000;
	Score = Score.tointeger();

	_MinchinWeb_Log_.Note(
		"Engine Rated: " + EngineID + " : " + Score + " : "
		+ AIEngine.GetName(EngineID),
		8
	);

	return Score;
}

/** \brief  Find or build the nearest Streetcara depot
 *  \param  StationLocation     An AITile
 *  \param  Pathfinder          An initialized pathfinder
 *  \param  Iterations          Maximum number of tiles to try. 225 covers a
 *                              15x15 area
 *  \return AITile of depot location. `false` if unable to find and/or build a
 *			depot.
 *
 *  Returns the nearsest depot to the Station. Will build a depot if there
 *  isn't one close enough. If it builds the depot, will build a link from the
 *  depot to the Station.
 */
function ManStreetcars::GetDepot(StationLocation, Pathfinder, Iterations=225) {
	//	set roadtype
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
	
	local myDepot;
	// local StationLocation = AIStation.GetLocation(Station);
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	
	// look for an existing depot close enough
	local AllDepots = AIDepotList(AITile.TRANSPORT_ROAD);
	AllDepots.Valuate(AIRoad.HasRoadType, AIRoad.ROADTYPE_TRAM);
	AllDepots.KeepValue(1);  // True
	AllDepots.Valuate(AIMap.DistanceManhattan, StationLocation);
	AllDepots.KeepBelowValue(this._MaxDepotSpread + 1);
	
	if (AllDepots.Count() > 0) {
		//	pick the closest depot
		AllDepots.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		myDepot = AllDepots.Begin();

		Log.Note("Found existing Depot.", 8);

		// ensure connection between station and depot
		local tick = AIController.GetTick();
		Pathfinder.InitializePath([StationLocation], [myDepot]);
		Pathfinder.PresetStreetcar();
		Pathfinder.FindPath(5000);

		if (Pathfinder.GetPath() == null) {
			Log.Warning(
				"Pathfinding took " + (AIController.GetTick() - tick)
				+ " ticks and failed. (MD = "
				+ AIMap.DistanceManhattan(StationLocation, myTile)
				+ ")."
			);
		} else if (Pathfinder.GetPathLength() > 1) {
			Money.FundsRequest(Pathfinder.GetBuildCost() * 1.1);
			Pathfinder.BuildPath();

			return myDepot;
		}
	}

	// implied "else"

	//	build new one
	local Walker = MetaLib.SpiralWalker();
	Walker.Start(StationLocation);
	
	local KeepTrying = true;
	local my_iterations = 0;
	local TestMode = AITestMode();
	while(KeepTrying) {
		local myTile = Walker.Walk();
		local frontTile;
		
		//	Check if we can build here
		if (AITile.IsBuildable(myTile)) {
			//	check the four neighbours for being front tiles
			for (local i=0; i < offsets.len(); i++) {
				frontTile = myTile + offsets[i];
				Log.Note("     Trying with front tile" + Array.ToStringTiles1D([frontTile], false), 8);
				//	if we can build between the front tile and the proposed
				//	depot tile...
				local TestMode2 = AITestMode();
				if (AIRoad.BuildRoad(myTile, frontTile)) {
					//	run the pathfinder from the front tile to the station
					local tick = AIController.GetTick();
					Pathfinder.InitializePath([StationLocation], [myTile]);
					Pathfinder.PresetStreetcar();
					local _pf_max_cost = 0;
					_pf_max_cost = Pathfinder.cost.tile;
					_pf_max_cost *= 4;
					_pf_max_cost *= AITile.GetDistanceManhattanToTile(StationLocation, myTile);
					Pathfinder.cost.max_cost = _pf_max_cost;
					Pathfinder.FindPath(5000);

					//	See if the pathfinder was successful
					if (Pathfinder.GetPath() == null) {
						Log.Warning(
							"Pathfinding took " + (AIController.GetTick() - tick)
							+ " ticks and failed. (MD = "
							+ AIMap.DistanceManhattan(StationLocation, myTile)
							+ ")."
						);
					} else if (Pathfinder.GetPathLength() > 1) {
						//	if yes, build everything
						
						//	pretend build to get cost
						local TestMode3 = AITestMode();
						local _costs = AIAccounting();
						AIRoad.BuildRoadDepot(myTile, frontTile);
						AIRoad.BuildRoad(myTile, frontTile);

						local _money_needed = 1000;    // fudge factor
						_money_needed += _costs.GetCosts();
						_money_needed += Pathfinder.GetBuildCost();
						_money_needed *= 1.1;  // bump up to keep ahead of inflations, etc
						Money.FundsRequest(_money_needed);

						local TestMode4 = AIExecMode();
						// have to build depot first; if the road is
						// already in place, the depot will fail to build
						AIRoad.BuildRoadDepot(myTile, frontTile);
						AIRoad.BuildRoad(myTile, frontTile);
						Pathfinder.BuildPath();
						myDepot = myTile;
						KeepTrying = false;

						Log.Note(
							"     Depot built! Took "
							+ (AIController.GetTick() - tick) + " ticks.",
							8
						);
					}
				} else {
					Log.Note("          Failed to build road connection.", 8);
				}
			}
		} else {
			Log.Note("     Tile is not buildable.", 8);
		}
		my_iterations++;
		if (my_iterations > Iterations) {
			KeepTrying = false;
			myDepot = false;
			Log.Note("Failed to find workable streetcar depot location.", 3);
		}
	}

	return myDepot;
}

// EOF
