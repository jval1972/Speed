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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

// From dcolors.c (Doom Utilities Source - https://www.doomworld.com/idgames/historic/dmutils)
unit speed_palette;

interface

uses
  d_delphi;

//==============================================================================
//
// SH_CreateDoomPalette
//
//==============================================================================
procedure SH_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray; const colormap: PByteArray);

//==============================================================================
// SH_CreateTranslation
//
// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
procedure SH_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);

//==============================================================================
//
// SH_FixBufferPalette
//
//==============================================================================
procedure SH_FixBufferPalette(const buf: PByteArray; const x1, x2: integer);

implementation

//==============================================================================
//
// SH_ColorShiftPalette
//
//==============================================================================
procedure SH_ColorShiftPalette(const inpal: PByteArray; const outpal: PByteArray;
  const r, g, b: integer; const shift: integer; const steps: integer);
var
  i: integer;
  dr, dg, db: integer;
  in_p, out_p: PByteArray;
begin
  in_p := inpal;
  out_p := outpal;

  for i := 0 to 255 do
  begin
    dr := r - in_p[0];
    dg := g - in_p[1];
    db := b - in_p[2];

    out_p[0] := in_p[0] + (dr * shift) div steps;
    out_p[1] := in_p[1] + (dg * shift) div steps;
    out_p[2] := in_p[2] + (db * shift) div steps;

    in_p := @in_p[3];
    out_p := @out_p[3];
  end;
end;

//==============================================================================
//
// SH_CopyPalette
//
//==============================================================================
procedure SH_CopyPalette(const inppal, outpal: PByteArray);
var
  i: integer;
begin
  for i := 0 to 767 do
    outpal[i] := inppal[i];
end;

//==============================================================================
//
// SH_BestColor
//
//==============================================================================
function SH_BestColor(const r, g, b: byte; const palette: PByteArray; const rangel, rangeh: integer): byte;
var
  i: integer;
  dr, dg, db: integer;
  bestdistortion, distortion: integer;
  bestcolor: integer;
  pal: PByteArray;
begin
//
// let any color go to 0 as a last resort
//
  bestdistortion := (r * r + g * g + b * b ) * 2;
  bestcolor := 0;

  pal := @palette[rangel * 3];
  for i := rangel to rangeh do
  begin
    dr := r - pal[0];
    dg := g - pal[1];
    db := b - pal[2];
    pal := @pal[3];
    distortion := dr * dr + dg * dg + db * db;
    if distortion < bestdistortion then
    begin
      if distortion = 0 then
      begin
        result := i;  // perfect match
        exit;
      end;

      bestdistortion := distortion;
      bestcolor := i;
    end;
  end;

  result := bestcolor;
end;

//==============================================================================
//
// SH_CreateDoomPalette
//
//==============================================================================
procedure SH_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray; const colormap: PByteArray);
const
  NUMLIGHTS = 32;
var
  lightpalette: packed array[0..NUMLIGHTS + 1, 0..255] of byte;
  i, l, c: integer;
  red, green, blue: integer;
  palsrc: PByte;
  gray: double;
  mx: integer;
begin
  mx := inppal[0];
  for i := 1 to 767 do
    if inppal[i] > mx then
      mx := inppal[i];

  if mx < 64 then
    for i := 0 to 767 do
      inppal[i] := 4 * inppal[i];

  SH_CopyPalette(inppal, outpal);

  for i := 1 to 8 do
    SH_ColorShiftPalette(inppal, @outpal[768 * i], 255, 0, 0, i, 9);

  for i := 1 to 4 do
    SH_ColorShiftPalette(inppal, @outpal[768 * (i + 8)], 215, 186, 69, i, 8);

  SH_ColorShiftPalette(inppal, @outpal[768 * 13], 0, 256, 0, 1, 8);

  for l := 0 to NUMLIGHTS - 1 do
  begin
    palsrc := @inppal[0];
    for c := 0 to 255 do
    begin
      red := palsrc^; inc(palsrc);
      green := palsrc^; inc(palsrc);
      blue := palsrc^; inc(palsrc);

      red := (red * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;
      green := (green * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;
      blue := (blue * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;

      lightpalette[l][c] := SH_BestColor(red, green, blue, inppal, 0, 255);
    end;
  end;

  palsrc := @inppal[0];
  for c := 0 to 255 do
  begin
    red := palsrc^; inc(palsrc);
    green := palsrc^; inc(palsrc);
    blue := palsrc^; inc(palsrc);

    // https://doomwiki.org/wiki/Carmack%27s_typo
    // Correct Carmack's typo
    gray := red * 0.299 / 256 + green * 0.587 / 265 + blue * 0.114 / 256;
    gray := 1.0 - gray;
    lightpalette[NUMLIGHTS][c] := SH_BestColor(trunc(gray * 255), trunc(gray * 255), trunc(gray * 255), inppal, 0, 255);
  end;

  for c := 0 to 255 do
    lightpalette[NUMLIGHTS + 1][c] := 0;

  for i := 0 to NUMLIGHTS + 1 do
    for c := 0 to 255 do
      colormap[i * 256 + c] := lightpalette[i][c];

end;

//==============================================================================
// SH_CreateTranslation
//
// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
procedure SH_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);
var
  i: integer;
  r, g, b: byte;
begin
  for i := 0 to 255 do
  begin
    r := topal[i * 3];
    g := topal[i * 3 + 1];
    b := topal[i * 3 + 2];
    trans[i] := SH_BestColor(r, g, b, frompal, 0, 255);
  end;
end;

//==============================================================================
//
// SH_FixBufferPalette
//
//==============================================================================
procedure SH_FixBufferPalette(const buf: PByteArray; const x1, x2: integer);
var
  i: integer;
  x0: integer;
begin
  x0 := x1;
  if x0 = 0 then
    x0 := 1;
  for i := x0 to x2 do
    if (buf[i] < 16) or (buf[i] > 239) then
      buf[i] := buf[i - 1];
end;

end.

