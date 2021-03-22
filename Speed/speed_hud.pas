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

unit speed_hud;

interface

procedure SH_InitSpeedHud;

procedure SH_ShutDownSpeedHud;

procedure SH_HudDrawer;

implementation

uses
  d_delphi,
  d_player,
  d_net,
  g_game,
  m_fixed,
  r_defs,
  speed_cars,
  v_data,
  v_video,
  w_wad,
  z_zone;

var
  bluedigitbig: array[0..9] of Ppatch_t;
  blueslashbig: Ppatch_t;
  bluedigitsmall: array[0..9] of Ppatch_t;
  blueslashsmall: Ppatch_t;
  whitedigitbig: array[0..9] of Ppatch_t;
  whitedigitsmall: array[0..9] of Ppatch_t;
  gearbox: Ppatch_t;
  gears: array[0..6] of Ppatch_t;
  speedometer: array[0..1] of Ppatch_t;
  mpals: Ppatch_t;
  mposbar: Ppatch_t;

procedure SH_InitSpeedHud;
var
  i: integer;
  sn: string;
begin
  for i := 0 to 9 do
  begin
    sn := itoa(i);
    bluedigitbig[i] := W_CacheLumpName('MFBG' + sn, PU_STATIC);
    bluedigitsmall[i] := W_CacheLumpName('MFMG' + sn, PU_STATIC);
    whitedigitbig[i] := W_CacheLumpName('MFBW' + sn, PU_STATIC);
    whitedigitsmall[i] := W_CacheLumpName('MFMW' + sn, PU_STATIC);
  end;
  blueslashbig := W_CacheLumpName('MFBGB', PU_STATIC);
  blueslashsmall := W_CacheLumpName('MFMGB', PU_STATIC);
  gearbox := W_CacheLumpName('MGEAR', PU_STATIC);
  for i := 0 to 6 do
    gears[i] := W_CacheLumpName('MG' + itoa(i), PU_STATIC);
  for i := 0 to 1 do
    speedometer[i] := W_CacheLumpName('MREVO' + itoa(i), PU_STATIC);
  mlaps := W_CacheLumpName('MLAPS', PU_STATIC);
  mposbar := W_CacheLumpName('MPOSBAR', PU_STATIC);
end;

var
  hud_player: Pplayer_t;

procedure SH_ShutDownSpeedHud;
begin
end;

procedure SH_DrawSpeed;
const
  S_XPOS: array[0..1] of integer = (265, 262);
var
  sspeed: string;
  i: integer;
  id: integer;
  xpos: integer;
begin
  V_DrawPatch(260, 195, SCN_HUD, speedometer[Ord(carinfo[hud_player.mo.carinfo].cartype)], false);
  sspeed := itoa(hud_player.mo.enginespeed div KMH_TO_FIXED);
  xpos := S_XPOS[Ord(carinfo[hud_player.mo.carinfo].cartype)];
  for i := 1 to length(sspeed) do
  begin
    id := Ord(sspeed[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
    begin
      V_DrawPatch(xpos, 192, SCN_HUD, whitedigitsmall[id], false);
      xpos := xpos + whitedigitsmall[id].width + 1;
    end;
  end;
end;

procedure SH_DrawGears;
begin
  V_DrawPatch(307, 195, SCN_HUD, gearbox, false);
  case hud_player.mo.cargear of
   1: V_DrawPatch(307, 151, SCN_HUD, gears[1], false);
   2: V_DrawPatch(307, 159, SCN_HUD, gears[2], false);
   3: V_DrawPatch(307, 167, SCN_HUD, gears[3], false);
   4: V_DrawPatch(307, 175, SCN_HUD, gears[4], false);
   5: V_DrawPatch(307, 183, SCN_HUD, gears[5], false);
   6: V_DrawPatch(307, 191, SCN_HUD, gears[6], false);
  else
    V_DrawPatch(307, 143, SCN_HUD, gears[0], false);
  end;
end;

procedure SH_HudDrawer;
begin
  hud_player := @players[consoleplayer];

  if firstinterpolation then
  begin
    ZeroMemory(screens[SCN_HUD], screendimentions[SCN_HUD].width * screendimentions[SCN_HUD].height);

    // Draw grears
    SH_DrawGears;

    // Draw speed
    SH_DrawSpeed;
  end;

  V_CopyRectTransparent(0, 0, SCN_HUD, 320, 200, 0, 0, SCN_FG, true);
end;

end.
