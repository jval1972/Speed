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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Screen fade effect.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_wipe;

interface

uses
  d_delphi;

procedure wipe_StartScreen;

procedure wipe_EndScreen;

function wipe_Ticker(ticks: integer): boolean;

var
  WIPESCREENWIDTH: integer;
  WIPESCREENHEIGHT: integer;

var
  w_screen32: PLongWordArray = nil;

procedure wipe_ClearMemory;

implementation

uses
  doomdef,
  r_hires,
  m_fixed,
  i_system,
  gl_main,
  v_data,
  v_video;

var
  fade_scr_start: PLongWordArray;
  fade_scr_end: PLongWordArray;

var
  fadefactor: fixed_t = 0;

function wipe_glsize(const value: integer): integer;
begin
  result := 1;
  while result < value do
    result := result * 2;
end;

procedure wipe_initFade;
var
  i, r: integer;
begin
  WIPESCREENWIDTH := wipe_glsize(SCREENWIDTH);
  WIPESCREENHEIGHT := wipe_glsize(SCREENHEIGHT);
  if w_screen32 = nil then
    w_screen32 := malloc(WIPESCREENWIDTH * WIPESCREENHEIGHT * SizeOf(LongWord));
  // copy start screen to main screen
  for i := 0 to SCREENWIDTH - 1 do
    for r := 0 to SCREENHEIGHT - 1 do
      w_screen32[r * WIPESCREENWIDTH + i] := fade_scr_start[r * SCREENWIDTH + i];
  fadefactor := FRACUNIT;
end;

function wipe_ColorFadeAverage(const c1, c2: LongWord; const factor: fixed_t): LongWord;
var
  ffade: fixed_t;
begin
  if factor > FRACUNIT div 2 then
  begin
    ffade := (FRACUNIT - factor) * 2;
    result := R_ColorAverage(c2, $161616, ffade);
  end
  else
  begin
    ffade := factor * 2;
    result := R_ColorAverage(c1, $161616, ffade);
  end;
end;

function wipe_doFade(ticks: integer): integer;
var
  i: integer;
  j: integer;
begin
  result := 1;

  if fadefactor = 0 then
    exit;

  fadefactor := fadefactor - ticks * 2048;
  if fadefactor < 0 then
    fadefactor := 0;

  for i := 0 to SCREENWIDTH - 1 do
    for j := 0 to SCREENHEIGHT - 1 do
      w_screen32[j * WIPESCREENWIDTH  + i] := wipe_ColorFadeAverage(fade_scr_end[j * SCREENWIDTH + i], fade_scr_start[j * SCREENWIDTH + i], fadefactor) or $FF000000;
  if fadefactor > 0 then
    result := 0;
end;

procedure wipe_exitFade;
begin
  memfree(pointer(fade_scr_start), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  memfree(pointer(fade_scr_end), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

procedure wipe_ClearMemory;
begin
  if w_screen32 <> nil then
    memfree(pointer(w_screen32), WIPESCREENWIDTH * WIPESCREENHEIGHT * SizeOf(LongWord));
end;

procedure wipe_StartScreen;
begin
  fade_scr_start := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  I_ReadScreen32(fade_scr_start);
  I_ReverseScreen(fade_scr_start);
end;

procedure wipe_EndScreen;
begin
  fade_scr_end := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  I_ReadScreen32(fade_scr_end);
  I_ReverseScreen(fade_scr_end);
end;

// when zero, stop the fade
var
  fading: boolean = false;

function wipe_Ticker(ticks: integer): boolean;
begin
  // initial stuff
  if not fading then
  begin
    fading := true;
    wipe_initFade;
  end;

  // do a piece of fade
  if wipe_doFade(ticks) <> 0 then
  begin
    // final stuff
    fading := false;
    wipe_exitFade;
  end;

  result := not fading;
end;

end.
