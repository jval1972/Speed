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

unit speed_actions;

interface

uses
  p_mobj_h;

procedure A_StartYourEngines(mo: Pmobj_t);

procedure A_StartRace(mo: Pmobj_t);

implementation

uses
  doomdef,
  psi_overlay,
  speed_cars,
  speed_race,
  s_sound;

procedure A_StartYourEngines(mo: Pmobj_t);
var
  pname: string;
begin
  S_StartSound(nil, 'speedhaste/STARTECH.RAW');
  
  if race.cartype = ct_stock then
    pname := 'RLOAD10'
  else
    pname := 'RLOAD00';

  overlay.AddPatch(50, pname, 0, 0);
end;

procedure A_StartRace(mo: Pmobj_t);
begin
  race.racestatus := rs_racing;
end;

end.
