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
//    Extra textures for I3D Models
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit i3d_textures;

interface

uses
  dglOpenGL;

procedure gld_InitI3DTextures;

procedure gld_ShutDownI3DTextures;

function gld_RegisterI3DTexture(const tname: string): GLUint;

implementation

uses
  d_delphi,
  gl_tex;

type
  TGLUintClass = class
    uint: GLUint;
    constructor Create(const auint: GLUint); virtual;
    destructor Destroy; override;
  end;

constructor TGLUintClass.Create(const auint: GLUint);
begin
  Inherited Create;
  uint := auint;
end;

destructor TGLUintClass.Destroy;
begin
  glDeleteTextures(1, @uint);
  Inherited
end;

var
  i3dtextures: TDStringList;

procedure gld_InitI3DTextures;
begin
  i3dtextures := TDStringList.Create;
end;

procedure gld_ShutDownI3DTextures;
var
  i: integer;
begin
  for i := 0 to i3dtextures.Count - 1 do
    i3dtextures.Objects[i].Free;

  i3dtextures.Free;
end;

function gld_RegisterI3DTexture(const tname: string): GLUint;
var
  idx: integer;
begin
  idx := i3dtextures.IndexOf(tname);
  if idx >= 0 then
  begin
    Result := (i3dtextures.Objects[idx] as TGLUintClass).uint;
    Exit;
  end;

  Result := gld_LoadExternalTexture(tname, false, GL_REPEAT);
  i3dtextures.AddObject(tname, TGLUintClass.Create(Result));
end;

end.

