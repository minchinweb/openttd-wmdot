/*	Streetcar Manager v.3, [2013-01-16]
 *		part of WmDOT v.12.1
 *		modified verision of Ship Manager v.2
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
	_StreetcarsToSell = null;
	_UseEngineID = null;
	_MaxDepotSpread = null;		//	maximum distance for a depot from a station before we try and build a closer one
	
	Log = null;
	Money = null;
	// Pathfinder = null;
	
	constructor()
	{
		this._NextRun = 0;
		this._SleepLength = 30;
		this._AllRoutes = [];
		this._StreetcarsToSell = [];
		// this._UseEngineID = this.PickEngine();
		this._MaxDepotSpread = 15;
		
		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
		// Pathfinder = StreetcarPathfinder();
	}
}

class Route {
	_EngineID = null;			// ID of Streetcar
	_Capacity = null;			// in tons
	_Cargo = null;				// what do we carry
	_SourceStation = null;		// StationID of where cargo is picked up
	_DestinationStation = null;	// StationID of where cargo is dropped off
	_Depot = null;				// TileID of depot
	_LastUpdate = null;			// last time (in ticks) that the route was updated
	_GroupID = null;			// ID of Group containing Ship
}

class ManStreetcars.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "SleepLength":			this._main._SleepLength = val; break;

			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "SleepLength":			return this._main._SleepLength; break;

			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}
 
class ManStreetcars.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
//			case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
//			case "ROI":				return this._main._ROI; break;
//			case "Cost":			return this._main._Cost; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function ManStreetcars::LinkUp() 
{
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
		Log.Note("Considering Route #" + i + "... " + AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) + " > " + this._AllRoutes[i]._Capacity + " ? " +(AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) > this._AllRoutes[i]._Capacity),3);
		if (AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) > this._AllRoutes[i]._Capacity) {
			Money.FundsRequest(AIEngine.GetPrice(AIVehicle.GetEngineType(this._AllRoutes[i]._EngineID)) * 1.1);
			local MyVehicle;
			MyVehicle = AIVehicle.CloneVehicle(this._AllRoutes[i]._Depot, this._AllRoutes[i]._EngineID, true);
			AIVehicle.StartStopVehicle(MyVehicle);
			Log.Note("New Vehicle Added: " + MyVehicle, 4);
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
					this._ShipsToSell.push(SellVehicle);					
					Log.Note("Vehicle #" + SellVehicle + " sent to depot to be sold.", 4);
				} while (!Waiting.IsEnd())
			}
		}
	}
}

function ManStreetcars::AddRoute (StartStation, EndStation, CargoNo, Pathfinder)
{
	//	this will build the streetcar as well
	
	local TempRoute = Route();
	TempRoute._SourceStation = StartStation;
	TempRoute._DestinationStation = EndStation;
	
	//	build link between StartStation and EndStation
	Pathfinder.InitializePath(StationStation, EndStation);
	Pathfinder.FindPath();
	Money.FundsRequest(Pathfinder.GetBuildCost() * 1.1);
	Pathfinder.BuildPath();

	TempRoute._EngineID = this._UseEngineID;
	TempRoute._Depot = GetDepot(StartStation, Pathfinder);
	
	//	build streetcar
	local RvID = AIVehicle.BuildVehicle(TempRoute._Depot, TempRoute._EngineID);
	
	//	give orders
	if (AIVehicle.IsValidVehicle(RvID)) {
		AIVehicle.RefitVehicle(RvID, CargoNo);
		Log.Note("Added Vehicle № " + RvID + ".", 4);
		
		///	Give Orders!
		//	start station; full load here
		AIOrder.AppendOrder(RvID, TempRoute._SourceStation, AIOrder.OF_FULL_LOAD);
		Log.Note("Order (Start): " + RvID + " : " + Array.ToStringTiles1D([AIStation.GetLocation(TempRoute._SourceStation)]) + ".", 5);
		
		//	end station
		AIOrder.AppendOrder(RvID, TempRoute._DestinationStation, AIOrder.OF_NONE);
		Log.Note("Order (End): " + RvID + " : " + Array.ToStringTiles1D([AIStation.GetLocation(TempRoute._DestinationStation)]) + ".", 5);
	
		// send it on it's merry way!!!
		AIVehicle.StartStopVehicle(RvID);
	
		TempRoute._Capacity = AIVehicle.GetCapacity(RvID, CargoNo);
		TempRoute._Cargo = CargoNo;
		
		// Name Streetcar - format: Town_Name Cargo R[Route Number]-[incremented number]
		local temp_name = "";
		temp_name += AITown.GetName(AIStation.GetNearestTown(TempRoute._SourceStation));
		if (temp_name.len() > 19) { temp_name = temp_name.slice(0,19); }	//	limit town name part to 19 characters
		temp_name = temp_name + " " + AICargo.GetCargoLabel(CargoNo) + " R";
		temp_name += (this._AllRoutes.len() + 1) + "-1";
		AIVehicle.SetName(RvID, temp_name);
		
		// Create a Group for the route
		local group_number = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
		AIGroup.SetName(group_number, "Route " + (this._AllRoutes.len() + 1));
		AIGroup.MoveVehicle(group_number, RvID);
		TempRoute._GroupID = group_number;
		
		TempRoute._LastUpdate = WmDOT.GetTick();
		
		this._AllRoutes.push(TempRoute);
		Log.Note("Route added! Road Vehicle " + TempRoute._EngineID + "; " + TempRoute._Capacity + " tons of " + AICargo.GetCargoLabel(TempRoute._Cargo) + "; starting at " + TempRoute._SourceStation + "; build at " + TempRoute._Depot + "; updated at tick " + TempRoute._LastUpdate + ".", 4);
		return true;
	} else {
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
	AllEngines.KeepValue(true);
	//	rate the remaining engines
	AllEngines.Valuate(RateEngines);
	
	//	pick highest rated
	AllEngines.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	this._UseEngine = AllEngines.Begin();
	return this._UseEngineID;
}

function ManStreetcars::RateEngines(EngineID)
{
	//	attempts to find the best rated engine
	
	local Score = AIEngine.GetCapacity(EngineID).tofloat() * AIEngine.GetMaxSpeed(EngineID).tofloat();
	local Cost = AIEngine.GetPrice(EngineID).tofloat() / AIEngine.GetMaxAge(EngineID).tofloat();
	Cost += AIEngine.GetRunningCost(EngineID).tofloat();
	Score = Score / Cost;
	
	//	discount articulated??
	
	return Score;
}

function ManStreetcars::GetDepot(Station, Pathfinder)
{
	//	returns the nears depot to the Station
	//	will build a depot if there isn't one close enough
	//	if it builds the depot, will build a link from the depot to the Station
	
	//	set roadtype
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_TRAM);
	
	local myDepot;
	local StationLocation = AIStation.GetLocation(Station);
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
		                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	
	// look for an exisiting depot close enought
	local AllDepots = AIDepotList(AITile.TRANSPORT_ROAD);
	AllDepots.Valuate(AIRoad.HasRoadType, AIRoad.ROADTYPE_TRAM);
	AllDepots.KeepValue(true);
	AllDepots.Valuate(AIMap.DistanceManhattan, StationLocation);
	AllDepots.KeepBelowValue(this._MaxDepotSpread + 1);
	
	if (AllDepots.Count() > 0) {
		//	pick the closest depot
		AllDepots.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
		myDepot = AllDepots.Begin();
	} else {
		//	build new one
		local Walker = MetaLib.SpiralWalker();
		Walker.Start(StationLocation);
		
		local KeepTrying = true;
		local TestMode = AITestMode();
		while(KeepTrying) {
			local myTile = Walker.Walk();
			local frontTile;
			
			//	Check if we can build here
			if (AITile.IsBuildable(myTile)) {
				//	check the four neighbours for being front tiles
				for (local i=0; i > offsets.len(); i++) {
					frontTile = myTile + offsets[i];
					//	if we can build between the front tile and the proposed depot tile...
					if (AIRoad.BuildRoad(myTile, frontTile)) {
						//	run the pathfinder from the front tile to the station
						Pathfinder.InitializePath(Station, myTile);
						Pathfinder.PresetStreetcar();
						Pathfinder.Set.max_cost(Pathfinder.get.tile() * 2 * AITile.DistanceManhattan(Station, myTile));
						Pathfinder.FindPath();
						
						//	See if the pathfinder was successful
						if (Pathfinder.GetPathLength() > 1) {
							//	if yes, build everything
							Money.FundsRequest(Pathfinder.GetBuildCost() * 1.1);
							AIRoad.BuildRoad(myTile, frontTile);
							AIRoad.BuildRoadDepot(myTile, frontTile);
							Pathfinder.BuildPath();
							myDepot = myTile;
							KeepTrying = false;
						}
					}
				}
			}
		}
	}
	
	return myDepot;
}
