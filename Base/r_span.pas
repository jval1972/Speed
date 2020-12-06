//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2020 by Jim Valavanis
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
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_span;

interface

uses
  d_delphi,
  m_fixed,
  r_main;

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
procedure R_DrawSpanLow;
procedure R_DrawSpanMedium;
procedure R_DrawSpanMedium_Ripple;

var
  ds_y: integer;
  ds_x1: integer;
  ds_x2: integer;

  ds_colormap: PByteArray;

  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;

// start of a 64*64 tile image
  ds_source: PByteArray;


type
  dsscale_t = (ds64x64, ds128x128, ds256x256, ds512x512, NUMDSSCALES);

const
  dsscalesize: array[0..Ord(NUMDSSCALES) - 1] of integer = (
     64 *  64,
    128 * 128,
    256 * 256,
    512 * 512
  );

var
  ds_scale: dsscale_t;

implementation

uses
  r_draw,
  r_ripple;
//
// R_DrawSpan
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//

//
// Draws the actual span (Low resolution).
//
procedure R_DrawSpanLow;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  dest: PByte;
  bdest: byte;
  ds_xstep2: fixed_t;
  ds_ystep2: fixed_t;
  count: integer;
  i: integer;
  spot: integer;
  _shift, _and1, _and2: integer;
  rpl: PIntegerArray;
  rpl_shift, rpl_factor: Integer;
begin
  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  if ds_scale = ds512x512 then
  begin
    _shift := 7;
    _and1 := 261632;
    _and2 := 511;
    xfrac := ds_xfrac * 8;
    yfrac := ds_yfrac * 8;
    // Blocky mode, multiply by 3 (!!).
    ds_xstep2 := ds_xstep * 24;
    ds_ystep2 := ds_ystep * 24;
  end
  else if ds_scale = ds256x256 then
  begin
    _shift := 8;
    _and1 := 65280;
    _and2 := 255;
    xfrac := ds_xfrac * 4;
    yfrac := ds_yfrac * 4;
    // Blocky mode, multiply by 3 (!!).
    ds_xstep2 := ds_xstep * 12;
    ds_ystep2 := ds_ystep * 12;
  end
  else if ds_scale = ds128x128 then
  begin
    _shift := 9;
    _and1 := 16256;
    _and2 := 127;
    xfrac := ds_xfrac * 2;
    yfrac := ds_yfrac * 2;
    // Blocky mode, multiply by 3 (!!).
    ds_xstep2 := ds_xstep * 6;
    ds_ystep2 := ds_ystep * 6;
  end
  else
  begin
    _shift := 10;
    _and1 := 4032;
    _and2 := 63;
    xfrac := ds_xfrac;
    yfrac := ds_yfrac;
    // Blocky mode, multiply by 3 (!!).
    ds_xstep2 := ds_xstep * 3;
    ds_ystep2 := ds_ystep * 3;
  end;

  if ds_ripple <> nil then
  begin
    rpl := ds_ripple;

    if ds_scale = ds512x512 then
    begin
      rpl_shift := 19;
      rpl_factor := 8;
    end
    else if ds_scale = ds256x256 then
    begin
      rpl_shift := 18;
      rpl_factor := 4;
    end
    else if ds_scale = ds128x128 then
    begin
      rpl_shift := 17;
      rpl_factor := 2;
    end
    else
    begin
      rpl_shift := 16;
      rpl_factor := 1;
    end;


    count := (ds_x2 - ds_x1) div 3;
    if count < 0 then
      exit;

    for i := 0 to count do
    begin
      spot := (LongWord(yfrac + rpl_factor * rpl[(LongWord(xfrac) shr rpl_shift) and 127]) shr _shift) and (_and1) or
              (LongWord(xfrac + rpl_factor * rpl[(LongWord(yfrac) shr rpl_shift) and 127]) shr FRACBITS) and _and2;
      // Lowres/blocky mode does it twice,
      //  while scale is adjusted appropriately.
      bdest := ds_colormap[ds_source[spot]];
      dest^ := bdest;
      inc(dest);
      dest^ := bdest;
      inc(dest);
      dest^ := bdest;
      inc(dest);

      xfrac := xfrac + ds_xstep2;
      yfrac := yfrac + ds_ystep2;
    end;

    count := (ds_x2 - ds_x1) mod 3;

    for i := 0 to count do
    begin
      spot := (LongWord(yfrac) shr _shift) and (_and1) or (LongWord(xfrac) shr FRACBITS) and _and2;
      // Lowres/blocky mode does it twice,
      //  while scale is adjusted appropriately.
      dest^ := ds_colormap[ds_source[spot]];
      inc(dest);

      xfrac := xfrac + ds_xstep;
      yfrac := yfrac + ds_ystep;
    end;

  end
  else
  begin
    count := (ds_x2 - ds_x1) div 3;
    if count < 0 then
      exit;

    for i := 0 to count do
    begin
      spot := (LongWord(yfrac) shr _shift) and (_and1) or (LongWord(xfrac) shr FRACBITS) and _and2;
      // Lowres/blocky mode does it twice,
      //  while scale is adjusted appropriately.
      bdest := ds_colormap[ds_source[spot]];
      dest^ := bdest;
      inc(dest);
      dest^ := bdest;
      inc(dest);
      dest^ := bdest;
      inc(dest);

      xfrac := xfrac + ds_xstep2;
      yfrac := yfrac + ds_ystep2;
    end;

    count := (ds_x2 - ds_x1) mod 3;

    for i := 0 to count do
    begin
      spot := (LongWord(yfrac) shr _shift) and (_and1) or (LongWord(xfrac) shr FRACBITS) and _and2;
      // Lowres/blocky mode does it twice,
      //  while scale is adjusted appropriately.
      dest^ := ds_colormap[ds_source[spot]];
      inc(dest);

      xfrac := xfrac + ds_xstep;
      yfrac := yfrac + ds_ystep;
    end;
  end;
end;

//
// Draws the actual span (Medium resolution).
//
procedure R_DrawSpanMedium;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
  fb: fourbytes_t;
begin
  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;
  if count < 0 then
    exit;

  {$UNDEF RIPPLE}
  {$I R_DrawSpanMedium.inc}
end;

procedure R_DrawSpanMedium_Ripple;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
  rpl: PIntegerArray;
  fb: fourbytes_t;
begin
  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  count := ds_x2 - ds_x1;
  if count < 0 then
    exit;

  rpl := ds_ripple;
  {$DEFINE RIPPLE}
  {$I R_DrawSpanMedium.inc}
end;

end.

