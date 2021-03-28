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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_championship;

interface

uses
  d_player,
  doomdef,
  speed_cars;

type
  championship_t = record
    numlaps: integer;
    racecartype: cartype_t;
    gametype: gametype_t;
    def_f1car: integer;
    def_ncar: integer;
    def_anycar: integer;
    consolepname: string[PILOTNAMESIZE];
  end;
  Pchampionship_t = ^championship_t;

procedure SH_SaveChampionShipData(const gtyp: gametype_t);

var
  championship: championship_t;

implementation

uses
  d_delphi,
  speed_race;

procedure SH_SaveChampionShipData(const gtyp: gametype_t);
begin
  ZeroMemory(@championship, SizeOf(championship_t));
  championship.numlaps := GetIntegerInRange(numlaps, MINLAPS, MAXLAPS);
  championship.racecartype := cartype_t(GetIntegerInRange(racecartype, 0, Ord(ct_any)));
  championship.gametype := gtyp;
  championship.def_f1car := def_f1car;
  championship.def_ncar := def_ncar;
  championship.def_anycar := def_anycar;
  championship.consolepname := pilotname;
end;

end.
