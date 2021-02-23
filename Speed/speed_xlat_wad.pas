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

implementation

uses
  speed_defs,
  speed_palette,
  speed_patch,
  speed_bitmap,
  speed_is2,
  speed_sounds,
  speed_level,
  r_defs,
  v_video,
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
    textures: TDStringList;
    numflats: integer;
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
    function GenerateLevels(const scale: integer): boolean;
    function GenerateCSVs(const path: string): boolean;
    function GenerateFlats: boolean;
    function GenerateMapFlats(const doublesize: boolean): boolean;
    function GenerateGraphicWithOutPalette(const rname, wname: string; const solid: boolean): boolean;
    function GenerateGraphicWithPalette(const rname, wname: string; const solid: boolean): boolean;
    function GenerateIS2(const rname, wname: string; const solid: boolean; const rightcrop: boolean; var aw, ah: integer): boolean;
    function GeneratePIX(const rname, wname: string; const solid: boolean): boolean;
    function GenerateGraphics: boolean;
    function GenerateSmallFont: boolean;
    function GenerateSprites: boolean;
    function GenerateSounds: boolean;
    procedure WritePK3Entry;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Convert(const fname: string);
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
  textures := nil;
  numflats := 0;
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
    if getlumpname(@l[i]) = lmp then
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
    if getlumpname(@l[i]) = lmp then
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
    fii := getlumpname(@lumps[ii]);
    fjj := getlumpname(@lumps[jj]);
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
    rname := getlumpname(@lumps[i]);
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

//begin
(*  i := FindLump(lumps, numlumps, 'WallBitmaps');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  position := lumps[i].position;
  f.Seek(position, sFromBeginning);
  f.Read(bnumlumps, SizeOf(word));

  blumps := mallocz(bnumlumps * SizeOf(radixbitmaplump_t));

  // Keep flats after loading levels
  numflats := bnumlumps + 1;
  markflats := mallocz(numflats);

  f.Read(bstart, SizeOf(integer));
  f.Seek(bstart, sFromBeginning);
  f.Read(blumps^, bnumlumps * SizeOf(radixbitmaplump_t));

  wadwriter.AddSeparator('P_START');

  mp := TDMemoryStream.Create;  // PNAMES
  mt := TDMemoryStream.Create;  // TEXTURE1

  psize := bnumlumps + 7; // 1 stub + 3x2 skies

  // PNAMES header
  mp.Write(psize, SizeOf(integer));

  // TEXTURE1 header
  psize := psize - 3; // 3 less - count for double skies
  mt.Write(psize, SizeOf(integer));
  psize := 0;
  for i := 0 to bnumlumps do
  begin
    psize := (bnumlumps + 4) * 4 + 4 + i * SizeOf(maptexture_t);
    mt.Write(psize, SizeOf(integer));
  end;
  // Skies have two patches
  for i := 1 to 3 do
  begin
    psize := psize + SizeOf(maptexture_t);
    if i > 1 then
      psize := psize + SizeOf(mappatch_t);
    mt.Write(psize, SizeOf(integer));
  end;

  // Stub texture
  buf := mallocz(32 * 32);
  SH_CreateDoomPatch(buf, 32, 32, true, p, size);
  stmp := SH_WALL_PREFIX + '0000';
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

  memfree(pointer(buf), 32 * 32);

  for i := 0 to bnumlumps - 1 do
  begin
    buf := malloc(blumps[i].width * blumps[i].height);

    f.Seek(blumps[i].position, sFromBeginning);
    f.Read(buf^, blumps[i].width * blumps[i].height);

    SH_CreateDoomPatch(buf, blumps[i].width, blumps[i].height, true, p, size);

    stmp := SH_WALL_PREFIX + IntToStrZFill(4, i + 1);
    wadwriter.AddData(stmp, p, size);
    memfree(p, size);

    // Save PNAMES entry
    c8 := stringtochar8(stmp);
    mp.Write(c8, 8);

    // Save TEXTURE1 entry
    ZeroMemory(@tex, SizeOf(maptexture_t));
    tex.name := c8;
    tex.width := blumps[i].width;
    tex.height := blumps[i].height;
    tex.patchcount := 1;
    tex.patches[0].patch := i + 1;
    mt.Write(tex, SizeOf(maptexture_t));

    texname := getlumpname(blumps[i]);
    // Save PK3ENTRY entry
    pk3entry.Add(stmp + '=' + texname);

    // Save Texture name
    textures.Add(texname);

    memfree(pointer(buf), blumps[i].width * blumps[i].height);
  end;

  extraskypatch.originx := 256;
  extraskypatch.originy := 0;
  for i := 1 to 3 do
  begin
    foundsky := FindLump(lumps, numlumps, 'MainEpisodeImage[' + itoa(i) + ']') >= 0;
    if foundsky then
      texname := 'MainEpisodeImage[' + itoa(i) + ']'
    else
      texname := 'MainEpisodeImage[1]';
    if ReadLump(lumps, numlumps, texname, pointer(buf), bufsize) then
    begin
      SH_CreateDoomSkyPatch(buf, p, size);

      stmp := 'RSKY' + itoa(i);
      wadwriter.AddData(stmp, p, size);

      // Save PNAMES entry
      c8 := stringtochar8(stmp);
      mp.Write(c8, 8);

      // Save TEXTURE1 entry
      ZeroMemory(@tex, SizeOf(maptexture_t));
      tex.name := stringtochar8('SKY' + itoa(i));
      tex.width := PSmallIntArray(p)[0] * 2;
      tex.height := PSmallIntArray(p)[1];
      memfree(p, size);
      tex.patchcount := 2;
      tex.patches[0].patch := bnumlumps + 2 * i - 1;
      mt.Write(tex, SizeOf(maptexture_t));

      // Save PK3ENTRY entry
      if foundsky then
        pk3entry.Add(stmp + '=' + texname);

      // Save Texture name
      textures.Add('SKY' + itoa(i));

      memfree(pointer(buf), bufsize);
    end;

    if foundsky then
      texname := 'FillEpisodeImage[' + itoa(i) + ']'
    else
      texname := 'FillEpisodeImage[1]';
    if ReadLump(lumps, numlumps, texname, pointer(buf), bufsize) then
    begin
      SH_CreateDoomSkyPatch(buf, p, size);

      stmp := 'RSKY' + itoa(i) + 'B';
      wadwriter.AddData(stmp, p, size);

      // Save PNAMES entry
      c8 := stringtochar8(stmp);
      mp.Write(c8, 8);

      // Save TEXTURE1 entry - extra patch
      memfree(p, size);
      extraskypatch.patch := bnumlumps + 2 * i;
      mt.Write(extraskypatch, SizeOf(mappatch_t));

      // Save PK3ENTRY entry
      if foundsky then
        pk3entry.Add(stmp + '=' + texname);

      memfree(pointer(buf), bufsize);
    end;
  end;

  wadwriter.AddSeparator('P_END');

  wadwriter.AddData(texture1, mt.Memory, mt.Size);
  wadwriter.AddData(pnames, mp.Memory, mp.Size);

  psize := 0;
  wadwriter.AddData('TEXTURE2', @psize, 4);

  mp.Free;
  mt.Free;

  memfree(pointer(blumps), bnumlumps * SizeOf(radixbitmaplump_t));
*)
//end;

function TSpeedToWADConverter.GenerateLevels(const scale: integer): boolean;

  function _makelevel(const prefix, prefix2: string; const mapname: string): boolean;
  var
    bufmap: pointer;
    bufmapsize: integer;
    bufsec: pointer;
    bufsecsize: integer;
    bufpath: pointer;
    bufpathsize: integer;
    ret1, ret2, ret3: boolean;
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
      wadwriter
    );

    memfree(pointer(bufmap), bufmapsize);
    memfree(pointer(bufsec), bufsecsize);
    memfree(pointer(bufpath), bufpathsize);
  end;

begin
  result := true;

  _makelevel('00', '00', 'MAP01');
  _makelevel('01', '01', 'MAP02');
  _makelevel('02', '02', 'MAP03');
  _makelevel('03', '03', 'MAP04');
  _makelevel('04', '04', 'MAP05');
  _makelevel('05', '05', 'MAP06');
  _makelevel('06', '06', 'MAP07');
  _makelevel('07', '07', 'MAP08');
end;

function TSpeedToWADConverter.GenerateCSVs(const path: string): boolean;
(*var
  i, j: integer;
  rlevel: pointer;
  rsize: integer;
  ret: boolean;

  procedure CreateAll(const prefix: string);
  var
    ii, jj, kk: integer;
    lsts: array[1..3,1..9] of TDStringList;
    l: TDStringList;
    finp: string;
    apath: string;
    header: string;
  begin
    apath := path;
    if apath <> '' then
      if apath[length(apath)] <> '\' then
        apath := apath + '\';
    header := '';
    for ii := 1 to 3 do
      for jj := 1 to 9 do
      begin
        lsts[ii, jj] := TDStringList.Create;
        finp := apath + '\' + 'E' + itoa(ii) + 'M' + itoa(jj) + '_' + prefix + '.txt';
        if fexists(finp) then
        begin
          lsts[ii, jj].LoadFromFile(finp);
          if lsts[ii, jj].Count > 0 then
          begin
            header := 'level' + ',' + lsts[ii, jj].Strings[0];
            lsts[ii, jj].Delete(0);
          end;
        end;
      end;
    l := TDStringList.Create;
    l.Add(header);
    for ii := 1 to 3 do
      for jj := 1 to 9 do
      begin
        for kk := 0 to lsts[ii, jj].Count - 1 do
          l.Add('E' + itoa(ii) + 'M' + itoa(jj) + ',' + lsts[ii, jj].Strings[kk]);
        lsts[ii, jj].Free;
      end;
    l.SaveToFile(apath + '\' + 'ALL' + '_' + prefix + '.txt');
    l.Free;
  end;
*)
begin
  result := true;
(*
  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      if ReadLump(lumps, numlumps, 'WorldData[' + itoa(i) +'][' + itoa(j) + ']', rlevel, rsize) then
      begin
        ret := SH_CreateRadixMapCSV('E' + itoa(i) + 'M' + itoa(j), path, rlevel, rsize);
        result := result or ret;
        memfree(rlevel, rsize);
      end;
    end;

  CreateAll('sectors');
  CreateAll('sprites');
  CreateAll('sprites2');
  CreateAll('sprites_movingsurface');
  CreateAll('sprites_newmovingsurface');
  CreateAll('things');
  CreateAll('walls');
  CreateAll('triggers');
  CreateAll('gridtable1');
  CreateAll('gridtable2');
*)
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
  end;

  // Create F_SKY1
  c := V_FindAproxColorIndex(@def_palL, 77 shl 16 + 179 shl 8 + 255);
  memset(buf, c, 64 * 64);
  wadwriter.AddData('F_SKY1', buf, 64 * 64);

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

  function GenerateMapBitmap(const smap: string): boolean;
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

  GenerateMapBitmap('00');
  GenerateMapBitmap('01');
  GenerateMapBitmap('02');
  GenerateMapBitmap('03');
  GenerateMapBitmap('04');
  GenerateMapBitmap('05');
  GenerateMapBitmap('06');
  GenerateMapBitmap('07');

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
begin
  lst := TDStringList.Create;
  for i := 0 to numlumps - 1 do
  begin
    rname := getlumpname(@lumps[i]);
    if strupper(RightStr(rname, 4)) = '.PIX' then
      lst.Add(rname);
  end;

  wadwriter.AddSeparator('G_START');

  for i := 0 to lst.Count - 1 do
  begin
    rname := lst.Strings[i];
    wname := LeftStr(rname, length(rname) - 4);

    GeneratePIX(rname, wname, true);
    pk3entry.Add(wname + '=' + rname);
  end;

  result := lst.Count > 0;

  lst.Clear;

  for i := 0 to numlumps - 1 do
  begin
    rname := getlumpname(@lumps[i]);
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

function TSpeedToWADConverter.GenerateSmallFont: boolean;
{var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  p: pointer;
  size: integer;
  fnt: string;
  idx: integer;
  ch: char;}
begin
(*  lump := FindLump(lumps, numlumps, 'SmallFont');
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  if lumps[lump].length <> 2222 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].length;
  buf := malloc(lumps[lump].length);
  f.Seek(lumps[lump].position, sFromBeginning);
  f.Read(buf^, bufsize);

  imginp := @PByteArray(buf)[8];
  SH_ColorReplace(imginp, 368, 6, 0, 254);
  SH_ColorReplace(imginp, 368, 6, 1, 254);
  SH_ColorReplace(imginp, 368, 6, 6, 254);
  SH_ColorReplace(imginp, 368, 6, 28, 254);

  SH_CreateDoomPatch(imginp, 368, 6, false, p, size, 0, 0);

  wadwriter.AddData('SMALLFNT', p, size);
  memfree(p, size);

  imgout := malloc(4 * 6);
  fnt := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.?[]!:;"`,-0123456789_';

  for ch := Chr(33) to Chr(128) do
    for idx := 1 to length(fnt) do
      if fnt[idx] <> ' ' then
        if fnt[idx] = ch then
        begin
          SH_BltImageBuffer(imginp, 368, 6, imgout, (idx - 1) * 5, idx * 5 - 2, 0, 5);
          SH_CreateDoomPatch(imgout, 4, 6, false, p, size, 0, 0);

          wadwriter.AddData('FNT_' + IntToStrzFill(3, Ord(fnt[idx])), p, size);
          memfree(p, size);
          fnt[idx] := ' ';
        end;

{  for i := 1 to length(fnt) do
  begin  // Not working!
    SH_BltImageBuffer(imginp, 368, 6, imgout, (i - 1) * 5, i * 5 - 2, 0, 5);
    SH_CreateDoomPatch(imgout, 4, 6, false, p, size, 0, 0);

    wadwriter.AddData('FNT_' + IntToStrzFill(3, Ord(fnt[i])), p, size);
    memfree(p, size);
  end;}

  memfree(pointer(imgout), 4 * 6);
  memfree(buf, bufsize);
*)
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

(*
var
  position: integer;
  bstart: integer;
  bnumlumps: word;
  blumps: Pradixbitmaplump_tArray;
  bl: Pradixbitmaplump_t;
  i, j: integer;
  buf: PByteArray;
  stmp: string;
  SPRITEINFO: array[0..1000] of spriteinfo_t;
  spr: Pspriteinfo_t;
  numsprinfo: integer;
  bmp: TRadixBitmap;
  rcol: radixcolumn_t;
  pc: Pradixcolumn_tArray;
  x, y, z: integer;
  p: pointer;
  size: integer;

  function remove_underline(const s: string): string;
  var
    ii: integer;
  begin
    result := '';
    for ii := 1 to length(s) do
      if s[ii] <> '_' then
        result := result + s[ii];
  end;

  procedure MakeNonRotatingSprite(const rprefix: string; const r_id: integer;
    const numframes: integer; const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true);
  var
    ii: integer;
  begin
    for ii := 1 to numframes do
    begin
      spr.rname := rprefix + '_' + itoa(ii);
      spr.dname := 'XR' + IntToStrzFill(2, r_id) + Chr(Ord('A') + ii - 1) + '0';
      spr.translation := trans;
      spr.xoffs := xofs;
      spr.yoffs := yofs;
      spr.centeroffs := cofs;
      spr.defaultoffs := defofs;
      inc(spr);
      inc(numsprinfo);
    end;
  end;

  procedure MakeRotatingSprite(const rprefix: string; const r_id: integer;
    const numframes: integer; const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true);
  var
    ii: integer;
    jj: integer;
  begin
    for ii := 1 to numframes do
      for jj := 1 to 8 do
      begin
        spr.rname := rprefix + '_' + itoa(jj + (ii - 1) * 8);
        spr.dname := 'XR' + IntToStrzFill(2, r_id) + Chr(Ord('A') + ii - 1) + itoa(jj);
        spr.translation := trans;
        spr.xoffs := xofs;
        spr.yoffs := yofs;
        spr.centeroffs := cofs;
        spr.defaultoffs := defofs;
        inc(spr);
        inc(numsprinfo);
      end;
  end;

  procedure MakeOneSprite(const rname: string; const r_id: integer;
    const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true);
  begin
    spr.rname := rname;
    spr.dname := 'XR' + IntToStrzFill(2, r_id) + 'A0';
    spr.translation := trans;
    spr.xoffs := xofs;
    spr.yoffs := yofs;
    spr.centeroffs := cofs;
    spr.defaultoffs := defofs;
    inc(spr);
    inc(numsprinfo);
  end;
*)

//begin
(*
  i := FindLump(lumps, numlumps, 'ObjectBitmaps');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  position := lumps[i].position;
  f.Seek(position, sFromBeginning);
  f.Read(bnumlumps, SizeOf(word));

  blumps := mallocz(bnumlumps * SizeOf(radixbitmaplump_t));

  f.Read(bstart, SizeOf(integer));
  f.Seek(bstart, sFromBeginning);
  f.Read(blumps^, bnumlumps * SizeOf(radixbitmaplump_t));

  wadwriter.AddSeparator('S_START');


  numsprinfo := 0;

  spr := @SPRITEINFO[0];

  // MT_FULLSHIED
  MakeNonRotatingSprite('FullShield', _MTRX_FULLSHIED, 3);

  // MT_FULLENERGY
  MakeNonRotatingSprite('FullEnergy', _MTRX_FULLENERGY, 3);

  // MT_SUPERCHARGE
  MakeNonRotatingSprite('SuperCharge', _MTRX_SUPERCHARGE, 3);

  // MT_RAPIDSHIELD
  MakeNonRotatingSprite('RapidShld.Recharger', _MTRX_RAPIDSHIELD, 3);

  // MT_RAPIDENERGY
  MakeNonRotatingSprite('RapidEngy.Energizer', _MTRX_RAPIDENERGY, 3);

  // MT_MANEUVERJETS
  MakeNonRotatingSprite('ManeuveringJets', _MTRX_MANEUVERJETS, 3);

  // MT_NIGHTVISION
  MakeNonRotatingSprite('NightVisionSys', _MTRX_NIGHTVISION, 3);

  // MT_PLASMABOMB
  MakeNonRotatingSprite('PlasmaBomb', _MTRX_PLASMABOMB, 3);

  // MT_ALDS
  MakeNonRotatingSprite('A.L.D.S', _MTRX_ALDS, 3);

  // MT_ULTRASHIELDS
  MakeNonRotatingSprite('GodMode', _MTRX_ULTRASHIELDS, 3);

  // MT_LEVEL2NEUTRONCANNONS
  MakeNonRotatingSprite('LaserCannons', _MTRX_LEVEL2NEUTRONCANNONS, 3);

  // MT_STANDARDEPC
  MakeNonRotatingSprite('ExplosiveCannon', _MTRX_STANDARDEPC, 3);

  // MT_LEVEL1PLASMASPREADER
  MakeNonRotatingSprite('PlasmaCannon', _MTRX_LEVEL1PLASMASPREADER, 3);

  // MT_NUCLEARCAPABILITY
  MakeNonRotatingSprite('NuclearWeaponSystem', _MTRX_NUCLEARCAPABILITY, 3);

  // MT_MISSILECAPABILITY
  MakeNonRotatingSprite('SeekingMissileSystem', _MTRX_MISSILECAPABILITY, 3);

  // MT_TORPEDOCAPABILITY
  MakeNonRotatingSprite('PhaseTorpedoSystem', _MTRX_TORPEDOCAPABILITY, 3);

  // MT_GRAVITYDEVICE
  MakeNonRotatingSprite('GravityWaveDevice', _MTRX_GRAVITYDEVICE, 3);

  // MT_250SHELLS
  MakeNonRotatingSprite('250ShellPack', _MTRX_250SHELLS, 3);

  // MT_500SHELLS
  MakeNonRotatingSprite('500ShellPack', _MTRX_500SHELLS, 3);

  // MT_1000SHELLS
  MakeNonRotatingSprite('1000ShellPack', _MTRX_1000SHELLS, 3);

  // MT_4NUKES
  MakeNonRotatingSprite('5Nukes', _MTRX_4NUKES, 3);

  // MT_10NUKES
  MakeNonRotatingSprite('25Nukes', _MTRX_10NUKES, 3);

  // MT_15TORPEDOES
  MakeNonRotatingSprite('10Torps', _MTRX_15TORPEDOES, 3);

  // MT_75TORPEDOES
  MakeNonRotatingSprite('50Torps', _MTRX_75TORPEDOES, 3);

  // MT_20MISSILES
  MakeNonRotatingSprite('20Missiles', _MTRX_20MISSILES, 3);

  // MT_50MISSILES
  MakeNonRotatingSprite('50Missiles', _MTRX_50MISSILES, 3);

  // MT_BOOMPACK
  MakeNonRotatingSprite('BoomPack', _MTRX_BOOMPACK, 3);

  // MT_BIOMINE1
  MakeNonRotatingSprite('WeakBiomine', _MTRX_BIOMINE1, 3);

  // MT_BIOMINE2
  MakeNonRotatingSprite('PowerBiomine', _MTRX_BIOMINE2, 3);

  // MT_ALIENFODDER
  MakeRotatingSprite('AlienFodder', _MTRX_ALIENFODDER, 3, nil, 68, 101, false, false);

  // MT_DEFENCEDRONE_STUB1
  MakeRotatingSprite('DroneB', _MTRX_DEFENCEDRONE_STUB1, 1, nil, 63, 67, false, false);

  // MT_DEFENCEDRONE_STUB2
  MakeRotatingSprite('DroneB', _MTRX_DEFENCEDRONE_STUB2, 1, nil, 63, 67, false, false);

  // MT_BATTLEDRONE1
  MakeRotatingSprite('DroneA', _MTRX_BATTLEDRONE1, 1, nil, 91, 50, false, false);

  // MT_MISSILEBOAT
  MakeRotatingSprite('DroneC', _MTRX_MISSILEBOAT, 1, nil, 83, 68, false, false);

  // MT_STORMBIRDHEAVYBOMBER
  MakeRotatingSprite('HeavyFighter', _MTRX_STORMBIRDHEAVYBOMBER, 1, nil, 86, 54, false, false);

  // MT_SKYFIREASSULTFIGHTER
  MakeRotatingSprite('LightAssault', _MTRX_SKYFIREASSULTFIGHTER, 1, nil, 62, 51, false, false);

  // MT_SPAWNER
  MakeRotatingSprite('Spawner', _MTRX_SPAWNER, 1, nil, 146, 154, false, false);

  // MT_EXODROID
  MakeRotatingSprite('ExoDroid', _MTRX_EXODROID, 3, nil, 113, 188, false, false);

  // MT_SNAKEDEAMON
  MakeNonRotatingSprite('SnakeDemonBadassHead', _MTRX_SNAKEDEAMON, 3, nil, 57, 109, false, false);

  // MT_MINE
  MakeNonRotatingSprite('Airmine', _MTRX_MINE, 3, nil, 51, 93, false, false);

  // MT_ROTATINGRADAR1
  MakeRotatingSprite('RadarDish', _MTRX_ROTATINGRADAR1, 1, nil, 53, 91, false, false);

  // MT_SHIELDGENERATOR1
  MakeNonRotatingSprite('ShieldGen', _MTRX_SHIELDGENERATOR1, 3, nil, 34, 135, false, false);

  // MT_SECONDCOOLAND1
  MakeNonRotatingSprite('SecondCoolant', _MTRX_SECONDCOOLAND1, 1, nil, 64, 183, false, false);

  // MT_BIOMECHUP
  MakeOneSprite('BioMech9', _MTRX_BIOMECHUP, nil, 45, 89, false, false);

  // MT_ENGINECORE
  MakeNonRotatingSprite('EngineCore', _MTRX_ENGINECORE, 1, nil, 59, 178, false, false);

  // MT_DEFENCEDRONE1
  MakeRotatingSprite('DroneB', _MTRX_DEFENCEDRONE1, 1, nil, 63, 67, false, false);

  // MT_BATTLEDRONE2
  MakeRotatingSprite('DroneA', _MTRX_BATTLEDRONE2, 1, nil, 91, 50, false, false);

  // MT_SKYFIREASSULTFIGHTER2
  MakeRotatingSprite('LightAssault', _MTRX_SKYFIREASSULTFIGHTER2, 1, nil, 62, 51, false, false);

  // MT_SKYFIREASSULTFIGHTER3
  MakeRotatingSprite('LightAssault', _MTRX_SKYFIREASSULTFIGHTER3, 1, nil, 62, 51, false, false);

  // MT_SKYFIREASSULTFIGHTER4
  MakeRotatingSprite('LightAssault', _MTRX_SKYFIREASSULTFIGHTER4, 1, nil, 62, 51, false, false);

  // MT_BIOMECH
  MakeRotatingSprite('BioMech', _MTRX_BIOMECH, 1, nil, 73, 60, false, false);

  // MT_DEFENCEDRONE2
  MakeRotatingSprite('DroneB', _MTRX_DEFENCEDRONE2, 1, nil, 63, 67, false, false);

  bmp := TRadixBitmap.Create;

  for j := 0 to numsprinfo - 1 do
  begin
    spr := @SPRITEINFO[j];
    bl := nil;
    for i := 0 to bnumlumps - 1 do
      if getlumpname(blumps[i]) = spr.rname then
      begin
        bl := @blumps[i];
        break;
      end;

    if bl = nil then
    begin
      spr.rname := remove_underline(spr.rname);
      for i := 0 to bnumlumps - 1 do
        if getlumpname(blumps[i]) = spr.rname then
        begin
          bl := @blumps[i];
          break;
        end;
    end;

    if bl = nil then
      Continue;

    f.Seek(bl.position + (bl.width - 1) * SizeOf(radixcolumn_t), sFromBeginning);
    f.Read(rcol, SizeOf(radixcolumn_t));
    f.Seek(bl.position, sFromBeginning);

    buf := malloc(rcol.offs + rcol.size);
    f.Read(buf^, rcol.offs + rcol.size);

    bmp.width := bl.width;
    bmp.height := bl.height;

    bmp.Clear(254);

    pc := Pradixcolumn_tArray(buf);

    for x := 0 to bl.width - 1 do
      for y := pc[x].start to pc[x].start + pc[x].size - 1 do
      begin
        z := pc[x].offs - pc[x].start + y;
        z := buf[z];
        if z < 255 then
          bmp.Pixels[x, y] := z;
      end;

    if spr.translation <> nil then
      bmp.ApplyTranslationTable(spr.translation);

    if (spr.dname = 'XR38B1') or (spr.dname = 'XR38B2') or (spr.dname = 'XR38B8') then
    begin
      for x := 0 to bmp.width - 1 do
        if bmp.Pixels[x, 0] = 0 then
          bmp.Pixels[x, 0] := 254;
    end
    else if (spr.dname = 'XR38A5') or (spr.dname = 'XR38A6') or (spr.dname = 'XR38C4') or (spr.dname = 'XR38C5') then
    begin
      for x := 0 to bmp.width - 1 do
        if bmp.Pixels[x, bmp.height - 1] = 0 then
          bmp.Pixels[x, bmp.height - 1] := 254;
    end;

    if spr.defaultoffs then
      SH_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size)
    else if spr.centeroffs then
      SH_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size, bl.width div 2, bl.height div 2)
    else
      SH_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size, spr.xoffs, spr.yoffs);

    stmp := spr.dname;

    wadwriter.AddData(stmp, p, size);

    memfree(pointer(buf), rcol.offs + rcol.size);
    memfree(p, size);
  end;

  bmp.Free;

  wadwriter.AddSeparator('S_END');

  memfree(pointer(blumps), bnumlumps * SizeOf(radixbitmaplump_t));
*)
//end;

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
    rname := getlumpname(@lumps[i]);
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

procedure TSpeedToWADConverter.WritePK3Entry;
begin
  if pk3entry = nil then
    exit;
  if pk3entry.Count = 0 then
    exit;

  wadwriter.AddString(S_SPEEDINF, pk3entry.Text);
end;

procedure TSpeedToWADConverter.Convert(const fname: string);
begin
  if not fexists(fname) then
    exit;

  Clear;

  f := TFile.Create(fname, fOpenReadOnly);
  wadwriter := TWadWriter.Create;
  pk3entry := TDStringList.Create;
  textures := TDStringList.Create;

  ReadHeader;
  ReadDirectory;
  GeneratePalette;
  GenerateTranslationTables;
  GenerateTextures('PNAMES', 'TEXTURE1');
  GenerateLevels(4);
  GenerateFlats;
  GenerateMapFlats(false);
  GenerateGraphics;
  GenerateSmallFont;
  GenerateSprites;
  GenerateSounds;
  WritePK3Entry;
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
    cnv.Convert(fname);
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
    cnv.Convert(fin);
    cnv.SavetoFile(fout);
  finally
    cnv.Free;
  end;
end;

end.

