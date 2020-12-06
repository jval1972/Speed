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

unit r_span32;

interface

uses
  d_delphi,
  m_fixed,
  r_main;

var
  ds_lightlevel: fixed_t;
  ds_llzindex: fixed_t; // Lightlevel index for z axis

// start of a WxW tile image
  ds_source32: PLongWordArray;

procedure R_DrawSpanNormal;
procedure R_DrawSpanNormal_Ripple;

implementation

uses
  r_precalc,
  r_ripple,
  r_span,
  r_draw,
  r_hires,
  r_grow,
  v_video;

//
// Draws the actual span (Normal resolution).
//
procedure R_DrawSpanNormal;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
begin
  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  count := ds_x2 - ds_x1;
  if count < 0 then
    exit;

  lfactor := ds_lightlevel;

  if lfactor >= 0 then // Use hi detail lightlevel
  begin
    R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
    {$UNDEF RIPPLE}
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$UNDEF RIPPLE}
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
end;

procedure R_DrawSpanNormal_Ripple;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
  rpl: PIntegerArray;
begin
  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;
  if count < 0 then
    exit;

  rpl := ds_ripple;
  lfactor := ds_lightlevel;
  if lfactor >= 0 then // Use hi detail lightlevel
  begin
    R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
    {$DEFINE RIPPLE}
    {$UNDEF INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end
  else // Use inversecolormap
  begin
    {$DEFINE RIPPLE}
    {$DEFINE INVERSECOLORMAPS}
    {$UNDEF TRANSPARENTFLAT}
    {$I R_DrawSpanNormal.inc}
  end;
end;

end.

