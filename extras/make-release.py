#! python3.5
# -*- coding: utf-8 -*-

# 	WmDOT v14 [2016-08-29],
# 	Copyright © 2011-16 by W. Minchin. For more info,
# 		please visit https://github.com/MinchinWeb/openttd-metalibrary
#
# 	Permission is granted to you to use, copy, modify, merge, publish,
# 	distribute, sublicense, and/or sell this software, and provide these
# 	rights to others, provided:
#
# 	+ The above copyright notice and this permission notice shall be included
# 		in all copies or substantial portions of the software.
# 	+ Attribution is provided in the normal place for recognition of 3rd party
# 		contributions.
# 	+ You accept that this software is provided to you "as is", without warranty.
#

"""This script is a Python script to generate a tar file of WmDOT for
upload to BaNaNaS. v2 [2014-03-03]"""

import fileinput
import os
import re
import tarfile
from os.path import join

import winshell

SourceDir = join("..")
OutputDir = join("..", "releases")
if not os.path.exists(OutputDir):
    os.makedirs(OutputDir)


def multiple_replacer(*key_values):
    """multiple replacement"""
    # from  http://stackoverflow.com/questions/6116978/python-replace-multiple-strings
    #
    # Usage:
    # >>> replacements = (u"café", u"tea"), (u"tea", u"café"), (u"like", u"love")
    # >>> print multiple_replace(u"Do you like café? No, I prefer tea.", *replacements)
    # Do you love tea? No, I prefer café.
    replace_dict = dict(key_values)
    replacement_function = lambda match: replace_dict[match.group(0)]
    pattern = re.compile("|".join([re.escape(k) for k, v in key_values]), re.M | re.I)
    return lambda string: pattern.sub(replacement_function, string)


def multiple_replace(string, *key_values):
    return multiple_replacer(*key_values)(string)


mdReplacements = ("%MinchinWeb", "MinchinWeb"), ("\\_", "_"), ("←", "<-")

# find version
version = 0
with open(join(SourceDir, "info.nut"), "r") as VersionFile:
    for line in VersionFile:
        if "GetVersion()" in line:
            version = line[line.find("return") + 6 : line.find(";")].strip()

# Create AI version
WmDOTVersion = "WmDOT-" + version
# LineCount = 0
TarFileName = join(OutputDir, WmDOTVersion + ".tar")
MyTarFile = tarfile.open(name=TarFileName, mode="w")
for File in os.listdir(SourceDir):
    if os.path.isfile(join(SourceDir, File)):
        if File.endswith(".nut"):
            MyTarFile.add(join(SourceDir, File), join(WmDOTVersion, File))
        elif File.endswith(".txt"):
            MyTarFile.add(join(SourceDir, File), join(WmDOTVersion, File))
        elif File.endswith(".md"):
            # create temp copy
            winshell.copy_file(join(SourceDir, File), File, rename_on_collision=False)
            for line in fileinput.input(File, inplace=1):
                # replace the characters escaped for dOxygen
                print(
                    multiple_replace(line, *mdReplacements),
                )
            MyTarFile.add(File, join(WmDOTVersion, File[:-3] + ".txt"))
            winshell.delete_file(File, no_confirm=True, allow_undo=False)
MyTarFile.close()

print("    " + WmDOTVersion + ".tar created!")
# print ("        " + str(LineCount) + " lines of code")
