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

unit speed_bitmap;

interface

uses
  d_delphi,
  speed_is2;

//==============================================================================
//
// SH_RotatebitmapBuffer90
//
//==============================================================================
procedure SH_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);

//==============================================================================
//
// SH_FlipbitmapbufferHorz
//
//==============================================================================
procedure SH_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);

//==============================================================================
//
// SH_BltImageBuffer
//
//==============================================================================
procedure SH_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);

//==============================================================================
//
// SH_ColorReplace
//
//==============================================================================
procedure SH_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);

type
  TSpeedBitmap = class
  private
    fwidth, fheight: integer;
    fimg: PByteArray;
    function pos2idx(const x, y: integer): integer;
  protected
    procedure Resize(const awidth, aheight: integer); virtual;
    procedure SetWidth(const awidth: integer); virtual;
    procedure SetHeight(const aheight: integer); virtual;
    function GetPixel(x, y: integer): byte; virtual;
    procedure SetPixel(x, y: integer; const apixel: byte); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ApplyTranslationTable(const trans: PByteArray);
    procedure AttachImage(const buf: PByteArray; const awidth, aheight: integer);
    function AttachIS2(const is2: IS2_TSprite_p): boolean;
    procedure Clear(const color: byte);
    procedure RightCrop(const color: byte);
    property width: integer read fwidth write SetWidth;
    property height: integer read fheight write SetHeight;
    property Pixels[x, y: integer]: byte read GetPixel write SetPixel; default;
    property Image: PByteArray read fimg;
  end;

implementation

//==============================================================================
//
// SH_RotatebitmapBuffer90
//
//==============================================================================
procedure SH_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[i * h + j] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

//==============================================================================
//
// SH_FlipbitmapbufferHorz
//
//==============================================================================
procedure SH_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[(h - j - 1) * w + i] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

//==============================================================================
//
// SH_BltImageBuffer
//
//==============================================================================
procedure SH_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);
var
  i, j: integer;
  b: byte;
  outh: integer;
begin
  outh := y2 - y1 + 1;
  for i := x1 to x2 do
    for j := y1 to y2 do
    begin
      b := inbuf[i * inh + j];
      outbuf[(i - x1) * outh + (j - y1)] := b;

//      b := inbuf[i + j * inw];
//      outbuf[(i - x1) + (j - y1) * (x2 - x1)] := b;
//      b := inbuf[i + j * inw];
//      outbuf[(i - x1) * (y2 - y1) + (j - y1)] := b;
    end;
end;

//==============================================================================
//
// SH_ColorReplace
//
//==============================================================================
procedure SH_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);
var
  i: integer;
begin
  for i := 0 to w * h - 1 do
    if buf[i] = oldc then
      buf[i] := newc;
end;

// TSpeedBitmap

constructor TSpeedBitmap.Create;
begin
  fwidth := 0;
  fheight := 0;
  fimg := nil;
  inherited;
end;

destructor TSpeedBitmap.Destroy;
begin
  if fimg <> nil then
    memfree(pointer(fimg), fwidth * fheight);
  inherited;
end;

//==============================================================================
//
// TSpeedBitmap.ApplyTranslationTable
//
//==============================================================================
procedure TSpeedBitmap.ApplyTranslationTable(const trans: PByteArray);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := trans[fimg[i]];
end;

//==============================================================================
//
// TSpeedBitmap.AttachImage
//
//==============================================================================
procedure TSpeedBitmap.AttachImage(const buf: PByteArray; const awidth, aheight: integer);
var
  i: integer;
begin
  SetWidth(awidth);
  SetHeight(aheight);
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := buf[i];
end;

//==============================================================================
//
// TSpeedBitmap.AttachIS2
//
//==============================================================================
function TSpeedBitmap.AttachIS2(const is2: IS2_TSprite_p): boolean;
type
  bmpixels_t = packed array[0..320, 0..200] of byte;
var
  bm: bmpixels_t;
  raw: PByteArray;
  rawcnt: integer;
  i, j, ii, x, y: integer;
  b: byte;
  n, ni: integer;
  offsets: PIntegerArray;

  function _read_byte: byte;
  begin
    if rawcnt >= is2.len then
    begin
      result := 0;
      exit;
    end;
    result := raw[rawcnt];
    inc(rawcnt);
  end;

begin
  if is2.sign <> IS2_MAGIC then
  begin
    result := false;
    exit;
  end;

  Resize(is2.w, is2.h);

  for i := 0 to is2.w - 1 do
    for j := 0 to is2.h - 1 do
      bm[i, j] := 255;

  raw := @is2.offsets[0];
  rawcnt := 0;

  if is2.flags and IS2F_HORIZONTAL <> 0 then
    n := is2.h
  else
    n := is2.w;

  offsets := malloc((n + 1) * SizeOf(integer));

  for i := 0 to n do
    offsets[i] := is2.len;

  i := 0;
  while i < n do
  begin
    offsets[i] := rawcnt;
    inc(rawcnt);
    while raw[rawcnt] <> 0 do
    begin
      rawcnt := rawcnt + raw[rawcnt] + 1;
      if rawcnt >= is2.len then
        break;
      if raw[rawcnt] = 0 then
        break;
      inc(rawcnt);
    end;
    inc(i);
    inc(rawcnt);
  end;

  for ni := 0 to n - 1 do
  begin
    rawcnt := offsets[ni];
    x := _read_byte;
    y := ni;
    while true do
    begin
      ii := _read_byte;
      for i := 0 to ii - 1 do
      begin
        b := _read_byte;
        if is2.flags and IS2F_HORIZONTAL <> 0 then
          bm[x, y] := b
        else
          bm[y, x] := b;
          inc(x);
      end;
      if raw[rawcnt] = 0 then
      begin
        inc(rawcnt);
        break;
      end;
      if rawcnt >= offsets[ni + 1] then
        break;
      x := x + _read_byte;
      if rawcnt >= is2.len then
        break;
    end;
  end;
  memfree(pointer(offsets), (n + 1) * SizeOf(integer));

  for i := 0 to fwidth - 1 do
    for j := 0 to fheight - 1 do
      fimg[pos2idx(i, j)] := bm[i, j];

  result := true;
end;

//==============================================================================
//
// TSpeedBitmap.Clear
//
//==============================================================================
procedure TSpeedBitmap.Clear(const color: byte);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := color;
end;

//==============================================================================
//
// TSpeedBitmap.RightCrop
//
//==============================================================================
procedure TSpeedBitmap.RightCrop(const color: byte);

  function _do_crop_right: boolean;
  var
    i: integer;
    c: integer;
  begin
    if fwidth = 0 then
    begin
      result := false;
      exit;
    end;
    result := true;
    for i := 0 to fheight - 1 do
    begin
      c := fimg[pos2idx(i, fwidth - 1)];
      if c <> color then
      begin
        result := false;
        exit;
      end;
    end;
    SetWidth(fwidth - 1);
  end;

begin
  repeat until not _do_crop_right;
end;

//==============================================================================
//
// TSpeedBitmap.pos2idx
//
//==============================================================================
function TSpeedBitmap.pos2idx(const x, y: integer): integer;
begin
  result := x * fheight + y;
end;

//==============================================================================
//
// TSpeedBitmap.Resize
//
//==============================================================================
procedure TSpeedBitmap.Resize(const awidth, aheight: integer);
var
  oldsz, newsz: integer;
begin
  if (awidth = fwidth) and (aheight = fheight) then
    exit;
  oldsz := fwidth * fheight;
  fwidth := awidth;
  fheight := aheight;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

//==============================================================================
//
// TSpeedBitmap.SetWidth
//
//==============================================================================
procedure TSpeedBitmap.SetWidth(const awidth: integer);
var
  oldsz, newsz: integer;
begin
  if awidth = fwidth then
    exit;
  oldsz := fwidth * fheight;
  fwidth := awidth;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

//==============================================================================
//
// TSpeedBitmap.SetHeight
//
//==============================================================================
procedure TSpeedBitmap.SetHeight(const aheight: integer);
var
  oldsz, newsz: integer;
begin
  if aheight = fheight then
    exit;
  oldsz := fwidth * fheight;
  fheight := aheight;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

//==============================================================================
//
// TSpeedBitmap.GetPixel
//
//==============================================================================
function TSpeedBitmap.GetPixel(x, y: integer): byte;
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
  begin
    result := 0;
    exit;
  end;
  if not IsIntegerInRange(y, 0, fheight - 1) then
  begin
    result := 0;
    exit;
  end;
  result := fimg[pos2idx(x, y)];
end;

//==============================================================================
//
// TSpeedBitmap.SetPixel
//
//==============================================================================
procedure TSpeedBitmap.SetPixel(x, y: integer; const apixel: byte);
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
    exit;
  if not IsIntegerInRange(y, 0, fheight - 1) then
    exit;
  fimg[pos2idx(x, y)] := apixel;
end;

end.
