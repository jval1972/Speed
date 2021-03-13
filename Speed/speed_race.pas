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

unit speed_race;

interface

uses
  d_delphi,
  m_fixed,
  speed_cars;

type
  ground_t = packed array[0..4095, 0..4095] of byte;
  Pground_t = ^ground_t;

  groundtype_t = (gt_asphalt, gt_grass, gt_dirt, gt_sand, gt_unknown);

  racestatus_t = (rs_waiting, rs_racing);

  race_t = record
    cartype: cartype_t;
    racestatus: racestatus_t;
    completed: boolean;
    ground: Pground_t;
    groundlump: integer;
  end;

  slipperinessinfo_t = record
    smin, smax: byte;
  end;
  Pslipperinessinfo_t = ^slipperinessinfo_t;

const
  MAXSLIPFACTOR = 255;

const
  slipperinessinfo: array[groundtype_t] of slipperinessinfo_t = (
    (smin: 224; smax: 255), // Asphalt
    (smin: 150; smax: 220), // grass
    (smin: 100; smax: 180), // dirt
    (smin:  80; smax: 150), // sand
    (smin: 100; smax: 200)  // unknown
  );

var
  race: race_t;

procedure SH_InitRace;

function SH_GroundTypeAtXY(const x, y: fixed_t): groundtype_t;

function SH_SlipperFactorAtXY(const x, y: fixed_t): byte;

function SH_SlipCalculation(const x: fixed_t; const slip: byte): fixed_t;

implementation

uses
  m_rnd,
  p_setup,
  r_data,
  speed_xlat_wad,
  w_wad,
  z_zone;

procedure SH_InitRace;
begin
  race.groundlump := R_GetLumpForFlat(sectors[0].floorpic);
  race.ground := W_CacheLumpNum(race.groundlump, PU_LEVEL);
end;

function SH_GroundTypeAtXY(const x, y: fixed_t): groundtype_t;
var
  nx, ny: integer;
  g: byte;
begin
  race.ground := W_CacheLumpNum(race.groundlump, PU_LEVEL);
  nx := GetIntegerInRange((x div FRACUNIT) div SPEED_LEVEL_SCALE, 0, 4095);
  ny := GetIntegerInRange((y div FRACUNIT) div SPEED_LEVEL_SCALE, 0, 4095);
  g := race.ground[4095 - ny, nx];
  if IsIntegerInRange(g, 160, 191) then
    Result := gt_asphalt
  else if IsIntegerInRange(g, 48, 63) then
    Result := gt_sand
  else if IsIntegerInRange(g, 64, 79) then
    Result := gt_grass
  else if IsIntegerInRange(g, 128, 143) then
    Result := gt_dirt
  else
    Result := gt_unknown;
end;

function SH_SlipperFactorAtXY(const x, y: fixed_t): byte;
var
  sinfo: Pslipperinessinfo_t;
begin
  sinfo := @slipperinessinfo[SH_GroundTypeAtXY(x, y)];
  Result := sinfo.smin + Sys_Random mod (sinfo.smax - sinfo.smin + 1);
end;

function SH_SlipCalculation(const x: fixed_t; const slip: byte): fixed_t;
var
  x64: int64;
begin
  x64 := x * slip;
  x64 := x64 div MAXSLIPFACTOR;
  Result := x64;
end;

end.
