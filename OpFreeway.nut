/*	Operation Freeway v.1, [2012-12-29],  
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
 
/*	Operation Freeways
 *		Operation Freeways builds off of OpDOT and the Dominion Land System
 *		(grid roads in MetaLibrary) to build 'rural' freeways. It does this by
 *		turning straight stretches of roads between grid points into two
 *		one-way roads running side by side.
 */

class OpFreeway {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return 121229; }
	function GetDate()          { return "2012-12-29"; }
	function GetName()          { return "Operation Freeway"; }

	_NextRun = null;
	_RoadType = null;
	_tiles = null;

	Log = null;
	Money = null;
	Pathfinder = null;

	constructor()
	{
		this._NextRun = 13001;
		this._RoadType = AIRoad.ROADTYPE_ROAD;
		
//		this.Settings = this.Settings(this);
		this.State = this.State(this);
		Log = OpLog();
		Money = OpMoney();
		Pathfinder = RoadPathfinder();
	}

}

class OpFreeway.State {

	_main = null;
	
	function _get(idx)
	{
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			default: throw("The index '" + idx + "' does not exist");
		}
	}
	
	function _set(idx, val)
	{
		switch (idx) {
			case "NextRun":				this._main._NextRun = val; break;
			default: throw("The index '" + idx + "' does not exist");
		}
		return val;
	}
	
	constructor(main)
	{
		this._main = main;
	}
}

function OpFreeway::LinkUp() 
{
	this.Log = WmDOT.Log;
	this.Money = WmDOT.Money;
	this.Pathfinder = WmDOT.DLS;
	Log.Note(this.GetName() + " linked up!",3);
}
 
function OpFreeway::AcceptPath(PathToTiles) {
	//	TO-DO: add safety check to input here
	this._tiles = PathToTiles;
	return;
}

function OpFreeway::SetToRun() {
	//	sets OpFreeway to run on next pass
	this._NextRun = AIController.GetTick();
	return this._NextRun;
}

function OpFreeway::Run() {
	//	runs over the list of tiles in the tiles array.
	//	when it reaches a grid point, it goes until it reaches another grid
	//	point, or the path changes direction
	//	if it goes from grid point to grid point without changing direction, it
	//	will add a second road parallel to the first and turn the two of them
	//	into a couplet of one-way roads, one in each direction
	Log.Note("OpFreeway running at tick " + AIController.GetTick() + ".",1);

	//	check to see if we're turned on
	if ((WmDOT.GetSetting("Freeways") != 1) || (AIGameSettings.IsDisabledVehicleType(AIVehicle.VT_ROAD) == true)) {
		this._NextRun = AIController.GetTick() + 13001;			//	6500 ticks is about a year
		Log.Note("** OpFreeway has been disabled. **", 0);
		return;
	}

	//	check to see if we have tiles to work with
	if (this._tiles == null) {
		Log.Note("No tile array for OpFreeway... skipping!", 2);
		this._NextRun = AIController.GetTick() + 13001;
		return;
	}

	//	We're here if we have tiles
	for (local i=0; i < this._tiles.len() - 2; i++) {
		//	loop over tiles
		local StartTile = this._tiles[i];
		local NextTile;
		local EndTile = null;
		Log.Note("i: " + i + " Tile:" + Array.ToStringTiles1D([StartTile], false) + " Grid Point: " + Pathfinder.IsGridPoint(StartTile),5);
		if (Pathfinder.IsGridPoint(StartTile)) {
			//	is tile a grid point? if not, skip
			local BeforeTile = StartTile;
			local myDirection = Direction.GetDirectionToTile(this._tiles[i], this._tiles[i+1]);
			local oldDirection;
			do {
				oldDirection = myDirection;
				i++;
				NextTile = this._tiles[i];
				myDirection = Direction.GetDirectionToTile(BeforeTile, NextTile);
				if (Pathfinder.IsGridPoint(NextTile) && (oldDirection == myDirection)) {
					//	if we get to the next grid point and haven't changed
					//	direction, Build couplet!

					//	Which way do we shift?
					local Shift;
					if ((myDirection == Direction.DIR_NW) || (myDirection == Direction.DIR_SE)) {
						Shift = Direction.DIR_SW;
					} else if ((myDirection == Direction.DIR_NE) || (myDirection == Direction.DIR_SW)) {
						Shift = Direction.DIR_SE;
					} else {
						Log.Warning ("OpFreeway.Run without direction shift!!");
					}
					// Get shifted endpoints
					local End1 = Direction.GetAdjacentTileInDirection(StartTile, Shift);
					local End2 = Direction.GetAdjacentTileInDirection(NextTile, Shift);
					local SquareEnd11 = StartTile;
					local SquareEnd12 = Direction.GetAdjacentTileInDirection(SquareEnd11, Direction.DIR_SW);
					local SquareEnd13 = Direction.GetAdjacentTileInDirection(SquareEnd12, Direction.DIR_SE);
					local SquareEnd14 = Direction.GetAdjacentTileInDirection(SquareEnd13, Direction.DIR_NE);
					local SquareEnd21 = NextTile;
					local SquareEnd22 = Direction.GetAdjacentTileInDirection(SquareEnd21, Direction.DIR_SW);
					local SquareEnd23 = Direction.GetAdjacentTileInDirection(SquareEnd22, Direction.DIR_SE);
					local SquareEnd24 = Direction.GetAdjacentTileInDirection(SquareEnd23, Direction.DIR_NE);

					//	test to see if we can build from End1 to End2
					//	this won't work if we need a bridge or a tunnel
					AIRoad.SetCurrentRoadType(this._RoadType);
					local BuildingMode = AITestMode();
					local BeanCounter = AIAccounting();				//	To figure out costs	
					if (AIRoad.BuildRoad(End1, End2)) {
						Log.Note("Parallel road buildable!", 6);
						//	Build some roads for costs only
						AIRoad.BuildRoad(End1, StartTile);
						AIRoad.BuildRoad(End2, NextTile);
						AIRoad.BuildRoad(SquareEnd11, SquareEnd12);
						AIRoad.BuildRoad(SquareEnd12, SquareEnd13);
						AIRoad.BuildRoad(SquareEnd13, SquareEnd14);
						AIRoad.BuildRoad(SquareEnd14, SquareEnd11);
						AIRoad.BuildRoad(SquareEnd21, SquareEnd22);
						AIRoad.BuildRoad(SquareEnd22, SquareEnd23);
						AIRoad.BuildRoad(SquareEnd23, SquareEnd24);
						AIRoad.BuildRoad(SquareEnd24, SquareEnd21);

						local BuildingMode2 = AIExecMode();			//	Now for real
						Money.FundsRequest(BeanCounter.GetCosts());	//	Get the money we need
						AIRoad.BuildRoad(End1, End2);				//	Build it!
						AIRoad.BuildRoad(SquareEnd11, SquareEnd12);
						AIRoad.BuildRoad(SquareEnd12, SquareEnd13);
						AIRoad.BuildRoad(SquareEnd13, SquareEnd14);
						AIRoad.BuildRoad(SquareEnd14, SquareEnd11);
						AIRoad.BuildRoad(SquareEnd21, SquareEnd22);
						AIRoad.BuildRoad(SquareEnd22, SquareEnd23);
						AIRoad.BuildRoad(SquareEnd23, SquareEnd24);
						AIRoad.BuildRoad(SquareEnd24, SquareEnd21);

						local String1 = "" + AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd12) + " || " + AIRoad.AreRoadTilesConnected(SquareEnd13, SquareEnd14) + ", " + AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd14) + " || " + AIRoad.AreRoadTilesConnected(SquareEnd12, SquareEnd13) + ", " + AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd22) + " || " + AIRoad.AreRoadTilesConnected(SquareEnd23, SquareEnd24) + ", " + AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd24) + " || " + AIRoad.AreRoadTilesConnected(SquareEnd22, SquareEnd23);
						local String2 = "" + (AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd12) || AIRoad.AreRoadTilesConnected(SquareEnd13, SquareEnd14)) + " &&  " + (AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd14) || AIRoad.AreRoadTilesConnected(SquareEnd12, SquareEnd13)) + " &&  " + (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd22) || AIRoad.AreRoadTilesConnected(SquareEnd23, SquareEnd24)) + " &&  " + (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd24) || AIRoad.AreRoadTilesConnected(SquareEnd22, SquareEnd23));
						local String3 = "" + ((AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd12) || AIRoad.AreRoadTilesConnected(SquareEnd13, SquareEnd14)) && (AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd14) || AIRoad.AreRoadTilesConnected(SquareEnd12, SquareEnd13)) && (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd22) || AIRoad.AreRoadTilesConnected(SquareEnd23, SquareEnd24)) && (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd24) || AIRoad.AreRoadTilesConnected(SquareEnd22, SquareEnd23)));
						Log.Note("Connections : " + String1 + " : " + String2 + " : " + String3, 6);
						if ((AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd12) || AIRoad.AreRoadTilesConnected(SquareEnd13, SquareEnd14)) && (AIRoad.AreRoadTilesConnected(SquareEnd11, SquareEnd14) || AIRoad.AreRoadTilesConnected(SquareEnd12, SquareEnd13)) && (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd22) || AIRoad.AreRoadTilesConnected(SquareEnd23, SquareEnd24)) && (AIRoad.AreRoadTilesConnected(SquareEnd21, SquareEnd24) || AIRoad.AreRoadTilesConnected(SquareEnd22, SquareEnd23))) {
							//	Build one way arrows
							//	To-Do: check for exiting one-way road so we don't make the road no-entry or remove the one-way-ness
							local OneWay11;
							local OneWay12;
							local OneWay21;
							local OneWay22;
							if (max(max(max(StartTile, NextTile), End1), End2) == StartTile) {
								Log.Note("StartTile [1] is largest." + Array.ToStringTiles1D([StartTile, NextTile, End1, End2]), 6);
								OneWay11 = StartTile;
								OneWay12 = NextTile;
								OneWay21 = End2;
								OneWay22 = End1;
							} else if (max(max(max(StartTile, NextTile), End1), End2) == NextTile) {
								Log.Note("NextTile [2] is largest." + Array.ToStringTiles1D([StartTile, NextTile, End1, End2]), 6);
								OneWay11 = NextTile;
								OneWay12 = StartTile;
								OneWay21 = End1;
								OneWay22 = End2;
							} else if (max(max(max(StartTile, NextTile), End1), End2) == End1) {
								Log.Note("End1 [3] is largest." + Array.ToStringTiles1D([StartTile, NextTile, End1, End2]), 6);
								OneWay11 = End1;
								OneWay12 = End2;
								OneWay21 = NextTile;
								OneWay22 = StartTile;
							} else if (max(max(max(StartTile, NextTile), End1), End2) == End2) {
								Log.Note("End2 [4] is largest." + Array.ToStringTiles1D([StartTile, NextTile, End1, End2]), 6);
								OneWay11 = End2;
								OneWay12 = End1;
								OneWay21 = StartTile;
								OneWay22 = NextTile;
							} else {
								Log.Warning("None are largest!!" + Array.ToStringTiles1D([StartTile, NextTile, End1, End2]));
								break;
								//	should never get here
							}
							
							local from = OneWay11;
							local to;
							for (local i = 0; i < AIMap.DistanceManhattan(OneWay11, OneWay12); i++) {
								to = Direction.GetAdjacentTileInDirection(from, Direction.GetDirectionToTile(from, OneWay12));
								Log.Note("OneWay 1 " + Array.ToStringTiles1D([from, to]), 7);
								AIRoad.BuildOneWayRoad(from, to);
								from = to;
							}

							from = OneWay21;
							for (local i = 0; i < AIMap.DistanceManhattan(OneWay21, OneWay22); i++) {
								to = Direction.GetAdjacentTileInDirection(from, Direction.GetDirectionToTile(from, OneWay22));
								Log.Note("OneWay 2 " + Array.ToStringTiles1D([from, to]), 7);
								AIRoad.BuildOneWayRoad(from, to);
								from = to;
							}
						} else {
							Log.Note("Not building one-way section...", 6);
						}
					}
					i--;
					i--;
				}
				BeforeTile = NextTile;

				if (oldDirection != myDirection) {
					//	if direction changes, break while loop
					break;
				}
			} while (i < this._tiles.len() - 1)
			EndTile = null;
		}
	}

	this._tiles = null;
	this._NextRun = AIController.GetTick() + 13001;
	return;
}