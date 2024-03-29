//
//  Speed
//  Engine remake of the game "Speed Haste" based on the DelphiDoom engine
//
//  Copyright (C) 1995 by Noriaworks
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2021 by Jim Valavanis
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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Put all global tate variables here.
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit doomstat;

interface

uses
  doomdef;

var
// Game Mode - identify IWAD as shareware, retail etc.
  gamemode: GameMode_t = indetermined;
  gamemission: GameMission_t = doom;
  gameversion: GameVersion_t = exe_ultimate;
  customgame: CustomGame_t = cg_none;

// Language.
  language: Language_t = english;

// Set if homebrew PWAD stuff has been added.
  modifiedgame: boolean = false;
  externalpakspresent: boolean = false;
  externaldehspresent: boolean = false;

implementation

end.

