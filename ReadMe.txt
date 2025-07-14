WmDOT Read-me
v.15, 2025-07-14
Copyright © 2011-16, 2025 by W. Minchin. For more info, please visit
    https://github.com/MinchinWeb/openttd-wmdot  or
    http://www.tt-forums.net/viewtopic.php?f=65&t=53698

== About WmDOT ===========================================================
WmDOT (short for "William's Department of Transportation") is an AI for
    OpenTTD, a freeware clone of Chris Sawyer's Transport Tycoon Deluxe.
    Having fallen in love with the original, I was quite delighted to find
    the remake! Of the things that has been added to OpenTTD is custom
    AI's, of which this is one. For me, it's a way to back in touch with a
    game I fell in love with years ago and to brush up on my programming
    skills at the same time.

== What WmDOT Does =======================================================
WmDOT is non-competitive. At the present time, it just builds out your
    highway network. It makes a little bit of money by transporting oil
    from offshore Oil Rigs to Oil Refineries.
WmDOT starts by selecting a 'capital' and builds its Headquarters there.
    (If you run multiple instances of WmDOT, they should pick different
    towns as their respective capitals.) First, WmDOT connects the
    surrounding towns to the capital. Next it connects the towns further
    out to the existing network. Once all towns have been connected to the
    network, WmDOT looks for shorter cross connections to fill out the
    network.
    
== Requirements ==========================================================
WmDOT requires OpenTTD version 1.2 or newer. This is available as a free
    download from OpenTTD.org
As dependencies, WmDOT also requires:
    - MinchinWeb's MetaLibrary, v.8
    - SuperLib, v.37
    - Binary Heap, v.1 ('Queue.BinaryHeap-1.tar')

== Installation ==========================================================
The easiest (and recommended) way to install WmDOT is use OpenTTD's 'Check
    Online Content' interface. Search for 'WmDOT.' If you have not already
    installed the required libraries, OpenTTD will prompt you to download
    them at the same time. This also makes it very easy for me to provide
    updates.
Manual installation can be accomplished by putting the 'WmDOT.6.tar' file
    you downloaded in the  '.\OpenTTD\ai'  folder. If you are manually
    installing, the libraries mentioned above need to be in the
    '.\OpenTTD\ai\library' folder.

Once installed, WmDOT can be selected through 'AI Settings' on OpenTTD's
    main interface. Alternately, WmDOT can be launched manually in-game by
    bringing up the console (press the key to the right of the '1',
    usually the '~' key; press the same key to close the console) and
    typing 'start_ai wmdot'.

== Settings ==============================================================
Settings can be accessed by going to 'AI Settings', selecting WmDOT, and
    then clicking 'Configure'

Number of days to start this AI after the previous one: 1..3600
    - this determines how soon the AI will start
DOT State (first letter) and (second letter): Default, A..Z
    - what do you want WmDOT to call itself? The default is 'WmDOT'. Note
        that two instances of WmDOT will not take the same name.
Debug Level: 0..8
    - How much debugging output do you want on the AI Debug screen
        in-game? 0 = next to nothing, 5 = more than you can follow,
        including signs Probably only useful to me, or if you wonder what
        WmDOT is doing
    - This setting can be changing in-game, but takes a little while for
        the change to be registered
Operation DOT: On/Off
    - whether Operation DOT (WmDOT's highway building routine) runs or not
The minimum size of towns to connect: 0..10000
    - this is the minimum size of towns WmDOT connects to the highway
        network
    - this setting can be changed in-game
Atlas Size: 20..150
    - this is how many towns WmDOT deals with at a time. Larger values
        can significantly slow down WmDOT's building speed and may lock
        the game
	- Note that this setting will only show up if you have AI Developer
        settings turned on
Rebuild Attempts: 1..15
    - if for some reason WmDOT couldn't finish a route (e.g. a bus was in
        the in way), it will try again this many times
Build Freeways: On/Off
    - whether or not OpDOT will build freeways (or dual carriageways)
        between cities
Operation Hibernia: On/Off
    - whether Operation Hibernia runs or not. Operation Hibernia
        transports oil from Oil Rigs to Oil Refineries to earn WmDOT a
        little bit of money.

== Version History =======================================================
Version 15 [2025-07-14]
    (Attempt to) fix crash where the Ship Pathfinder returned `null` for buoy
        count (see Issue #15 and #17).
    Fix logging crash in OpHibernia if one of the depots was unbuilt
        (see Issue #18).
    Fix the Freeway builder so it is consistently right-handed (see Issue #10).
    Fix a crash if the HQ Town had too small a population.
    Updated to MetaLibrary v10 and SuperLib v40

See the attached CHANGELOG.txt for full version history.

== Roadmap ===============================================================
These are features I hope to add to WmDOT shortly. However, this is
    subject to change without notice. However, I am open to suggestions!
v15 Ship Pathfinder improvements
v16 Provide streetcar service in towns
v17 Provide inter-city valuables transportation
v18 Bring water and food to towns in the desert and above the snowline to
        help them grow

== Known Issues ==========================================================
NewGRF support (beyond FIRS and FISH) has not been tested.
Bankruptcy: Because WmDOT does not prioritize making money so may go 
    bankrupt. This becomes more of an issue in long games, on mountainous
    and watery maps, and on large maps. Allowing WmDOT to go bankrupt and
    then restarting itself will allow WmDOT to keep going.
Save/Load functionality has not been added. On loading a game, WmDOT will
    take some time but should eventually pick up where it left off.
Building multiple versions of the same routes is a trade-off for
    pathfinder speed. While WmDOT only builds one road between each town
    pair, it has no conception of the compete network. If the extra road
    becomes excessive, let me know. (a savegame or screenshot would be
    very helpful to illustrate the particular problem)
Pathfinding can take an exceptionally long time if there is no possible
    path. This is most often an issue when the two towns in question are
    on different islands.
Cleanup Crew does funny things...
WmDOT will add ships, but does not currently remove them. Therefore, if
    industry production drops, there could be a number of ships waiting
    for fill-ups and driving WmDOT to bankruptcy.

== Help! It broke! (Bug Report) ==========================================
If WmDOT crashes, please help me fix it! Save a screenshot (under the ? on
    the far right of the in-game toolbar) and report the bug to either:
        http://www.tt-forums.net/viewtopic.php?f=65&t=53698
        https://github.com/MinchinWeb/openttd-wmdot/issues/new

== Helpful Links =========================================================
Get OpenTTD!                                               www.openttd.org
TT-Forums - all things Transport Tycoon related          www.tt-forums.net
WmDOT's thread on TT-Forums: release announcements, bug reports,
    suggestions, and general commentary
                       http://www.tt-forums.net/viewtopic.php?f=65&t=53698
WmDOT on GitHub: source code, and WmDOT: Bleeding Edge edition
                               https://github.com/MinchinWeb/openttd-wmdot
To report issues:   https://github.com/MinchinWeb/openttd-wmdot/issues/new

My other projects (for OpenTTD):
    MinchinWeb's MetaLibrary (for AIs)
                       http://www.tt-forums.net/viewtopic.php?f=65&t=57903
    Alberta Town Names
                       http://www.tt-forums.net/viewtopic.php?f=67&t=53313
    MinchinWeb's Random Town Name Generator
                       http://www.tt-forums.net/viewtopic.php?f=67&t=53579
    Progressive Rail Set
                       http://www.tt-forums.net/viewtopic.php?f=67&t=63182

== License ===============================================================
Permission is granted to you to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell this software, and provide these
rights to others, provided:
    + The above copyright notice and this permission notice shall be
        included in all copies or substantial portions of the software.
    + Attribution is provided in the normal place for recognition of 3rd
        party contributions.
    + You accept that this software is provided to you "as is", without
        warranty.
