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
  doomdef,
  d_player,
  p_tick,
  d_net,
  g_game,
  m_fixed,
  r_defs,
  speed_cars,
  speed_race,
  speed_path,
  speed_string_format,
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
  mlaps: Ppatch_t;
  mposbar: Ppatch_t;
  mbest, mlap: Ppatch_t;
  timedigityellow: array[0..11] of Ppatch_t;
  timedigitwhite: array[0..11] of Ppatch_t;
  mpos: Ppatch_t;
  rfinlap: Ppatch_t;
  pendrace: Ppatch_t;

var
  timelaps: timelaps_t;

const
  TIMEDIGITLOOKUP = '0123456789"''';

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
    timedigityellow[i] := W_CacheLumpName('MFLG' + sn, PU_STATIC);
    timedigitwhite[i] := W_CacheLumpName('MFLW' + sn, PU_STATIC);
  end;
  blueslashbig := W_CacheLumpName('MFBGB', PU_STATIC);
  blueslashsmall := W_CacheLumpName('MFMGB', PU_STATIC);
  timedigityellow[10] := W_CacheLumpName('MGDQUOTE', PU_STATIC);
  timedigityellow[11] := W_CacheLumpName('MGQUOTE', PU_STATIC);
  timedigitwhite[10] := W_CacheLumpName('MWDQUOTE', PU_STATIC);
  timedigitwhite[11] := W_CacheLumpName('MWQUOTE', PU_STATIC);
  gearbox := W_CacheLumpName('MGEAR', PU_STATIC);
  for i := 0 to 6 do
    gears[i] := W_CacheLumpName('MG' + itoa(i), PU_STATIC);
  for i := 0 to 1 do
    speedometer[i] := W_CacheLumpName('MREVO' + itoa(i), PU_STATIC);
  mlaps := W_CacheLumpName('MLAPS', PU_STATIC);
  mposbar := W_CacheLumpName('MPOSBAR', PU_STATIC);
  mbest := W_CacheLumpName('MBEST', PU_STATIC);
  mlap := W_CacheLumpName('MLAP', PU_STATIC);
  mpos := W_CacheLumpName('MPOS', PU_STATIC);
  rfinlap := W_CacheLumpName('RFINLAP', PU_STATIC);
  pendrace := W_CacheLumpName('ENDRACE', PU_STATIC);
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

function _big_blue_string_width(const s: string): integer;
var
  i, id: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
  begin
    id := Ord(s[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
      Result := Result + bluedigitbig[id].width + 1;
  end;
end;

function _big_blue_string_offset(const ch: char): integer;
var
  id: integer;
begin
  Result := 0;
  id := Ord(ch) - Ord('0');
  if IsIntegerInRange(id, 0, 9) then
    Result := bluedigitbig[id].leftoffset;
end;

function _small_blue_string_width(const s: string): integer;
var
  i, id: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
  begin
    id := Ord(s[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
      Result := Result + bluedigitsmall[id].width + 1;
  end;
end;

function _small_blue_string_offset(const ch: char): integer;
var
  id: integer;
begin
  Result := 0;
  id := Ord(ch) - Ord('0');
  if IsIntegerInRange(id, 0, 9) then
    Result := bluedigitsmall[id].leftoffset;
end;

procedure SH_DrawNumLaps;
var
  l, t: integer;
  sl, st: string;
  wl, wt: integer;
  i, id: integer;
  xpos: integer;
begin
  V_DrawPatch(160, 14, SCN_HUD, mlaps, false);
  l := GetIntegerInRange(hud_player.mo.lapscompleted + 1, 1, race.numlaps);
  t := race.numlaps;
  sl := itoa(l);
  st := itoa(t);
  wl := _big_blue_string_width(sl);
  wt := _small_blue_string_width(st);

  V_DrawPatch(160, 48, SCN_HUD, blueslashbig, false);

  xpos := 160 - (blueslashbig.width div 2 + 1 + wl);
  for i := 1 to Length(sl) do
  begin
    id := Ord(sl[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
    begin
      V_DrawPatch(xpos + bluedigitbig[id].leftoffset, 48, SCN_HUD, bluedigitbig[id], false);
      xpos := xpos + bluedigitbig[id].width + 1;
    end;
  end;

  xpos := 160 + (blueslashbig.width div 2 + 1);
  for i := 1 to Length(st) do
  begin
    id := Ord(st[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
    begin
      V_DrawPatch(xpos + bluedigitsmall[id].leftoffset, 48, SCN_HUD, bluedigitsmall[id], false);
      xpos := xpos + bluedigitsmall[id].width + 1;
    end;
  end;

end;

procedure _draw_lap_time(const x, y: integer; const tm: integer; const fnt: Ppatch_tPArray);
var
  i: integer;
  stmp: string;
  p, xpos: integer;
begin
  stmp := SH_TicsToTimeStr(tm);
  xpos := x;
  for i := Length(stmp) downto 1 do
  begin
    p := Pos(stmp[i], TIMEDIGITLOOKUP) - 1;
    if p >= 0 then
    begin
      V_DrawPatch(xpos - fnt[p].leftoffset, y - 8 + fnt[p].topoffset, SCN_HUD, fnt[p], false);
      xpos := xpos - fnt[p].width;
    end;
  end;
end;

procedure SH_DrawLapTime;
var
  i: integer;
  numcompletedlaps: integer;
  best: integer;
  ypos: integer;
  curlaptime: integer;
begin
  numcompletedlaps := 0;
  for i := 0 to MAXLAPS do
    if timelaps[i] <> 0 then
      numcompletedlaps := i + 1
    else
      break;

  ypos := 122 - race.numlaps * 10;
  if ypos > 72 then
    ypos := 72;
  if numcompletedlaps > 0 then
  begin
    best := MAXINT;
    for i := 0 to numcompletedlaps - 1 do
      if timelaps[i] < best then
        best := timelaps[i];
    V_DrawPatch(35, ypos, SCN_HUD, mbest, false);
    _draw_lap_time(66, ypos + 10, best, @timedigitwhite);
  end;
  ypos := ypos + 20;
  V_DrawPatch(36, ypos, SCN_HUD, mlap, false);
  if numcompletedlaps < race.numlaps then
  begin
    ypos := ypos + 10;
    if numcompletedlaps = 0 then
      curlaptime := racetime
    else
    begin
      curlaptime := racetime;
      for i := 0 to numcompletedlaps - 1 do
        curlaptime := curlaptime - timelaps[i];
    end;
    _draw_lap_time(66, ypos, curlaptime, @timedigityellow);
  end;
  for i := numcompletedlaps - 1 downto 0 do
    _draw_lap_time(66, ypos + (i + 1) * 10, timelaps[numcompletedlaps - 1 - i], @timedigityellow);
end;

function _big_white_string_width(const s: string): integer;
var
  i, id: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
  begin
    id := Ord(s[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
      Result := Result + whitedigitbig[id].width + 1;
  end;
end;

function _big_white_string_offset(const ch: char): integer;
var
  id: integer;
begin
  Result := 0;
  id := Ord(ch) - Ord('0');
  if IsIntegerInRange(id, 0, 9) then
    Result := whitedigitbig[id].leftoffset;
end;

function _small_white_string_width(const s: string): integer;
var
  i, id: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
  begin
    id := Ord(s[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
      Result := Result + whitedigitsmall[id].width + 1;
  end;
end;

function _small_white_string_offset(const ch: char): integer;
var
  id: integer;
begin
  Result := 0;
  id := Ord(ch) - Ord('0');
  if IsIntegerInRange(id, 0, 9) then
    Result := whitedigitsmall[id].leftoffset;
end;

procedure SH_DrawRacePositions;
var
  wp, wt: integer;
  sp, st: string;
  i, id, xpos: integer;
begin
  V_DrawPatch(54, 164, SCN_HUD, mpos, false);
  V_DrawPatch(54, 196, SCN_HUD, mposbar, false);

  sp := itoa(hud_player.mo.raceposition);
  st := itoa(racepositions.numracepositions);

  wp := _big_white_string_width(sp);
  wt := _small_blue_string_width(st);

  xpos := 54 - (mposbar.width div 2 + 1 + wp);
  for i := 1 to Length(sp) do
  begin
    id := Ord(sp[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
    begin
      V_DrawPatch(xpos + whitedigitbig[id].leftoffset, 196, SCN_HUD, whitedigitbig[id], false);
      xpos := xpos + whitedigitbig[id].width + 1;
    end;
  end;

  xpos := 54 + (mposbar.width div 2 + 1);
  for i := 1 to Length(st) do
  begin
    id := Ord(st[i]) - Ord('0');
    if IsIntegerInRange(id, 0, 9) then
    begin
      V_DrawPatch(xpos + whitedigitsmall[id].leftoffset, 196, SCN_HUD, whitedigitsmall[id], false);
      xpos := xpos + whitedigitsmall[id].width + 1;
    end;
  end;
end;

procedure SH_DrawLastLap;
const
  TICS_SHOW_LAST_LAP = 5 * TICRATE; // 5 seconds
var
  tics: integer;
  tottime: integer;
  i: integer;
begin
  if not IsIntegerInRange(race.numlaps, 2, MAXLAPS) then
    Exit;

  if timelaps[race.numlaps - 2] = 0 then
    Exit;

  tottime := 0;
  for i := 0 to race.numlaps - 2 do
    tottime := tottime + timelaps[i];

  tics := racetime - tottime;
  if tics >= TICS_SHOW_LAST_LAP then
    Exit;

  if tics mod TICRATE < 20 then
    V_DrawPatch(160, 68, SCN_HUD, rfinlap, false);
end;

procedure SH_DrawEndOfRace;
var
  tics: integer;
  tottime: integer;
  i: integer;
begin
  if not IsIntegerInRange(race.numlaps, 2, MAXLAPS) then
    Exit;

  if timelaps[race.numlaps - 1] = 0 then
    Exit;

  tottime := 0;
  for i := 0 to race.numlaps - 1 do
    tottime := tottime + timelaps[i];

  tics := racetime - tottime;

  if tics mod TICRATE < 20 then
    V_DrawPatch(160, 68, SCN_HUD, pendrace, false);
end;

procedure SH_HudDrawer;
begin
  hud_player := @players[consoleplayer];

  if firstinterpolation then
  begin
    ZeroMemory(screens[SCN_HUD], screendimentions[SCN_HUD].width * screendimentions[SCN_HUD].height);

    SH_GetTimeLaps(hud_player.mo, @timelaps);
    // Draw grears
    SH_DrawGears;

    // Draw speed
    SH_DrawSpeed;

    // Elapsed laps
    SH_DrawNumLaps;

    // Lap times
    SH_DrawLapTime;

    // Positions
    SH_DrawRacePositions;

    // Last Lap
    SH_DrawLastLap;

    // End of Race
    SH_DrawEndOfRace;
  end;

  V_CopyRectTransparent(0, 0, SCN_HUD, 320, 200, 0, 0, SCN_FG, true);
end;

end.
