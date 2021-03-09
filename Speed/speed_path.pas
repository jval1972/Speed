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
  speed_level,
  speed_things;

function SH_LoadPath(const lmpthings, lmppath: integer): boolean;

implementation

uses
  doomdata,
  m_fixed,
  p_maputl,
  p_mobj_h,
  p_mobj,
  r_main,
  w_wad,
  z_zone;

type
  rtlpath_t = record
    mo: Pmobj_t;
    speed: fixed_t;
    next: integer;
  end;
  Prtlpath_t = ^rtlpath_t;
  rtlpath_tArray = array[0..$FF] of rtlpath_t;
  Prtlpath_tArray = ^rtlpath_tArray;

var
  numpaths: integer;
  rtlpaths: Prtlpath_tArray;

function SH_LoadPath(const lmpthings, lmppath: integer): boolean;
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
        rtlpaths[p].speed := mappaths[p].speed;
        inc(p);
      end
      else
        Break;  // JVAL: 20210309 - Ouch!
    end;

    inc(mt);
  end;

  Z_Free(data);
  Z_Free(mappaths);

  Result := True;
end;

end.
