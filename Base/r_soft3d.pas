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
//  Software Rendering Library
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit r_soft3d;

interface

uses
  Windows, SysUtils, Classes, Graphics, Math;

type
  IUINT32 = LongWord;
  IUINT32Array = array[0..$FF] of IUINT32;
  PIUINT32Array = ^IUINT32Array;
  IUINT32PArray = array[0..$FF] of PIUINT32Array;
  PIUINT32PArray = ^IUINT32PArray;

  float = single;
  floatArray = array[0..$FF] of float;
  PfloatArray = ^floatArray;
  floatPArray = array[0..$FF] of PfloatArray;
  PfloatPArray = ^floatPArray;

type
  matrix_t = array[0..3, 0..3] of float;
  Pmatrix_t = ^matrix_t;

  vector_t = record
    x, y, z, w: float;
  end;
  Pvector_t = ^vector_t;

type
  transform_t = record
    world: matrix_t;
    view: matrix_t;
    projection: matrix_t;
    transform: matrix_t;  // transform = world * view * projection
    w, h: float;
  end;
  Ptransform_t = ^transform_t;

type
  color_t = record
    r, g, b: float;
  end;
  Pcolor_t = ^color_t;

  texcoord_t = record
    u, v: float;
  end;
  Ptexcoord_t = ^texcoord_t;

  vertex_t = record
    pos: vector_t;
    tc: texcoord_t;
    color: color_t;
    rhw: float;
  end;
  Pvertex_t = ^vertex_t;

  edge_t = record
    v, v1, v2: vertex_t;
  end;
  Pedge_t = ^edge_t;

  trapezoid_t = record
    top, bottom: float;
    left, right: edge_t;
  end;
  Ptrapezoid_t = ^trapezoid_t;
  trapezoid_tArray = array[0..1] of trapezoid_t;
  Ptrapezoid_tArray = ^trapezoid_tArray;

  scanline_t = record
    v, step: vertex_t;
    x, y, w: integer;
  end;
  Pscanline_t = ^scanline_t;

type
  device_t = record
    transform: transform_t;
    width: integer;
    height: integer;
    bframebuffer: TBitmap;
    bzbuffer: TBitmap;
    bztexture: TBitmap;
    framebuffer: PIUINT32PArray;
    zbuffer: PfloatPArray;
    texture: PIUINT32PArray;
    tex_width: integer;
    tex_height: integer;
    max_u: float; // tex_width - 1
    max_v: float; // tex_height - 1
    render_state: integer;
    texture_state: integer;
    background: IUINT32;
    foreground: IUINT32;
  end;
  Pdevice_t = ^device_t;

const
  RENDER_STATE_WIREFRAME = 1;
  RENDER_STATE_COLOR = 2;
  RENDER_STATE_TEXTURE_SOLID = 4;
  RENDER_STATE_TEXTURE_ALPHAZERO = 8;

const
  TEXTURE_STATE_CLAMP = 0;
  TEXTURE_STATE_REPEAT = 1;

const
  TEXTURESIZE = 256;

procedure device_init(const device: Pdevice_t; const width, height: integer);

procedure camera_at_zero(const device: Pdevice_t; const x, y, z: float);

procedure device_set_texture(const device: Pdevice_t; const tex: TBitmap);

procedure device_clear(const device: Pdevice_t);

procedure device_destroy(const device: Pdevice_t);

procedure device_draw_primitive(const device: Pdevice_t; const v1, v2, v3: Pvertex_t);

procedure matrix_set_rotate(const m: Pmatrix_t; x, y, z: float; const theta: float);

procedure transform_update(const ts: Ptransform_t);

procedure matrix_add(const c: Pmatrix_t; const a, b: Pmatrix_t);

procedure matrix_sub(const c: Pmatrix_t; const a, b: Pmatrix_t);

procedure matrix_mul(const c: Pmatrix_t; const a, b: Pmatrix_t);

implementation

function CMID(const x: integer; const amin, amax: integer): integer;
begin
  if x < amin then
    Result := amin
  else if x > amax then
    Result := amax
  else
    Result := x;
end;

function interp(const x1, x2: float; const t: float): float;
begin
  Result := x1 + (x2 - x1) * t;
end;

function vector_length(const v: Pvector_t): float;
var
  sq: float;
begin
  sq := v.x * v.x + v.y * v.y + v.z * v.z;
  Result := Sqrt(sq);
end;

procedure vector_add(const z: Pvector_t; const x, y: Pvector_t);
begin
  z.x := x.x + y.x;
  z.y := x.y + y.y;
  z.z := x.z + y.z;
  z.w := 1.0;
end;

procedure vector_sub(const z: Pvector_t; const x, y: Pvector_t);
begin
  z.x := x.x - y.x;
  z.y := x.y - y.y;
  z.z := x.z - y.z;
  z.w := 1.0;
end;

function vector_dotproduct(const x, y: Pvector_t): float;
begin
  Result := x.x * y.x + x.y * y.y + x.z * y.z;
end;

procedure vector_crossproduct(const z: Pvector_t; const x, y: Pvector_t);
var
  m1, m2, m3: float;
begin
  m1 := x.y * y.z - x.z * y.y;
  m2 := x.z * y.x - x.x * y.z;
  m3 := x.x * y.y - x.y * y.x;
  z.x := m1;
  z.y := m2;
  z.z := m3;
  z.w := 1.0;
end;

procedure vector_interp(const z: Pvector_t; const x1, x2: Pvector_t; const t: float);
begin
  z.x := interp(x1.x, x2.x, t);
  z.y := interp(x1.y, x2.y, t);
  z.z := interp(x1.z, x2.z, t);
  z.w := 1.0;
end;

procedure vector_normalize(const v: Pvector_t );
var
  len, inv: float;
begin
  len := vector_length(v);
  if len <> 0.0 then
  begin
    inv := 1.0 / len;
    v.x := v.x * inv;
    v.y := v.y * inv;
    v.z := v.z * inv;
  end;
end;

procedure matrix_add(const c: Pmatrix_t; const a, b: Pmatrix_t);
var
  i, j: integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      c[i][j] := a[i][j] + b[i][j];
end;

procedure matrix_sub(const c: Pmatrix_t; const a, b: Pmatrix_t);
var
  i, j: integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      c[i][j] := a[i][j] - b[i][j];
end;

procedure matrix_mul(const c: Pmatrix_t; const a, b: Pmatrix_t);
var
  z: matrix_t;
  i, j: integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      z[j][i] :=
        (a[j][0] * b[0][i]) +
        (a[j][1] * b[1][i]) +
        (a[j][2] * b[2][i]) +
        (a[j][3] * b[3][i]);
  c^ := z;
end;

procedure matrix_scale(const c: Pmatrix_t; const a: Pmatrix_t; const f: float);
var
  i, j: integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      c[i][j] := a[i][j] * f;
end;

procedure matrix_apply(const y: Pvector_t; const x: Pvector_t; const m: Pmatrix_t);
var
  xx, yy, zz, ww: float;
begin
  xx := x.x;
  yy := x.y;
  zz := x.z;
  ww := x.w;
  y.x := xx * m[0][0] + yy * m[1][0] + zz * m[2][0] + ww * m[3][0];
  y.y := xx * m[0][1] + yy * m[1][1] + zz * m[2][1] + ww * m[3][1];
  y.z := xx * m[0][2] + yy * m[1][2] + zz * m[2][2] + ww * m[3][2];
  y.w := xx * m[0][3] + yy * m[1][3] + zz * m[2][3] + ww * m[3][3];
end;

procedure matrix_set_identity(const m: Pmatrix_t);
begin
  m[0][0] := 1.0;
  m[1][1] := 1.0;
  m[2][2] := 1.0;
  m[3][3] := 1.0;
  m[0][1] := 0.0;
  m[0][2] := 0.0;
  m[0][3] := 0.0;
  m[1][0] := 0.0;
  m[1][2] := 0.0;
  m[1][3] := 0.0;
  m[2][0] := 0.0;
  m[2][1] := 0.0;
  m[2][3] := 0.0;
  m[3][0] := 0.0;
  m[3][1] := 0.0;
  m[3][2] := 0.0;
end;

procedure matrix_set_zero(const m: Pmatrix_t);
begin
  m[0][0] := 0.0;
  m[0][1] := 0.0;
  m[0][2] := 0.0;
  m[0][3] := 0.0;
  m[1][0] := 0.0;
  m[1][1] := 0.0;
  m[1][2] := 0.0;
  m[1][3] := 0.0;
  m[2][0] := 0.0;
  m[2][1] := 0.0;
  m[2][2] := 0.0;
  m[2][3] := 0.0;
  m[3][0] := 0.0;
  m[3][1] := 0.0;
  m[3][2] := 0.0;
  m[3][3] := 0.0;
end;

procedure matrix_set_translate(const m: Pmatrix_t; const x, y, z: float);
begin
  matrix_set_identity(m);
  m[3][0] := x;
  m[3][1] := y;
  m[3][2] := z;
end;

procedure matrix_set_scale(const m: Pmatrix_t; const x, y, z: float);
begin
  matrix_set_identity(m);
  m[0][0] := x;
  m[1][1] := y;
  m[2][2] := z;
end;

procedure matrix_set_rotate(const m: Pmatrix_t; x, y, z: float; const theta: float);
var
  qsin, qcos: float;
  vec: vector_t;
  w: float;
begin
  qsin := Sin(theta * 0.5);
  qcos := Cos(theta * 0.5);
  vec.x := x;
  vec.y := y;
  vec.z := z;
  vec.w := 1.0;
  vector_normalize(@vec);
  x := vec.x * qsin;
  y := vec.y * qsin;
  z := vec.z * qsin;
  w := qcos;
  m[0][0] := 1 - 2 * y * y - 2 * z * z;
  m[1][0] := 2 * x * y - 2 * w * z;
  m[2][0] := 2 * x * z + 2 * w * y;
  m[0][1] := 2 * x * y + 2 * w * z;
  m[1][1] := 1 - 2 * x * x - 2 * z * z;
  m[2][1] := 2 * y * z - 2 * w * x;
  m[0][2] := 2 * x * z - 2 * w * y;
  m[1][2] := 2 * y * z + 2 * w * x;
  m[2][2] := 1 - 2 * x * x - 2 * y * y;
  m[0][3] := 0.0;
  m[1][3] := 0.0;
  m[2][3] := 0.0;
  m[3][0] := 0.0;
  m[3][1] := 0.0;
  m[3][2] := 0.0;
  m[3][3] := 1.0;
end;

procedure matrix_set_lookat(m: Pmatrix_t; const eye, at, up: Pvector_t);
var
  xaxis, yaxis, zaxis: vector_t;
begin
  vector_sub(@zaxis, at, eye);
  vector_normalize(@zaxis);
  vector_crossproduct(@xaxis, up, @zaxis);
  vector_normalize(@xaxis);
  vector_crossproduct(@yaxis, @zaxis, @xaxis);

  m[0][0] := xaxis.x;
  m[1][0] := xaxis.y;
  m[2][0] := xaxis.z;
  m[3][0] := -vector_dotproduct(@xaxis, eye);

  m[0][1] := yaxis.x;
  m[1][1] := yaxis.y;
  m[2][1] := yaxis.z;
  m[3][1] := -vector_dotproduct(@yaxis, eye);

  m[0][2] := zaxis.x;
  m[1][2] := zaxis.y;
  m[2][2] := zaxis.z;
  m[3][2] := -vector_dotproduct(@zaxis, eye);

  m[0][3] := 0.0;
  m[1][3] := 0.0;
  m[2][3] := 0.0;
  m[3][3] := 1.0;
end;

procedure matrix_set_perspective(const m: Pmatrix_t; const fovy, aspect, zn, zf: float);
var
  fax: float;
begin
  fax := 1.0 / tan(fovy * 0.5);
  matrix_set_zero(m);
  m[0][0] := fax / aspect;
  m[1][1] := fax;
  m[2][2] := zf / (zf - zn);
  m[3][2] := - zn * zf / (zf - zn);
  m[2][3] := 1.0;
end;

procedure transform_update(const ts: Ptransform_t);
var
  m: matrix_t;
begin
  matrix_mul(@m, @ts.world, @ts.view);
  matrix_mul(@ts.transform, @m, @ts.projection);
end;

procedure transform_init(const ts: Ptransform_t; const width, height: integer);
var
  aspect: float;
begin
  aspect := width / height;
  matrix_set_identity(@ts.world);
  matrix_set_identity(@ts.view);
  matrix_set_perspective(@ts.projection, PI * 0.5, aspect, 1.0, 500.0);
  ts.w := width;
  ts.h := height;
  transform_update(ts);
end;

procedure transform_apply(const ts: Ptransform_t; const y: Pvector_t; const x: Pvector_t);
begin
  matrix_apply(y, x, @ts.transform);
end;

function transform_check_cvv(const v: Pvector_t): integer;
var
  w: float;
begin
  w := v.w;
  Result := 0;
  if v.z < 0.0 then Result := Result or 1;
  if v.z >  w then Result := Result or 2;
  if v.x < -w then Result := Result or 4;
  if v.x >  w then Result := Result or 8;
  if v.y < -w then Result := Result or 16;
  if v.y >  w then Result := Result or 32;
end;

procedure transform_homogenize(const ts: Ptransform_t; const y: Pvector_t; const x: Pvector_t);
var
  rhw: float;
begin
  rhw := 1.0 / x.w;
  y.x := (x.x * rhw + 1.0) * ts.w * 0.5;
  y.y := (1.0 - x.y * rhw) * ts.h * 0.5;
  y.z := x.z * rhw;
  y.w := 1.0;
end;

procedure vertex_rhw_init(v: Pvertex_t);
var
  rhw: float;
begin
  rhw := 1.0 / v.pos.w;
  v.rhw := rhw;
  v.tc.u := v.tc.u * rhw;
  v.tc.v := v.tc.v * rhw;
  v.color.r := v.color.r * rhw;
  v.color.g := v.color.g * rhw;
  v.color.b := v.color.b * rhw;
end;

procedure vertex_interp(const y: Pvertex_t; const x1, x2: Pvertex_t; const t: float);
begin
  vector_interp(@y.pos, @x1.pos, @x2.pos, t);
  y.tc.u := interp(x1.tc.u, x2.tc.u, t);
  y.tc.v := interp(x1.tc.v, x2.tc.v, t);
  y.color.r := interp(x1.color.r, x2.color.r, t);
  y.color.g := interp(x1.color.g, x2.color.g, t);
  y.color.b := interp(x1.color.b, x2.color.b, t);
  y.rhw := interp(x1.rhw, x2.rhw, t);
end;

procedure vertex_division(const y: Pvertex_t; const x1, x2: Pvertex_t; const w: float);
var
  inv: float;
begin
  inv := 1.0 / w;
  y.pos.x := (x2.pos.x - x1.pos.x) * inv;
  y.pos.y := (x2.pos.y - x1.pos.y) * inv;
  y.pos.z := (x2.pos.z - x1.pos.z) * inv;
  y.pos.w := (x2.pos.w - x1.pos.w) * inv;
  y.tc.u := (x2.tc.u - x1.tc.u) * inv;
  y.tc.v := (x2.tc.v - x1.tc.v) * inv;
  y.color.r := (x2.color.r - x1.color.r) * inv;
  y.color.g := (x2.color.g - x1.color.g) * inv;
  y.color.b := (x2.color.b - x1.color.b) * inv;
  y.rhw := (x2.rhw - x1.rhw) * inv;
end;

procedure vertex_add(const y: Pvertex_t; const x: Pvertex_t);
begin
  y.pos.x := y.pos.x + x.pos.x;
  y.pos.y := y.pos.y + x.pos.y;
  y.pos.z := y.pos.z + x.pos.z;
  y.pos.w := y.pos.w + x.pos.w;
  y.rhw := y.rhw + x.rhw;
  y.tc.u := y.tc.u + x.tc.u;
  y.tc.v := y.tc.v + x.tc.v;
  y.color.r := y.color.r + x.color.r;
  y.color.g := y.color.g + x.color.g;
  y.color.b := y.color.b + x.color.b;
end;

function trapezoid_init_triangle(const trap: Ptrapezoid_tArray; p1, p2, p3: Pvertex_t): integer;
var
  p: Pvertex_t;
  k, x: float;
begin
  if p1.pos.y > p2.pos.y then
  begin
    p := p1;
    p1 := p2;
    p2 := p;
  end;
  if p1.pos.y > p3.pos.y then
  begin
    p := p1;
    p1 := p3;
    p3 := p;
  end;
  if p2.pos.y > p3.pos.y then
  begin
    p := p2;
    p2 := p3;
    p3 := p;
  end;
  if (p1.pos.y = p2.pos.y) and (p1.pos.y = p3.pos.y) then
  begin
    Result := 0;
    Exit;
  end;
  if (p1.pos.x = p2.pos.x) and (p1.pos.x = p3.pos.x) then
  begin
    Result := 0;
    Exit;
  end;

  if p1.pos.y = p2.pos.y then // triangle down
  begin
    if p1.pos.x > p2.pos.x then
    begin
      p := p1;
      p1 := p2;
      p2 := p;
    end;
    trap[0].top := p1.pos.y;
    trap[0].bottom := p3.pos.y;
    trap[0].left.v1 := p1^;
    trap[0].left.v2 := p3^;
    trap[0].right.v1 := p2^;
    trap[0].right.v2 := p3^;
    if trap[0].top < trap[0].bottom then
      Result := 1
    else
      Result := 0;
    Exit;
  end;

  if p2.pos.y = p3.pos.y then // triangle up
  begin
    if p2.pos.x > p3.pos.x then
    begin
      p := p2;
      p2 := p3;
      p3 := p;
    end;
    trap[0].top := p1.pos.y;
    trap[0].bottom := p3.pos.y;
    trap[0].left.v1 := p1^;
    trap[0].left.v2 := p2^;
    trap[0].right.v1 := p1^;
    trap[0].right.v2 := p3^;
    if trap[0].top < trap[0].bottom then
      Result := 1
    else
      Result := 0;
    Exit;
  end;

  trap[0].top := p1.pos.y;
  trap[0].bottom := p2.pos.y;
  trap[1].top := p2.pos.y;
  trap[1].bottom := p3.pos.y;

  k := (p3.pos.y - p1.pos.y) / (p2.pos.y - p1.pos.y);
  x := p1.pos.x + (p2.pos.x - p1.pos.x) * k;

  if x <= p3.pos.x then // triangle left
  begin
    trap[0].left.v1 := p1^;
    trap[0].left.v2 := p2^;
    trap[0].right.v1 := p1^;
    trap[0].right.v2 := p3^;
    trap[1].left.v1 := p2^;
    trap[1].left.v2 := p3^;
    trap[1].right.v1 := p1^;
    trap[1].right.v2 := p3^;
  end
  else  // triangle right
  begin
    trap[0].left.v1 := p1^;
    trap[0].left.v2 := p3^;
    trap[0].right.v1 := p1^;
    trap[0].right.v2 := p2^;
    trap[1].left.v1 := p1^;
    trap[1].left.v2 := p3^;
    trap[1].right.v1 := p2^;
    trap[1].right.v2 := p3^;
  end;

  Result := 2;
end;

procedure trapezoid_edge_interp(const trap: Ptrapezoid_t; const y: float);
var
  s1, s2, t1, t2: float;
begin
  s1 := trap.left.v2.pos.y - trap.left.v1.pos.y;
  s2 := trap.right.v2.pos.y - trap.right.v1.pos.y;
  t1 := (y - trap.left.v1.pos.y) / s1;
  t2 := (y - trap.right.v1.pos.y) / s2;
  vertex_interp(@trap.left.v, @trap.left.v1, @trap.left.v2, t1);
  vertex_interp(@trap.right.v, @trap.right.v1, @trap.right.v2, t2);
end;

procedure trapezoid_init_scan_line(const trap: Ptrapezoid_t; const scanline: Pscanline_t;
  const y: integer);
var
  width: float;
begin
  width := trap.right.v.pos.x - trap.left.v.pos.x;
  scanline.x := Trunc(trap.left.v.pos.x + 0.5);
  scanline.w := Trunc(trap.right.v.pos.x + 0.5) - scanline.x;
  scanline.y := y;
  scanline.v := trap.left.v;
  if trap.left.v.pos.x >= trap.right.v.pos.x then
    scanline.w := 0;
  vertex_division(@scanline.step, @trap.left.v, @trap.right.v, width);
end;

procedure device_init(const device: Pdevice_t; const width, height: integer);
var
  j: integer;
begin
  device.bframebuffer := TBitmap.Create;
  device.bframebuffer.PixelFormat := pf32bit;
  device.bframebuffer.Width := width;
  device.bframebuffer.Height := height;

  device.bzbuffer := TBitmap.Create;
  device.bzbuffer.PixelFormat := pf32bit;
  device.bzbuffer.Width := width;
  device.bzbuffer.Height := height;

  device.bztexture := TBitmap.Create;
  device.bztexture.PixelFormat := pf32bit;
  device.bztexture.width := TEXTURESIZE;
  device.bztexture.height := TEXTURESIZE;
  device.tex_width := TEXTURESIZE;
  device.tex_height := TEXTURESIZE;
  device.max_u := TEXTURESIZE - 1.0;
  device.max_v := TEXTURESIZE - 1.0;

  GetMem(device.framebuffer, height * SizeOf(Pointer));
  GetMem(device.zbuffer, height * SizeOf(Pointer));
  GetMem(device.texture, TEXTURESIZE * SizeOf(Pointer));

  for j := 0 to height - 1 do
  begin
    device.framebuffer[j] := PIUINT32Array(device.bframebuffer.scanline[j]);
    device.zbuffer[j] := PfloatArray(device.bzbuffer.scanline[j]);
  end;

  for j := 0 to device.tex_height - 1 do
    device.texture[j] := PIUINT32Array(device.bztexture.scanline[j]);


  device.background := RGB(0, 0, 0);
  device.foreground := RGB(0, 0, 0);
  device.width := width;
  device.height := height;
  transform_init(@device.transform, width, height);
  device.render_state := RENDER_STATE_TEXTURE_SOLID;
  device.texture_state := TEXTURE_STATE_REPEAT;
end;

procedure device_destroy(const device: Pdevice_t);
begin
  FreeMem(device.framebuffer, device.height * SizeOf(Pointer));
  FreeMem(device.zbuffer, device.height * SizeOf(Pointer));
  FreeMem(device.texture, device.tex_height * SizeOf(Pointer));

  device.framebuffer := nil;
  device.zbuffer := nil;
  device.texture := nil;

  FreeAndNil(device.bframebuffer);
  FreeAndNil(device.bzbuffer);
  FreeAndNil(device.bztexture);
end;

procedure device_set_texture(const device: Pdevice_t; const tex: TBitmap);
var
  j: integer;
begin
  tex.PixelFormat := pf32bit;
  device.bztexture.width := tex.Width;
  device.bztexture.height := tex.Height;
  device.bztexture.Canvas.Draw(0, 0, tex);
  device.tex_width := tex.Width;
  device.tex_height := tex.Height;
  device.max_u := tex.Width - 1.0;
  device.max_v := tex.Height - 1.0;

  ReallocMem(device.texture, tex.Height * SizeOf(Pointer));

  for j := 0 to device.tex_height - 1 do
    device.texture[j] := PIUINT32Array(device.bztexture.scanline[j]);
end;

procedure device_clear(const device: Pdevice_t);
var
  x, y: integer;
  idst: PIUINT32Array;
  fdst: PfloatArray;
begin
  for y := 0 to device.height - 1 do
  begin
    idst := device.framebuffer[y];
    for x := 0 to device.width - 1 do
      idst[x] := device.background;
    fdst := device.zbuffer[y];
    for x := 0 to device.width - 1 do
      fdst[x] := 0.0;
  end;
end;

procedure device_pixel(const device: Pdevice_t; const x, y: integer; const color: IUINT32);
begin
  if (IUINT32(x) < IUINT32(device.width)) and (IUINT32(y) < IUINT32(device.height)) then
    device.framebuffer[y][x] := color;
end;

procedure device_draw_line(const device: Pdevice_t; x1, y1, x2, y2: integer;
  const c: IUINT32);
var
  x, y, rem: integer;
  isign, dx, dy: integer;
begin
  if (x1 = x2) and (y1 = y2) then
    device_pixel(device, x1, y1, c)
  else if x1 = x2 then
  begin
    if y1 <= y2 then
      isign := 1
    else
      isign := -1;
    y := y1;
    while y <> y2 do
    begin
      device_pixel(device, x1, y, c);
      y := y + isign;
    end;
    device_pixel(device, x2, y2, c);
  end
  else if y1 = y2 then
  begin
    if x1 <= x2 then
      isign := 1
    else
      isign := -1;
    x := x1;
    while x <> x2 do
    begin
      device_pixel(device, x, y1, c);
      x := x + isign;
    end;
    device_pixel(device, x2, y2, c);
  end
  else
  begin
    rem := 0;
    if x1 < x2 then
      dx := x2 - x1
    else
      dx := x1 - x2;
    if y1 < y2 then
      dy := y2 - y1
    else
      dy := y1 - y2;
    if dx >= dy then
    begin
      if x2 < x1 then
      begin
        x := x1;
        x1 := x2;
        x2 := x;
        y := y1;
        y1 := y2;
        y2 := y;
      end;
      x := x1;
      y := y1;
      while x <= x2 do
      begin
        device_pixel(device, x, y, c);
        rem := rem + dy;
        if rem >= dx then
        begin
          rem := rem - dx;
          if y2 >= y1 then
            inc(y)
          else
            dec(y);
          device_pixel(device, x, y, c);
        end;
        inc(x);
      end;
      device_pixel(device, x2, y2, c);
    end
    else
    begin
      if y2 < y1 then
      begin
        x := x1;
        y := y1;
        x1 := x2;
        y1 := y2;
        x2 := x;
        y2 := y;
      end;
      x := x1;
      y := y1;
      while y <= y2 do
      begin
        device_pixel(device, x, y, c);
        rem := rem + dx;
        if rem >= dy then
        begin
          rem := rem - dy;
          if x2 >= x1 then
            inc(x)
          else
            dec(x);
          device_pixel(device, x, y, c);
        end;
        inc(y);
      end;
      device_pixel(device, x2, y2, c);
    end;
  end;
end;

function device_texture_read(const device: Pdevice_t; u, v: float): IUINT32;
var
  x, y: integer;
begin
  u := u * device.max_u;
  v := v * device.max_v;
  x := Trunc(u + 0.5);
  y := Trunc(v + 0.5);
  if device.texture_state = TEXTURE_STATE_REPEAT then
  begin
    if x < 0 then
      x := (-x) mod device.tex_width
    else
      x := x mod device.tex_width;
    if y < 0 then
      y := (-y) mod device.tex_height
    else
      y := y mod device.tex_height;
  end
  else
  begin
    x := CMID(x, 0, device.tex_width - 1);
    y := CMID(y, 0, device.tex_height - 1);
  end;
  Result := device.texture[y][x];
end;


procedure device_draw_scanline(const device: Pdevice_t; const scanline: Pscanline_t);
var
  framebuffer: PIUINT32Array;
  zbuffer: PfloatArray;
  x, w, width, render_state: integer;
  invrhw, rhw: float;
  r, g, b: float;
  RR, GG, BB: integer;
  u, v: float;
  cc: IUINT32;
begin
  framebuffer := device.framebuffer[scanline.y];
  zbuffer := device.zbuffer[scanline.y];
  x := scanline.x;
  w := scanline.w;
  width := device.width;
  render_state := device.render_state;
  while w > 0 do
  begin
    if (x >= 0) and (x < width) then
    begin
      rhw := scanline.v.rhw;
      if rhw >= zbuffer[x] then
      begin
        invrhw := 1.0 / rhw;
        if render_state and RENDER_STATE_COLOR <> 0 then
        begin
          r := scanline.v.color.r * invrhw;
          g := scanline.v.color.g * invrhw;
          b := scanline.v.color.b * invrhw;
          RR := Trunc(r * 255.0);
          GG := Trunc(g * 255.0);
          BB := Trunc(b * 255.0);
          RR := CMID(RR, 0, 255);
          GG := CMID(GG, 0, 255);
          BB := CMID(BB, 0, 255);
          framebuffer[x] := (RR shl 16) or (GG shl 8) or (BB);
          zbuffer[x] := rhw;
        end;
        if render_state and RENDER_STATE_TEXTURE_SOLID <> 0 then
        begin
          u := scanline.v.tc.u * invrhw;
          v := scanline.v.tc.v * invrhw;
          framebuffer[x] := device_texture_read(device, u, v);
          zbuffer[x] := rhw;
        end
        else if render_state and RENDER_STATE_TEXTURE_ALPHAZERO <> 0 then
        begin
          u := scanline.v.tc.u * invrhw;
          v := scanline.v.tc.v * invrhw;
          cc := device_texture_read(device, u, v);
          if cc <> 0 then
          begin
            framebuffer[x] := cc;
            zbuffer[x] := rhw;
          end;
        end
        else if render_state and RENDER_STATE_WIREFRAME <> 0 then
          zbuffer[x] := rhw;
      end;
    end;
    vertex_add(@scanline.v, @scanline.step);
    if x >= width then
      Break;
    inc(x);
    dec(w);
  end;
end;

procedure device_render_trap(const device: Pdevice_t; const trap: Ptrapezoid_t);
var
  scanline: scanline_t;
  j, top, bottom: integer;
begin
  top := Trunc(trap.top + 0.5);
  bottom := Trunc(trap.bottom + 0.5);
  for j := top to bottom - 1 do
  begin
    if (j >= 0) and (j < device.height) then
    begin
      trapezoid_edge_interp(trap, j + 0.5);
      trapezoid_init_scan_line(trap, @scanline, j);
      device_draw_scanline(device, @scanline);
    end;
    if j >= device.height then
      break;
  end;
end;

// ?? render_state ???????
procedure device_draw_primitive(const device: Pdevice_t; const v1, v2, v3: Pvertex_t);
var
  p1, p2, p3, c1, c2, c3: vector_t;
  t1, t2, t3: vertex_t;
  render_state: integer;
  n: integer;
  traps: array[0..1] of trapezoid_t;
begin
  render_state := device.render_state;

  transform_apply(@device.transform, @c1, @v1.pos);
  transform_apply(@device.transform, @c2, @v2.pos);
  transform_apply(@device.transform, @c3, @v3.pos);

  if transform_check_cvv(@c1) <> 0 then Exit;
  if transform_check_cvv(@c2) <> 0 then Exit;
  if transform_check_cvv(@c3) <> 0 then Exit;

  transform_homogenize(@device.transform, @p1, @c1);
  transform_homogenize(@device.transform, @p2, @c2);
  transform_homogenize(@device.transform, @p3, @c3);

  if render_state and (RENDER_STATE_TEXTURE_SOLID or RENDER_STATE_TEXTURE_ALPHAZERO or RENDER_STATE_COLOR) <> 0 then
  begin
    t1 := v1^;
    t2 := v2^;
    t3 := v3^;

    t1.pos := p1;
    t2.pos := p2;
    t3.pos := p3;
    t1.pos.w := c1.w;
    t2.pos.w := c2.w;
    t3.pos.w := c3.w;

    vertex_rhw_init(@t1);
    vertex_rhw_init(@t2);
    vertex_rhw_init(@t3);

    n := trapezoid_init_triangle(@traps, @t1, @t2, @t3);

    if n >= 1 then
      device_render_trap(device, @traps[0]);
    if n >= 2 then
      device_render_trap(device, @traps[1]);
  end;

  if render_state and RENDER_STATE_WIREFRAME <> 0 then
  begin
    device_draw_line(device, Trunc(p1.x), Trunc(p1.y), Trunc(p2.x), Trunc(p2.y), device.foreground);
    device_draw_line(device, Trunc(p1.x), Trunc(p1.y), Trunc(p3.x), Trunc(p3.y), device.foreground);
    device_draw_line(device, Trunc(p3.x), Trunc(p3.y), Trunc(p2.x), Trunc(p2.y), device.foreground);
  end;
end;

procedure camera_at_zero(const device: Pdevice_t; const x, y, z: float);
var
  eye, up, at: vector_t;
begin
  eye.x := x;
  eye.y := y;
  eye.z := z;
  eye.w := 1.0;
  at.x := 0.0;
  at.y := 0.0;
  at.z := 0.0;
  at.w := 1.0;
  up.x := 0.0;
  up.y := 0.0;
  up.z := 1.0;
  up.w := 1.0;
  matrix_set_lookat(@device.transform.view, @eye, @at, @up);
  transform_update(@device.transform);
end;

end.

