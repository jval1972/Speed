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

unit speed_player;

interface

uses
  d_player;

procedure SH_PlayerThing(const p: Pplayer_t);

implementation

uses
  info_common,
  p_mobj,
  speed_cars;

const
  STR_MESSAGESOUND = 'MESSAGESOUND';

var
  messagesound_id: integer = -1;

procedure SH_PlayerMessageSound(const p: Pplayer_t);
begin
  if p.messagesoundtarget = nil then
  begin
    if messagesound_id = -1 then
      messagesound_id := Info_GetMobjNumForName(STR_MESSAGESOUND);

    p.messagesoundtarget := P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, messagesound_id);
  end
  else
  begin
    p.messagesoundtarget.x := p.mo.x;
    p.messagesoundtarget.y := p.mo.y;
    p.messagesoundtarget.z := p.mo.z;
  end;
end;

const
  STR_ENGINESOUND = 'ENGINESOUND';

var
  enginesound_id: integer = -1;

procedure SH_PlayerEngineSound(p: Pplayer_t);
begin
  if p.enginesoundtarget = nil then
  begin
    if enginesound_id = -1 then
      enginesound_id := Info_GetMobjNumForName(STR_ENGINESOUND);

    p.enginesoundtarget := P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, enginesound_id);
  end
  else
  begin
    p.enginesoundtarget.x := p.mo.x;
    p.enginesoundtarget.y := p.mo.y;
    p.enginesoundtarget.z := p.mo.z;
  end;

  SH_EngineSound(p.mo, p.enginesoundtarget);
end;

procedure SH_PlayerThing(const p: Pplayer_t);
begin
  SH_PlayerMessageSound(p);
  SH_PlayerEngineSound(p);
end;

end.
