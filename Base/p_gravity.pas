//
//  Speed
//  Engine remake of the game "Speed Haste" based on the DelphiDoom engine
//
//  Copyright (C) 1995 by Noriaworks
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
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
//  Custom gravity
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit p_gravity;

interface

uses
  m_fixed,
  p_local,
  p_mobj_h,
  r_defs;

//==============================================================================
//
// P_GetMobjGravity
//
//==============================================================================
function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;

//==============================================================================
//
// P_GetSectorGravity
//
//==============================================================================
function P_GetSectorGravity(const sec: Psector_t): fixed_t;

implementation

uses
  doomdef,
  g_game;

//==============================================================================
//
// P_GetMobjGravity
//
//==============================================================================
function P_GetMobjGravity(const mo: Pmobj_t): fixed_t;
begin
  if G_PlayingEngineVersion > VERSION204 then
    result := FixedMul(Psubsector_t(mo.subsector).sector.gravity, mo.gravity)
  else if G_PlayingEngineVersion = VERSION204 then
    result := Psubsector_t(mo.subsector).sector.gravity
  else
    result := GRAVITY;
end;

//==============================================================================
//
// P_GetSectorGravity
//
//==============================================================================
function P_GetSectorGravity(const sec: Psector_t): fixed_t;
begin
  if G_PlayingEngineVersion < VERSION204 then
    result := GRAVITY
  else
    result := sec.gravity;
end;

end.
