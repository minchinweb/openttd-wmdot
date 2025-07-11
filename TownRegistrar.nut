/*	Town Registrar v.1, r.221, [2012-01-28]
 *		part of WmDOT v.9
 *	Copyright © 2011-12 by W. Minchin. For more info,
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
 
/*	The Town Registrar
 *			Registrar - n. someone responsible for keeping records
 *		The Town Registrar keeps track of all things town related and is
 *		responsible to dividing the map into neighbourhoods, providing the town
 *		list to OpDOT, and recording connections make.
 *		No expenditures. No revenue stream.
 */
 
 class TownRegistrar {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 221; }
	function GetDate()          { return "2011-01-28"; }
	function GetName()          { return "Town Registrar"; }
		
	_MaxAtlasSize = null;
	_PopLimit = null;
	_WorldSize = null;
	_ListOfNeighbourhoods = null;
	_LookUpList = null;		//	An array, where the index corresponds to the
							//		TownID and the value is the neighbourhood
							//		the town is in
//	_NeighbourhoodCapitalToHQ = null;
	_ConnectionsTT = null;	//	town<>town connections
//	_ConnectionsTN = null;	//	town<>neighbourhood connections
//	_ConnectionsNN = null;	//	neighbourhood<>neighbourhood connections
							//		2D arrays. The index corresponds to the
							//			town (or neighbourhood) in question,
							//			and the array at that index is the
							//			connections out.
//	_ConnectedHeap = null;
//	_UnconnectedHeap = null;
	
	_NextRun = null;
	_UpdateInterval = null;
	_Mode = null;
	
	Log = null;
	
	constructor()
	{
		this._MaxAtlasSize = 50;
		this._NextRun = 0;
		this._UpdateInterval = 65000;	//	6500 is about a year
		//	TO-DO:
		//		- Lower this to 6500, but then _ConnectionsTN & _ConnectionsNN
		//			need to be remapped based on _ConnectionsTT 
		this._Mode = 1;
		this._PopLimit = 0;
		this._ListOfNeighbourhoods = [];
		this._LookUpList = [];
//		this._NeighbourhoodCapitalToHQ = [];
		this._ConnectionsTT = [];
//		this._ConnectionsTN = [];
//		this._ConnectionsNN = [];
//		this._ConnectedHeap = Fibonacci_Heap();
//		this._UnconnectedHeap = Fibonacci_Heap();
		
		Log = OpLog();
		
		this.State = this.State(this);
		this.Settings = this.Settings(this);
	}
}

class TownRegistrar.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "PopLimit":			this._main._PopLimit = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "PopLimit":			return this._main._PopLimit; break;
			default: throw("the index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
 }

class TownRegistrar.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
			case "Mode":			return this._main._Mode; break;
			case "NextRun":			return this._main._NextRun; break;
//			case "ROI":				return this._main._ROI; break;
//			case "Cost":			return this._main._Cost; break;
			case "NeighbourhoodCount":	return this._main._ListOfNeighbourhoods.len(); break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function TownRegistrar::LinkUp() 
{
	this.Log = WmDOT.Log;
	this._PopLimit = WmDOT.GetSetting("OpDOT_MinTownSize");
	this._MaxAtlasSize = WmDOT.GetSetting("TownRegistrar_AtlasSize");
	Log.Note(this.GetName() + " linked up!",3);
}

function TownRegistrar::Run()
{
//	Running the Town Registrar will destroy previous neighbourhoods
//	Call TownRegistrar::LinkUp() before calling this function for the first time
	local tick = AIController.GetTick();
	this._NextRun = tick;
	Log.Note("Town Registrar's office open at tick " + tick + " . Population Limit is " + this._PopLimit + ".",1);
	
	if (this._Mode == 1) {
		this._PopLimit = WmDOT.GetSetting("OpDOT_MinTownSize");
	}
	
	local ListOfTowns = AITownList();
	this._WorldSize = ListOfTowns.Count();
	ListOfTowns.Valuate(AITown.GetPopulation);
	ListOfTowns.KeepAboveValue(this._PopLimit);
	
	if (ListOfTowns.Count() > 0) {	
		local WmTownArray = [];
		WmTownArray.resize(ListOfTowns.Count());
		local iTown = ListOfTowns.Begin();
		for(local i=0; i < ListOfTowns.Count(); i++) {
			WmTownArray[i]=iTown;
			iTown = ListOfTowns.Next();
		}
		
		_ListOfNeighbourhoods = [];
		_ListOfNeighbourhoods.push(Neighbourhood(0,WmTownArray));
		// If WorldSize < MaxAtlasSize, dump everyone in the same neighbourhood and be done with it
	//	ListOfTowns.Valuate(AITown.GetTownID);
		local SplitMore = true;
		while (SplitMore == true) {
			SplitMore = false;
			for (local i = 0; i < this._ListOfNeighbourhoods.len(); i++) {
				if (this._ListOfNeighbourhoods[i].GetSize() > this._MaxAtlasSize) {
					Log.Note("Spliting neighbourhood " + i + "...",3);
					local Splinters = [2];
					Splinters = this._ListOfNeighbourhoods[i].SplitNeighbourhood();
					this._ListOfNeighbourhoods[i].UpdateTownList(Splinters[0]);
					this._ListOfNeighbourhoods.push(Neighbourhood(this._ListOfNeighbourhoods.len(), Splinters[1]));
					SplitMore = true;	//	Double check we've done everyone by taking another run
					i--;				//	Double check this neighbourhood
				}
			}
		}
		
		this._LookUpList = MapTownsToNeighbourhoods(this._WorldSize, this._ListOfNeighbourhoods);
		this._ConnectionsTT.resize(this._WorldSize);
	//	this._ConnectionsTN.resize(this._WorldSize);
	//	this._ConnectionsNN.resize(this._ListOfNeighbourhoods.len());
		
		for  (local i = 0; i < this._WorldSize; i++) {
			this._ConnectionsTT[i] = [];
	//		this._ConnectionsTN[i] = [];
		}
	//	for  (local i = 0; i < this._ConnectionsNN.len(); i++) {
	//		this._ConnectionsNN[i] = [];
	//	}

		Log.Note(this._ListOfNeighbourhoods.len() + " neighbourhoods generated. Took " + (AIController.GetTick() - tick) + " ticks.", 3);
		Log.Note("The Registry is:" ,7);
		Log.Note(Array.ToString1D(this._LookUpList, true, true), 7);

		if (Log.UpdateDebugLevel() >= 6) {
			for (local i = 0; i < this._ListOfNeighbourhoods.len(); i++) {
				this._ListOfNeighbourhoods[i].MarkOut();
			}
		}

		this._NextRun += this._UpdateInterval;
	} else {
		Log.Warning("No towns large enough to generate neighbourhoods. Took " + (AIController.GetTick() - tick) + " ticks.");
		this._NextRun = this._NextRun + (this._UpdateInterval / 10);
		WmDOT.DOT.State.NextRun = this._NextRun + 75;		// plus a game day
	}
//	return null;
}

//	this._TownArray = Towns.GenerateTownList(this._Mode);
function TownRegistrar::GenerateTownList(HQTown) {
	//	Generates the town list for OpDOT
	//	The town list corresponds to the neighbourhood where the HQ is located

	local neighbourhood_number = this._LookUpList[HQTown];
	if (neighbourhood_number == null) {
		Log.Warning("HQTown is not in the Town Registry (population too small?).")
		//	return empty list
		return [];
	}

	local neighbourhood_towns = this._ListOfNeighbourhoods[neighbourhood_number];
	local my_towns = neighbourhood_towns.GetTowns();

	return my_towns;
}

function TownRegistrar::GenerateCapitalToHQArray(HQTown)
{
//	Generates an array that lists the distance from the capital of each
//		neighbourhood to the HQTown
	this._NeighbourhoodCapitalToHQ.resize(this._ListOfNeighbourhoods.len());
	for (local i = 0; i < this._ListOfNeighbourhoods.len(); i++) {
		this._NeighbourhoodCapitalToHQ[i] = AIMap.DistanceManhattan(AITown.GetLocation(HQTown),AITown.GetLocation(this._ListOfNeighbourhoods[i].GetHighestPopulation() ) );
	}
}

function TownRegistrar::RegisterConnection(TownA, TownB)
{
//	After building or finding a connection, the Town Registrar records it as a
//		town<>town, a town<>neighbourhood, and a neighbourhood<>neighbourhood
//		connection
	if (Array.ContainedIn1D(this._ConnectionsTT[TownA], TownB) != true) {
		this._ConnectionsTT[TownA].push(TownB);
		this._ConnectionsTT[TownB].push(TownA);
		if (Array.ContainedIn1D(this._ConnectionsTN[TownA], this._LookUpList[TownB]) != true) {
			this._ConnectionsTN[TownA].push(this._LookUpList[TownB]);
			if (Array.ContainedIn1D(this._ConnectionsNN[this._LookUpList[TownA]], this._LookUpList[TownB]) != true) {
				this._ConnectionsNN[this._LookUpList[TownA]].push(this._LookUpList[TownB]);
				this._ConnectionsNN[this._LookUpList[TownB]].push(this._LookUpList[TownA]);
			}
		}
		if (Array.ContainedIn1D(this._ConnectionsTN[TownB], this._LookUpList[TownA]) != true) {
			this._ConnectionsTN[TownB].push(this._LookUpList[TownA]);
		}
		
		if (this._ConnectedHeap.Exists(TownA) != true) {
			this._ConnectedHeap.Inset(TownA, AITown.GetPopulation(TownA));
		}
		if (this._ConnectedHeap.Exists(TownB) != true) {
			this._ConnectedHeap.Inset(TownB, AITown.GetPopulation(TownB));
		}
	}
}

function TownRegistrar::UpdateMode(NewMode = 1)
{
//	Changes the mode TownRegistrar is running in and sets it to run on the
//	next pass
//		Mode 0 = considers all towns, regardless of population (or allows you
//					to set the population limit) (set population following this
//					call but before you allow TownRegistrar to run again)
//		Mode 1 = Abides by OpDOT's Population Limit
	this._Mode = NewMode;
	if (NewMode == 1) {
		this._PopLimit = WmDOT.GetSetting("OpDOT_MinTownSize");
	}
	this._NextRun = AIController.GetTick();
}
