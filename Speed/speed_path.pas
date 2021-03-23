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

unit speed_path;

interface

uses
  m_fixed,
  p_mobj_h,
  speed_cars,
  speed_level,
  speed_race,
  speed_things;

type
  rtlcarpathinfo_t = record
    entertime: array[0..MAXLAPS] of integer;
    exittime: array[0..MAXLAPS] of integer;
  end;
  Prtlcarpathinfo_t = ^rtlcarpathinfo_t;

  rtlpath_t = record
    mo: Pmobj_t;
    id: integer;
    speed: fixed_t;
    prev: integer;
    next: integer;
    dist_to_next: fixed_t;
    cardata: array[0..NUMCARINFO - 1] of rtlcarpathinfo_t;
  end;
  Prtlpath_t = ^rtlpath_t;
  rtlpath_tArray = array[0..$FF] of rtlpath_t;
  Prtlpath_tArray = ^rtlpath_tArray;

function SH_LoadPath(const lmpthings, lmppath: integer): boolean;

function SH_GetNextPath(const mo: Pmobj_t): Prtlpath_t;

procedure SH_NotifyPath(const mo: Pmobj_t);

type
  timelaps_t = array[0..MAXLAPS - 1] of integer;
  Ptimelaps_t = ^timelaps_t;

procedure SH_GetTimeLaps(const mo: Pmobj_t; const tl: Ptimelaps_t);

var
  numpaths: integer;
  rtlpaths: Prtlpath_tArray;

implementation

uses
  d_delphi,
  doomdata,
  tables,
  p_maputl,
  p_mobj,
  p_tick,
  r_main,
  w_wad,
  z_zone;

procedure SH_GroupPathSequence;
var
  aheadpaths: TDNumberList;
  i, j: integer;
  an: angle_t;
  dist, mindist: fixed_t;
  best: integer;
begin
  aheadpaths := TDNumberList.Create;

  for i := 0 to numpaths - 1 do
  begin
    aheadpaths.FastClear;
    for j := 0 to numpaths - 1 do
      if i <> j then
      begin
        an := R_PointToAngle2(rtlpaths[i].mo.x, rtlpaths[i].mo.y, rtlpaths[j].mo.x, rtlpaths[j].mo.y) - rtlpaths[j].mo.angle;
        if (an <= ANG90) or (an >= ANG270) then
          aheadpaths.Add(j);
      end;
    best := 0;
    mindist := MAXINT;
    for j := 0 to aheadpaths.Count - 1 do
    begin
      dist := P_Distance(rtlpaths[i].mo.x - rtlpaths[aheadpaths.Numbers[j]].mo.x, rtlpaths[i].mo.y - rtlpaths[aheadpaths.Numbers[j]].mo.y);
      if dist < mindist then
      begin
        mindist := dist;
        best := aheadpaths.Numbers[j];
      end;
    end;
    rtlpaths[i].id := i;
    rtlpaths[i].next := best;
    rtlpaths[i].dist_to_next := mindist;
    rtlpaths[best].prev := i;
  end;

  aheadpaths.Free;
end;

function SH_LoadPath(const lmpthings, lmppath: integer): boolean;
const
  PATH_TO_KMH_DIV = 10240;
var
  data: pointer;
  i, p: integer;
  mt: Pmapthing_t;
  numthings: integer;
  mappaths: Pmapspeedpathpoint_tArray;
begin
  if lmppath >= W_NumLumps then
  begin
    Result := False;
    Exit;
  end;

  if char8tostring(W_GetNameForNum(lmppath)) <> 'PATH' then
  begin
    Result := False;
    Exit;
  end;

  numpaths := W_LumpLength(lmppath) div SizeOf(mapspeedpathpoint_t);
  rtlpaths := Z_Malloc(numpaths * SizeOf(rtlpath_t), PU_LEVEL, nil);
  ZeroMemory(rtlpaths, numpaths * SizeOf(rtlpath_t));

  mappaths := W_CacheLumpNum(lmppath, PU_STATIC);

  data := W_CacheLumpNum(lmpthings, PU_STATIC);
  numthings := W_LumpLength(lmpthings) div SizeOf(mapthing_t);

  mt := Pmapthing_t(data);
  p := 0;
  for i := 0 to numthings - 1 do
  begin
    if mt._type = _SHTH_PATH then
    begin
      if p < numpaths then
      begin
        rtlpaths[p].mo := P_SpawnMapThing(mt);
        rtlpaths[p].speed := mappaths[p].speed div PATH_TO_KMH_DIV;
        inc(p);
      end
      else
        Break;  // JVAL: 20210309 - Ouch!
    end;

    inc(mt);
  end;

  Z_Free(data);
  Z_Free(mappaths);

  SH_GroupPathSequence;

  Result := True;
end;

function SH_GetNextPath(const mo: Pmobj_t): Prtlpath_t;
var
  i: integer;
  tmppaths: TDNumberList;
  an: angle_t;
  dist, mindist: fixed_t;
  best: integer;
begin
  tmppaths := TDNumberList.Create;

  for i := 0 to numpaths - 1 do
  begin
    if mo.x = rtlpaths[i].mo.x then
      if mo.y = rtlpaths[i].mo.y then
      begin
        tmppaths.Free;
        Result := @rtlpaths[rtlpaths[i].next];
        Exit;
      end;

    an := R_PointToAngle2(mo.x, mo.y, rtlpaths[i].mo.x, rtlpaths[i].mo.y) - rtlpaths[i].mo.angle;
    if (an <= ANG90) or (an >= ANG270) then
      tmppaths.Add(i);
  end;
  best := 0;
  mindist := MAXINT;
  for i := 0 to tmppaths.Count - 1 do
  begin
    dist := P_AproxDistance(mo.x - rtlpaths[tmppaths.Numbers[i]].mo.x, mo.y - rtlpaths[tmppaths.Numbers[i]].mo.y);
    if dist < mindist then
    begin
      mindist := dist;
      best := tmppaths.Numbers[i];
    end;
  end;

  tmppaths.Free;
  Result := @rtlpaths[best];
end;

procedure SH_NotifyPath(const mo: Pmobj_t);
var
  path: Prtlpath_t;
  cpinfo: Prtlcarpathinfo_t;
begin
  // Crossed the finish line
  if mo.currPath = 0 then
    if mo.prevPath = rtlpaths[0].prev then
    begin
      inc(mo.lapscompleted);
      mo.prevPath := mo.currPath;
    end;

  // Crossed the finish line the wrong way;
  if mo.currPath = rtlpaths[0].prev then
    if mo.prevPath = 0 then
    begin
      dec(mo.lapscompleted);
      mo.prevPath := mo.currPath;
    end;

  if IsIntegerInRange(mo.lapscompleted, 0, race.numlaps) then
  begin
    path := @rtlpaths[mo.currPath];

    cpinfo := @path.cardata[mo.carinfo];

    if cpinfo.entertime[mo.lapscompleted] = 0 then
      cpinfo.entertime[mo.lapscompleted] := GetIntegerInRange(leveltime, 1, MAXINT);
    if (mo.currPath <> 0) or (cpinfo.exittime[mo.lapscompleted] = 0) then
      cpinfo.exittime[mo.lapscompleted] := leveltime;
  end;
end;

procedure SH_GetTimeLaps(const mo: Pmobj_t; const tl: Ptimelaps_t);
var
  i: integer;
  path: Prtlpath_t;
  cpinfo: Prtlcarpathinfo_t;
  timestartlap, timeendlap: integer;
begin
  for i := 0 to MAXLAPS - 1 do
    tl[i] := 0;

  path := @rtlpaths[0];
  cpinfo := @path.cardata[mo.carinfo];
  for i := 0 to race.numlaps - 1 do
  begin
    if i = 0 then
      timestartlap := 0
    else
      timestartlap := cpinfo.exittime[i];
    timeendlap := cpinfo.exittime[i + 1];
    if timeendlap > timestartlap then
      tl[i] := timeendlap - timestartlap
    else
      Break;
  end;
end;

end.
