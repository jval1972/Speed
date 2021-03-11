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

const
  KMH_TO_FIXED = 4370; // Speed in fixed point arithmetic

type
  cartype_t = (ct_formula, ct_stock);

  carinfo_t = record
    tex1old, tex1: string[64]; // Replacement textures
    tex2old, tex2: string[64]; // Replacement textures
    number: integer;  // Number (as seen in texture replacements)
    maxspeed: fixed_t;  // in Doom units (fixed_t)
    baseaccel: fixed_t; // Acceleration speed (Doom units per TIC)
    basedeccel: fixed_t;  // Brake speed (Doom units per TIC)
    turnspeed: angle_t; // angle to turn per TIC
    model3d: string[64];
    cartype: cartype_t;
  end;
  Pcarinfo_t = ^carinfo_t;
  carinfo_tArray = array[0..$FF] of carinfo_t;
  Pcarinfo_tArray = ^carinfo_tArray;

const
  NUMCARINFO_FORMULA = 20;

  carinfo_formula: array[0..NUMCARINFO_FORMULA - 1] of carinfo_t = (
    (
      tex1old: 'f_1_4';
      tex1: '';
      tex2old: 'f_1_5';
      tex2: '';
      number: 27;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_01_03.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 3;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_02_56.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 56;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_03_30.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 30;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula
    ),

    (
      tex1old: 'f_2_4';
      tex1: '';
      tex2old: 'f_2_5';
      tex2: '';
      number: 1;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_2_4';
      tex1: 'f_2_4_01_33.png';
      tex2old: 'f_2_5';
      tex2: '';
      number: 33;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_2_4';
      tex1: 'f_2_4_02_12.png';
      tex2old: 'f_2_5';
      tex2: '';
      number: 12;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula
    ),

    (
      tex1old: 'f_3_4';
      tex1: '';
      tex2old: 'f_3_5';
      tex2: '';
      number: 4;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_01_09.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 9;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_02_22.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 22;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_03_62.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 62;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula
    ),

    (
      tex1old: 'f_4_4';
      tex1: '';
      tex2old: 'f_4_5';
      tex2: '';
      number: 7;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_01_18.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 18;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_02_54.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 54;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_03_88.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 88;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula
    ),

    (
      tex1old: 'f_5_4';
      tex1: '';
      tex2old: 'f_5_5';
      tex2: '';
      number: 6;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_5_4';
      tex1: 'f_5_4_01_23.png';
      tex2old: 'f_5_5';
      tex2: '';
      number: 23;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_5_4';
      tex1: 'f_5_4_02_45.png';
      tex2old: 'f_5_5';
      tex2: '';
      number: 45;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula
    ),

    (
      tex1old: 'f_6_4';
      tex1: '';
      tex2old: 'f_6_5';
      tex2: '';
      number: 73;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N5A.I3D';
      cartype: ct_formula
    ),
    (
      tex1old: 'f_6_4';
      tex1: 'f_6_4_01_99.png';
      tex2old: 'f_6_5';
      tex2: '';
      number: 99;
      maxspeed: 315 * KMH_TO_FIXED;
      baseaccel: 16 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 364 * FRACUNIT; // ~2 * ANG1
      model3d: 'CAR0N5A.I3D';
      cartype: ct_formula
    )
  );

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

var
  numcars: integer;
  rtlcars: Pcar_tArray;

procedure SH_InitLevelCars;

procedure SH_MoveCar(const c: Pcar_t);

procedure SH_MoveCars;

implementation

uses
  d_delphi,
  d_think,
  p_tick,
  p_mobj,
  r_main,
  speed_things,
  z_zone;

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
    rtlcars[i].info := @carinfo_formula[0];
    rtlcars[i].maxspeed := 0;
    rtlcars[i].damage := 0;
  end;
  lst.Free;
end;

procedure SH_MoveCar(const c: Pcar_t);
var
  curspeed: fixed_t;
  curx, cury, destx, desty: integer;
  an, destan: angle_t;
  destspeed: fixed_t;
begin
  curspeed := Trunc(FRACUNIT * Sqrt(FixedMul(c.mo.x - c.mo.oldx, c.mo.x - c.mo.oldx) + FixedMul(c.mo.y - c.mo.oldy, c.mo.y - c.mo.oldy)));
  if curspeed > c.info.maxspeed then
    curspeed := c.info.maxspeed;

  c.toPath := SH_GetNextPath(c.mo);
  curx := c.mo.x;
  cury := c.mo.y;
  destx := c.toPath.mo.x;
  desty := c.toPath.mo.y;
  destspeed := c.toPath.speed * KMH_TO_FIXED;
  if (destx = curx) and (desty = cury) then
  begin
    destx := rtlpaths[c.toPath.next].mo.x;
    desty := rtlpaths[c.toPath.next].mo.y;
  end;

  destan := R_PointToAngle2(destx, desty, curx, cury) - c.mo.angle;
  if destan < ANG180 then
    c.mo.angle := c.mo.angle - c.info.turnspeed
  else
    c.mo.angle := c.mo.angle + c.info.turnspeed;

  if curspeed > destspeed then
  begin
    curspeed := curspeed - c.info.basedeccel;
    if curspeed < destspeed then
      curspeed := destspeed;
  end
  else if curspeed < destspeed then
  begin
    curspeed := curspeed + c.info.baseaccel;
    if curspeed > destspeed then
      curspeed := destspeed;
  end;

  an := c.mo.angle shr ANGLETOFINESHIFT;
  c.mo.momx := FixedMul(curspeed, finecosine[an]);
  c.mo.momy := FixedMul(curspeed, finesine[an]);
end;

procedure SH_MoveCars;
var
  i: integer;
begin
  for i := 0 to numcars - 1 do
    SH_MoveCar(@rtlcars[i]);
end;

end.
