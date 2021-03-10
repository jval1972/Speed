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

unit speed_cars;

interface

uses
  p_mobj_h,
  m_fixed,
  speed_path,
  tables;


type
  cartype_t = (ct_formula, ct_stock);

  carinfo_t = record
    tex1old, tex1: string[64]; // Replacement textures
    tex2old, tex2: string[64]; // Replacement textures
    number: integer;  // Number (as seen in texture replacements)
    maxspeed: integer;  // km/h
    model3d: string[64];
    cartype: cartype_t;
  end;
  Pcarinfo_t = ^carinfo_t;
  carinfo_tArray = array[0..$FF] of carinfo_t;
  Pcarinfo_tArray = ^carinfo_tArray;

type
  car_t = record
    mo: Pmobj_t;
    toAngle: angle_t;
    toSpeed: fixed_t;
    toPath: Prtlpath_t;
    gear: integer;
    info: Pcarinfo_t;
    maxspeed: integer;
    damage: integer;
  end;
  Pcar_t = ^car_t;
  car_tArray = array[0..$FF] of car_t;
  Pcar_tArray = ^car_tArray;

procedure SH_InitLevelCars;

const
  KMH_TO_FIXED = 4370; // Speed in fixed point arithmetic

implementation

uses
  d_delphi,
  d_think,
  p_tick,
  p_mobj,
  speed_things,
  z_zone;

var
  numcars: integer;
  rtlcars: Pcar_tArray;

procedure SH_InitLevelCars;
var
  mo: Pmobj_t;
  think: Pthinker_t;
  lst: TDPointerList;
  i: integer;
begin
  lst := TDPointerList.Create;
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 <> @P_MobjThinker then
    begin
      think := think.next;
      continue;
    end;

    mo := Pmobj_t(think);

    if mo.info.doomednum = _SHTH_STARPOSITION then
      lst.Add(mo);
    think := think.next;
  end;

  numcars := lst.Count;
  rtlcars := Z_Malloc(numcars * SizeOf(car_t), PU_LEVEL, nil);
  for i := 0 to lst.Count - 1 do
  begin
    rtlcars[i].mo := lst.Pointers[i];
    rtlcars[i].toPath := SH_GetNextPath(lst.Pointers[i]);
    rtlcars[i].toAngle := rtlcars[i].toPath.mo.angle;
    rtlcars[i].toSpeed := rtlcars[i].toPath.speed;
    rtlcars[i].gear := 0;
    rtlcars[i].info := 0;
    rtlcars[i].maxspeed := 0;
    rtlcars[i].damage := 0;
  end;
  lst.Free;
end;

end.
