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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  OpenGL Slopes
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit gl_slopes;

interface

uses
  d_delphi,
  r_defs;

function gld_FloorHeight(const sec: Psector_t; const x, y: float): float;

function gld_CeilingHeight(const sec: Psector_t; const x, y: float): float;

implementation

uses
  gl_defs;

function gld_ZatPointFloor(const s: Psector_t; const x, y: float): float;
begin
  result := -(s.fa * (-x) + s.fb * (y) + s.fd / MAP_COEFF) * s.fic;
end;

function gld_ZatPointCeiling(const s: Psector_t; const x, y: float): float;
begin
  result := -(s.ca * (-x) + s.cb * (y) + s.cd / MAP_COEFF) * s.cic;
end;

function gld_FloorHeight(const sec: Psector_t; const x, y: float): float;
begin
  if sec.renderflags and SRF_SLOPEFLOOR <> 0 then
    result := gld_ZatPointFloor(sec, x, y)
  else
    result := sec.floorheight / MAP_SCALE;
end;

function gld_CeilingHeight(const sec: Psector_t; const x, y: float): float;
begin
  if sec.renderflags and SRF_SLOPECEILING <> 0 then
    result := gld_ZatPointCeiling(sec, x, y)
  else
    result := sec.ceilingheight / MAP_SCALE;
end;

end.