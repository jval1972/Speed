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
//    I3D Models
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit i3d_model;

interface

uses
  d_delphi,
//  SysUtils,
//  Classes,
  i3d_structs;

type
  TI3dModelCorrection = record
    face: integer;
    vertex: integer;
    visible: boolean;
    x, y, z: integer;
    tx, ty: integer;
    color: byte;
  end;
  PI3dModelCorrection = ^TI3dModelCorrection;
  TI3dModelCorrectionArray = array[0..$FFF] of TI3dModelCorrection;
  PI3dModelCorrectionArray = ^TI3dModelCorrectionArray;

type
  TI3DModelLoader = class(TObject)
  private
    obj: O3DM_TObject_p;
    objfaces: PO3DM_TFaceArray;
    objsize: integer;
    textures: array[0..$7F] of LongWord;  // texid is shortint (-128..127)
    numtextures: integer;
    headers: PO3DM_TFaceHeaderArray;
    materials: PO3DM_TMaterialArray;
    facevertexes: PO3DM_TFaceVertexArray;
    numfacevertexes: integer;
    vertexes: PO3DM_TVertexArray;
    numvertexes: integer;
    fbitmaps: TDStringList;
    fselected: integer;
    corrections: PI3dModelCorrectionArray;
    numcorrections: integer;
  protected
    function GetNumFaces: integer; virtual;
    function GetFace(Index: Integer): O3DM_TFace_p; virtual;
    procedure ApplyCorrection(const cor: PI3dModelCorrection); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function LoadFromStream(const strm: TDStream): boolean;
    function LoadFromFile(const fname: string): boolean;
    procedure Clear;
    function CreateTexture(const m: O3DM_TMaterial_p): integer;
    function RenderGL(const scalex, scaley, scalez: single;
      const offsetx, offsety, offsetz: single): integer;
    function AddCorrection(const face: integer; const vertex: integer; const visible: boolean;
      const x, y, z: integer; const du, dv: single; const c: LongWord): boolean;
    procedure SaveCorrectionsToStream(const strm: TDStream);
    procedure SaveCorrectionsToFile(const fname: string);
    procedure LoadCorrectionsFromStream(const strm: TDStream);
    procedure LoadCorrectionsFromFile(const fname: string);
    procedure UVtoGL(const tx, tv: integer; var du, dv: single);
    procedure GLtoUV(const du, dv: single; var tx, tv: integer);
    property faces[Index: integer]: O3DM_TFace_p read GetFace;
    property numfaces: integer read GetNumFaces;
    property Bitmaps: TDStringList read fbitmaps;
    property selected: integer read fselected write fselected;
  end;

implementation

uses
  dglOpenGL,
  gl_tex,
  Graphics,
  i3d_palette,
  sc_engine;

constructor TI3DModelLoader.Create;
begin
  Inherited Create;
  obj := nil;
  objsize := 0;
  numtextures := 0;
  fselected := -1;
  fbitmaps := TDStringList.Create;
  corrections := nil;
  numcorrections := 0;
end;

destructor TI3DModelLoader.Destroy;
begin
  Clear;
  fbitmaps.Free;
  Inherited Destroy;
end;

function TI3DModelLoader.GetNumFaces: integer;
begin
  if obj = nil then
    Result := 0
  else
    Result := obj.nFaces;
end;

function TI3DModelLoader.GetFace(Index: Integer): O3DM_TFace_p;
begin
  if obj = nil then
    Result := nil
  else if (Index >= 0) and (Index < obj.nFaces) then
    Result := @objfaces[Index]
  else
    Result := nil;
end;

function TI3DModelLoader.LoadFromStream(const strm: TDStream): boolean;
var
  magic: LongWord;
  base: LongWord;
  i, j, l: integer;
  facecachepos: integer;

  function _OF(const p: pointer): pointer;
  begin
    Result := pointer(LongWord(p) + base);
  end;

  function _CacheRead(size: integer): pointer;
  begin
    result := @obj.facecache[facecachepos];
    facecachepos := facecachepos + size;
  end;

begin
  Clear;
  strm.Read(magic, SizeOf(LongWord));
  if magic <> ID3_MAGIC then
  begin
    Result := False;
    Exit;
  end;

  strm.Read(objsize, SizeOf(integer));
  GetMem(obj, objsize);
  strm.Read(obj^, objsize);
  base := LongWord(obj);

  obj.verts := _OF(obj.verts);
  obj.normals := _OF(obj.normals);
  obj.facecache := _OF(obj.facecache);
  obj.materials := _OF(obj.materials);

  GetMem(objfaces, obj.nFaces * SizeOf(O3DM_TFace));

  GetMem(headers, obj.nFaces * SizeOf(O3DM_TFaceHeader));
  GetMem(materials, obj.nFaces * SizeOf(O3DM_TMaterial));
  numfacevertexes := 0;
  numvertexes := 0;
  facecachepos := 0;
  for i := 0 to obj.nFaces - 1 do
  begin
    objfaces[i].h := _CacheRead(SizeOf(O3DM_TFaceHeader));
    headers[i] := objfaces[i].h^;
    objfaces[i].h := @headers[i];
    numfacevertexes := numfacevertexes + headers[i].nVerts;
    numvertexes := numvertexes + headers[i].nVerts;
    objfaces[i].verts := _CacheRead(objfaces[i].h.nVerts * SizeOf(O3DM_TFaceVertex));
    for j := 0 to objfaces[i].h.nVerts - 1 do
    begin
      objfaces[i].verts[j].vert := _OF(objfaces[i].verts[j].vert);
      if objfaces[i].verts[j].normal <> nil then
        objfaces[i].verts[j].normal := _OF(objfaces[i].verts[j].normal);
    end;
    if objfaces[i].h.material <> nil then
      objfaces[i].h.material := _OF(objfaces[i].h.material);
    objfaces[i].h.visible := True;
  end;

  for i := 0 to obj.nMaterials - 1 do
    if obj.materials[i].texture <> nil then
    begin
      if obj.materials[i].flags and O3DMF_256 <> 0 then
        l := 256 * 64
      else
        l := 64 * 64;
      GetMem(obj.materials[i].texture, l);
      if obj.materials[i].texture <> nil then
        strm.read(obj.materials[i].texture^, l)
      else
        strm.Seek(strm.Position + 1, sFromBeginning);
      CreateTexture(@obj.materials[i]);
    end
    else
      obj.materials[i].texid := -1;

  GetMem(facevertexes, numfacevertexes * SizeOf(O3DM_TFaceVertex));
  l := 0;
  for i := 0 to obj.nFaces - 1 do
  begin
    for j := 0 to objfaces[i].h.nVerts - 1 do
    begin
      facevertexes[l] := objfaces[i].verts[j];
      inc(l);
    end;
    objfaces[i].verts := @facevertexes[l - objfaces[i].h.nVerts];
  end;

  GetMem(vertexes, numvertexes * SizeOf(O3DM_TVertex));
  l := 0;
  for i := 0 to obj.nFaces - 1 do
    for j := 0 to objfaces[i].h.nVerts - 1 do
    begin
      vertexes[l] := objfaces[i].verts[j].vert^;
      objfaces[i].verts[j].vert := @vertexes[l];
      inc(l);
    end;

  for i := 0 to obj.nFaces - 1 do
  begin
    materials[i] := objfaces[i].h.material^;
    objfaces[i].h.material := @materials[i];
  end;

  Result := True;
end;

function TI3DModelLoader.CreateTexture(const m: O3DM_TMaterial_p): integer;
type
  TLongWordArrayBuffer = array[0..$3FFF] of LongWord;
  PLongWordArrayBuffer = ^TLongWordArrayBuffer;
var
  buffer: PLongWordArrayBuffer;
  i: integer;
  dest: PLongWord;
  TEXDIMX, TEXDIMY: integer;
  gltex: LongWord;
  bm: TBitmap;
begin
  if m.flags and O3DMF_256 <> 0 then
  begin
    TEXDIMX := 256;
    TEXDIMY := 64;
  end
  else
  begin
    TEXDIMX := 64;
    TEXDIMY := 64;
  end;

  bm := TBitmap.create;
  bm.Width := TEXDIMX;
  bm.height := TEXDIMY;

  GetMem(buffer, TEXDIMX * TEXDIMY * SizeOf(LongWord));
  dest := @buffer[0];
  for i := 0 to TEXDIMX * TEXDIMY - 1 do
  begin
    dest^ := I3DPalColorL(m.texture[i]);
    bm.Canvas.Pixels[i mod TEXDIMX, i div TEXDIMX] := dest^;
    inc(dest);
  end;

  fbitmaps.AddObject(m.texname, bm);

  glGenTextures(1, @gltex);
  glBindTexture(GL_TEXTURE_2D, gltex);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
               TEXDIMX, TEXDIMY,
               0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  FreeMem(buffer, TEXDIMX * TEXDIMY * SizeOf(LongWord));

  Result := numtextures;
  m.texid := Result;
  textures[numtextures] := gltex;
  inc(numtextures);
end;

function TI3DModelLoader.LoadFromFile(const fname: string): boolean;
var
  fs: TFile;
begin
  fs := TFile.Create(fname, fOpenReadOnly);
  try
    result := LoadFromStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TI3DModelLoader.Clear;
var
  i, l: integer;
begin
  if obj <> nil then
  begin
    FreeMem(headers, obj.nFaces * SizeOf(O3DM_TFaceHeader));
    FreeMem(materials, obj.nFaces * SizeOf(O3DM_TMaterial));
    FreeMem(facevertexes, numfacevertexes * SizeOf(O3DM_TFaceVertex));
    FreeMem(vertexes, numvertexes * SizeOf(O3DM_TVertex));
    FreeMem(objfaces, obj.nFaces * SizeOf(O3DM_TFace));
    for i := 0 to obj.nMaterials - 1 do
      if obj.materials[i].texture <> nil then
      begin
        if obj.materials[i].flags and O3DMF_256 <> 0 then
          l := 256 * 64
        else
          l := 64 * 64;
        FreeMem(obj.materials[i].texture, l);
      end;
    FreeMem(obj, objsize);
    obj := nil;
    objsize := 0;
    for i := 0 to numtextures - 1 do
      glDeleteTextures(1, @textures[i]);
    numtextures := 0;
  end;
  for i := 0 to fbitmaps.Count - 1 do
    fbitmaps.Objects[i].Free;
  fbitmaps.Clear;
  fselected := -1;
  if numcorrections <> 0 then
  begin
    FreeMem(corrections, numcorrections * SizeOf(TI3dModelCorrection));
    corrections := nil;
    numcorrections := 0;
  end;
end;

procedure TI3DModelLoader.ApplyCorrection(const cor: PI3dModelCorrection);
var
  face: O3DM_TFace_p;
begin
  if obj = nil then
    Exit;
    
  if not IsIntegerInRange(cor.face, 0, obj.nFaces - 1) then
    Exit;

  face := @objfaces[cor.face];
  if not IsIntegerInRange(cor.vertex, 0, face.h.nVerts - 1) then
    Exit;

  face.h.visible := cor.visible;
  face.verts[cor.vertex].vert.x := cor.x;
  face.verts[cor.vertex].vert.y := cor.y;
  face.verts[cor.vertex].vert.z := cor.z;
  face.verts[cor.vertex].tx := cor.tx;
  face.verts[cor.vertex].ty := cor.ty;
  if face.h.material <> nil then
    face.h.material.color := cor.color;
end;

function TI3DModelLoader.AddCorrection(const face: integer; const vertex: integer; const visible: boolean;
  const x, y, z: integer; const du, dv: single; const c: LongWord): boolean;
var
  i, idx: integer;
  cor: PI3dModelCorrection;
  tx, ty: integer;
begin
  Result := False;

  if not IsIntegerInRange(face, 0, obj.nFaces - 1) then
    Exit;

  if not IsIntegerInRange(vertex, 0, objfaces[face].h.nVerts - 1) then
    Exit;

  idx := -1;
  for i := 0 to numcorrections - 1 do
    if (corrections[i].face = face) and (corrections[i].vertex = vertex) then
    begin
      idx := i;
      Break;
    end;

  if idx < 0 then
  begin
    ReAllocMem(corrections, (numcorrections + 1) * SizeOf(TI3dModelCorrection));
    idx := numcorrections;
    inc(numcorrections);
  end;

  cor := @corrections[idx];
  cor.face := face;
  cor.vertex := vertex;
  for i := 0 to numcorrections - 1 do
    if corrections[i].face = face then
    begin
      corrections[i].visible := visible;
      ApplyCorrection(@corrections[i]);
    end;
  cor.x := x;
  cor.y := y;
  cor.z := z;
  GLtoUV(du, dv, tx, ty);
  cor.tx := tx;
  cor.ty := ty;
  cor.color := I3DPalColorIndex(c);
  ApplyCorrection(cor);

  Result := True;
end;

procedure TI3DModelLoader.SaveCorrectionsToStream(const strm: TDStream);
var
  i: integer;
  s: TDStringList;
  cor: PI3dModelCorrection;
  vis: integer;
  stmp: string;
begin
  if obj = nil then
    Exit;
  s := TDStringList.Create;
  try
    for i := 0 to numcorrections - 1 do
    begin
      cor := @corrections[i];
      if IsIntegerInRange(cor.face, 0, obj.nFaces - 1) then
        if IsIntegerInRange(cor.vertex, 0, objfaces[cor.face].h.nVerts - 1) then
        begin
          if cor.visible then
            vis := 1
          else
            vis := 0;
          sprintf(stmp, 'face %d vertex %d visible %d x %d y %d z %d tx %d ty %d color %d',
              [cor.face, cor.vertex, vis, cor.x, cor.y, cor.z, cor.tx, cor.ty, cor.color]);
          s.Add(stmp);
        end;
    end;
    s.SaveToStream(strm);
  finally
    s.Free;
  end;
end;

procedure TI3DModelLoader.SaveCorrectionsToFile(const fname: string);
var
  fs: TFile;
begin
  fs := TFile.Create(fname, fCreate);
  try
    SaveCorrectionsToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TI3DModelLoader.LoadCorrectionsFromStream(const strm: TDStream);
var
  sc: TScriptEngine;
  s: TDStringList;
  cor: PI3dModelCorrection;
begin
  ReallocMem(corrections, 0);
  numcorrections := 0;
  s := TDStringList.Create;
  try
    s.LoadFromStream(strm);
    sc := TScriptEngine.Create(s.Text);
    while sc.GetString do
    begin
      if sc.MatchString('face') then
      begin
        ReallocMem(corrections, (numcorrections + 1) * SizeOf(TI3dModelCorrection));
        cor := @corrections[numcorrections];
        inc(numcorrections);

        sc.MustGetInteger;
        cor.face := sc._Integer;

        sc.MustGetStringName('vertex');
        sc.MustGetInteger;
        cor.vertex := sc._Integer;

        sc.MustGetStringName('visible');
        sc.MustGetInteger;
        if sc._Integer = 0 then
          cor.visible := False
        else
          cor.visible := True;

        sc.MustGetStringName('x');
        sc.MustGetInteger;
        cor.x := sc._Integer;

        sc.MustGetStringName('y');
        sc.MustGetInteger;
        cor.y := sc._Integer;

        sc.MustGetStringName('z');
        sc.MustGetInteger;
        cor.z := sc._Integer;

        sc.MustGetStringName('tx');
        sc.MustGetInteger;
        cor.tx := sc._Integer;

        sc.MustGetStringName('ty');
        sc.MustGetInteger;
        cor.ty := sc._Integer;

        sc.MustGetStringName('color');
        sc.MustGetInteger;
        cor.color := sc._Integer;

        ApplyCorrection(cor);
      end;
    end;
    sc.Free;
  finally
    s.Free;
  end;
end;

procedure TI3DModelLoader.LoadCorrectionsFromFile(const fname: string);
var
  fs: TFile;
begin
  fs := TFile.Create(fname, fOpenReadOnly);
  try
    LoadCorrectionsFromStream(fs);
  finally
    fs.Free;
  end;
end;

const
  UVGLCONST = 262144 * 64;

procedure TI3DModelLoader.UVtoGL(const tx, tv: integer; var du, dv: single);
begin
  du := -tx / UVGLCONST;
  dv := tv / UVGLCONST;
end;

procedure TI3DModelLoader.GLtoUV(const du, dv: single; var tx, tv: integer);
begin
  tx := -Round(du * UVGLCONST);
  tv := Round(dv * UVGLCONST);
end;

function TI3DModelLoader.RenderGL(const scalex, scaley, scalez: single;
  const offsetx, offsety, offsetz: single): integer;
var
  i, j: integer;
  lasttex, newtex: LongWord;

  procedure _glcolor(const m: O3DM_TMaterial_p);
  var
    cl: i3dcolor3f_t;
  begin
    cl := I3DPalColor3f(m.color);
    if m.flags and O3DMF_TRANS <> 0 then
      glColor4f(cl.r, cl.g, cl.b, 0.5)
    else
      glColor4f(cl.r, cl.g, cl.b, 1.0);
  end;

  procedure _gltexcoord(const tx, ty: integer);
  var
    ax, ay: single;
  begin
    UVtoGL(tx, ty, ax, ay);
    glTexCoord2f(ax, ay);
  end;

  procedure _glvertex(const x, y, z: integer);
  begin
    glVertex3f(x * scalex + offsetx, y * scaley + offsety, z * scalez + offsetz);
  end;

begin
  Result := 0;

  if obj = nil then
    Exit;

  lasttex := $FFFFFFFF;

  for i := 0 to obj.nFaces - 1 do
  begin
    if not objfaces[i].h.visible then
      Continue;
    if fselected = i then
      Continue;
    if objfaces[i].h.material <> nil then
    begin
      newtex := 0;
      if objfaces[i].h.material.texid >= 0 then
        newtex := textures[objfaces[i].h.material.texid];
      if newtex > 0 then
      begin
        glEnable(GL_TEXTURE_2D);
        if newtex <> lasttex then
        begin
          glColor4f(1.0, 1.0, 1.0, 1.0);
          glBindTexture(GL_TEXTURE_2D, newtex);
          lasttex := newtex;
        end;
      end
      else
      begin
        glDisable(GL_TEXTURE_2D);
        lasttex := 0;
        _glcolor(objfaces[i].h.material);
      end;
    end
    else
    begin
      glDisable(GL_TEXTURE_2D);
      lasttex := 0;
      glColor4f(1.0, 1.0, 1.0, 1.0);
    end;

    glBegin(GL_TRIANGLE_FAN);

    for j := 0 to objfaces[i].h.nVerts - 1 do
    begin
      _gltexcoord(objfaces[i].verts[j].tx, objfaces[i].verts[j].ty);
      _glvertex(objfaces[i].verts[j].vert.x, objfaces[i].verts[j].vert.y, objfaces[i].verts[j].vert.z);
    end;

    glEnd;

    Result := Result + objfaces[i].h.nVerts - 2;
  end;
  glEnable(GL_TEXTURE_2D);
  gld_ResetLastTexture;
end;

end.
