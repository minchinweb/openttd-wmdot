/*	Event Handler v.1, r.252, [2012-06-30]
 *		part of WmDOT v.11
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

/*	Event Handler deals with events as OpenTTD feed them to the AI.
 */

class Events {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 252; }
	function GetDate()          { return "2012-06-30"; }
	function GetName()          { return "Event Handler"; }


	_NextRun = null;
	_SleepLength = null;	//	as measured in days

	Log = null;
	Money = null;
	Manager_Ships = null;

	constructor() {
		this._NextRun = 0;
		this._SleepLength = 3;

		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
		Manager_Ships = ManShips();
	}
}

class Events.Settings {
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

class Events.State {
	_main = null;

	function _get(idx) {
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
}

function Events::LinkUp()
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	this.Manager_Ships = WmDOT.Manager_Ships;

	Log.Note(this.GetName() + " linked up!",3);
}


function Events::Run() {
	Log.Note("Event Handler running at tick " + AIController.GetTick() + ".", 1);

	//	Reset next run
	this._NextRun = AIController.GetTick() + this._SleepLength * 17;

	// Handle Events
	while(AIEventController.IsEventWaiting()) {
		local Event = AIEventController.GetNextEvent();
		Log.Note("Event: " + Event.GetEventType(), 3);

		switch(Event.GetEventType()) {
			case AIEvent.ET_SUBSIDY_OFFER:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_SUBSIDY_OFFER_EXPIRED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_SUBSIDY_AWARDED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_SUBSIDY_EXPIRED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_COMPANY_NEW:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_COMPANY_IN_TROUBLE:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_COMPANY_MERGER:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_COMPANY_BANKRUPT:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_VEHICLE_LOST:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_VEHICLE_UNPROFITABLE:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_INDUSTRY_OPEN:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_INDUSTRY_CLOSE:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_ENGINE_AVAILABLE:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_STATION_FIRST_VEHICLE:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_DISASTER_ZEPPELINER_CRASHED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_DISASTER_ZEPPELINER_CLEARED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_TOWN_FOUNDED:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_AIRCRAFT_DEST_TOO_FAR:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_ADMIN_PORT:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_WINDOW_WIDGET_CLICK:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;
			case AIEvent.ET_GOAL_QUESTION_ANSWER:
				Log.Note("Nice event and all, but I have no idea what to do about it...", 4);
				break;

			case AIEvent.ET_COMPANY_ASK_MERGER:
				// Accept the merger is the company is a 'DOT' or the value is $2
				local Event2 = AIEventCompanyAskMerger.Convert(Event);
				local Company = Event2.GetCompanyID();
				local Value = Event2.GetValue();
				local Name = AICompany.GetName(Company);

				// if Name == null, then the company has ceased to exist, and
				// so we can't accept the merger.
				if (Name != null) {
					Name.find("DOT") == null
					if ((Name.find("DOT") != null) || (Value < 2)) {
						Money.FundsRequest(Value);
						local Accepted = Event2.AcceptMerger();
						Log.Note("Merger Accepted with " + Name + " (Value: " + Value + "£) : " + Accepted, 4);
					} else {
						Log.Note("Merger request with " + Name + " (Value: " + Value + "£) : Declined", 4);
					}
				} else {
					Log.Note("Merger offered, but we're too late.", 4);
				}
				break;

			case AIEvent.ET_VEHICLE_CRASHED:
				//	Clone the crashed vehicle
				local Event2 = AIEventVehicleCrashed.Convert(Event);
				local Reason = Event2.GetCrashReason();
				if (Reason == AIEventVehicleCrashed.CRASH_FLOODED) {
					//	don't replace if vehicle flooded out
					Log.Note("Vehicle flooded out!", 4);
				} else if (Reason == AIEventVehicleCrashed.CRASH_AIRCRAFT_NO_AIRPORT) {
					//	don't replace if there was no place to land
					Log.Note("Aircraft crashed because no airport to land at could be found...", 4);
				} else {
					local OldVehicle = Event2.GetVehicleID();
					Money.FundsRequest(AIEngine.GetPrice(AIVehicle.GetEngineType(OldVehicle)) * 1.1);
					//	Get the depot closest to the first order of the vehicle
					// TODO: check this
					local AllDepots = AIDepotList(AIVehicle.GetVehicleType(OldVehicle));
					AllDepot.Valuate(GetDistanceManhattanToTile, AIOrder.GetOrderDestination(OldVehicle, 0));
					local Depot = AllDepots.Begin();
					local NewVehicle;
					NewVehicle = AIVehicle.CloneVehicle(Depot, OldVehicle, true);
					AIVehicle.StartStopVehicle(NewVehicle);
					Log.Note("Crashed Vehicle Replaced: " + NewVehicle, 4);
				}
				break;

			case AIEvent.ET_VEHICLE_WAITING_IN_DEPOT:
				//	Sell the sucker!!
				//  TODO: Check to see if it is on the 'to sell' list
				local Event2 = AIEventVehicleWaitingInDepot.Convert(Event);
				local Vehicle = Event2.GetVehicleID();
				local Result = AIVehicle.SellVehicle(Vehicle);
				Log.Note("Vehicle " + Vehicle + " sold! : " + Result, 4);
				break;

			case AIEvent.ET_ENGINE_PREVIEW:
				//	Always accept
				local Event2 = AIEventEnginePreview.Convert(Event);
				local Name = Event2.GetName();
				local Result = Event2.AcceptPreview();
				Log.Note("Preview of " + Name + " accepted! : " + Result, 4);
				break;

			default:
				Log.Warning("                Unknown event type!!");
				break;
		}	// end	switch(Event.GetEventType())
	}	// end  while(AIEventController.IsEventWaiting())
}
