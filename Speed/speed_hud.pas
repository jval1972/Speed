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

var
  draw_speed_hud: boolean = true;

implementation

uses
  d_delphi,
  c_cmds,
  doomdef,
  d_player,
  p_tick,
  d_net,
  g_game,
  m_fixed,
  tables,
  r_defs,
  speed_cars,
  speed_race,
  speed_path,
  speed_string_format,
  v_data,
  v_video,
  w_wad,
  z_zone;

procedure CmdprintSpeedHud(const parm: string);
begin
  if parm = '' then
  begin
    printf('draw_speed_hud=' + decide(draw_speed_hud, 'TRUE', 'FALSE') + #13#10);
    Exit;
  end;

  draw_speed_hud := C_BoolEval(parm, draw_speed_hud);
  CmdprintSpeedHud('');
end;

var
  bluedigitbig: array[0..9] of Ppatch_t;
  blueslashbig: Ppatch_t;
  bluedigitsmall: array[0..9] of Ppatch_t;
  blueslashsmall: Ppatch_t;
  whitedigitbig: array[0..9] of Ppatch_t;
  whitedigitsmall: array[0..9] of Ppatch_t;
  gearbox: Ppatch_t;
  gears: array[0..6] of Ppatch_t;
  gear_reverse: Ppatch_t;
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

type
  point_t = record
    x, y: integer;
  end;

  triangle_t = array[0..2] of point_t;
  Ptriangle_t = ^triangle_t;

const
  ARROW_RESAMPLE = 4;

type
  colorinfo_t = record
    r, g, b: integer;
  end;

  resamplescreen_t = array[0..320 * ARROW_RESAMPLE - 1, 0..200 * ARROW_RESAMPLE - 1] of colorinfo_t;
  Presamplescreen_t = ^resamplescreen_t;

var
  resamplescreen: Presamplescreen_t;

procedure SH_InitSpeedHud;
var
  i: integer;
  sn: string;
begin
  C_AddCmd('draw_speed_hud, draw_player_hud', @CmdprintSpeedHud);
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
  gear_reverse := W_CacheLumpName('MGR', PU_STATIC);
  for i := 0 to 1 do
    speedometer[i] := W_CacheLumpName('MREVO' + itoa(i), PU_STATIC);
  mlaps := W_CacheLumpName('MLAPS', PU_STATIC);
  mposbar := W_CacheLumpName('MPOSBAR', PU_STATIC);
  mbest := W_CacheLumpName('MBEST', PU_STATIC);
  mlap := W_CacheLumpName('MLAP', PU_STATIC);
  mpos := W_CacheLumpName('MPOS', PU_STATIC);
  rfinlap := W_CacheLumpName('RFINLAP', PU_STATIC);
  pendrace := W_CacheLumpName('ENDRACE', PU_STATIC);
  resamplescreen := mallocz(SizeOf(resamplescreen_t));
end;

var
  hud_player: Pplayer_t;

procedure SH_ShutDownSpeedHud;
begin
  memfree(pointer(resamplescreen), SizeOf(resamplescreen_t));
end;

var
  rminx, rmaxx, rminy, rmaxy: integer;

procedure SH_DrawColoredTriangle(const tri: Ptriangle_t; const cl: LongWord;
  const rot: angle_t; const center: point_t);

var
  cr, cg, cb: integer;

  procedure fillLeftFlatTriangle(v1, v2, v3: point_t);
  var
    invslope1, invslope2: fixed_t;
    cury1, cury2: fixed_t;
    i, j: integer;
    v: point_t;
    iup: integer;
    idown: integer;
    jup: integer;
    jdown: integer;
  begin
    if v2.y > v3.y then
    begin
      v := v3;
      v3 := v2;
      v2 := v;
    end;
    invslope1 := Round((v2.y - v1.y) / (v2.x - v1.x) * FRACUNIT);
    invslope2 := Round((v3.y - v1.y) / (v3.x - v1.x) * FRACUNIT);

    cury1 := v1.y * FRACUNIT;
    cury2 := cury1;

    iup := v2.x;
    idown := v1.x;

    for i := idown to iup do
    begin
      jup := cury2 div FRACUNIT + 1;
      if jup >= 0 then
      begin
        if jup >= 200 * ARROW_RESAMPLE then
          jup := 200 * ARROW_RESAMPLE - 1;
        jdown := cury1 div FRACUNIT;
        if jdown < 0 then
          jdown := 0;

        for j := jdown to jup do
        begin
          resamplescreen[i, j].r := cr;
          resamplescreen[i, j].g := cg;
          resamplescreen[i, j].b := cb;
        end;
      end;
      cury1 := cury1 + invslope1;
      cury2 := cury2 + invslope2;
    end;
  end;

  procedure fillRightFlatTriangle(v1, v2, v3: point_t);
  var
    invslope1, invslope2: fixed_t;
    cury1, cury2: fixed_t;
    i, j: integer;
    v: point_t;
    idown: integer;
    iup: integer;
    jup: integer;
    jdown: integer;
  begin
    if v2.y < v1.y then
    begin
      v := v2;
      v2 := v1;
      v1 := v;
    end;
    invslope1 := Round((v3.y - v1.y) / (v3.x - v1.x) * FRACUNIT);
    invslope2 := Round((v3.y - v2.y) / (v3.x - v2.x) * FRACUNIT);

    cury1 := v3.y * FRACUNIT;
    cury2 := cury1;

    idown := v1.x + 1;

    iup := v3.x;

    for i := iup downto idown do
    begin
      cury1 := cury1 - invslope1;
      cury2 := cury2 - invslope2;

      jup := cury2 div FRACUNIT + 1;
      if jup >= 0 then
      begin
        if jup >= 200 * ARROW_RESAMPLE then
          jup := 200 * ARROW_RESAMPLE - 1;
        jdown := cury1 div FRACUNIT;
        if jdown < 0 then
          jdown := 0;

        for j := jdown to jup do
        begin
          resamplescreen[i, j].r := cr;
          resamplescreen[i, j].g := cg;
          resamplescreen[i, j].b := cb;
        end;
      end;
    end;
  end;

  procedure _transformcoords(const xx, yy: PInteger);
  var
    tmp: integer;
    ang: angle_t;
  begin
    ang := rot shr FRACBITS;

    tmp := ARROW_RESAMPLE * center.x +
      (ARROW_RESAMPLE * xx^ * fixedcosine[ang] -
       ARROW_RESAMPLE * yy^ * fixedsine[ang]) div FRACUNIT;

    yy^ := ARROW_RESAMPLE * center.y +
      (ARROW_RESAMPLE * xx^ * fixedsine[ang] +
       ARROW_RESAMPLE * yy^ * fixedcosine[ang]) div FRACUNIT;

    xx^ := tmp;
  end;

var
  v1, v2, v3, v4: point_t;
  t: triangle_t;
  i: integer;
begin
  cr := cl and $FF;
  cg := (cl shr 8) and $FF;
  cb := (cl shr 16) and $FF;

  t[0] := tri[0];
  t[1] := tri[1];
  t[2] := tri[2];

  for i := 0 to 2 do
  begin
    _transformcoords(@t[i].x, @t[i].y);
    if t[i].x < rminx then
      rminx := t[i].x;
    if t[i].x > rmaxx then
      rmaxx := t[i].x;
    if t[i].y < rminy then
      rminy := t[i].y;
    if t[i].y > rmaxy then
      rmaxy := t[i].y;
  end;

  if t[1].x < t[0].x then
  begin
    v1 := t[1];
    t[1] := t[0];
    t[0] := v1;
  end;

  if t[2].x < t[1].x then
  begin
    v1 := t[2];
    t[2] := t[1];
    t[1] := v1;
  end;

  if t[1].x < t[0].x then
  begin
    v1 := t[1];
    t[1] := t[0];
    t[0] := v1;
  end;

  if t[0].y < 0 then
    if t[1].y < 0 then
      if t[2].y < 0 then
        Exit;

  if t[0].y >= 200 * ARROW_RESAMPLE - 1 then
    if t[1].y >= 200 * ARROW_RESAMPLE - 1 then
      if t[2].y >= 200 * ARROW_RESAMPLE - 1 then
        Exit;

  v1 := t[0];
  v2 := t[1];
  v3 := t[2];

  if v2.x = v3.x then
  begin
    fillLeftFlatTriangle(v1, v2, v3);
    Exit;
  end;

  if v1.x = v2.x then
  begin
    fillRightFlatTriangle(v1, v2, v3);
    Exit;
  end;

  v4.y := round(v1.y + ((v2.x - v1.x) / (v3.x - v1.x)) * (v3.y - v1.y));
  v4.x := v2.x;

  fillLeftFlatTriangle(v1, v2, v4);
  fillRightFlatTriangle(v2, v4, v3);
end;

procedure SH_DrawNeedle(const x, y: integer; const cl: LongWord; const rot: angle_t;
  const pidx1, pidx2: integer);
var
  tri: triangle_t;
  center: point_t;
  i, j: integer;
  ii, jj: integer;
  pixel: colorinfo_t;
  cc: LongWord;
begin
  rminx := MAXINT;
  rmaxx := -MAXINT;
  rminy := MAXINT;
  rmaxy := -MAXINT;
  center.x := x;
  center.y := y;
  tri[0].x := 0;
  tri[0].y := 0;
  tri[1].x := 4;
  tri[1].y := 4;
  tri[2].x := 0;
  tri[2].y := 20;
  SH_DrawColoredTriangle(@tri, cl, rot, center);
  tri[1].x := -4;
  SH_DrawColoredTriangle(@tri, cl, rot, center);
  for i := rminx div ARROW_RESAMPLE - 1 to (1 + rmaxx) div ARROW_RESAMPLE + 1 do
    for j := rminy div ARROW_RESAMPLE - 1 to (1 + rmaxy) div ARROW_RESAMPLE + 1 do
    begin
      pixel.r := 0;
      pixel.g := 0;
      pixel.b := 0;
      for ii := i * ARROW_RESAMPLE to (1 + i) * ARROW_RESAMPLE - 1 do
        for jj := j * ARROW_RESAMPLE to (1 + j) * ARROW_RESAMPLE - 1 do
        begin
          pixel.r := pixel.r + resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].r;
          pixel.g := pixel.g + resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].g;
          pixel.b := pixel.b + resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].b;
        end;
      pixel.r := pixel.r div (ARROW_RESAMPLE * ARROW_RESAMPLE);
      pixel.g := pixel.g div (ARROW_RESAMPLE * ARROW_RESAMPLE);
      pixel.b := pixel.b div (ARROW_RESAMPLE * ARROW_RESAMPLE);
      cc := pixel.r + (pixel.g shl 8) + (pixel.b shl 16);
      if cc <> 0 then
      begin
        screens[SCN_HUD][j * 320 + i] := V_FindAproxColorIndex(@curpal, cc, pidx1, pidx2);
        for ii := i * ARROW_RESAMPLE to (1 + i) * ARROW_RESAMPLE - 1 do
          for jj := j * ARROW_RESAMPLE to (1 + j) * ARROW_RESAMPLE - 1 do
          begin
            resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].r := 0;
            resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].g := 0;
            resamplescreen[ii - ARROW_RESAMPLE div 2, jj - ARROW_RESAMPLE div 2].b := 0;
          end;
      end;
    end;
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
  SH_DrawNeedle(259, 166, $FFE000, (leveltime div 35) * ANG1, 51, 60);
end;

procedure SH_DrawGears;
begin
  V_DrawPatch(307, 195, SCN_HUD, gearbox, false);
  case hud_player.mo.gear of
  -1: V_DrawPatch(307, 143, SCN_HUD, gear_reverse, false);
   0: V_DrawPatch(307, 143, SCN_HUD, gears[0], false);
   1: V_DrawPatch(307, 151, SCN_HUD, gears[1], false);
   2: V_DrawPatch(307, 159, SCN_HUD, gears[2], false);
   3: V_DrawPatch(307, 167, SCN_HUD, gears[3], false);
   4: V_DrawPatch(307, 175, SCN_HUD, gears[4], false);
   5: V_DrawPatch(307, 183, SCN_HUD, gears[5], false);
   6: V_DrawPatch(307, 191, SCN_HUD, gears[6], false);
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
    for i := numcompletedlaps - 1 downto 0 do
      _draw_lap_time(66, ypos + (i + 1) * 10, timelaps[numcompletedlaps - 1 - i], @timedigityellow);
  end
  else
  begin
    for i := race.numlaps - 1 downto 0 do
      _draw_lap_time(66, ypos + (i + 1) * 10, timelaps[race.numlaps - 1 - i], @timedigityellow);
  end;
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
  if not draw_speed_hud then
    Exit;

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
