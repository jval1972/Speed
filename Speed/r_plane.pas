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
// DESCRIPTION:
//  Refresh, visplane stuff (floor, ceilings).
//  Here is a core component: drawing the floors and ceilings,
//   while maintaining a per column clipping list only.
//  Moreover, the sky areas have to be determined.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit r_plane;

interface

uses
  d_delphi,
  doomdef,
  m_fixed,
  r_data,
  r_defs,
  r_visplanes;  // JVAL: 3d Floors

procedure R_ClearPlanes;

function R_FindPlane(height: fixed_t; picnum: integer; lightlevel: integer;
  xoffs, yoffs: fixed_t; flags: LongWord; const floor_or_ceiling: boolean;
  slopeSID: integer = -1): Pvisplane_t;

var
  floorplane: Pvisplane_t;
  ceilingplane: Pvisplane_t;

//
// opening
//

// JVAL: 3d Floors -> moved to interface
// Here comes the obnoxious "visplane".
const
// JVAL - Note about visplanes:
//   Top and Bottom arrays (of visplane_t struct) are now
//   allocated dynamically (using zone memory)
//   Use -zone cmdline param to specify more zone memory allocation
//   if out of memory.
//   See also R_NewVisPlane()
// Now maximum visplanes are 64K (originally 128)
  MAXVISPLANES = $10000;

var
  visplanes: array[0..MAXVISPLANES - 1] of visplane_t;
  lastvisplane: integer;

const
  PL_SKYFLAT = $80000000;

implementation

uses
  tables,
  i_system,
  r_sky,
  r_main,
  r_draw,
  z_zone;

// JVAL: Visplane hash
const
  VISPLANEHASHSIZE = MAXVISPLANES;
  VISPLANEHASHOVER = 16;

var
  visplanehash: array[0..VISPLANEHASHSIZE + VISPLANEHASHOVER - 1] of LongWord;

//
// R_ClearPlanes
// At begining of frame.
//
procedure R_ClearPlanes;
begin
  ZeroMemory(@visplanehash, SizeOf(visplanehash));
  lastvisplane := 0;
end;

//
// R_NewVisPlane
//
// JVAL
//   Create a new visplane
//   Uses zone memory to allocate top and bottom arrays
//
function R_NewVisPlane: Pvisplane_t;
begin
  if lastvisplane > maxvisplane then
    maxvisplane := lastvisplane;

  result := @visplanes[lastvisplane];

  inc(lastvisplane);
end;

//
// R_VisplaneHash
//
function R_VisplaneHash(height: fixed_t; picnum: integer; lightlevel: integer;
  xoffs, yoffs: fixed_t; flags: LongWord; slopeSID: integer): LongWord;
begin
  result := (((((LongWord(flags) * 3 +
                 LongWord(xoffs)) * 1296727 +
                 LongWord(yoffs)) * 1297139 +
                 LongWord(lightlevel)) * 1 +
                 LongWord(height)) * 233 +
                 LongWord(picnum)) * 3 +
                 LongWord(height div FRACUNIT) +
                 LongWord(height and (FRACUNIT - 1));
  result := result + LongWord(slopeSID + 1) * 7;  // JVAL: Slopes
  result := result and (VISPLANEHASHSIZE - 1);
end;

//
// R_FindPlane
//
function R_FindPlane(height: fixed_t; picnum: integer; lightlevel: integer;
  xoffs, yoffs: fixed_t; flags: LongWord; const floor_or_ceiling: boolean;
  slopeSID: integer = -1): Pvisplane_t;
var
  check: integer;
  hash: LongWord;
  p: LongWord;
begin
  if (picnum = skyflatnum) or (picnum and PL_SKYFLAT <> 0) then
  begin
    if floor_or_ceiling then
      height := 1  // all skies map together
    else
      height := 0; // all skies map together
    lightlevel := 0;
    xoffs := 0;
    yoffs := 0;
    flags := flags and not SRF_SLOPED; // JVAL: Sloped surface do not have sky
    slopeSID := -1; // JVAL: Slopes
  end;

  hash := R_VisplaneHash(height, picnum, lightlevel, xoffs, yoffs, flags, slopeSID);
  check := hash;
  while check < hash + VISPLANEHASHOVER do
  begin
    p := visplanehash[check];
    if p = 0 then
    begin
      result := R_NewVisPlane;  // JVAL: 3d Floors

      result.height := height;
      result.picnum := picnum;
      result.lightlevel := lightlevel;
      result.xoffs := xoffs;
      result.yoffs := yoffs;
      result.renderflags := flags;
      result.slopeSID := slopeSID;  // JVAL: Slopes

      visplanehash[check] := lastvisplane;
      exit;
    end;
    Dec(p);
    // JVAL: should not happen
    if p >= lastvisplane then
      break;
    result := @visplanes[p];
    if (height = result.height) and
       (picnum = result.picnum) and
       (xoffs = result.xoffs) and
       (yoffs = result.yoffs) and
       (lightlevel = result.lightlevel) and
       (slopeSID = result.slopeSID) and // JVAL: Slopes
       (flags = result.renderflags) then
      exit;
    Inc(check);
  end;

  check := 0;
  result := @visplanes[0];
  while check < lastvisplane do
  begin
    if (height = result.height) and
       (picnum = result.picnum) and
       (xoffs = result.xoffs) and
       (yoffs = result.yoffs) and
       (lightlevel = result.lightlevel) and
       (slopeSID = result.slopeSID) and // JVAL: Slopes
       (flags = result.renderflags) then
      break;
    inc(check);
    inc(result);
  end;

  if check < lastvisplane then
  begin
    exit;
  end;

  if lastvisplane = MAXVISPLANES then
    I_Error('R_FindPlane(): no more visplanes');

  R_NewVisPlane;

  result.height := height;
  result.picnum := picnum;
  result.lightlevel := lightlevel;
  result.xoffs := xoffs;
  result.yoffs := yoffs;
  result.renderflags := flags;
  result.slopeSID := slopeSID;  // JVAL: Slopes

  check := hash;
  while check < hash + VISPLANEHASHOVER do
  begin
    if visplanehash[check] = 0 then
    begin
      visplanehash[check] := lastvisplane;
      Break;
    end;
    Inc(check);
  end;

end;

end.

