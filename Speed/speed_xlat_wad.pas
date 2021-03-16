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

unit speed_xlat_wad;

interface

uses
  d_delphi;

procedure Speed2Stream_Game(const fname: string; const handle: TDStream);

procedure Speed2WAD_Game(const fin, fout: string);

const
  SPEED_LEVEL_SCALE = 2;
  NUM_SPEED_MAPS = 8;

const
  sMAPDATA_sprite = 'sprite';
  sMAPDATA_sky = 'sky';
  sMAPDATA_mountain = 'mountain';
  sMAPDATA_ground = 'ground';
  sMAPDATA_name = 'name';
  sMAPDATA_best = 'best';
  sMAPDATA_level = 'level';

implementation

uses
  Math,
  speed_defs,
  speed_flatsize,
  speed_palette,
  speed_patch,
  speed_bitmap,
  speed_font,
  speed_is2,
  speed_sounds,
  speed_level,
  sc_engine,
  r_defs,
  v_video,
  w_pak,
  w_wadwriter,
  w_wad;

type
  TSpeedToWADConverter = class(TObject)
  private
    wadwriter: TWadWriter;
    header: speedheader_t;
    f: TFile;
    lumps: Pspeedlump_tArray;
    numlumps: integer;
    def_pal: packed array[0..767] of byte;
    def_palL: array[0..255] of LongWord;
    redfromblue_tr: array[0..255] of byte;
    greenfromblue_tr: array[0..255] of byte;
    yellowfromblue_tr: array[0..255] of byte;
    pk3entry: TDStringList;
    sflatsize: TDStringList;
    textures: TDStringList;
    numflats: integer;
    ffilename: string;
    extramapflats: array[0..NUM_SPEED_MAPS - 1] of string;
  protected
    function ReadLump(const l: Pspeedlump_tArray; const numl: integer;
      const lmp: string; var buf: pointer; var size: integer): boolean;
    function FindLump(const l: Pspeedlump_tArray; const numl: integer;
       const lmp: string): integer;
    procedure Clear;
    function ReadHeader: boolean;
    function ReadDirectory: boolean;
    function GeneratePalette: boolean;
    function GenerateTranslationTables: boolean;
    function GenerateTextures(const pnames, texture1: string): boolean;
    function GenerateStubTexturesEntry(const textureX: string): boolean;
    function GenerateLevels(const scale: integer): boolean;
    function GenerateFlats: boolean;
    function GenerateMapFlats(const doublesize: boolean): boolean;
    function GenerateGraphicWithOutPalette(const rname, wname: string; const solid: boolean): boolean;
    function GenerateGraphicWithPalette(const rname, wname: string; const solid: boolean): boolean;
    function GenerateIS2(const rname, wname: string; const solid: boolean; const rightcrop: boolean; var aw, ah: integer): boolean;
    function GeneratePIX(const rname, wname: string; const solid: boolean): boolean;
    function GenerateGraphics: boolean;
    function GenerateFonts: boolean;
    function GenerateSprites: boolean;
    function GenerateSounds: boolean;
    function GeneratePK3ModelEntries: boolean;
    procedure WritePK3Entry;
    procedure WriteFlatSizeEntry;
    function AddPAKFileSystemEntry(const lumpname: string; const aliasname: string): boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ConvertGame(const fname: string);
    procedure SavetoFile(const fname: string);
    procedure SavetoStream(const strm: TDStream);
  end;

constructor TSpeedToWADConverter.Create;
begin
  f := nil;
  wadwriter := nil;
  lumps := nil;
  numlumps := 0;
  pk3entry := nil;
  sflatsize := nil;
  textures := nil;
  numflats := 0;
  ffilename := '';
  Inherited;
end;

destructor TSpeedToWADConverter.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TSpeedToWADConverter.Clear;
begin
  if wadwriter <> nil then
    wadwriter.Free;

  if f <> nil then
    f.Free;

  if pk3entry <> nil then
    pk3entry.Free;

  if sflatsize <> nil then
    sflatsize.Free;

  if textures <> nil then
    textures.Free;

  if numlumps <> 0 then
  begin
    memfree(pointer(lumps), numlumps * SizeOf(speedlump_t));
    numlumps := 0;
  end;
end;

function TSpeedToWADConverter.ReadLump(const l: Pspeedlump_tArray; const numl: integer;
  const lmp: string; var buf: pointer; var size: integer): boolean;
var
  i: integer;
begin
  for i := 0 to numl - 1 do
    if getjcllumpname(@l[i]) = lmp then
    begin
      f.Seek(l[i].start, sFrombeginning);
      size := l[i].size;
      buf := malloc(size);
      f.Read(buf^, size);
      result := true;
      exit;
    end;
  buf := nil;
  result := false;
  size := 0;
end;

function TSpeedToWADConverter.FindLump(const l: Pspeedlump_tArray; const numl: integer;
  const lmp: string): integer;
var
  i: integer;
begin
  for i := 0 to numl - 1 do
    if getjcllumpname(@l[i]) = lmp then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

function TSpeedToWADConverter.ReadHeader: boolean;
begin
  f.Seek(SizeOf(speedheader_t), sFromEnd);
  f.Read(header, SizeOf(speedheader_t));
  result := header.magic = JCL_MAGIC;
end;

function TSpeedToWADConverter.ReadDirectory: boolean;
var
  i, j: integer;
  sz: integer;
  item: speedlump_t;

  function _compare_lumps(const ii, jj: integer): integer;
  var
    vii, vjj: integer;
    fii, fjj: string;
    nii, njj: string;
    eii, ejj: string;
  begin
    fii := getjcllumpname(@lumps[ii]);
    fjj := getjcllumpname(@lumps[jj]);
    splitstring(fii, nii, eii, '.');
    splitstring(fjj, njj, ejj, '.');
    vii := atoi(nii);
    vjj := atoi(njj);
    if vii > vjj then
      result := 1
    else if vii < vjj then
      result := -1
    else if lumps[ii].filename > lumps[jj].filename then
      result := 1
    else if lumps[ii].filename < lumps[jj].filename then
      result := -1
    else
      result := 0;
  end;

begin
  numlumps := header.nlumps;
  lumps := mallocz(numlumps * SizeOf(speedlump_t));
  f.Seek(header.lastoffset, sFromEnd);
  result := f.Read(lumps^, numlumps * SizeOf(speedlump_t)) = numlumps * SizeOf(speedlump_t);
  sz := f.Size;
  for i := 0 to numlumps - 1 do
    lumps[i].start := sz - header.lastoffset - lumps[i].start;

  for i := 0 to numlumps - 1 do
    for j := 0 to numlumps - 2 do
      if _compare_lumps(j, j + 1) > 0 then
      begin
        item := lumps[j];
        lumps[j] := lumps[j + 1];
        lumps[j + 1] := item;
      end;

end;

function TSpeedToWADConverter.GeneratePalette: boolean;
var
  p: pointer;
  pal: PByteArray;
  size: integer;
  playpal: packed array[0..768 * 14 - 1] of byte;
  colormap: packed array[0..34 * 256 - 1] of byte;
  i: integer;
  r, g, b: LongWord;
begin
  result := ReadLump(lumps, numlumps, 'GRAFS.PAL', p, size);
  if not result then
    exit;
  pal := p;
  SH_CreateDoomPalette(pal, @playpal, @colormap);

  // Keep def_pal AFTER SH_CreateDoomPalette call
  for i := 0 to 767 do
    def_pal[i] := pal[i];
  for i := 0 to 255 do
  begin
    r := def_pal[3 * i];
    if r > 255 then r := 255;
    g := def_pal[3 * i + 1];
    if g > 255 then g := 255;
    b := def_pal[3 * i + 2];
    if b > 255 then b := 255;
    def_palL[i] := (r shl 16) + (g shl 8) + (b);
  end;

  wadwriter.AddData('PLAYPAL', @playpal, SizeOf(playpal));
  wadwriter.AddData('COLORMAP', @colormap, SizeOf(colormap));
  memfree(p, size);
end;

function TSpeedToWADConverter.GenerateTranslationTables: boolean;
var
  p1, p2, p3: pointer;
  pal1, pal2, pal3: PByteArray;
  size1, size2, size3: integer;
  ret1, ret2, ret3: boolean;
begin
  ret1 := ReadLump(lumps, numlumps, 'RedFromBluePal', p1, size1);
  pal1 := p1;

  ret2 := ReadLump(lumps, numlumps, 'GreenFromBluePal', p2, size2);
  pal2 := p2;

  ret3 := ReadLump(lumps, numlumps, 'YellowFromBluePal', p3, size3);
  pal3 := p3;

  result := ret1 and ret2 and ret3;

  if result then
  begin
    SH_CreateTranslation(@def_pal, pal1, @redfromblue_tr);
    SH_CreateTranslation(@def_pal, pal2, @greenfromblue_tr);
    SH_CreateTranslation(@def_pal, pal3, @yellowfromblue_tr);
  end;

  memfree(p1, size1);
  memfree(p2, size2);
  memfree(p3, size3);
end;

function TSpeedToWADConverter.GenerateTextures(const pnames, texture1: string): boolean;
var
  rname, pname: string;
  s1, s2: string;
  aw, ah: integer;
  numpatches: word;
  i: integer;
  buf: PByteArray;
  p: pointer;
  size: integer;
  stmp: string;
  mp, mt: TDMemoryStream;
  psize: integer;
  c8: char8_t;
  tex: maptexture_t;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  for i := 0 to numlumps - 1 do
  begin
    rname := getjcllumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.IS2' then
    begin
      splitstring(rname, s1, s2, '.');
      if itoa(atoi(s1)) = s1 then
        lst.Add(rname);
    end;
  end;

  numpatches := lst.Count;

  mp := TDMemoryStream.Create;  // PNAMES
  mt := TDMemoryStream.Create;  // TEXTURE1

  psize := numpatches + 1 + 7; // 1 stub + 7 skies

  // PNAMES header
  mp.Write(psize, SizeOf(integer));

  // TEXTURE1 header
  mt.Write(psize, SizeOf(integer));

  psize := 0;
  for i := 0 to numpatches + 7 do
  begin
    psize := (numpatches + 1 + 7) * 4 + 4 + i * SizeOf(maptexture_t);
    mt.Write(psize, SizeOf(integer));
  end;

  wadwriter.AddSeparator('P_START');

  // Stub texture
  buf := mallocz(32 * 32);
  SH_CreateDoomPatch(buf, 32, 32, true, p, size);
  memfree(pointer(buf), 32 * 32);
  stmp := 'AA0000';
  wadwriter.AddData(stmp, p, size);
  memfree(p, size);

  // Save PNAMES entry
  c8 := stringtochar8(stmp);
  mp.Write(c8, 8);

  // Save TEXTURE1 entry
  ZeroMemory(@tex, SizeOf(maptexture_t));
  tex.name := c8;
  tex.width := 32;
  tex.height := 32;
  tex.patchcount := 1;
  tex.patches[0].patch := 0;
  mt.Write(tex, SizeOf(maptexture_t));

  for i := 0 to lst.Count - 1 do
  begin
    rname := lst.Strings[i];
    pname := SH_WALL_PREFIX + LeftStr(rname, Length(rname) - 4);
    GenerateIS2(rname, pname, false, true, aw, ah);
    // Save PNAMES entry
    c8 := stringtochar8(pname);
    mp.Write(c8, 8);

    // Save TEXTURE1 entry
    ZeroMemory(@tex, SizeOf(maptexture_t));
    tex.name := c8;
    tex.width := aw;
    tex.height := ah;
    tex.patchcount := 1;
    tex.patches[0].patch := i + 1;
    mt.Write(tex, SizeOf(maptexture_t));

    // Save PK3ENTRY entry
    pk3entry.Add(pname + '=' + rname);

    // Save Texture name
    textures.Add(pname);
  end;

  // Stub skies
  buf := mallocz(256 * 128);
  for i := 1 to 7 do
  begin
    FillChar(buf^, 256 * 128, 127);
    SH_CreateDoomPatch(buf, 256, 128, true, p, size);
    stmp := 'SKY' + itoa(i);
    wadwriter.AddData(stmp, p, size);
    memfree(p, size);

    // Save PNAMES entry
    c8 := stringtochar8(stmp);
    mp.Write(c8, 8);

    // Save TEXTURE1 entry
    ZeroMemory(@tex, SizeOf(maptexture_t));
    tex.name := c8;
    tex.width := 256;
    tex.height := 128;
    tex.patchcount := 1;
    tex.patches[0].patch := lst.Count + i;
    mt.Write(tex, SizeOf(maptexture_t));
  end;
  memfree(pointer(buf), 256 * 128);

  wadwriter.AddSeparator('P_END');

  wadwriter.AddData(texture1, mt.Memory, mt.Size);
  wadwriter.AddData(pnames, mp.Memory, mp.Size);

  mp.Free;
  mt.Free;

  result := lst.Count > 0;

  lst.Free;
end;

function TSpeedToWADConverter.GenerateStubTexturesEntry(const textureX: string): boolean;
var
  sz: LongWord;
begin
  sz := 0;
  wadwriter.AddData(textureX, @sz, 4);
  Result := True;
end;

function TSpeedToWADConverter.GenerateLevels(const scale: integer): boolean;
type
  circuit_t = record
    name: string[64];
    number: integer;
    level: integer;
    len: integer;
    best: integer;
    record1, record2: integer;
    nback: integer;
  end;
const
  MAXCIRCUITS = 8;
var
  circuits: array[0..MAXCIRCUITS - 1] of circuit_t;

  function _makelevel(const prefix, prefix2: string; const mapname: string;
    const mapsprite, mapsky, mapmount, extraflat: string): boolean;
  var
    bufmap: pointer;
    bufmapsize: integer;
    bufsec: pointer;
    bufsecsize: integer;
    bufpath: pointer;
    bufpathsize: integer;
    ret1, ret2, ret3: boolean;
    lst: TDStringList;
  begin
    bufmap := nil;
    bufmapsize := 0;
    bufsec := nil;
    bufsecsize := 0;
    bufpath := nil;
    bufpathsize := 0;

    ret1 := ReadLump(lumps, numlumps, 'MAP' + prefix + '.DAT', bufmap, bufmapsize);
    ret2 := ReadLump(lumps, numlumps, 'MAP' + prefix + '.SEC', bufsec, bufsecsize);
    ret3 := ReadLump(lumps, numlumps, 'MAP' + prefix + '.PTH', bufpath, bufpathsize);

    result := ret1 and ret2 and ret3;
    if not result then
    begin
      if bufmap <> nil then
        memfree(pointer(bufmap), bufmapsize);
      if bufsec <> nil then
        memfree(pointer(bufsec), bufsecsize);
      if bufpath <> nil then
        memfree(pointer(bufpath), bufpathsize);
      exit;
    end;

    SH_CreateDoomLevel(
      prefix2, mapname,
      bufmap, bufmapsize,
      bufsec, bufsecsize,
      bufpath, bufpathsize,
      scale,
      extraflat,
      wadwriter
    );

    memfree(pointer(bufmap), bufmapsize);
    memfree(pointer(bufsec), bufsecsize);
    memfree(pointer(bufpath), bufpathsize);

    lst := TDStringList.Create;
    lst.Add(sMAPDATA_sprite + '=' + mapsprite);
    lst.Add(sMAPDATA_sky + '=' + mapsky);
    lst.Add(sMAPDATA_mountain + '=' + mapmount);
    lst.Add(sMAPDATA_ground + '=' + extraflat);
    lst.Add(sMAPDATA_name + '=' + circuits[atoi(prefix)].name);
    lst.Add(sMAPDATA_best + '=' + itoa(circuits[atoi(prefix)].best));
    lst.Add(sMAPDATA_level + '=' + itoa(circuits[atoi(prefix)].level));

    wadwriter.AddString('MAPDATA', lst.Text);
    lst.Free;
  end;

var
  sc: TScriptEngine;
  buf: pointer;
  i, nc, sz: integer;
  pc: PChar;
  stmp: string;
begin
  result := true;

  stmp := '';

  if ReadLump(lumps, numlumps, 'CIRCUITS.LST', buf, sz) then
  begin
    pc := buf;
    for i := 0 to sz - 1 do
    begin
      stmp := stmp + pc^;
      inc(pc);
    end;
    memfree(buf, sz);
  end;

  ZeroMemory(@circuits, SizeOf(circuits));

  if stmp <> '' then
  begin
    sc := TScriptEngine.Create(stmp);
    sc.MustGetInteger;
    nc := sc._Integer;
    for i := 0 to nc - 1 do
    begin
      if i = MAXCIRCUITS then
        break;
      sc.GetString; // Circuit
      sc.GetString; // Name
      if sc.GetString then
        circuits[i].name := sc._String;
      sc.GetString; // Number
      if sc.GetInteger then
        circuits[i].number := sc._Integer;
      sc.GetString; // Level
      if sc.GetInteger then
        circuits[i].level := sc._Integer;
      sc.GetString; // Length
      if sc.GetInteger then
        circuits[i].len := sc._Integer;
      sc.GetString; // Best
      if sc.GetInteger then
        circuits[i].best := sc._Integer;
      sc.GetString; // Record
      if sc.GetInteger then
        circuits[i].record1 := sc._Integer;
      if sc.GetInteger then
        circuits[i].record2 := sc._Integer;
      sc.GetString; // NBack
      if sc.GetInteger then
        circuits[i].nback := sc._Integer;
    end;
    sc.Free;
  end;

  _makelevel('00', '00', 'E1M1', 'MAPSPR00', 'NUBES0', 'MOUNT0' ,extramapflats[0]);
  _makelevel('01', '01', 'E1M2', 'MAPSPR01', 'NUBES1', 'MOUNT1' ,extramapflats[1]);
  _makelevel('02', '02', 'E1M3', 'MAPSPR02', 'NUBES2', 'MOUNT2' ,extramapflats[2]);
  _makelevel('03', '03', 'E1M4', 'MAPSPR03', 'NUBES3', 'MOUNT3' ,extramapflats[3]);
  _makelevel('04', '04', 'E1M5', 'MAPSPR04', 'NUBES4', 'MOUNT4' ,extramapflats[4]);
  _makelevel('05', '05', 'E1M6', 'MAPSPR05', 'NUBES5', 'MOUNT5' ,extramapflats[5]);
  _makelevel('06', '06', 'E1M7', 'MAPSPR06', 'NUBES6', 'MOUNT6' ,extramapflats[6]);
  _makelevel('07', '07', 'E1M8', 'MAPSPR07', 'NUBES7', 'MOUNT7' ,extramapflats[7]);
end;

function TSpeedToWADConverter.GenerateFlats: boolean;
var
  position: integer;
  i: integer;
  buf: PByteArray;
  stmp: string;
  c: byte;
begin
  i := FindLump(lumps, numlumps, 'GRAFS.DAT');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  numflats := lumps[i].size div (64 * 64);

  position := lumps[i].start;
  f.Seek(position, sFromBeginning);

  buf := malloc(64 * 64);

  wadwriter.AddSeparator('F_START');

  for i := 0 to numflats - 1 do
  begin
    f.Read(buf^, 64 * 64);
    stmp := SH_FLAT_PREFIX + IntToStrZFill(4, i + 1);
    wadwriter.AddData(stmp, buf, 64 * 64);
    sflatsize.Add(stmp + '=' + itoa(SPEED_LEVEL_SCALE * 64));
  end;

  // Create F_SKY1
  c := V_FindAproxColorIndex(@def_palL, 77 shl 16 + 179 shl 8 + 255);
  memset(buf, c, 64 * 64);
  wadwriter.AddData('F_SKY1', buf, 64 * 64);
  sflatsize.Add('F_SKY1=64');

  memfree(pointer(buf), 64 * 64);

  wadwriter.AddSeparator('F_END');
end;

function TSpeedToWADConverter.GenerateMapFlats(const doublesize: boolean): boolean;
var
  position: integer;
  i: integer;
  grafs: PByteArray;
  grafsize: integer;

  procedure _rotate_tile(const pt: PByteArray; const rot: integer);
  var
    buf: packed array[0..4095] of byte;
    ii, jj: integer;
  begin
    if rot = 0 then
      exit;

    for ii := 0 to 4095 do
      buf[ii] := pt[ii];

    if rot = 1 then
      for ii := 0 to 63 do
        for jj :=  0 to 63 do
          pt[ii * 64 + jj] := buf[(63 - jj) * 64 + ii];
    if rot = 2 then
      for ii := 0 to 63 do
        for jj :=  0 to 63 do
          pt[ii * 64 + jj] := buf[(63 - ii) * 64 + 63 - jj];
    if rot = 3 then
      for ii := 0 to 63 do
        for jj :=  0 to 63 do
          pt[ii * 64 + jj] := buf[jj * 64 + 63 - ii];
  end;

  function GenerateMapBitmap(const smap: string; const mapid: integer): boolean;
  type
    bmbuffer4096_t = packed array[0..4095, 0..4095] of byte;
    bmbuffer4096_p = ^bmbuffer4096_t;
    bmbuffer8192_t = packed array[0..8191, 0..8191] of byte;
    bmbuffer8192_p = ^bmbuffer8192_t;
  var
    xb, yb: integer;
    ix, iy: integer;
    ig: integer;
    g, m: integer;
    map: packed array[0..4095] of smallint;
    angles: packed array[0..4095] of byte;
    tile: packed array[0..4095] of byte;
    it: integer;
    bmbuffer4096: bmbuffer4096_p;
    bmbuffer8192: bmbuffer8192_p;
    pl: speedlump_p;
    ll: integer;
    b: byte;
  begin
    ll := FindLump(lumps, numlumps, 'MAP' + smap + '.DAT');
    if ll < 0 then
    begin
      result := false;
      exit;
    end;

    pl := @lumps[ll];

    f.Seek(pl.start + 4, sFromBeginning);
    f.Read(map, SizeOf(map));
    f.Read(angles, SizeOf(angles));

    extramapflats[mapid] := SH_FLAT_PREFIX + IntToStrZFill(4, map[0] + 1);

    bmbuffer4096 := malloc(SizeOf(bmbuffer4096_t));
    for m := 0 to 4095 do
    begin
      xb := (m div 64) * 64;
      yb := (m mod 64) * 64;
      g := map[m];
      ig := g * 64 * 64;
      for ix := 0 to 4095 do
        tile[ix] := grafs[ig + ix];

      _rotate_tile(@tile, angles[m]);

      it := 0;
      for iy := yb to yb + 63 do
        for ix := xb to xb + 63 do
        begin
          bmbuffer4096[ix, iy] := tile[it];
          inc(it);
        end;
    end;

    for iy := 0 to 2047 do
      for ix := 0 to 4095 do
      begin
        b := bmbuffer4096[ix, iy];
        bmbuffer4096[ix, iy] := bmbuffer4096[ix, 4095 - iy];
        bmbuffer4096[ix, 4095 - iy] := b;
      end;

    if doublesize then
    begin
      bmbuffer8192 := malloc(SizeOf(bmbuffer8192_t));
      for iy := 0 to 4095 do
        for ix := 0 to 4095 do
        begin
          b := bmbuffer4096[ix, iy];
          bmbuffer8192[2 * ix, 2 * iy] := b;
          bmbuffer8192[2 * ix + 1, 2 * iy] := b;
          bmbuffer8192[2 * ix + 1, 2 * iy + 1] := b;
          bmbuffer8192[2 * ix, 2 * iy + 1] := b;
        end;
      wadwriter.AddData('FMAP' + smap, bmbuffer8192, SizeOf(bmbuffer8192_t));
      memfree(pointer(bmbuffer8192), SizeOf(bmbuffer8192_t));
    end
    else
      wadwriter.AddData('FMAP' + smap, bmbuffer4096, SizeOf(bmbuffer4096_t));

    sflatsize.Add('FMAP' + smap + '=' + itoa(SPEED_LEVEL_SCALE * 4096));

    memfree(pointer(bmbuffer4096), SizeOf(bmbuffer4096_t));

    result := true;
  end;

begin
  i := FindLump(lumps, numlumps, 'GRAFS.DAT');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  grafsize := lumps[i].size;

  position := lumps[i].start;
  f.Seek(position, sFromBeginning);

  grafs := malloc(grafsize);
  f.Read(grafs^, grafsize);

  wadwriter.AddSeparator('F_START');

  GenerateMapBitmap('00', 0);
  GenerateMapBitmap('01', 1);
  GenerateMapBitmap('02', 2);
  GenerateMapBitmap('03', 3);
  GenerateMapBitmap('04', 4);
  GenerateMapBitmap('05', 5);
  GenerateMapBitmap('06', 6);
  GenerateMapBitmap('07', 7);

  wadwriter.AddSeparator('F_END');

  memfree(pointer(grafs), grafsize);
end;

function TSpeedToWADConverter.GenerateGraphicWithOutPalette(const rname, wname: string; const solid: boolean): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  size: integer;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].size;
  buf := malloc(bufsize);
  f.Seek(lumps[lump].start, sFromBeginning);
  f.Read(buf^, bufsize);

  SH_CreateDoomPatchFromLumpData(buf, solid, p, size);

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TSpeedToWADConverter.GenerateIS2(const rname, wname: string; const solid: boolean;
  const rightcrop: boolean; var aw, ah: integer): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  size: integer;
  bm: TSpeedBitmap;
  len: integer;
begin
  aw := 0;
  ah := 0;

  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].size;
  buf := malloc(bufsize);
  f.Seek(lumps[lump].start, sFromBeginning);
  f.Read(buf^, bufsize);

  len := IS2_TSprite_p(buf).len + 24;
  if bufsize < len then
  begin
    memfree(buf, bufsize);
    bufsize := len;
    buf := malloc(bufsize);
    f.Seek(lumps[lump].start, sFromBeginning);
    f.Read(buf^, bufsize);
  end;

  bm := TSpeedBitmap.Create;
  bm.AttachIS2(buf);
  if rightcrop then
    bm.width := bm.width - 1;
//    bm.RightCrop(255);

  SH_CreateDoomPatch(bm.Image, bm.width, bm.height, solid, p, size);

  aw := bm.width;
  ah := bm.height;

  bm.Free;

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TSpeedToWADConverter.GeneratePIX(const rname, wname: string; const solid: boolean): boolean;
var
  lump: integer;
  buf: PByteArray;
  bufsize: integer;
  i: integer;
  p: pointer;
  size: integer;
  palname: string;
  pallump: integer;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  palname := rname;
  palname[length(palname) - 2] := 'P';
  palname[length(palname) - 1] := 'A';
  palname[length(palname) - 0] := 'L';
  pallump := FindLump(lumps, numlumps, palname);
  if pallump >= 0 then
  begin
    bufsize := lumps[lump].size + 800;
    buf := malloc(bufsize);

    f.Seek(lumps[lump].start, sFromBeginning);
    f.Read(buf[800], lumps[lump].size);
    PSmallIntArray(buf)[1] := 320;
    PSmallIntArray(buf)[2] := lumps[lump].size div 320;

    f.Seek(lumps[pallump].start, sFromBeginning);
    f.Read(buf[32], 768);

    SH_CreateDoomPatchFromLumpDataPal(buf, solid, @def_palL, p, size);
  end
  else
  begin
    bufsize := lumps[lump].size + 4;
    buf := malloc(bufsize);
    f.Seek(lumps[lump].start, sFromBeginning);
    f.Read(buf[4], lumps[lump].size);
    PSmallIntArray(buf)[0] := 320;
    PSmallIntArray(buf)[1] := lumps[lump].size div 320;

    for i := 5 to lumps[lump].size + 3 do
      if buf[i] > 0 then
        if (buf[i] < 16) or (buf[i] > 239) then
          buf[i] := buf[i - 1];

    if not solid then
      for i := 4 to lumps[lump].size + 3 do
        if buf[i] = 0 then
          buf[i] := 255;

    SH_CreateDoomPatchFromLumpData(buf, solid, p, size);
  end;

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(pointer(buf), bufsize);
end;

function TSpeedToWADConverter.GenerateGraphicWithPalette(const rname, wname: string; const solid: boolean): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  size: integer;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].size;
  buf := malloc(size);
  f.Seek(lumps[lump].start, sFromBeginning);
  f.Read(buf^, bufsize);

  SH_CreateDoomPatchFromLumpDataPal(buf, solid, @def_palL, p, size);

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TSpeedToWADConverter.GenerateGraphics: boolean;
var
  rname, wname: string;
  i: integer;
  lst: TDStringList;
  s1, s2: string;
  aw, ah: integer;
  transparentpix: TDSTringList;
begin
  lst := TDStringList.Create;
  for i := 0 to numlumps - 1 do
  begin
    rname := getjcllumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.PIX' then
      lst.Add(rname);
  end;

  transparentpix := TDSTringList.Create;
  transparentpix.Add('MSCBAR.PIX');
  transparentpix.Add('MSFBAR.PIX');
  transparentpix.Add('SALP0.PIX');
  transparentpix.Add('SALP1.PIX');

  wadwriter.AddSeparator('G_START');

  for i := 0 to lst.Count - 1 do
  begin
    rname := lst.Strings[i];
    wname := LeftStr(rname, length(rname) - 4);

    GeneratePIX(rname, wname, transparentpix.IndexOf(rname) < 0);
    pk3entry.Add(wname + '=' + rname);
  end;
  
  transparentpix.Free;

  result := lst.Count > 0;

  lst.Clear;

  for i := 0 to numlumps - 1 do
  begin
    rname := getjcllumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.IS2' then
    begin
      splitstring(rname, s1, s2, '.');
      if itoa(atoi(s1)) <> s1 then
        if strupper(LeftStr(s1, 3)) <> 'XPR' then
          if strupper(LeftStr(s1, 4)) <> 'SPRK' then
            if strupper(LeftStr(s1, 4)) <> 'SMOK' then
              if strupper(LeftStr(s1, 4)) <> 'GND0' then
                if strupper(LeftStr(s1, 4)) <> 'GND1' then
                  if strupper(LeftStr(s1, 4)) <> 'GND2' then
                    lst.Add(rname);
    end;
  end;


  for i := 0 to lst.Count - 1 do
  begin
    rname := lst.Strings[i];
    wname := LeftStr(rname, Length(rname) - 4);
    GenerateIS2(rname, wname, false, false, aw, ah);

    // Save PK3ENTRY entry
    pk3entry.Add(wname + '=' + rname);
  end;

  wadwriter.AddSeparator('G_END');

  result := result or (lst.Count > 0);

  lst.Free;

end;

function TSpeedToWADConverter.GenerateFonts: boolean;
const
  NUM_SMALL_FONT_COLORS = 5;
  NUM_BIG_FONT_COLORS = 5;
var
  SMALL_FONT_COLORS: array[0..NUM_SMALL_FONT_COLORS - 1] of LongWord;
  BIG_FONT_COLORS: array[0..NUM_SMALL_FONT_COLORS - 1] of LongWord;
  buf: PByteArray;
  cidx: integer;
  r1, g1, b1: LongWord;
  r, g, b: integer;
  c: LongWord;
  ch: integer;
  imgout: PByteArray;
  pnoise: double;
  p: pointer;
  size: integer;
  i, j, k, x, y, fpos: integer;
  imgsize: integer;
  imginp: PByteArray;
  fidx, widx, w: integer;
  imgoutw: PByteArray;

  function Interpolate(const a, b, frac: double): double;
  begin
    result := (1.0 - cos(pi * frac)) * 0.5;
    result:= a * (1 - result) + b * result;
  end;

  function Noise(const x,y: double): double;
  var
    n: integer;
  begin
    n := trunc(x + y * 57);
    n := (n shl 13) xor n;
    result := (1.0 - ( (n * (n * n * $EC4D + $131071F) + $5208DD0D) and $7FFFFFFF) / $40000000);
  end;

  function SmoothedNoise(const x, y: double): double;
  var
    corners: double;
    sides: double;
    center: double;
  begin
    corners := (Noise(x - 1, y - 1) + Noise(x + 1, y - 1) + Noise(x - 1, y + 1) + Noise(x + 1, y + 1) ) / 16;
    sides := (Noise(x - 1, y) + Noise(x + 1, y) + Noise(x, y - 1) + Noise(x, y + 1)) / 8;
    center := Noise(x, y) / 4;
    result := corners + sides + center
  end;

  function InterpolatedNoise(const x, y: double): double;
  var
    i1, i2: double;
    v1, v2, v3, v4: double;
    xInt: double;
    yInt: double;
    xFrac: double;
    yFrac: double;
  begin
    xInt := Int(x);
    xFrac := Frac(x);

    yInt := Int(y);
    yFrac := Frac(y);

    v1 := SmoothedNoise(xInt, yInt);
    v2 := SmoothedNoise(xInt + 1, yInt);
    v3 := SmoothedNoise(xInt, yInt + 1);
    v4 := SmoothedNoise(xInt + 1, yInt + 1);

    i1 := Interpolate(v1, v2, xFrac);
    i2 := Interpolate(v3, v4, xFrac);

    result := Interpolate(i1, i2, yFrac);
  end;

  function PerlinNoise(const x, y: integer): double;
  const
    PERSISTENCE = 0.50;
    LOOPCOUNT = 3;
    VARIATION = 16;
  var
    amp: double;
    ii: integer;
    freq: integer;
  begin
    freq := 1;
    result := 0.0;
    for ii := 0 to LOOPCOUNT - 1 do
    begin
      amp := Power(PERSISTENCE, ii);
      result := result + InterpolatedNoise(x * freq, y * freq) * amp;
      freq := freq shl 1;
    end;
    result := result * VARIATION;
  end;

begin
  Result := True;

  SMALL_FONT_COLORS[0] := $E2CE4A;
  SMALL_FONT_COLORS[1] := $F0F0F0;
  SMALL_FONT_COLORS[2] := $0F0F0F;
  SMALL_FONT_COLORS[3] := $F00000;
  SMALL_FONT_COLORS[4] := $C0C0C0;

  buf := @SMALL_FONT_DATA[0];

  imgout := malloc(8 * 8);
  for cidx := 0 to NUM_SMALL_FONT_COLORS - 1 do
  begin
    r1 := (SMALL_FONT_COLORS[cidx] shr 16) and $FF;
    g1 := (SMALL_FONT_COLORS[cidx] shr 8) and $FF;
    b1 := SMALL_FONT_COLORS[cidx] and $FF;
    wadwriter.AddSeparator('FN_START');
    for ch := 33 to 127 do
    begin
      x := (Ord(ch - 31) - 1) mod 16;
      y := (Ord(ch - 31) - 1) div 16;
      for j := 0 to 7 do
      begin
        fpos := x * 8 + (y * 8 + j) * 128;
        for i := 0 to 7 do
        begin
          imgout[i * 8 + j] := buf[fpos];
          inc(fpos);
        end;
      end;
      for i := 0 to 63 do
        if imgout[i] <> 0 then
        begin
          pnoise := PerlinNoise((i + x * 8) mod 128, (i * y + x * 8) div 128);
          r := GetIntegerInRange(round(r1 * imgout[i] / 256 + pnoise), 0, 255);
          g := GetIntegerInRange(round(g1 * imgout[i] / 256 + pnoise), 0, 255);
          b := GetIntegerInRange(round(b1 * imgout[i] / 256 + pnoise), 0, 255);
          c := r shl 16 + g shl 8 + b;
          imgout[i] := V_FindAproxColorIndex(@def_palL, c, 16, 239);
        end
        else
          imgout[i] := 255;
      SH_CreateDoomPatch(imgout, 8, 8, false, p, size, 0, 0);
      wadwriter.AddData('SFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;
  MemFree(pointer(imgout), 8 * 8);


  BIG_FONT_COLORS[0] := $E2CE4A;
  BIG_FONT_COLORS[1] := $F0F0F0;
  BIG_FONT_COLORS[2] := $0F0F0F;
  BIG_FONT_COLORS[3] := $F00000;
  BIG_FONT_COLORS[4] := $C0C0C0;

  imgsize := SizeOf(BIG_FONT_DATA);
  imginp := malloc(imgsize);

  imgout := malloc(16 * 16);

  for cidx := 0 to NUM_BIG_FONT_COLORS - 1 do
  begin
    r1 := (BIG_FONT_COLORS[cidx] shr 16) and $FF;
    g1 := (BIG_FONT_COLORS[cidx] shr 8) and $FF;
    b1 := BIG_FONT_COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if BIG_FONT_DATA[i] = 0 then
        imginp[i] := 255
      else
      begin
        if BIG_FONT_DATA[i] = 255 then
          pnoise := PerlinNoise(i mod 1520, i div 1520)
        else
          pnoise := 0.0;
        r := round(r1 * BIG_FONT_DATA[i] / 256 + pnoise);
        if r > 255 then
          r := 255
        else if r < 0 then
          r := 0;
        g := round(g1 * BIG_FONT_DATA[i] / 256 + pnoise);
        if g > 255 then
          g := 255
        else if g < 0 then
          g := 0;
        b := round(b1 * BIG_FONT_DATA[i] / 256 + pnoise);
        if b > 255 then
          b := 255
        else if b < 0 then
          b := 0;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 16, 239);
        if def_palL[imginp[i]] = 0 then
          imginp[i] := 255;
      end;
    end;

    wadwriter.AddSeparator('FN_START');
    for ch := 33 to 127 do
    begin
      fidx := ch - 32;
      if fidx > 0 then
      begin
        y := (fidx - 1) * 16;
        for k := 0 to 16 * 16 - 1 do
          imgout[k] := imginp[y * 16 + k];
        SH_RotatebitmapBuffer90(imgout, 16, 16);
        // Right trim image
        widx := 16 * 16 - 1;
        while widx > 0 do
        begin
          if imgout[widx] <> 255 then
            break;
          dec(widx);
        end;
        if widx < 14 * 16 then
        begin
          w := (widx div 16) + 1;
          imgoutw := malloc(16 * w);
          memcpy(imgoutw, imgout, w * 16);
          SH_CreateDoomPatch(imgoutw, w, 16, false, p, size, 1, 3);
          memfree(pointer(imgoutw), 16 * w);
        end
        else
          SH_CreateDoomPatch(imgout, 16, 16, false, p, size, 1, 3);
      end
      else
      begin
        memset(imgout, 0, 16 * 16);
        SH_CreateDoomPatch(imgout, 5, 16, false, p, size, 1, 3);
      end;
      wadwriter.AddData('BFNT' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
    wadwriter.AddSeparator('FN_END');
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 16 * 16);
end;

type
  spriteinfo_t = record
    sname: string[24];
    dname: string[8];
    translation: PByteArray;
    xoffs, yoffs: integer;
    centeroffs: boolean;
    defaultoffs: boolean;
  end;
  Pspriteinfo_t = ^spriteinfo_t;

function TSpeedToWADConverter.GenerateSprites: boolean;

  procedure GenerateOneSprite(const is2: string; const sprname: string);
  var
    aw, ah: integer;
  begin
    GenerateIS2(is2, sprname, false, false, aw, ah);
    // Save PK3ENTRY entry
    pk3entry.Add(sprname + '=' + is2);
  end;

begin
  wadwriter.AddSeparator('S_START');

  GenerateOneSprite('XPR020.IS2', 'S020A0');
  GenerateOneSprite('XPR021.IS2', 'S021A0');
  GenerateOneSprite('XPR022.IS2', 'S022A0');
  GenerateOneSprite('XPR023.IS2', 'S023A0');
  GenerateOneSprite('XPR024.IS2', 'S024A0');
  GenerateOneSprite('XPR025.IS2', 'S025A0');
  GenerateOneSprite('XPR026.IS2', 'S026A0');
  GenerateOneSprite('XPR027.IS2', 'S027A0');
  GenerateOneSprite('XPR028.IS2', 'S028A0');
  GenerateOneSprite('XPR029.IS2', 'S029A0');
  GenerateOneSprite('XPR02A.IS2', 'S02AA0');
  GenerateOneSprite('XPR02B.IS2', 'S02BA0');
  GenerateOneSprite('XPR02C.IS2', 'S02CA0');
  GenerateOneSprite('XPR02D.IS2', 'S02DA0');
  GenerateOneSprite('XPR02E.IS2', 'S02EA0');
  GenerateOneSprite('XPR02F.IS2', 'S02FA0');
  GenerateOneSprite('GND001AA.IS2', 'GND0A0');
  GenerateOneSprite('GND002AA.IS2', 'GND0B0');
  GenerateOneSprite('GND003AA.IS2', 'GND0C0');
  GenerateOneSprite('GND004AA.IS2', 'GND0D0');
  GenerateOneSprite('GND005AA.IS2', 'GND0E0');
  GenerateOneSprite('GND006AA.IS2', 'GND0F0');
  GenerateOneSprite('GND101AA.IS2', 'GND1A0');
  GenerateOneSprite('GND102AA.IS2', 'GND1B0');
  GenerateOneSprite('GND103AA.IS2', 'GND1C0');
  GenerateOneSprite('GND104AA.IS2', 'GND1D0');
  GenerateOneSprite('GND105AA.IS2', 'GND1E0');
  GenerateOneSprite('GND106AA.IS2', 'GND1F0');
  GenerateOneSprite('GND201AA.IS2', 'GND2A0');
  GenerateOneSprite('GND202AA.IS2', 'GND2B0');
  GenerateOneSprite('GND203AA.IS2', 'GND2C0');
  GenerateOneSprite('GND204AA.IS2', 'GND2D0');
  GenerateOneSprite('GND205AA.IS2', 'GND2E0');
  GenerateOneSprite('GND206AA.IS2', 'GND2F0');
  GenerateOneSprite('SMOK01AA.IS2', 'SMOKA0');
  GenerateOneSprite('SMOK02AA.IS2', 'SMOKB0');
  GenerateOneSprite('SMOK03AA.IS2', 'SMOKC0');
  GenerateOneSprite('SMOK04AA.IS2', 'SMOKD0');
  GenerateOneSprite('SMOK05AA.IS2', 'SMOKE0');
  GenerateOneSprite('SMOK06AA.IS2', 'SMOKF0');
  GenerateOneSprite('SPRK01AA.IS2', 'SPRKA0');
  GenerateOneSprite('SPRK02AA.IS2', 'SPRKB0');
  GenerateOneSprite('SPRK03AA.IS2', 'SPRKC0');
  GenerateOneSprite('SPRK04AA.IS2', 'SPRKD0');
  GenerateOneSprite('SPRK05AA.IS2', 'SPRKE0');
  GenerateOneSprite('SPRK06AA.IS2', 'SPRKF0');

  wadwriter.AddSeparator('S_END');

  result := true;
end;

function TSpeedToWADConverter.GenerateSounds: boolean;
var
  i: integer;
  sbuffer, pcmbuffer: pointer;
  ssize, pcmsize: integer;
  wname, rname: string;
  sndinfo: TDStringList;
  lst: TDStringList;
begin
  lst := TDStringList.Create;
  for i := 0 to numlumps - 1 do
  begin
    rname := getjcllumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.RAW' then
      lst.Add(rname);
  end;

  sndinfo := TDStringList.Create;
  sndinfo.Add('// Speed Haste sounds');
  sndinfo.Add('');
  result := false;
  for i := 0 to lst.Count - 1 do
  begin
    rname := lst.Strings[i];
    if ReadLump(lumps, numlumps, rname, sbuffer, ssize) then
    begin
      SH_RawToWAV(sbuffer, ssize, 13000, pcmbuffer, pcmsize);
      wname := 'DS_' + IntToStrzFill(5, i);
      wadwriter.AddData(wname, pcmbuffer, pcmsize);
      memfree(sbuffer, ssize);
      memfree(pcmbuffer, pcmsize);
      pk3entry.Add(wname + '=' + rname);
      sndinfo.Add('speedhaste/' + rname + ' ' + wname);
      result := true;
    end;
  end;
  if result then
    wadwriter.AddString('SNDINFO', sndinfo.Text);
  sndinfo.Free;
  lst.Free;
end;

function TSpeedToWADConverter.GeneratePK3ModelEntries: boolean;
var
  i: integer;
  rname: string;
begin
  Result := False;
  for i := 0 to numlumps - 1 do
  begin
    rname := getjcllumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.I3D' then
    begin
      PAK_AddEntry(lumps[i].start, lumps[i].size, 'MODELS\' + rname, ffilename);
      Result := True;
    end;
  end;
end;

procedure TSpeedToWADConverter.WritePK3Entry;
begin
  if pk3entry = nil then
    exit;
  if pk3entry.Count = 0 then
    exit;

  wadwriter.AddString(S_SPEEDINF, pk3entry.Text);
end;

procedure TSpeedToWADConverter.WriteFlatSizeEntry;
begin
  if sflatsize = nil then
    exit;
  if sflatsize.Count = 0 then
    exit;

  wadwriter.AddString(FLATSIZELUMPNAME, sflatsize.Text);
end;

function TSpeedToWADConverter.AddPAKFileSystemEntry(const lumpname: string; const aliasname: string): boolean;
var
  lump: integer;
begin
  lump := FindLump(lumps, numlumps, lumpname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;

  result := true;

  PAK_AddEntry(lumps[lump].start, lumps[lump].size, aliasname, ffilename);
end;

procedure TSpeedToWADConverter.ConvertGame(const fname: string);
begin
  if not fexists(fname) then
    exit;

  ffilename := fname;

  Clear;

  f := TFile.Create(fname, fOpenReadOnly);
  wadwriter := TWadWriter.Create;
  pk3entry := TDStringList.Create;
  sflatsize := TDStringList.Create;
  textures := TDStringList.Create;

  ReadHeader;
  ReadDirectory;
  GeneratePalette;
  GenerateTranslationTables;
  GenerateTextures('PNAMES', 'TEXTURE1');
  GenerateStubTexturesEntry('TEXTURE2');
  GenerateFlats;
  GenerateMapFlats(false);
  GenerateLevels(SPEED_LEVEL_SCALE);
  GenerateGraphics;
  GenerateFonts;
  GenerateSprites;
  GenerateSounds;
  GeneratePK3ModelEntries;
  WritePK3Entry;
  WriteFlatSizeEntry;
end;

procedure TSpeedToWADConverter.SavetoFile(const fname: string);
begin
  wadwriter.SaveToFile(fname);
end;

procedure TSpeedToWADConverter.SavetoStream(const strm: TDStream);
begin
  wadwriter.SaveToStream(strm);
end;

procedure Speed2Stream_Game(const fname: string; const handle: TDStream);
var
  cnv: TSpeedToWADConverter;
begin
  cnv := TSpeedToWADConverter.Create;
  try
    cnv.ConvertGame(fname);
    cnv.SavetoStream(handle);
  finally
    cnv.Free;
  end;
end;

procedure Speed2WAD_Game(const fin, fout: string);
var
  cnv: TSpeedToWADConverter;
begin
  cnv := TSpeedToWADConverter.Create;
  try
    cnv.ConvertGame(fin);
    cnv.SavetoFile(fout);
  finally
    cnv.Free;
  end;
end;

end.

