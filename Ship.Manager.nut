/*	Ship Manager v.3, [2025-07-14]
 *		part of WmDOT v.15
 *	Copyright © 2012 by W. Minchin. For more info,
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

/*	Ship Manager takes existing ship routes and add and deletes ships as needed.
 */

class ManShips {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return 250714; }
	function GetDate()          { return "2025-07-14"; }
	function GetName()          { return "Ship Manager"; }


	_NextRun = null;
	_SleepLength = null;  //	as measured in days; time between runs
	_EngineSpeepLength = null;  // as measured in days; time between engine checks
	_AllRoutes = null;
	_ShipsToSell = null;  //	Vehicles are actually sold in the Event Manager

	Log = null;
	Money = null;

	constructor() {
		this._NextRun = 0;
		this._SleepLength = 30;
		this._EngineSpeepLength = 365;
		this._AllRoutes = [];
		this._ShipsToSell = [];

		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
	}
}

class ShipRoute {
	_FirstShipID = null;		// ID of Ship
	_Capacity = null;			// in tons
	_Cargo = null;				// what do we carry
	_SourceStation = null;		// StationID of where cargo is picked up
	_DestinationStation = null;	// StationID of where cargo is going
	_Depot = null;				// TileID of depot
	_LastUpdate = null;			// last time (in ticks) that the route was updated
	_LastEngineCheck = null;	// last time (in ticks) that the engine in use on this route was checked
	_GroupID = null;			// ID of Group containing Ship
}

class ManShips.Settings {

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

class ManShips.State {

	_main = null;

	function _get(idx) {
		switch (idx) {
			// case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
			// case "ROI":			return this._main._ROI; break;
			// case "Cost":			return this._main._Cost; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
}

function ManShips::LinkUp() {
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;

	Log.Note(this.GetName() + " linked up!",3);
}


function ManShips::Run() {
	Log.Note("Ship Manager (Ship Count) running at tick " + AIController.GetTick() + ".", 1);

	if (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_WATER) == true) {
		this._NextRun = AIController.GetTick() + 13001;			//	6500 ticks is about a year
		Log.Note("** Ships (for this AI) have been disabled. **", 0);
		return;
	}

	//	reset counter
	this._NextRun = AIController.GetTick() + this._SleepLength * 17;	//	SleepLength in days

	RecheckEngine();
	CheckVehicleCount();
}

/** \brief  Consider each route to decide if the right number of vehicles has
 *			been provided.
 */
function CheckVehicleCount() {
	Log.Note("Considering Route : (Waiting Cargo) > (Per-ship Capacity) ? (more vehicles needed)", 4);

	for (local i = 0; i < this._AllRoutes.len(); i++) {
		//	Add Ships
		Log.Note(
			"Considering Route № " + i + "... "
			+ AIStation.GetCargoWaiting(
				this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo
			)
			+ " > "
			+ this._AllRoutes[i]._Capacity
			+ " ? "
			+ (AIStation.GetCargoWaiting(
				this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo
			  ) > this._AllRoutes[i]._Capacity),
			3
		);

		if (AIStation.GetCargoWaiting(this._AllRoutes[i]._SourceStation, this._AllRoutes[i]._Cargo) > this._AllRoutes[i]._Capacity) {
			Money.FundsRequest(AIEngine.GetPrice(AIVehicle.GetEngineType(this._AllRoutes[i]._FirstShipID)) * 1.1);
			local MyVehicle;
			MyVehicle = AIVehicle.CloneVehicle(this._AllRoutes[i]._Depot, this._AllRoutes[i]._FirstShipID, true);
			AIVehicle.StartStopVehicle(MyVehicle);
			Log.Note("New Vehicle Added: " + MyVehicle, 4);
			this._AllRoutes[i]._LastUpdate = AIController.GetTick();
		} else {
			//  Delete extra ships
			//	if there are three ships waiting at to fill up, delete them
			local Waiting = AIVehicleList();
			Log.Note(Waiting.Count() + " vehicles...", 6);
			Waiting.Valuate(AIVehicle.GetVehicleType);
			Waiting.KeepValue(AIVehicle.VT_WATER);
			Log.Note(Waiting.Count() + " ships...", 6);
			Waiting.Valuate(AIVehicle.GetCapacity, this._AllRoutes[i]._Cargo);
			Waiting.KeepAboveValue(0);
			Log.Note(Waiting.Count() + " ships that carry " + AICargo.GetCargoLabel(this._AllRoutes[i]._Cargo) + "...", 6);
			Waiting.Valuate(MetaLib.Station.DistanceFromStation, this._AllRoutes[i]._SourceStation);
			Waiting.KeepBelowValue(6);
			Log.Note(Waiting.Count() + " ships close enough...", 6);
			local FirstCount = Waiting.Count();
			if (FirstCount > 3) {
				Waiting.Valuate(AIVehicle.GetCargoLoad, this._AllRoutes[i]._Cargo);
				Waiting.KeepBelowValue(1);
				Log.Note(Waiting.Count() + " ships empty enough...", 6);
				Waiting.Sort(AIList.SORT_BY_ITEM, AIList.SORT_DESCENDING);
				local SellVehicle;
				SellVehicle = Waiting.Begin();
				//	Skip the first vehicle at least...
				do {
					SellVehicle = Waiting.Next();
					AIVehicle.SendVehicleToDepot(SellVehicle);
					this._ShipsToSell.push(SellVehicle);
					Log.Note("Vehicle №" + SellVehicle + " sent to depot to be sold.", 4);
				} while (!Waiting.IsEnd())
			}
		}
	}
}

/**	\brief	Consider each route to determine if the Engine is use should be
 *			changed.
 *
 *	This doubles as a check for vehicle aging out.
 */
function RecheckEngine() {
	for (local i = 0; i < this._AllRoutes.len(); i++) {
		local _prime_vehicle = this._AllRoutes[i]._FirstShipID;
		local _start_station = this._AllRoutes[i]._SourceStation;
		local _end_station = this._AllRoutes[i]._DestinationStation;
		local _cargo = this._AllRoutes[i]._Cargo;
		local _group = this._AllRoutes[i]._GroupID;

		local _monthly_cargo = AIStation.GetCargoPlanned(_start_station, _cargo);
		local _current_engine = AIVehicle.GetEngineType(_prime_vehicle);
		local _current_capacity = AIVehicle.GetCapacity(_prime_vehicle, _cargo);
		local _travel_distance = 0;
		for (i = 0; i < AIOrder.GetOrderCount(_prime_vehicle) - 1; i++) {
			local _o1 = AIOrder.GetOrderDestination(_prime_vehicle, i);
			local _o2 = AIOrder.GetOrderDestination(_prime_vehicle, i + 1);
			_travel_distance = AIMap.DistanceManhattan(_o1, _o2);
		}
		_travel_distance = AIMap.DistanceManhattan(
			AIOrder.GetOrderDestination(_prime_vehicle, AIOrder.GetOrderCount(_prime_vehicle)),
			AIOrder.GetOrderDestination(_prime_vehicle, 0)
		);
		local _pay_distance = AIMap.DistanceManhattan(
			AIBaseStation.GetLocation(_start_station),
			AIBaseStation.GetLocation(_end_station)
		);
		local _travel_ratio = (_travel_distance.tofloat() / _pay_distance.tofloat() * 100).tointeger();

		Log.Note(
			"Confirming Engine for Route № " + i + "... using "
			+ AIEngine.GetName(_current_engine) + " (" + _current_engine + "),"  // current engine
			+ " carries " _current_capacity + " tons of " + AICargo.GetCargoLabel(_cargo), // cargo capacity
			3
		);
		Log.Note(
			// "     " +
			"from " + AIBaseStation.GetName(_station_station) // from station
			+ " to " + AIBaseStation.GetName(_end_station)  // to station
			+ " with production of " + _monthly_cargo + " ton/month.",  // station cargo volume (monthly)
			4
		);
		Log.Note(
			// "     " +
			"travel distance of " + _travel_distance
			+ " on pay distance of " + _pay_distance
			+ " (gives a ratio of " + _travel_ratio + "%).",
			4
		);

		Engines.Valuate(Marine.RateShips3, _cargo, _monthly_cargo, _travel_distance, _pay_distance);

		//	Only keep the vehicles expected to make a
		//	profit
		Engines.KeepAboveValue(0);
		//	Pick the best rated one
		Engines.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

		if (Engines.Count() > 0) {
			local _picked_engine = Engines.Begin();
			if (_picked_engine == _current_engine) {
				Log.Note("Current engine still best. No changes.", 4);
			} else {
				Log.Note(
					"     Engine " + _picked_engine +
					" (" + AIEngine.GetName(_picked_engine) + ")"
					" came back better rated. Setting up auto-replace.",
					3
				);
				AIGroup.SetAutoReplace( _group, _current_engine, _picked_engine);
			}
		} else {
			Log.Note("     No profitable engine available. No changes.", 3);
		}

		this._AllRoutes[i]._LastEngineCheck = AIController.GetTick();
	}
}

function ManShips::AddRoute (ShipID, CargoNo) {
	local TempRoute = ShipRoute();
	TempRoute._FirstShipID = ShipID;
	TempRoute._Cargo = CargoNo;
	TempRoute._Capacity = AIVehicle.GetCapacity(ShipID, CargoNo);

	for (local i = 0; i < AIOrder.GetOrderCount(ShipID); i++) {
		local _first_station = true
		if (AIOrder.IsGotoStationOrder(ShipID, i) == true) {
			if (_first_station == true) {
				TempRoute._SourceStation = AIStation.GetStationID(AIOrder.GetOrderDestination(ShipID, i));
				TempRoute._Depot = Marine.NearestDepot(AIOrder.GetOrderDestination(ShipID, i));
				_first_station = false;
			} else {
				// assumes the orders only include two stations
				// TODO: this isn't being provided properly and is breaking the
				// 			later engine check.
				TempRoute._DestinationStation = AIStation.GetStationID(AIOrder.GetOrderDestination(ShipID, i));
				i = 1000;	// break
			}
		}
	}

	// Name Ship --> format: Town_Name Cargo R[Route Number]-[incremented number]
	local temp_name = "";
	temp_name += AITown.GetName(AIStation.GetNearestTown(TempRoute._SourceStation));
	if (temp_name.len() > 19) { temp_name = temp_name.slice(0, 19); }	//	limit town name part to 19 characters
	temp_name = temp_name + " " + AICargo.GetCargoLabel(CargoNo) + " R";
	temp_name += (this._AllRoutes.len() + 1) + "-1";
	AIVehicle.SetName(ShipID, temp_name);

	// Create a Group for the route
	local group_number = AIGroup.CreateGroup(AIVehicle.VT_WATER, AIGroup.GROUP_INVALID);
	AIGroup.SetName(group_number, "Route " + (this._AllRoutes.len() + 1));
	AIGroup.MoveVehicle(group_number, ShipID);
	TempRoute._GroupID = group_number;

	// TempRoute._Depot = Marine.NearestDepot(TempRoute._SourceStation);
	TempRoute._LastUpdate = AIController.GetTick();
	TempRoute._LastEngineCheck = AIController.GetTick();

	this._AllRoutes.push(TempRoute);
	Log.Note("Route added! Ship " + TempRoute._FirstShipID + "; " + TempRoute._Capacity + " tons of " + AICargo.GetCargoLabel(TempRoute._Cargo) + "; starting at " + TempRoute._SourceStation + "; build at " + TempRoute._Depot + "; updated at tick " + TempRoute._LastUpdate + ".", 4);
}
// EOF
