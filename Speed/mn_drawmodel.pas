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
//  Draw models to the menu screen
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit mn_drawmodel;

interface

uses
  d_delphi;

procedure M_DrawCarModel(const x, y: integer; const w, h: integer; const carid: integer;
  const fviewdist: float; const ftheta, ftheta2: float);

implementation

uses
  Graphics,
  speed_cars,
  gl_models,
  mdl_i3d,
  r_soft3d,
  i_system,
  v_data,
  v_video;

procedure M_DrawCarModel(const x, y: integer; const w, h: integer; const carid: integer;
  const fviewdist: float; const ftheta, ftheta2: float);
var
  cinfo: Pcarinfo_t;
  i, j, idx: integer;
  modelinf: Pmodelmanageritem_t;
  i3d: TI3DModel;
  device: device_t;
  c, m, m2: matrix_t;
  ln: PLongWordArray;
  pb: PByteArray;
begin
  cinfo := @carinfo[carid];

  idx := -1;
  for i := 0 to modelmanager.size - 1 do
    if cinfo.model3d = modelmanager.items[i].name then
    begin
      idx := i;
      Break;
    end;

  if idx < 0 then
  begin
    I_Warning('M_DrawCarModel(): Can not find model %s'#13#10, [cinfo.model3d]);
    Exit; // Not found !
  end;

  modelinf := @modelmanager.items[idx];
  if modelinf.model = nil then
  begin
    modelinf.model :=
      TModel.Create(modelinf.name, modelinf.proc,
        modelinf.xoffset, modelinf.yoffset, modelinf.zoffset,
        modelinf.xscale, modelinf.yscale, modelinf.zscale,
        modelinf.framemerge
      );
    if modelinf.model = nil then
    begin
      I_Warning('M_DrawCarModel(): Can not load model %s'#13#10, [modelinf.name]);
      Exit;
    end;
  end;

  if not (modelinf.model.model is TI3DModel) then
  begin
    I_Warning('M_DrawCarModel(): Can not render %s, only I3D models are supported'#13#10, [modelinf.name]);
    Exit;
  end;

  i3d := modelinf.model.model as TI3DModel;

  device_init(@device, w, h);

  device_clear(@device);
  camera_at_zero(@device, fviewdist, 0.5, 0);
  matrix_set_rotate(@m, 0.0, 0.0, 1.0, ftheta);
  matrix_set_rotate(@m2, 0.0, 1.0, 0.0, ftheta2);
  matrix_mul(@c, @m, @m2);
  device.transform.world := c;
  transform_update(@device.transform);
  device.render_state := RENDER_STATE_TEXTURE_SOLID;

  i3d.DrawCarSoft(cinfo, @device);

  device.bframebuffer.PixelFormat := pf32bit;
  for j := 0 to device.bframebuffer.Height - 1 do
  begin
    ln := device.bframebuffer.ScanLine[j];
    pb := @screens[SCN_TMP][(y + j) * 320 + x];
    for i := 0 to device.bframebuffer.Width - 1 do
      if ln[i] <> 0 then
        pb[i] := V_FindAproxColorIndex(@videopal, ln[i], 16, 239);
  end;

  device_destroy(@device);

end;

end.
