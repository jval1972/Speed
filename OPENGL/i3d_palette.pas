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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    I3D Model Palette Stuff
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit i3d_palette;

interface

type
  I3DPalette_t = array[0..255] of LongWord;

type
  i3dcolor3f_t = record
    r, g, b: single;
  end;

function I3DPalColor3f(const idx: byte): i3dcolor3f_t;

function I3DPalColorL(const idx: byte): LongWord;

function I3DPalColorIndex(const c: LongWord): integer;

implementation

const
 RawPalette: array[0..767] of Byte = (
    $00, $00, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $3F, $38, $32, $3B, $32, $2C, $38, $2E, $27, $35, $29, $21,
    $32, $24, $1D, $2F, $1F, $18, $2C, $1B, $14, $29, $16, $11, $26, $12, $0D,
    $22, $0F, $0A, $1F, $0B, $07, $1C, $08, $05, $19, $05, $03, $16, $02, $01,
    $13, $01, $00, $10, $00, $00, $3F, $36, $36, $3B, $2B, $2B, $37, $21, $21,
    $33, $18, $18, $2F, $10, $10, $2B, $09, $09, $27, $03, $03, $23, $00, $00,
    $3F, $2A, $17, $3F, $26, $10, $3F, $22, $08, $3F, $1E, $00, $39, $1B, $00,
    $33, $18, $00, $2D, $15, $00, $27, $13, $00, $3F, $3F, $36, $3E, $3D, $30,
    $3D, $3C, $2B, $3C, $3A, $25, $3B, $39, $20, $3A, $37, $1B, $39, $35, $16,
    $38, $33, $12, $33, $2E, $0E, $2E, $2A, $0A, $29, $26, $07, $24, $22, $05,
    $1F, $1D, $03, $1A, $19, $01, $15, $14, $00, $10, $10, $00, $39, $39, $2D,
    $36, $36, $28, $33, $33, $24, $30, $30, $20, $2D, $2D, $1C, $2A, $2B, $19,
    $27, $28, $16, $24, $25, $12, $21, $22, $0F, $1E, $1F, $0D, $1C, $1D, $0A,
    $19, $1A, $08, $16, $17, $06, $13, $14, $04, $10, $11, $03, $0E, $0F, $02,
    $2C, $33, $00, $27, $30, $00, $23, $2E, $00, $1F, $2C, $00, $1B, $29, $00,
    $17, $27, $00, $14, $25, $00, $11, $22, $00, $0E, $20, $00, $0C, $1E, $00,
    $09, $1B, $00, $07, $19, $00, $05, $17, $00, $03, $14, $00, $02, $12, $00,
    $01, $10, $00, $3B, $3D, $3E, $34, $39, $3B, $2D, $34, $37, $28, $31, $34,
    $22, $2E, $31, $1D, $2B, $2E, $18, $27, $2B, $14, $25, $28, $10, $22, $25,
    $0C, $1F, $22, $09, $1C, $1F, $06, $1A, $1C, $04, $17, $19, $02, $15, $16,
    $00, $12, $13, $00, $10, $10, $36, $3B, $3F, $30, $37, $3C, $2B, $33, $3A,
    $27, $2F, $38, $22, $2A, $36, $1E, $26, $34, $1A, $22, $31, $16, $1E, $2F,
    $13, $1A, $2D, $10, $16, $2B, $0D, $12, $29, $0A, $0E, $26, $07, $0A, $24,
    $05, $07, $22, $03, $04, $20, $01, $01, $1E, $31, $24, $1A, $2E, $21, $17,
    $2C, $1F, $14, $29, $1D, $11, $27, $1B, $0F, $24, $19, $0C, $22, $18, $0A,
    $1F, $16, $08, $1D, $14, $06, $1A, $12, $05, $18, $11, $03, $15, $0F, $02,
    $13, $0E, $01, $11, $0C, $00, $0E, $0A, $00, $0C, $09, $00, $3F, $3D, $37,
    $3C, $39, $32, $3A, $36, $2E, $38, $32, $2A, $35, $2F, $26, $33, $2B, $22,
    $31, $27, $1E, $2F, $24, $1B, $2C, $21, $18, $29, $1E, $15, $26, $1B, $13,
    $23, $18, $11, $20, $15, $0F, $1D, $13, $0C, $1B, $10, $0B, $18, $0E, $09,
    $3B, $3B, $3B, $39, $39, $39, $37, $37, $37, $35, $35, $35, $33, $33, $33,
    $31, $31, $31, $2F, $2F, $2F, $2D, $2D, $2D, $2B, $2B, $2B, $29, $29, $29,
    $27, $27, $27, $25, $25, $25, $23, $23, $23, $22, $22, $22, $20, $20, $20,
    $1E, $1E, $1E, $1C, $1C, $1C, $1A, $1A, $1A, $18, $18, $18, $16, $16, $16,
    $14, $14, $14, $12, $12, $12, $10, $10, $10, $0E, $0E, $0E, $0C, $0C, $0C,
    $0A, $0A, $0A, $09, $09, $09, $07, $07, $07, $05, $05, $05, $03, $03, $03,
    $01, $01, $01, $00, $00, $00, $3B, $32, $32, $38, $2C, $2C, $36, $28, $28,
    $34, $23, $23, $32, $1F, $1F, $30, $1A, $1A, $2D, $17, $17, $2B, $13, $13,
    $29, $10, $10, $27, $0C, $0C, $25, $09, $09, $22, $07, $07, $20, $04, $04,
    $1E, $02, $02, $1C, $01, $01, $1A, $00, $00, $3F, $3F, $2E, $3F, $3D, $22,
    $3F, $39, $16, $3F, $34, $0A, $3F, $2D, $00, $37, $26, $00, $2F, $20, $00,
    $27, $1A, $00, $1F, $15, $00, $3B, $32, $3F, $32, $25, $38, $2B, $1B, $31,
    $24, $12, $2A, $1D, $0A, $23, $17, $05, $1C, $11, $01, $15, $37, $38, $3F,
    $33, $33, $3C, $2F, $30, $39, $2C, $2C, $36, $29, $28, $33, $26, $25, $31,
    $24, $22, $2E, $21, $1F, $2B, $1F, $1C, $28, $1D, $19, $25, $1B, $16, $23,
    $19, $14, $20, $17, $11, $1D, $15, $0F, $1A, $13, $0D, $17, $11, $0B, $15,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $3F, $10, $3F
  );

function I3DPalColor3f(const idx: byte): i3dcolor3f_t;
begin
  Result.b := (RawPalette[3 * idx + 2] + 0.5) / 64;
  Result.g := (RawPalette[3 * idx + 1] + 0.5) / 64;
  Result.r := (RawPalette[3 * idx + 0] + 0.5) / 64;
end;

function I3DPalColorL(const idx: byte): LongWord;
begin
  Result :=
    (RawPalette[3 * idx + 2] * 4 + 2) shl 16 +
    (RawPalette[3 * idx + 1] * 4 + 2) shl 8 +
    (RawPalette[3 * idx + 0] * 4 + 2);
end;

function I3DPalColorIndex(const c: LongWord): integer;
var
  r, g, b: integer;
  rc, gc, bc: integer;
  dr, dg, db: integer;
  i: integer;
  dist: LongWord;
  mindist: LongWord;
begin
  r := c and $FF;
  g := (c shr 8) and $FF;
  b := (c shr 16) and $FF;
  Result := 0;
  mindist := LongWord($ffffffff);
  for i := 0 to 255 do
  begin
    rc := RawPalette[3 * i];
    gc := RawPalette[3 * i + 1];
    bc := RawPalette[3 * i + 2];
    dr := r - rc;
    dg := g - gc;
    db := b - bc;
    dist := dr * dr + dg * dg + db * db;
    if dist < mindist then
    begin
      Result := i;
      if dist = 0 then
        Exit
      else
        mindist := dist;
    end;
  end;
end;


end.
