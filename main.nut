/*	WmDOT v.11, [2011-12-29]
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

import("util.MinchinWeb", "MetaLib", 6);
//	RoadPathfinder <- MetaLib.RoadPathfinder;
	RoadPathfinder <- MetaLib.DLS;
	ExistingRoadPathfinder <- MetaLib.RoadPathfinder;
	Array <- MetaLib.Array;
	Atlas <- MetaLib.Atlas;
	Marine <- MetaLib.Marine;
	OpLog <- MetaLib.Log;
import("util.superlib", "SuperLib", 27);		//	For loan management
	SLMoney <- SuperLib.Money;
	Helper <- SuperLib.Helper;
	Direction <- SuperLib.Direction;
//	AIAbstractList <- AIList	// to support SuperLib v.21
		
require("OpDOT.nut");				//	OperationDOT
require("OpMoney.nut");				//	Operation Money
require("TownRegistrar.nut");		//	Town Registrar
require("Neighbourhood.nut");		//	Neighbourhood Class	
// require("Fibonacci.Heap.WM.nut");	//	Fibonacci Heap (Max)
require("Cleanup.Crew.nut");		//	Cleanup Crew
require("OpHibernia.nut");			//	Operation Hibernia
require("Ship.Manager.nut");		//	Ship Manager
require("Event.Handler.nut");		//	Event Handler
require("OpFreeway.nut");			//	Freeway Builder
		

 
 class WmDOT extends AIController 
{
	//	SETTINGS
	WmDOTv = 11;
	/*	Version number of AI
	 */	
	WmDOTr = 121229;
	/*	Reversion number of AI
	 */
	 
	SingleLetterOdds = 7;
	/*	Control on single letter companies.  Set this value higher to increase
	 *	the chances of a single letter DOT name (eg. 'CDOT').		
	 */
	
	//	END SETTINGS
	
	Log = OpLog();
	Towns = TownRegistrar();
	Money = OpMoney();
	DOT = OpDOT();
	CleanupCrew = OpCleanupCrew();
	Hibernia = OpHibernia();
	Manager_Ships = ManShips();
	Event = Events();
	Freeways = OpFreeway();
	DLS = RoadPathfinder();
  
	function Start();
}

/*	TO DO
	- figure out how to get the version number to show up in Start()
 */

function WmDOT::Start()
{
//	For debugging crashes...
	local Debug_2 = "/* Settings: " + GetSetting("DOT_name1") + "-" + GetSetting("DOT_name2") + " - dl" + GetSetting("Debug_Level") + " // OpDOT: " + GetSetting("OpDOT") + " - " + GetSetting("OpDOT_MinTownSize") + " - " + GetSetting("TownRegistrar_AtlasSize") + " - " + GetSetting("OpDOT_RebuildAttempts") + " // OpHibernia: " + GetSetting("OpHibernia") + " */" ;
	local Debug_1 = "/* v." + WmDOTv + ", r." + WmDOTr + " // r." + MetaLib.Extras.GetOpenTTDRevision() + " // " + AIDate.GetYear(AIDate.GetCurrentDate()) + "-" + AIDate.GetMonth(AIDate.GetCurrentDate()) + "-" + AIDate.GetDayOfMonth(AIDate.GetCurrentDate()) + " start // " + AIMap.GetMapSizeX() + "x" + AIMap.GetMapSizeY() + " map - " + AITown.GetTownCount() + " towns */";
	
//	AILog.Info("Welcome to WmDOT, version " + GetVersion() + ", revision " + WmDOTr + " by " + GetAuthor() + ".");
	Log.Note("Welcome to WmDOT, version " + WmDOTv + ", revision " + WmDOTr + " by W. Minchin.", 0);
	Log.Note("               Copyright © 2011-12 by W. Minchin.", 0);
	Log.Note("     For more info, please visit http://www.tt-forums.net/viewtopic.php?f=65&t=53698", 0)
	Log.Note(" ", 0);
	
	Log.Note("Loading Libraries...",0);		// Actually, by this point it's already happened
	Log.Note("     " + MetaLib.GetName() + ", v." + MetaLib.GetVersion() + " r." + MetaLib.GetRevision() + "  loaded!", 0);
	Log.Note("     " + Log.GetName() + ", v." + Log.GetVersion() + " r." + Log.GetRevision() + "  loaded!",0);
	Log.Note("     " + Money.GetName() + ", v." + Money.GetVersion() + " r." + Money.GetRevision() + "  loaded!",0);
	Log.Note("     " + DOT.GetName() + ", v." + DOT.GetVersion() + " r." + DOT.GetRevision() + "  loaded!",0);
	Log.Note("     " + Towns.GetName() + ", v." + Towns.GetVersion() + " r." + Towns.GetRevision() + "  loaded!",0);
	Log.Note("     " + CleanupCrew.GetName() + ", v." + CleanupCrew.GetVersion() + " r." + CleanupCrew.GetRevision() + "  loaded!",0);
	Log.Note("     " + Hibernia.GetName() + ", v." + Hibernia.GetVersion() + " r." + Hibernia.GetRevision() + "  loaded!",0);
	Log.Note("     " + Manager_Ships.GetName() + ", v." + Manager_Ships.GetVersion() + " r." + Manager_Ships.GetRevision() + "  loaded!",0);
	Log.Note("     " + Event.GetName() + ", v." + Event.GetVersion() + " r." + Event.GetRevision() + "  loaded!",0);
	Log.Note("     " + Freeways.GetName() + ", v." + Freeways.GetVersion() + " r." + Freeways.GetRevision() + "  loaded!",0);
	StartInfo();		//	AyStarInfo()
						//	RoadPathfinder()
						//	NeighbourhoodInfo()
						//	Fibonacci_Heap_Info()
	Log.Note("",0);
	
	TheGreatLinkUp();
		
	if (GetSetting("Debug_Level") == 0) {
		Log.Note("Increase Debug Level in AI settings to get more verbose output.",0);
		Log.Note("",0);
	}
	
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		//	Build normal road (no tram tracks)
	
	NameWmDOT();
	local HQTown = BuildWmHQ();
	local Time;
	
	DOT.Settings.HQTown = HQTown;

	while (true) {
		Time = this.GetTick();	
//		Log.UpdateDebugLevel();

		if (Time > Money.State.NextRun)			{ Money.Run(); }
		if (Time > Towns.State.NextRun)			{ Towns.Run(); }
		if (Time > CleanupCrew.State.NextRun)	{ CleanupCrew.Run(); }
		if (Time > DOT.State.NextRun)			{ DOT.Run(); }
		if (Time > Freeways.State.NextRun)		{ Freeways.Run(); }
		if (Time > Hibernia.State.NextRun)		{ Hibernia.Run(); }
		if (Time > Manager_Ships.State.NextRun)	{ Manager_Ships.Run(); }
		if (Time > Event.State.NextRun)			{ Event.Run(); }

		this.Sleep(1);		
	}
}

function WmDOT::StartInfo()
{
//	By placing classes here that need to be created to get their info, we
//		destroy them right away (which doubles to clean up the bug report
//		screens and to free up a little bit of memory)
//	local MyAyStar = AyStarInfo();
//	Log.Note("     " + MyAyStar.GetName() + ", v." + MyAyStar.GetVersion() + " r." + MyAyStar.GetRevision() + "  loaded!",0);
	local MyRoadPathfiner = RoadPathfinder();
	Log.Note("     " + MyRoadPathfiner.Info.GetName() + ", v." + MyRoadPathfiner.Info.GetVersion() + " r." + MyRoadPathfiner.Info.GetRevision() + "  loaded!",0);	
	local MyNeighbourhood = NeighbourhoodInfo();
	Log.Note("     " + MyNeighbourhood.GetName() + ", v." + MyNeighbourhood.GetVersion() + " r." + MyNeighbourhood.GetRevision() + "  loaded!",0);
//	local FHI = Fibonacci_Heap_Info();
//	Log.Note("     " + FHI.GetName() + ", v." + FHI.GetVersion() + " r." + FHI.GetRevision() + "  loaded!",0);
}

function WmDOT::NameWmDOT()
{
	/*	This function names the company based on the AI settings.  If the names
	 *	given by the settings is already taken, a default ('WmDOT', for
	 *	'William Department of Transportation') is used.  Failing that, a
	 *	second default ('ZxDOT', chosen becuase I thought it looked cool) is
	 *	tried.  Failing that, a random one or two letter prefix is chosen and
	 *	added to DOT until and unused name is found.
	 */

	Log.Note("Naming Company...",1);
	
	// Test for already named company (basically just an issue on
	//		savegame loading)
	local OldName = AICompany.GetName(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	Log.Note("Currently named " + OldName + " (" + OldName.find("DOT") + ")." ,3);
	if (OldName.find("DOT")== null) {
		local tick;
		tick = this.GetTick();
		
		// Get Name Settings and Build Name String
		local Name2 = WmDOT.GetSetting("DOT_name2");
		local NewName = "";
		Log.Note("Name settings are " + WmDOT.GetSetting("DOT_name1") + " " + WmDOT.GetSetting("DOT_name2") + ".",2);
		switch (WmDOT.GetSetting("DOT_name1"))
		{
			case 0: 
				NewName = "Wm";
				break;
			case 1: 
				NewName = "A";
				break;
			case 2: 
				NewName = "B";
				break;
			case 3: 
				NewName = "C";
				break;
			case 4: 
				NewName = "D";
				break;
			case 5: 
				NewName = "E";
				break;
			case 6: 
				NewName = "F";
				break;
			case 7: 
				NewName = "G";
				break;
			case 8: 
				NewName = "H";
				break;
			case 9: 
				NewName = "I";
				break;
			case 10: 
				NewName = "J";
				break;
			case 11: 
				NewName = "K";
				break;
			case 12: 
				NewName = "L";
				break;
			case 13: 
				NewName = "M";
				break;
			case 14: 
				NewName = "N";
				break;
			case 15: 
				NewName = "O";
				break;
			case 16: 
				NewName = "P";
				break;
			case 17: 
				NewName = "Q";
				break;
			case 18: 
				NewName = "R";
				break;
			case 19: 
				NewName = "S";
				break;
			case 20: 
				NewName = "T";
				break;
			case 21: 
				NewName = "U";
				break;
			case 22: 
				NewName = "V";
				break;
			case 23: 
				NewName = "W";
				break;
			case 24: 
				NewName = "X";
				break;
			case 25: 
				NewName = "Y";
				break;
			case 26: 
				NewName = "Z";
				break;
			default:
				AILog.Warning("          Unexpected DOT_name1 parameter.");
				break;
		}
		switch (WmDOT.GetSetting("DOT_name2"))
		{
			case 0: 
				break;
			case 1: 
				NewName = NewName + "a";
				break;
			case 2: 
				NewName = NewName + "b";
				break;
			case 3: 
				NewName = NewName + "c";
				break;
			case 4: 
				NewName = NewName + "d";
				break;
			case 5: 
				NewName = NewName + "e";
				break;
			case 6: 
				NewName = NewName + "f";
				break;
			case 7: 
				NewName = NewName + "g";
				break;
			case 8: 
				NewName = NewName + "h";
				break;
			case 9: 
				NewName = NewName + "i";
				break;
			case 10: 
				NewName = NewName + "j";
				break;
			case 11: 
				NewName = NewName + "k";
				break;
			case 12: 
				NewName = NewName + "l";
				break;
			case 13: 
				NewName = NewName + "m";
				break;
			case 14: 
				NewName = NewName + "n";
				break;
			case 15: 
				NewName = NewName + "o";
				break;
			case 16: 
				NewName = NewName + "p";
				break;
			case 17: 
				NewName = NewName + "q";
				break;
			case 18: 
				NewName = NewName + "r";
				break;
			case 19: 
				NewName = NewName + "s";
				break;
			case 20: 
				NewName = NewName + "t";
				break;
			case 21: 
				NewName = NewName + "u";
				break;
			case 22: 
				NewName = NewName + "v";
				break;
			case 23: 
				NewName = NewName + "w";
				break;
			case 24: 
				NewName = NewName + "x";
				break;
			case 25: 
				NewName = NewName + "y";
				break;
			case 26: 
				NewName = NewName + "z";
				break;
			default:
				AILog.Warning("          Unexpected DOT_name2 parameter.");
				break;
		}
		NewName = NewName + "DOT"
		if (!AICompany.SetName(NewName))
		{
			Log.Note("Setting Company Name failed. Trying default...",3);
			if (!AICompany.SetName("WmDOT"))
			{
				Log.Note("Default failed. Trying backup...",3)
				if (!AICompany.SetName("ZxDOT"))
				{
					Log.Note("Backup failed. Trying random...",3)
					do
					{
						local c;
						c = AIBase.RandRange(26) + 65;
						NewName = c.tochar();
						c = AIBase.RandRange(26 + SingleLetterOdds) + 97;
						if (c <= 122)
						{
							NewName = NewName + c.tochar();
						}
						NewName = NewName + "DOT";					
					} while (!AICompany.SetName(NewName))
				}
			}
		}
		
		//	Add 'P.Eng' to the end of the founder's name
		NewName = AICompany.GetPresidentName(AICompany.COMPANY_SELF);
		NewName += ", P.Eng"
		AICompany.SetPresidentName(NewName);
		
		tick = this.GetTick() - tick;
		Log.Note("Company named " + AICompany.GetName(AICompany.COMPANY_SELF) + ". " + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " is in charge. Took " + tick + " tick(s).",2);
	} else {
		Log.Note("Company ALREADY named " + AICompany.GetName(AICompany.COMPANY_SELF) + ". " + AICompany.GetPresidentName(AICompany.COMPANY_SELF) + " remains in charge.",2)
	}
}

function WmDOT::BuildWmHQ()
{
	//  TO-DO
	//	- create other options for where to build HQ (random, setting?)
	
	//	There is no check to keep the map co-ordinates from wrapping around the edge of the map
	//	There is a safety in place that if it tries twenty squares in a line in one step, it exits
	
	Log.Note("Building Headquarters...",1)
	
	local tick;
	tick = this.GetTick();
	
	// AICompany.BuildCompanyHQ(0xA284);
	
	// Check for exisiting HQ (mine)
	if (AICompany.GetCompanyHQ(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) != -1) {
		Log.Note("What are you trying to pull on me?? HQ are already established at " + AIMap.GetTileX(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF)) + ", " +  AIMap.GetTileY(AICompany.GetCompanyHQ(AICompany.COMPANY_SELF)) + " in town no. " + HQInWhatTown(AICompany.COMPANY_SELF) + ".",2);
		return HQInWhatTown(AICompany.COMPANY_SELF);		//	Actually return the town where the HQ is...
	}
	
	// Gets a list of the towns	
	local WmTownList = AITownList();
	//	Remove the towns with a DOT HQ and make a note of them - TODO
	local DotHQList = [];
	for (local i=0; i < AICompany.COMPANY_LAST; i++) {
		//	Test if company has built HQ
		// AILog.Info("     Testing Company " + i + ".");
		if (AICompany.GetCompanyHQ(AICompany.ResolveCompanyID(i)) != -1) {
			local TestName = AICompany.GetName(i);
			if (TestName.find("DOT") != null) {
				Log.Note("DOT HQ found for company no. " + i + " in town " + HQInWhatTown(i) + ".",3);
				DotHQList.append(HQInWhatTown(i));
			}
		}
	}

	WmTownList.Valuate(AITown.GetPopulation);	
	local HQTown = AITown();	
	HQTown = WmTownList.Begin();
	local OriginalHQTown = HQTown;
	
	while (Array.ContainedIn1D(DotHQList, HQTown)) {
		Log.Note("Failed best for HQTown " + HQTown + ".",3);
		HQTown = WmTownList.Next();
	}
	//	TO-DO: Doesn't address the case where all towns have a DOT HQ in them...
	
	local Walker = MetaLib.SpiralWalker();
	Walker.Start(AITown.GetLocation(HQTown));
	local HQBuilt = false;
	while (HQBuilt == false) {
		HQBuilt = AICompany.BuildCompanyHQ(Walker.Walk());
		// AISign.BuildSign(Walker.GetTile(), Walker.GetStep());
		
		// Safety: Break if it tries for 400 times and still doesn't work!
		if (Walker.GetStage() == 40) {
			Log.Warning("Failed to build HQ!");
			HQTown = WmTownList.Next();
			while (Array.ContainedIn1D(DotHQList, HQTown)) {
				Log.Note("Failed best for HQTown " + HQTown + ".",3);
				HQTown = WmTownList.Next();
				
				//	TO-DO: Is this check needed here, or is the check two lines down good enough?
				if (WmTownList.IsEnd() == true) {
					Log.Warning("Failed to Build HQ. Returning town " + OriginalHQTown + " anyway...");
					return OriginalHQTown;
				}
			}
			if (WmTownList.IsEnd() == true) {
				Log.Warning("Failed to Build HQ. Returning town " + OriginalHQTown + " anyway...");
				return OriginalHQTown;
			}
			Walker.Start(AITown.GetLocation(HQTown));	
			
		}
	}
	
	tick = this.GetTick() - tick;
	Log.Note("HQ built at "+ AIMap.GetTileX(Walker.GetTile()) + ", " + AIMap.GetTileY(Walker.GetTile()) + ". Took " + Walker.GetStep() + " tries. Took " + tick + " tick(s).",2);
	return HQTown;
}

function WmDOT::HQInWhatTown(CompanyNo)
{
//	Given a company ID, returns the townID of where the HQ is located
//	-1 means that an invalid Company ID was given
//	-2 means that the HQ is beyond a town's influence
	
	//	Test for valid CompanyID
	if (AICompany.ResolveCompanyID(CompanyNo) == -1) {
		Log.Warning("Invalid Company ID!");
		return -1;
	}
	
	local PreReturn = AICompany.GetCompanyHQ(CompanyNo);
	PreReturn = TileIsWhatTown(PreReturn);
	if (PreReturn == -1) {
		Log.Warning("Company in Invalid Town!");
		return -2;
	}
	else {
		return PreReturn;
	}
}

function WmDOT::TileIsWhatTown(TileIn)
{
//	Given a tile, returns the town whose influence it falls under
//	Else returns -1 (i.e. under no town's incfluence)
	
	local TestValue = false;
	
	for (local i = 0; i < AITown.GetTownCount(); i++) {
		TestValue = AITown.IsWithinTownInfluence(i, TileIn);
//		AILog.Info("          " + i + ". Testing Town " + " and returns " + TestValue);
		if (TestValue == true) {
			return i;
		}
	}
	
	//	If it get this far, it's not in any town's influence
	return -1;
}

function WmDOT::TheGreatLinkUp()
{
	DOT.LinkUp();
	Money.LinkUp();
	Towns.LinkUp();
	CleanupCrew.LinkUp();
	Hibernia.LinkUp();
	Manager_Ships.LinkUp();
	Event.LinkUp();
	Freeways.LinkUp();
	Log.Note("The Great Link Up is Complete!",1);
	Log.Note("",1);
}


/*
function TestAI::Save()
 {
   local table = {};	
   //TODO: Add your save data to the table.
   return table;
 }
 
 function TestAI::Load(version, data)
 {
   AILog.Info(" Loaded");
   //TODO: Add your loading routines.
 }
 */