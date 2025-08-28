/*	Neighbourhood Class, v.1, r.221, [2012-01-28]
 *		part of Town Registrar v.1,
 *		part of WmDOT v.8
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

class NeighbourhoodInfo {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 221; }
	function GetDate()          { return "2012-01-28"; }
	function GetName()          { return "Neighbourhood Library"; }
}

class Neighbourhood {
	_index = null;
	_townlist = null;	//	townlist needs to be an array
	_size = null;
	_FloatOffset = null;

	_Info = null;
	Log = null;

	constructor () {
		this._size = 0;
		this._townlist = [];
		this._FloatOffset = 0.001;

		this._Info = NeighbourhoodInfo();
		this.Log = WmDOT.Log;
	}

	constructor (Index, Towns) {
		this._index = Index;
		this._townlist = Towns;
		this._size = this._townlist.len();
		this._FloatOffset = 0.001;

		this._Info = NeighbourhoodInfo();
		this.Log = WmDOT.Log;
	}

	function GetSize()			{ return this._size; }
	function GetTowns()			{ return this._townlist }
	function GetIndex()			{ return this._index; }

	function GetVersion()       { return this._Info.GetVersion(); }
	function GetRevision()		{ return this._Info.GetRevision(); }
	function GetDate()          { return this._Info.GetDate(); }
	function GetName()          { return this._Info.GetName(); }
}

/* function Neighbourhood::GetSize()
{
	return this._size;
} */

function Neighbourhood::SplitNeighbourhood() {
	//	Spliting the Neighbourhood takes the existing neighbourhood, finds the
	//		two biggest towns, and then creates two neighbourhoods by spliting
	//		the old neighbourhood by drawing a line between the two capitals
	//	Returns 2 element array, containing to arrays of the town ID's that
	//		fall into the two neighbourhoods

	local CapitalA = this.GetHighestPopulation();
	local CapitalB = this.GetHighestPopulation([CapitalA]);
	Log.Note("New capitals are " + AITown.GetName(CapitalA) + " and " + AITown.GetName(CapitalB) + ".",4);
	local xA = AIMap.GetTileX(AITown.GetLocation(CapitalA));
	local yA = AIMap.GetTileY(AITown.GetLocation(CapitalA));
	local xB = AIMap.GetTileX(AITown.GetLocation(CapitalB));
	local yB = AIMap.GetTileY(AITown.GetLocation(CapitalB));
	local dx = xA - xB;
	local dy = yA - yB;
	local avex = (xA + xB) / 2;
	local avey = (yA + yB) / 2;

	//	Solve a linear system:  ƒ(x) = y = mx + b
	local m = (dx + this._FloatOffset) / (dy + this._FloatOffset);		// slope
		//	FloatOffset is to avoid divide by zero problems
//	local b = yA - m * xA;												// y-intercept

	//	But we actually want the line that is perpenticular to and bisects the
	//		line between the two towns
	m = -m;
	local b = avey - m * avex;

	local NA = [];
	local NB = [];

	local xtest, ytest, ydivide;

	for (local i = 0; i  < this._townlist.len(); i++) {
		xtest = AIMap.GetTileX(AITown.GetLocation(this._townlist[i]));
		ytest = AIMap.GetTileY(AITown.GetLocation(this._townlist[i]));
		ydivide = m * xtest + b;
		if (ytest < ydivide) {
			NA.push(this._townlist[i]);
		} else {
			NB.push(this._townlist[i]);
		}
	}

	Log.Note("NA is: " + Array.ToString1D(NA), 4);
	Log.Note("NB is: " + Array.ToString1D(NB), 4);


	return [NA, NB];
}

function Neighbourhood::GetHighestPopulation(IgnoreList = [-1]) {
	//	Returns the town with the highest population
	//	TownID's on the Ignore list will not be returned
	local HighPop = 0;
	local KeepIndex = -1;

	for (local i = 0; i  < this._townlist.len(); i++) {
		if ((Array.ContainedIn1D(IgnoreList, this._townlist[i]) != true) && AITown.GetPopulation(this._townlist[i]) > HighPop) {
			KeepIndex = this._townlist[i];
			HighPop = AITown.GetPopulation(this._townlist[i]);
		}
	}

	return KeepIndex;
}

function Neighbourhood::UpdateTownList(NewTowns) {
	//	Bulk updates the town list (this completely replaces it! use with
	//		caution)
	this._townlist = NewTowns;
	this._size = this._townlist.len();
}

function MapTownsToNeighbourhoods(WorldSize, ListOfNeighbourhoods) {
	//	Returns an array where the index corresponds to the townID and the
	//		value at that index corresponds to the Neighbourhood it's in
	local LookUpList = [];
	LookUpList.resize(WorldSize);

	for (local i = 0; i < ListOfNeighbourhoods.len(); i++) {
		for (local j = 0; j < ListOfNeighbourhoods[i]._townlist.len(); j++) {
			LookUpList[ListOfNeighbourhoods[i]._townlist[j]] = i;
		}
	}

	//	Remove existing signs
	SuperLib.Helper.ClearAllSigns();	//	I don't like this really, but I
										//	don't put signs elsewhere, so this
										//	isn't a problem (yet...)

	return LookUpList;
}

function Neighbourhood::MarkOut() {
	//	When called, posts signs at the town centre of each town in the
	//		neighbourhood with the neighbourhood's index number. The capital is
	//		noted with stars **

	//	Now place
	Log.Sign(AITown.GetLocation(this._townlist[0]), "** " + this._index + " **", 5);
		for (local i = 1; i < this._townlist.len(); i++) {
			Log.Sign(AITown.GetLocation(this._townlist[i]), this._index, 7);
		}
}

// EOF
