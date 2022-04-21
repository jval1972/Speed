//
//  Speed
//  Engine remake of the game "Speed Haste" based on the DelphiDoom engine
//
//  Copyright (C) 1995 by Noriaworks
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

To play the game you need the main data file of the original DOS game (speedh.jcl).
Both shareware and register versions of the game should work OK.

History
-------
Fixed problem with lump reading when a namespace was required.
It will load KVX voxels even if the ".kvx" extension is not defined in VOXELDEF.
Improved ZDoom compatiblility in VOXELDEF lumps.
Speed optimizations to ACTORDEF parsing.
Speed optimizations to PascalScript initialization.
Speed optimizations to startup memo text output.

Version 1.0.4.745 (20220411)
-----------------
Use 64 characters long string for short names in PK3.
Fixed missileheight ACTORDEF export.
Fixed wrong coordinates check in sight check.
Fix of OPENARRAYOFU16 and OPENARRAYOFS16 declarations (PascalScript).
Fix ReadParameters not setting parameter parser positions even though ValidateParameters does use them (PascalScript).
Fixed misspelled of "joystick" in the menus.
Speed optimizations in R_PointToAngleEx().
Improved priority logic for sound channel selection.
Added support for tall patches in PNG format.
Added SPIN field in VOXELDEF lumps, it compines DROPPEDSPIN & PLACEDSPIN behavior.
Proper windowed mode.

Version 1.0.3.743 (20220206)
-----------------
Holds up to 2047 bytes for environment variables.
Fixed loading utf16 strings.
Fixed flags in A_ChangeVelocity() ACTORDEF function.
Fixed MF2_EX_CANTLEAVEFLOORPIC flag behavior.
Fixed uncapped framerate bug for floor & ceiling offsets.
Fixed PS_GetConsoleStr(), PS_GetConsoleInt() & PS_GetConsoleBool() PascalScript functions.
Corrected ACTORDEF parsing of goto keyword at the end of the actor definition.
Added GetSectorInterpolate() & SetSectorInterpolate() PascalScript functions.
Integer/float tolerance examines negative values in DEHACKED & ACTORDEF.
Fixed bug that could rarely cause infinite loop in DEHACKED lumps, also now recognizes correctly multiple SUBMITNEWFRAMES commands in DEHACKED
Faster and safer thread de-allocation.
Fixed problem with the "-" prefix in MF4_EX_xxx flags in ACTORDEF.
Fix gravity field inheritance in ACTORDEF declarations.
String and boolean evaluation in parameters of ACTORDEF functions.
Infinite state cycle error message will display the actor's name.
Evaluate actor flags in ACTORDEF functions parameters with the FLAG() function.
3D floor collision logic corrections.
Auto fix interpolation for instant changes in sectors heights and texture offsets.
Added full_sounds console variable. When true, the mobjs will finish their sounds when removed.
Added MF4_EX_ALWAYSFINISHSOUND & MF4_EX_NEVERFINISHSOUND mobj flags to overwrite the full_sounds console variable.
Correct evaluation of angle in functions parameter's evaluation.
Use sound files in pk3 without WAD equivalent. Supported file formats are WAV, OGG, FLAC, OGA, AU, VOC & SND.
Support for the wait keyword in ACTORDEF.
"ACTIVE SOUND" alias for "ACTION SOUND" DEHACKED field.
"RADIUS" alias for "WIDTH" DEHACKED field.
Emulates correctly the ripple effect in OpenGL mode.
Small speed optimization to the OpenGL rendering.
Support for SPRITES dehacked keyword.
Speed optimizations to string manipulation.
Corrected flat scale for big flats.

Version 1.0.2.739 (20210425)
-----------------
Corrected automap level name and position.
Use racetime in automap, not leveltime.

Version 1.0.1.738 (20210425)
-----------------
Initial release.

