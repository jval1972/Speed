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
//  Game completion, end screen
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_end_screen;

interface

uses
  d_event;

var
  EndLumpName: string = 'SPHLOGO';
  displayendscreen: boolean;

//==============================================================================
//
// E_Responder
//
//==============================================================================
function E_Responder(ev: Pevent_t): boolean;

//==============================================================================
//
// E_Init
//
//==============================================================================
procedure E_Init;

//==============================================================================
//
// E_Drawer
//
//==============================================================================
procedure E_Drawer;

//==============================================================================
//
// E_ShutDown
//
//==============================================================================
procedure E_ShutDown;

//==============================================================================
//
// E_Ticker
//
//==============================================================================
procedure E_Ticker;

implementation

uses
  doomdef,
  i_system,
  v_data,
  v_video,
  w_wad;

var
  e_ticks: integer = 0;

//==============================================================================
//
// E_Responder
//
//==============================================================================
function E_Responder(ev: Pevent_t): boolean;
begin
  if ev._type <> ev_keyup then
  begin
    result := false;
    exit;
  end;

  if gamestate = GS_ENDOOM then
  begin
    result := e_ticks > TICRATE div 2;
    if result then
      I_Quit;
  end
  else
    result := false;
end;

var
  e_lump: integer = -1;

//==============================================================================
//
// E_Init
//
//==============================================================================
procedure E_Init;
begin
  e_lump := W_CheckNumForName(EndLumpName);
  e_ticks := 1;
end;

//==============================================================================
//
// E_Drawer
//
//==============================================================================
procedure E_Drawer;
begin
  V_DrawPatchFullScreenTMP320x200(e_lump);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

//==============================================================================
//
// E_ShutDown
//
//==============================================================================
procedure E_ShutDown;
begin
end;

//==============================================================================
//
// E_Ticker
//
//==============================================================================
procedure E_Ticker;
begin
  if e_ticks > 0 then
  begin
    inc(e_ticks);
    if e_ticks > 10 * TICRATE then
      I_Quit;
  end;
end;

end.
