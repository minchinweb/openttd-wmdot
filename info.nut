/*	WmDOT v.15, [2025-07-14]
 *	Copyright © 2011-16, 2025 by W. Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-wmdot
 *		OR  http://www.tt-forums.net/viewtopic.php?f=65&t=53698
 *
 *	Permission is granted to you to use, copy, modify, merge, publish,
 *	distribute, sublicense, and/or sell this software, and provide these
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */

class WmDOT extends AIInfo
{
	function GetAuthor()        { return "Wm. Minchin"; }
	function GetName()          { return "WmDOT"; }
	function GetDescription()   { return "An AI that doesn't compete with you but rather builds out the highway network. It makes a little money transporting offshore oil and running public transit. v.15.1 (r.250715)"; }
	function GetVersion()       { return 15; }
	function MinVersionToLoad() { return 1; }
	function GetDate()          { return "2025-07-14"; }
	function GetShortName()     { return "}}mW"; }	//	0x576D7D7D
	function CreateInstance()   { return "WmDOT"; }
	function GetAPIVersion()    { return "1.9"; }
	function UseAsRandomAI()	{ return false; }
	function GetURL()			{ return "http://www.tt-forums.net/viewtopic.php?f=65&t=53698"; }
//	function GetURL()			{ return "http://code.google.com/p/openttd-noai-wmdot/issues/"; }
	function GetEmail()			{ return "w_minchin@hotmail.com"}

	function GetSettings() {
		AddSetting({name = "DOT_name1", description = "DOT State (first letter)      ", min_value = 0, max_value = 26, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("DOT_name1", {_0 = "Default", _1 = "A", _2 = "B", _3 = "C", _4 = "D", _5 = "E", _6 = "F", _7 = "G", _8 = "H", _9 = "I", _10 = "J", _11 = "K", _12 = "L", _13 = "M", _14 = "N", _15 = "O", _16 = "P", _17 = "Q", _18 = "R", _19 = "S", _20 = "T", _21 = "U", _22 = "V", _23 = "W", _24 = "X", _25 = "Y", _26 = "Z"});
		AddSetting({name = "DOT_name2", description = "DOT State (second letter) ", min_value = 0, max_value = 26, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("DOT_name2", {_0 = "none", _1 = "A", _2 = "B", _3 = "C", _4 = "D", _5 = "E", _6 = "F", _7 = "G", _8 = "H", _9 = "I", _10 = "J", _11 = "K", _12 = "L", _13 = "M", _14 = "N", _15 = "O", _16 = "P", _17 = "Q", _18 = "R", _19 = "S", _20 = "T", _21 = "U", _22 = "V", _23 = "W", _24 = "X", _25 = "Y", _26 = "Z"});

		AddSetting({name = "Debug_Level", description = "Debug Level ", min_value = 0, max_value = 8, easy_value = 3, medium_value = 3, hard_value = 3, custom_value = 3, flags = CONFIG_INGAME});

		AddSetting({name = "OpDOT", description = "--  Operation DOT  --  is ", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN});
//		AddLabels("OpDOT", {_0 = "no go ----------------------- :,-(", _1 = "GO!  ------------------------ :-)"});
		AddSetting({name = "OpDOT_MinTownSize", description = "     The minimum size of towns to connect", min_value = 0, max_value = 10000, easy_value = 100, medium_value = 500, hard_value = 1000, custom_value = 300, flags = CONFIG_INGAME, step_size=50});
		AddSetting({name = "TownRegistrar_AtlasSize", description = "     Max Atlas Size", min_value = 20, max_value = 150, easy_value = 50, medium_value = 50, hard_value = 50, custom_value = 50, step_size = 5, flags = CONFIG_DEVELOPER});
		AddSetting({name = "OpDOT_RebuildAttempts", description = "     Build Attemps", min_value = 1, max_value = 15, easy_value = 2, medium_value = 2, hard_value = 2, custom_value = 2, flags = (CONFIG_DEVELOPER, CONFIG_INGAME)});
		AddSetting({name = "Freeways", description = "     Build Freeways", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN});	// 1 == true

		AddSetting({name = "OpHibernia", description = "--  Operation Hibernia  --  is ", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN});
//		AddLabels("OpHibernia", {_0 = "no go ------------------- :,-(", _1 = "GO!  -------------------- :-)"});

//		AddLabels("Grid_Spacing", {_12 = "12 (default)", _14 = "14 (min. for full-sized airports)"});
//		AddSetting({name = "Hwy_Prefix", description = "Highway Prefix", min_value = 0, max_value = 4, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
//		AddLabels("Hwy_Prefix", {_0 = "Match DOT name", _1 = "Hwy", _2 = "I-", _3 = "US", _4 = "RN"});

		AddSetting({name = "OpStreetcar", description = "--  Operation Streetcar  --  is ", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN});

		AddSetting({name = "info0", description = "-------------------------------------------------------------------- ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info0", {_0 = "", _1 = ""});
		AddSetting({name = "info1", description = "     For more information on WmDOT and its settings, visit                         ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info1", {_0 = "", _1 = ""});
		AddSetting({name = "info2", description = "                http://www.tt-forums.net/viewtopic.php?f=65&t=53698  ", min_value = 0, max_value = 1, easy_value = 0, medium_value = 0, hard_value = 0, custom_value = 0, flags = 0});
		AddLabels("info2", {_0 = "", _1 = ""});
	}
}

/* Tell the core we are an AI */
RegisterAI(WmDOT());

//	Requires:
//		Zuu's SuperLib, v.40
//		MinchinWeb's MetaLib, v.10
//		Queue.Fibonacci_Heap v.3  (for Cleanup Crew)
