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
  dglOpenGL,
  r_soft3d,
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
    textures: array[0..$7F] of TGluint; // texid is shortint (-128..127)
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
    defPos: R3D_TPosVector;
    defRot: R3D_TAngles;
    tireperimeters: array[0..3] of integer;
    tirecenters: array[0..3] of vec3i_t;
  protected
    function GetNumFaces: integer; virtual;
    function GetFace(Index: Integer): O3DM_TFace_p; virtual;
    procedure ApplyCorrection(const cor: PI3dModelCorrection); virtual;
    function HasTires: boolean; virtual;
    procedure FindTireCenters; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function LoadFromStream(const strm: TDStream): boolean;
    function LoadFromFile(const fname: string): boolean;
    procedure Clear;
    function CreateTexture(const m: O3DM_TMaterial_p): integer;
    function RenderGL(const scalex, scaley, scalez: single;
      const offsetx, offsety, offsetz: single): integer;
    function RenderGLEx(const scalex, scaley, scalez: single;
      const offsetx, offsety, offsetz: single;
      const oldtex1, tex1, oldtex2, tex2: string): integer;
    function RenderSoft(const device: Pdevice_t; const scalex, scaley, scalez: single;
      const offsetx, offsety, offsetz: single): integer;
    function RenderSoftEx(const device: Pdevice_t; const scalex, scaley, scalez: single;
      const offsetx, offsety, offsetz: single;
      const oldtex1, tex1, oldtex2, tex2: string): integer;
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
  t_main,
  gl_defs,
  gl_tex,
  Graphics,
  i3d_palette,
  i3d_textures,
  sc_engine;

constructor TI3DModelLoader.Create;
begin
  Inherited Create;

  tireperimeters[0] := 0;
  tireperimeters[1] := 0;
  tireperimeters[2] := 0;
  tireperimeters[3] := 0;

  tirecenters[0].x := 0;
  tirecenters[0].y := 0;
  tirecenters[0].z := 0;
  tirecenters[1].x := 0;
  tirecenters[1].y := 0;
  tirecenters[1].z := 0;
  tirecenters[2].x := 0;
  tirecenters[2].y := 0;
  tirecenters[2].z := 0;
  tirecenters[3].x := 0;
  tirecenters[3].y := 0;
  tirecenters[3].z := 0;

  defPos[0] := 0;
  defPos[1] := 0;
  defPos[2] := 0;

  defRot[0] := 0;
  defRot[1] := 0;
  defRot[2] := 0;

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

function TI3DModelLoader.HasTires: boolean;
begin
  Result := obj.flags and FLOF_HASTIRES <> 0;
end;

procedure TI3DModelLoader.FindTireCenters;
var
  i, j, k, n: integer;
  xmin, xmax, ymin, ymax, zmin, zmax: integer;
  x, y, z: integer;
begin
  if obj.nFaces < 64 then
    Exit;

  n := 0;
  for i := 0 to 3 do
  begin
    xmin := MAXINT;
    xmax := -MAXINT;
    ymin := MAXINT;
    ymax := -MAXINT;
    zmin := MAXINT;
    zmax := -MAXINT;
    for j := 0 to 15 do
    begin
      for k := 0 to objfaces[n].h.nVerts - 1 do
      begin
        x := objfaces[n].verts[k].vert.x;
        y := objfaces[n].verts[k].vert.y;
        z := objfaces[n].verts[k].vert.z;
        if x < xmin then
          xmin := x;
        if x > xmax then
          xmax := x;
        if y < ymin then
          ymin := y;
        if y > ymax then
          ymax := y;
        if z < zmin then
          zmin := z;
        if z > zmax then
          zmax := z;
      end;
      inc(n);
    end;
    tirecenters[i].x := (xmin + xmax) div 2;
    tirecenters[i].y := (ymin + ymax) div 2;
    tirecenters[i].z := (zmin + zmax) div 2;
    tireperimeters[i] := (ymax - ymin);
  end;
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
  if obj.pos = nil then
    obj.pos := @defPos
  else
    obj.pos := _OF(obj.pos);
  if obj.rot = nil then
    obj.rot := @defRot
  else
    obj.rot := _OF(obj.rot);

  if obj.scx = 0 then
    obj.scx := DEF_I3D_SCALE;
  if obj.scy = 0 then
    obj.scy := DEF_I3D_SCALE;
  if obj.scz = 0 then
    obj.scz := DEF_I3D_SCALE;

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

  if HasTires then
    FindTireCenters;

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
  color: LongWord;
  TEXDIMX, TEXDIMY: integer;
  gltex: TGluint;
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
    color := I3DPalColorL(m.texture[i]);
    bm.Canvas.Pixels[i mod TEXDIMX, i div TEXDIMX] := color;
    dest^ := color or $FF000000;
    inc(dest);
  end;

  fbitmaps.AddObject(m.texname, bm);

  glGenTextures(1, @gltex);
  glBindTexture(GL_TEXTURE_2D, gltex);

  glTexImage2D(GL_TEXTURE_2D, 0, gl_tex_format,
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

  tireperimeters[0] := 0;
  tireperimeters[1] := 0;
  tireperimeters[2] := 0;
  tireperimeters[3] := 0;

  tirecenters[0].x := 0;
  tirecenters[0].y := 0;
  tirecenters[0].z := 0;
  tirecenters[1].x := 0;
  tirecenters[1].y := 0;
  tirecenters[1].z := 0;
  tirecenters[2].x := 0;
  tirecenters[2].y := 0;
  tirecenters[2].z := 0;
  tirecenters[3].x := 0;
  tirecenters[3].y := 0;
  tirecenters[3].z := 0;
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

  // Recalculate tire centers
  if HasTires then
    FindTireCenters;
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
  lasttex, newtex: TGluint;

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
    glVertex3f(
      (1.0 * x - obj.dcx) * obj.scx / DEF_I3D_SCALE * scalex + offsetx,
      (1.0 * y - obj.dcy) * obj.scy / DEF_I3D_SCALE * scaley + offsety,
      -(1.0 * z - obj.dcz) * obj.scz / DEF_I3D_SCALE * scalez + offsetz
    );
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

function TI3DModelLoader.RenderGLEx(const scalex, scaley, scalez: single;
  const offsetx, offsety, offsetz: single;
  const oldtex1, tex1, oldtex2, tex2: string): integer;
var
  do1, do2: boolean;
  i: integer;
  savetex1, savetex2: TGluint;
  idx1, idx2: integer;
begin
  do1 := tex1 <> '';
  do2 := tex2 <> '';

  savetex1 := 0;
  savetex2 := 0;
  idx1 := -1;
  idx2 := -1;

  if do1 then
    for i := 0 to obj.nMaterials - 1 do
      if obj.materials[i].texname = oldtex1 then
      begin
        idx1 := i;
        savetex1 := textures[obj.materials[i].texid];
        textures[obj.materials[i].texid] := gld_RegisterI3DTexture(tex1);
        Break;
      end;
  if do2 then
    for i := 0 to obj.nMaterials - 1 do
      if obj.materials[i].texname = oldtex2 then
      begin
        idx2 := i;
        savetex2 := textures[obj.materials[i].texid];
        textures[obj.materials[i].texid] := gld_RegisterI3DTexture(tex2);
        Break;
      end;

  Result := RenderGL(scalex, scaley, scalez, offsetx, offsety, offsetz);

  if idx1 >= 0 then
    textures[obj.materials[idx1].texid] := savetex1;
  if idx2 >= 0 then
    textures[obj.materials[idx2].texid] := savetex2;
end;

function TI3DModelLoader.RenderSoft(const device: Pdevice_t; const scalex, scaley, scalez: single;
  const offsetx, offsety, offsetz: single): integer;
var
  i, j, k: integer;
  v1, v2, v3: vertex_t;
  lasttex, newtex: TBitmap;
  extra: TDStringList;
  idx: integer;
  basetex: TBitmap;

  procedure _softcolor(const m: O3DM_TMaterial_p);
  var
    cl: LongWord;
    cname: string;
    idx: integer;
    bm: TBitmap;
  begin
    cl := I3DPalColorL(m.color);
    if cl = 0 then
      cl := $010101;
    cname := itoa(cl);
    idx := extra.IndexOf(cname);
    if idx >= 0 then
    begin
      device_set_texture(device, extra.Objects[idx] as TBitmap);
      Exit;
    end;

    bm := TBitmap.Create;
    bm.PixelFormat := pf32bit;
    bm.Width := 2;
    bm.Height := 2;
    bm.Canvas.Pixels[0, 0] := cl;
    bm.Canvas.Pixels[1, 0] := cl;
    bm.Canvas.Pixels[0, 1] := cl;
    bm.Canvas.Pixels[1, 1] := cl;
    extra.AddObject(cname, bm);
    device_set_texture(device, bm);
  end;

  procedure _softtexcoord(const v: Pvertex_t; const tx, ty: integer);
  var
    ax, ay: single;
  begin
    UVtoGL(tx, ty, ax, ay);
    v.tc.u := ax;
    v.tc.v := ay;
  end;

  procedure _softvertex(const v: Pvertex_t; const x, y, z: integer);
  begin
    v.pos.x := (1.0 * x - obj.dcx) * obj.scx / DEF_I3D_SCALE * scalex + offsetx;
    v.pos.z := (1.0 * y - obj.dcy) * obj.scy / DEF_I3D_SCALE * scaley + offsety;
    v.pos.y := -(1.0 * z - obj.dcz) * obj.scz / DEF_I3D_SCALE * scalez + offsetz;
  end;

begin
  Result := 0;

  if obj = nil then
    Exit;

  lasttex := nil;

  extra := TDStringList.Create;

  v1.pos.w := 1.0;
  v1.color.r := 1.0;
  v1.color.g := 1.0;
  v1.color.b := 1.0;
  v1.rhw := 1.0;
  v2.pos.w := 1.0;
  v2.color.r := 1.0;
  v2.color.g := 1.0;
  v2.color.b := 1.0;
  v2.rhw := 1.0;
  v3.pos.w := 1.0;
  v3.color.r := 1.0;
  v3.color.g := 1.0;
  v3.color.b := 1.0;
  v3.rhw := 1.0;

  basetex := TBitmap.Create;
  basetex.PixelFormat := pf32bit;
  basetex.Width := 2;
  basetex.Height := 2;
  basetex.Canvas.Pixels[0, 0] := $FFFFFF;
  basetex.Canvas.Pixels[1, 0] := $FFFFFF;
  basetex.Canvas.Pixels[0, 1] := $FFFFFF;
  basetex.Canvas.Pixels[1, 1] := $FFFFFF;

  for i := 0 to obj.nFaces - 1 do
  begin
    if not objfaces[i].h.visible then
      Continue;
    if fselected = i then
      Continue;
    if objfaces[i].h.material <> nil then
    begin
      newtex := nil;

      idx := fbitmaps.IndexOf(objfaces[i].h.material.texname);
      if idx >= 0 then
        newtex := fbitmaps.Objects[idx] as TBitmap;
      if newtex <> nil then
      begin
        if newtex <> lasttex then
        begin
          device_set_texture(device, newtex);
          lasttex := newtex;
        end;
      end
      else
      begin
        lasttex := nil;
        _softcolor(objfaces[i].h.material);
      end;
    end
    else
    begin
      lasttex := nil;
      device_set_texture(device, basetex);
    end;

    _softtexcoord(@v1, objfaces[i].verts[0].tx, objfaces[i].verts[0].ty);
    _softvertex(@v1, objfaces[i].verts[0].vert.x, objfaces[i].verts[0].vert.y, objfaces[i].verts[0].vert.z);

    for j := 1 to objfaces[i].h.nVerts - 2 do
    begin
      _softtexcoord(@v2, objfaces[i].verts[j].tx, objfaces[i].verts[j].ty);
      _softvertex(@v2, objfaces[i].verts[j].vert.x, objfaces[i].verts[j].vert.y, objfaces[i].verts[j].vert.z);
      k := j + 1;
      _softtexcoord(@v3, objfaces[i].verts[k].tx, objfaces[i].verts[k].ty);
      _softvertex(@v3, objfaces[i].verts[k].vert.x, objfaces[i].verts[k].vert.y, objfaces[i].verts[k].vert.z);
      device_draw_primitive(device, @v1, @v2, @v3);
    end;

    Result := Result + objfaces[i].h.nVerts - 2;
  end;

  for i := 0 to extra.Count - 1 do
    extra.Objects[i].Free;
  extra.Free;
  basetex.Free;
end;

function TI3DModelLoader.RenderSoftEx(const device: Pdevice_t; const scalex, scaley, scalez: single;
  const offsetx, offsety, offsetz: single;
  const oldtex1, tex1, oldtex2, tex2: string): integer;
var
  do1, do2: boolean;
  i: integer;
  savetex1, savetex2: TBitmap;
  idx1, idx2: integer;
begin
  do1 := tex1 <> '';
  do2 := tex2 <> '';

  savetex1 := nil;
  savetex2 := nil;
  idx1 := -1;
  idx2 := -1;

  if do1 then
    for i := 0 to fbitmaps.Count - 1 do
      if fbitmaps.Strings[i] = oldtex1 then
      begin
        idx1 := i;
        savetex1 := fbitmaps.Objects[i] as TBitmap;
        fbitmaps.Objects[i] := T_HiResTextureAsBitmap(tex1);
        Break;
      end;
  if do2 then
    for i := 0 to obj.nMaterials - 1 do
      if obj.materials[i].texname = oldtex2 then
      begin
        idx2 := i;
        savetex2 := fbitmaps.Objects[i] as TBitmap;
        fbitmaps.Objects[i] := T_HiResTextureAsBitmap(tex2);
        Break;
      end;

  Result := RenderSoft(device, scalex, scaley, scalez, offsetx, offsety, offsetz);

  if idx1 >= 0 then
  begin
    fbitmaps.Objects[idx1].Free;
    fbitmaps.Objects[idx1] := savetex1;
  end;
  if idx2 >= 0 then
  begin
    fbitmaps.Objects[idx2].Free;
    fbitmaps.Objects[idx2] := savetex2;
  end;
end;

end.
