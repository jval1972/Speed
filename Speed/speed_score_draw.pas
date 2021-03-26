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
//  Draw lap and course times
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_score_draw;

interface

uses
  speed_score;

procedure SH_DrawScoreTableItems(const si: Pspeedtimetableitems_t);

implementation

uses
  d_delphi,
  doomdef,
  hu_stuff,
  mn_textwrite,
  speed_cars,
  speed_string_format,
  v_data,
  v_video;

procedure SH_DrawScoreTableItems(const si: Pspeedtimetableitems_t);
var
  ypos: integer;
  i: integer;
begin
  ypos := 64;
  M_WriteText(18, ypos, 'NAME', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(143, ypos, 'CAR', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(253, ypos, 'TIME', ma_left, @hu_fontY, @hu_fontB);

  ypos := 80;
  for i := 0 to NUMSCORES - 1 do
  begin
    M_WriteText(16, ypos, itoa(i + 1), ma_right, @hu_fontY, @hu_fontB);
    if si[i].time > 0 then
    begin
      M_WriteText(18, ypos, si[i].drivername, ma_left, @hu_fontW, @hu_fontB);
      M_WriteText(143, ypos, CARINFO[si[i].carid].name, ma_left, @hu_fontW, @hu_fontB);
      M_WriteText(253, ypos, SH_TicsToTimeStr(si[i].time), ma_left, @hu_fontW, @hu_fontB);
    end;
    ypos := ypos + 10;
  end;

end;

end.