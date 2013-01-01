WmDOT Read-me
v.11, 2012-12-28
Copyright © 2011-12 by W. Minchin. For more info, please visit
    https://github.com/MinchinWeb/openttd-wmdot  or
    http://www.tt-forums.net/viewtopic.php?f=65&t=53698

-- About WmDOT ----------------------------------------------------------------
WmDOT (short for "William's Department of Transportation") is an AI for
    OpenTTD, a freeware clone of Chris Saywer's Transport Tycoon Deluxe. Having
    fallen in love with the original, I was quite delighted to find the
    remake! Of the things that has been added to OpenTTD is custom AI's, of
    which this is one. For me, it's a way to back in touch with a game I fell
    in love with years ago and to brush up on my programming skills at the same
    time.

-- What WmDOT Does ------------------------------------------------------------
WmDOT is non-competitive. At the present time, it just builds out your highway
    network. It makes a little bit of money by transporting oil from offshore
    Oil Rigs to Oil Refineries.
WmDOT starts by selecting a 'capital' and builds its Headquarters there. (If
    you run multiple instances of WmDOT, they should pick different towns as
    their respective capitals.) First, WmDOT connects the surrounding towns to
    the capital. Next it connects the towns further out to the existing
    network. Once all towns have been connected to the network, WmDOT looks for
    shorter cross connections to fill out the network.
    
-- Requirements ---------------------------------------------------------------
WmDOT requires OpenTTD version 1.2 or newer. This is available as a free
    download from OpenTTD.org
As dependencies, WmDOT also requires:
    - MinchinWeb's MetaLibrary, v.6
    - SuperLib, v.27 ('SuperLib-27.tar')
    - Binary Heap, v.1 ('Queue.BinaryHeap-1.tar')

-- Installation ---------------------------------------------------------------
The easiest (and recommended) way to install WmDOT is use OpenTTD's 'Check
    Online Content' inferface. Search for 'WmDOT.' If you have not already
    installed the required libraries, OpenTTD will prompt you to download them
    at the same time. This also makes it very easy for me to provide updates.
Manual installation can be accomplished by putting the 'WmDOT.6.tar' file you
    downloaded in the  '.\OpenTTD\ai'  folder. If you are manually installing,
    the libraries mentioned above need to be in the '.\OpenTTD\ai\library'
    folder.

Once installed, WmDOT can be selected through 'AI Settings' on OpenTTD's main
    interface. Alternately, WmDOT can be launched manually in-game by bringing
    up the console (press the key to the right of the '1', usually the '~' key;
    press the same key to close the console) and typing 'start_ai wmdot'.

-- Settings -------------------------------------------------------------------
Settings can be accessed by going to 'AI Settings', selecting WmDOT, and then
    clicking 'Configure'

Number of days to start this AI after the previous one: 1..3600
    - this determines how soon the AI will start
DOT State (first letter) and (second letter): Default, A..Z
    - what do you want WmDOT to call itself? The default is 'WmDOT'. Note that
        two instances of WmDOT will not take the same name.
Debug Level: 0..5
    - How much debugging output do you want on the AI Debug screen in-game?
        0 = next to nothing, 5 = more than you can follow, including signs
        Probably only useful to me, or if you wonder what WmDOT is doing
    - This setting can be changing in-game, but takes a little while for the
        change to be registered
Operation DOT: GO! .. no go
    - whether Operation DOT (WmDOT's highway building routine) runs or not.
The minimum size of towns to connect: 0..10000
    - this is the minimum size of towns WmDOT connects to the highway network
    - this setting can be changed in-game
Atlas Size: 20..150
    - this is how many towns WmDOT deals with at a time. Larger values can
        significanly slow down WmDOT's building speed and may lock the game
Rebuild Attempts: 1..15
    - if for some reason WmDOT couldn't finish a route (e.g. a bus was in the
        in way), it will try again this many times
Operation Hibernia: GO! .. no go
    - whether Operation Hibernia runs or not. Operation Hibernia transports oil
        from Oil Rigs to Oil Refineries to earn WmDOT a little bit of money.

-- Version History ------------------------------------------------------------
Version 11 [2012-11-25]
    Moved source control to GitHub
    Delete extra ships
    Name and group ships

See the attached CHANGELOG.txt for full version history.

-- Roadmap --------------------------------------------------------------------
These are features I hope to add to WmDOT shortly. However, this is subject to
    change without notice. However, I am open to suggestions!
v11 Dynamically route managmentment (replace old ships)
v12 Ship Pathfinder improvements
v12 Provide streetcar service in towns
v13 Grid-based road pathfinder
v14 Provide 'freeways' between cities
v15 Provide inter-city valuables transportation
v16 Bring water and food to towns in the desert and above the snowline to help
        them grow

-- Known Issues ---------------------------------------------------------------
NewGRF support (beyond FIRS and FISH) has not been tested.
Bankruptcy: Because WmDOT does not prioritize making money so may go bankrupt. 
    This becomes more of an issue in long games, on mountainous and watery maps,
    and on large maps. Allowing WmDOT to go bankrupt and then restarting itself 
    will allow WmDOT to keep going.
Save/Load functionality has not been added. On loading a game, WmDOT will take
    some time but should eventually pick up where it left off.
Building multiple versions of the same routes is a tradeoff for pathfinder
    speed. While WmDOT only builds one road between each town pair, it has no
    conception of the compete network. If the extra road becomes excessive, let
    me know. (a savegame or screenshot would be very helpful to illustrate the
    particular problem)
Pathfinding can take an exceptionally long time if there is no possible path.
    This is most often an issue when the two towns in question are on different
    islands.
Cleanup Crew does funny things...
WmDOT will add ships, but does not currently remove them. Therefore, if industry
    production drops, there could be a number of ships waiting for fill-ups and
    driving WmDOT to bankruptcy.

-- Help! It broke! (Bug Report) -----------------------------------------------
If WmDOT crashes, please help me fix it! Save a screenshot (under the ? on the
    far right of the in-game toolbar) and report the bug to either:
        http://www.tt-forums.net/viewtopic.php?f=65&t=53698
        http://code.google.com/p/openttd-noai-wmdot/issues/

-- Helpful Links --------------------------------------------------------------
Get OpenTTD!                                                    www.openttd.org
TT-Forums - all things Transport Tycoon related               www.tt-forums.net
WmDOT's thread on TT-Forums: release announcements, bug reports, suggestions,
    and general commentary
                            http://www.tt-forums.net/viewtopic.php?f=65&t=53698
WmDOT on GitHub: source code, and WmDOT: Bleeding Edge edition
                                    https://github.com/MinchinWeb/openttd-wmdot
To report issues:            https://github.com/MinchinWeb/openttd-wmdot/issues

My other projects (for OpenTTD):
    MinchinWeb's MetaLibrary (for AIs)
                            http://www.tt-forums.net/viewtopic.php?f=65&t=57903
    Alberta Town Names      http://www.tt-forums.net/viewtopic.php?f=67&t=53313
    MinchinWeb's Random Town Name Generator
                            http://www.tt-forums.net/viewtopic.php?f=67&t=53579
    Progressive Rail Set    http://www.tt-forums.net/viewtopic.php?f=67&t=63182

-- Licence -------------------------------------------------------------------
Permission is granted to you to use, copy, modify, merge, publish, distribute,
sublincense, and/or sell this software, and provide these rights to others,
provided:
    + The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the software.
    + Attribution is provided in the normal place for recognition of 3rd party
        contributions.
    + You accept that this software is provided to you "as is", without
        warranty.
