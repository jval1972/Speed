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
//    External I3D Model support
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit mdl_i3d;

interface

uses
  d_delphi,
  mdl_base,
  i3d_model;

type
  TI3DModel = class(TBaseModel)
  protected
    fmdl: TI3DModelLoader;
    fname: string;
    fxoffset, fyoffset, fzoffset: float;
    fxscale, fyscale, fzscale: float;
    procedure LoadData;
  public
    constructor Create(const name: string;
      const xoffset, yoffset, zoffset: float;
      const xscale, yscale, zscale: float;
      const additionalframes: TDStringList); override;
    destructor Destroy; override;
    procedure Draw(const frm1, frm2: integer; const offset: float); override;
    procedure DrawSimple(const frm: integer); override;
  end;

implementation

uses
  dglOpenGL,
  doomdef,
  gl_defs,
  i_system,
  w_folders,
  w_pak;

constructor TI3DModel.Create(const name: string;
  const xoffset, yoffset, zoffset: float;
  const xscale, yscale, zscale: float;
  const additionalframes: TDStringList);
begin
  Inherited;
  printf('  Found external model %s'#13#10, [name]);
  fname := name;
  fxoffset := xoffset / MAP_COEFF;
  fyoffset := yoffset / MAP_COEFF;
  fzoffset := zoffset / MAP_COEFF;
  fxscale := xscale / MAP_COEFF;
  fyscale := yscale / MAP_COEFF;
  fzscale := zscale / MAP_COEFF;

  fmdl := TI3DModelLoader.Create;

  LoadData;
end;

procedure TI3DModel.LoadData;
var
  strm: TPakStream;
  ext: string;
begin
  strm := TPakStream.Create(fname, pm_prefered, gamedirectories);
  if strm.IOResult <> 0 then
  begin
    strm.Free;
    strm := TPakStream.Create(fname, pm_short, '', FOLDER_MODELS);
  end;
  if strm.IOResult <> 0 then
    I_Error('TI3DModel.LoadFrom(): Can not find model %s!', [fname]);

  fmdl.LoadFromStream(strm);
  strm.Free;

  if Length(fname) > 4 then
  begin
    ext := fname;
    ext[Length(ext) - 2] := 't';
    ext[Length(ext) - 1] := 'x';
    ext[Length(ext) - 0] := 't';

    strm := TPakStream.Create(ext, pm_prefered, gamedirectories);
    if strm.IOResult <> 0 then
    begin
      strm.Free;
      strm := TPakStream.Create(ext, pm_short, '', FOLDER_MODELS);
    end;
    if strm.IOResult = 0 then
      fmdl.LoadCorrectionsFromStream(strm);

    strm.Free;
  end;
end;

destructor TI3DModel.Destroy;
begin
  fmdl.Free;
  Inherited;
end;

procedure TI3DModel.Draw(const frm1, frm2: integer; const offset: float);
begin
  fmdl.RenderGL(fxscale, fyscale, fzscale, fxoffset, fyoffset, fzoffset);
end;

procedure TI3DModel.DrawSimple(const frm: integer);
begin
  fmdl.RenderGL(fxscale, fyscale, fzscale, fxoffset, fyoffset, fzoffset);
end;

end.
