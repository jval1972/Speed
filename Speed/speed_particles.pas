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
//  Particles
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_particles;

interface

uses
  m_fixed,
  p_mobj_h;

procedure SH_SpawnParticleCheck(const mo: Pmobj_t; const actualspeed, enginespeed: fixed_t);

implementation

uses
  doomdef,
  info_common,
  m_rnd,
  p_mobj,
  p_tick,
  speed_race,
  tables;

var
  MT_DIRT1A: integer = -1;
  MT_DIRT1B: integer = -1;
  MT_DIRT2A: integer = -1;
  MT_DIRT2B: integer = -1;
  MT_DIRT3A: integer = -1;
  MT_DIRT3B: integer = -1;
  MT_SMOKE1A: integer = -1;
  MT_SMOKE1B: integer = -1;
  MT_SPARK1A: integer = -1;
  MT_SPARK1B: integer = -1;

const
  REAR_WHEEL_OFFSET = 32;

function SH_SpawnParticle(var id1, id2: integer; const idname1, idname2: string;
  const x, y, z: fixed_t): Pmobj_t;
var
  id: integer;
begin
  if id1 < 0 then
    id1 := Info_GetMobjNumForName(idname1);
  if id2 < 0 then
    id2 := Info_GetMobjNumForName(idname2);

  if P_Random < 128 then
    id := id1
  else
    id := id2;

  if id < 0 then
  begin
    Result := nil;
    Exit;
  end;

  Result := P_SpawnMobj(x, y, z, id);
end;

procedure SH_SpawnParticleCheck(const mo: Pmobj_t; const actualspeed, enginespeed: fixed_t);
var
  wx, wy: fixed_t; // Rear wheels aprox position
  wx1, wy1, wx2, wy2: fixed_t;
  an: angle_t;
  gtype: groundtype_t;
  part: Pmobj_t;
begin
  if mo.nextparticle > leveltime then
    Exit;

  an := mo.angle shr ANGLETOFINESHIFT;
  wx := mo.x - REAR_WHEEL_OFFSET * finecosine[an];
  wy := mo.y - REAR_WHEEL_OFFSET * finesine[an];

  gtype := SH_GroundTypeAtXY(wx, wy);

  case gtype of
    gt_asphalt:
      begin
        if enginespeed > actualspeed + 4 * FRACUNIT then
        begin
          part := SH_SpawnParticle(MT_SPARK1A, MT_SPARK1B, 'MT_SPARK1A', 'MT_SPARK1B', wx, wy, mo.z);
          part.momx := - 2 * finecosine[an];
          part.momy := - 2 * finesine[an];
          if enginespeed > actualspeed + 8 * FRACUNIT then  // Spinning hard
          begin
            an := (mo.angle + 10 * ANG1) shr ANGLETOFINESHIFT;
            wx1 := mo.x - REAR_WHEEL_OFFSET * finecosine[an];
            wy1 := mo.y - REAR_WHEEL_OFFSET * finesine[an];
            part := SH_SpawnParticle(MT_SMOKE1A, MT_SMOKE1B, 'MT_SMOKE1A', 'MT_SMOKE1B', wx1, wy1, mo.z);
            part.momx := - finecosine[an];
            part.momy := - finesine[an];

            an := (mo.angle - 10 * ANG1) shr ANGLETOFINESHIFT;
            wx2 := mo.x - REAR_WHEEL_OFFSET * finecosine[an];
            wy2 := mo.y - REAR_WHEEL_OFFSET * finesine[an];
            part := SH_SpawnParticle(MT_SMOKE1A, MT_SMOKE1B, 'MT_SMOKE1A', 'MT_SMOKE1B', wx2, wy2, mo.z);
            part.momx := - finecosine[an];
            part.momy := - finesine[an];
          end;
          mo.nextparticle := leveltime + TICRATE;
        end;
      end;
    gt_grass:
      begin
        part := SH_SpawnParticle(MT_DIRT3A, MT_DIRT3B, 'MT_DIRT3A', 'MT_DIRT3B', wx, wy, mo.z);
        part.momx := - finecosine[an];
        part.momy := - finesine[an];
        mo.nextparticle := leveltime + TICRATE div 2;
      end;
    gt_dirt:
      begin
        part := SH_SpawnParticle(MT_DIRT1A, MT_DIRT1B, 'MT_DIRT1A', 'MT_DIRT1B', wx, wy, mo.z);
        part.momx := - finecosine[an];
        part.momy := - finesine[an];
        mo.nextparticle := leveltime + TICRATE div 2;
      end;
    gt_sand:
      begin
        part := SH_SpawnParticle(MT_DIRT2A, MT_DIRT2B, 'MT_DIRT2A', 'MT_DIRT2B', wx, wy, mo.z);
        part.momx := - finecosine[an];
        part.momy := - finesine[an];
        mo.nextparticle := leveltime + TICRATE div 2;
      end;
  end;

end;

end.
