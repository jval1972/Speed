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

unit speed_level;

interface

uses
  d_delphi,
  w_wadwriter;

function SH_CreateDoomLevel(const prefix: string; const levelname: string;
  const bufmap: pointer; const bufmapsize: integer;
  const bufsec: pointer; const bufsecsize: integer;
  const bufpath: pointer; const bufpathsize: integer;
  const xyscale: integer; const wadwriter: TWadWriter): boolean;

implementation

uses
  doomdata,
  r_defs,
  sc_engine,
  speed_defs,
  speed_things,
  w_wad;

type
  speedvertex_t = record
    x, y: integer;
  end;
  speedvertex_p = ^speedvertex_t;
  speedvertex_tArray = packed array[0..$FFF] of speedvertex_t;
  Pspeedvertex_tArray = ^speedvertex_tArray;

  speedline_t = record
    v1, v2: integer;
    texture: string[24];
    back: integer;
  end;
  speedline_p = ^speedline_t;
  speedline_tArray = packed array[0..$FFF] of speedline_t;
  Pspeedline_tArray = ^speedline_tArray;

  speedsector_t = record
    numlines: integer;
    flags: integer;
    firstline: integer;
  end;
  speedsector_p = ^speedsector_t;
  speedsector_tArray = packed array[0..$FFF] of speedsector_t;
  Pspeedsector_tArray = ^speedsector_tArray;

  speedDiskMap_t = packed record
    version: word;
    reserved: word;
    tiles: packed array[0..63, 0..63] of word;
    angles: packed array[0..63, 0..63] of byte;
  end;
  speedDiskMap_p = ^speedDiskMap_t;

  speedthing_t = packed record
    x, y: word;
    angle: word;
    thingtype: word;
  end;
  speedthing_p = ^speedthing_t;
  speedthing_tArray = packed array[0..$FFF] of speedthing_t;
  Pspeedthing_tArray = ^speedthing_tArray;

  speedpathpoint_t = packed record
    x, y: LongWord;
    dir: LongWord; //word dir;
    speed: integer;
    ncars: integer;
  end;

  mapspeedpathpoint_t = packed record
    x, y: LongWord;
    dir: LongWord; //word dir;
    speed: integer;
  end;
  mapspeedpathpoint_p = ^mapspeedpathpoint_t;
  mapspeedpathpoint_tArray = packed array[0..$FFF] of mapspeedpathpoint_t;
  Pmapspeedpathpoint_tArray = ^mapspeedpathpoint_tArray;

const
  PATHSIGNATURE = $48544150; // "PATH"

const
  THNF_SOLID = $01;          // Things with this flag collide each other.
  THNF_VECTOR = $80;         // Things with this flag have a vector visual.

  THNT_PLAYER   = $0100;
  THNT_CAR      = $0500;
  THNT_OBSTACLE = $0600;
  THNT_SPARKS   = $1000;
  THNT_SMOKE    = $1100;
  THNT_RACEPOS  = $1200;
  THNT_HUMANPOS = $1300;

const
    FLSF_VECTOR  = $0001;
    FLSF_NOSCALE = $0002;

    // Mesh flags (in O3DM_Object).
    FLOF_HASTIRES = $0001;

function SH_CreateDoomLevel(const prefix: string; const levelname: string;
  const bufmap: pointer; const bufmapsize: integer;
  const bufsec: pointer; const bufsecsize: integer;
  const bufpath: pointer; const bufpathsize: integer;
  const xyscale: integer; const wadwriter: TWadWriter): boolean;
var
  doomthings: Pmapthing_tArray;
  numdoomthings: integer;
  doomlinedefs: Pmaplinedef_tArray;
  numdoomlinedefs: integer;
  doomsidedefs: Pmapsidedef_tArray;
  numdoomsidedefs: integer;
  doomvertexes: Pmapvertex_tArray;
  numdoomvertexes: integer;
  doomsectors: Pmapsector_tArray;
  numdoomsectors: integer;
  sec1: integer;

  procedure AddDoomThingToWad(const x, y: integer; const angle: smallint; const mtype: word; const options: smallint);
  var
    mthing: Pmapthing_t;
  begin
    realloc(pointer(doomthings), numdoomthings * SizeOf(mapthing_t), (numdoomthings + 1) * SizeOf(mapthing_t));
    mthing := @doomthings[numdoomthings];

    mthing.x := xyscale * x;
    mthing.y := xyscale * y;

    mthing.angle := angle;
    mthing._type := mtype;
    mthing.options := options;

    inc(numdoomthings);
  end;

  function AddSectorToWAD(const floorheight, ceilingheight: integer;
    const floortexture, ceilingtexture: string): integer;
  var
    dsec: Pmapsector_t;
  begin
    realloc(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t), (numdoomsectors  + 1) * SizeOf(mapsector_t));
    //Create classic map
    dsec := @doomsectors[numdoomsectors];
    dsec.floorheight := floorheight;
    dsec.ceilingheight := ceilingheight;
    dsec.floorpic := stringtochar8(floortexture);
    dsec.ceilingpic := stringtochar8(ceilingtexture);
    dsec.lightlevel := 192;
    dsec.special := 0;
    dsec.tag := 0;

    result := numdoomsectors;
    inc(numdoomsectors);
  end;

  function AddVertexToWAD(const x, y: smallint): integer;
  var
    ii: integer;
    xx, yy: integer;
  begin
    xx := x * xyscale;
    yy := y * xyscale;
    for ii := 0 to numdoomvertexes - 1 do
      if (doomvertexes[ii].x = xx) and (doomvertexes[ii].y = yy) then
      begin
        result := ii;
        exit;
      end;

    realloc(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t), (numdoomvertexes  + 1) * SizeOf(mapvertex_t));
    doomvertexes[numdoomvertexes].x := xx;
    doomvertexes[numdoomvertexes].y := yy;

    result := numdoomvertexes;
    inc(numdoomvertexes);
  end;

  function AddSidedefToWAD(const toptex, bottomtex, midtex: string;
    const sector: smallint): integer;
  var
    pside: Pmapsidedef_t;
  begin
    realloc(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t), (numdoomsidedefs  + 1) * SizeOf(mapsidedef_t));
    pside := @doomsidedefs[numdoomsidedefs];
    pside.textureoffset := 0;
    pside.rowoffset := 0;
    if toptex = '' then
      pside.toptexture := stringtochar8('-')
    else
      pside.toptexture := stringtochar8(toptex);
    if bottomtex = '' then
      pside.bottomtexture := stringtochar8('-')
    else
      pside.bottomtexture := stringtochar8(bottomtex);
    if midtex = '' then
      pside.midtexture := stringtochar8('-')
    else
      pside.midtexture := stringtochar8(midtex);
    pside.sector := sector;

    result := numdoomsidedefs;
    inc(numdoomsidedefs);
  end;

  function AddLineToWAD(const x1, y1, x2, y2: integer): integer;
  var
    ii: integer;
    v1, v2: integer;
  begin
    v1 := AddVertexToWAD(x1, y1);
    v2 := AddVertexToWAD(x2, y2);
    for ii := 0 to numdoomlinedefs - 1 do
    begin
      if (doomlinedefs[ii].v1 = v1) and (doomlinedefs[ii].v2 = v2) then
      begin
        result := ii;
        exit;
      end;
      if (doomlinedefs[ii].v1 = v2) and (doomlinedefs[ii].v2 = v1) then
      begin
        result := ii;
        exit;
      end;
    end;

    realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
    doomlinedefs[numdoomlinedefs].v1 := v1;
    doomlinedefs[numdoomlinedefs].v2 := v2;
    doomlinedefs[numdoomlinedefs].flags := ML_MAPPED;
    doomlinedefs[numdoomlinedefs].special := 0;
    doomlinedefs[numdoomlinedefs].tag := 0;
    doomlinedefs[numdoomlinedefs].sidenum[0] := -1;
    doomlinedefs[numdoomlinedefs].sidenum[1] := -1;
    result := numdoomlinedefs;
    inc(numdoomlinedefs);
  end;

  procedure _do_main_sector;
  var
    l1, l2, l3, l4: integer;
  begin
    sec1 := AddSectorToWAD(0, 256, 'FMAP' + prefix, 'F_SKY1');

    l1 := AddLineToWAD(0, 0, 0, 4096);
    l2 := AddLineToWAD(0, 4096, 4096, 4096);
    l3 := AddLineToWAD(4096, 4096, 4096, 0);
    l4 := AddLineToWAD(4096, 0, 0, 0);

    doomlinedefs[l1].sidenum[0] := AddSidedefToWAD('', '', '', sec1);
    doomlinedefs[l2].sidenum[0] := AddSidedefToWAD('', '', '', sec1);
    doomlinedefs[l3].sidenum[0] := AddSidedefToWAD('', '', '', sec1);
    doomlinedefs[l4].sidenum[0] := AddSidedefToWAD('', '', '', sec1);
  end;

  procedure _do_dat_file;
  var
    ii: integer;
    speedthings: Pspeedthing_tArray;
    numspeedthings: integer;
    th: speedthing_p;
    tid: integer;
    ang: integer;
    x, y: integer;
  begin
    speedthings := @PByteArray(bufmap)[SizeOf(speedDiskMap_t)];
    numspeedthings := (bufmapsize - SizeOf(speedDiskMap_t)) div SizeOf(speedthing_t);

//    if prefix = '00' then
//      logtofile('F:\DelphiDoom_Release\SPEEDHASTE\data_csv\speed_things.txt', 'map;thing_id;x;y;angle;type;type2' + #13#10);
    for ii := 0 to numspeedthings - 1 do
    begin
      th := @speedthings[ii];
      tid := th.thingtype;
{      if tid > 240 shl 8 then
        tid := tid - 240 shl 8
      else
        tid := ((tid and $FF00) shr 4) + (tid and $0F);}
      if tid > 240 shl 8 then
        tid := tid and $FF00 shr 8
      else
        tid := ((tid and $FF00) shr 4) + (tid and $0F);
//      logtofile('F:\DelphiDoom_Release\SPEEDHASTE\data_csv\speed_things.txt', 'map' + prefix + ';' + 'thing' + itoa(ii) + ';' + itoa(th.x) + ';' + itoa(th.y) + ';' + itoa(th.angle) + ';' + itoa(th.thingtype) + ';' + itoa(tid) + #13#10);
      ang := 360 - round((th.angle  / 65536) * 360);

      if ang < 0 then
        ang := ang + 360;
      x := (4096 - th.y);
      y := (4096 - th.x);
      AddDoomThingToWad(x, y, ang, tid, 7);
    end;
    // Add a player start
    for ii := 0 to numdoomthings - 1 do
      if doomthings[ii]._type = 241 then
      begin
        doomthings[ii]._type := 1;
        break;
      end;
  end;

  procedure _do_pth_file;
  var
    ii, npaths: integer;
    pA: Pmapspeedpathpoint_tArray;
    ang: integer;
    x, y: integer;
  begin
    if PLongWord(bufpath)^ <> PATHSIGNATURE then
      exit;

//    if prefix = '00' then
//      logtofile('F:\DelphiDoom_Release\SPEEDHASTE\data_csv\speed_paths.txt', 'map;id;x;y;angle;speed' + #13#10);
    npaths := PSmallIntArray(bufpath)[98];
    pA := @(PByteArray(bufpath)[$100]);
    for ii := 0 to npaths - 1 do
    begin
//      logtofile('F:\DelphiDoom_Release\SPEEDHASTE\data_csv\speed_paths.txt', 'map' + prefix + ';' + itoa(ii) + ';' + itoa(pA[ii].x) + ';' + itoa(pA[ii].y) + ';' + itoa(pA[ii].dir) + ';' + itoa(pA[ii].speed) + #13#10);
      ang := round((pA[ii].dir / 65536) * 360) - 90;
      if ang < 0 then
        ang := ang + 360;

      x := (4096 - (pA[ii].y div 1048576));
      y := (4096 - (pA[ii].x div 1048576));

      AddDoomThingToWad(x, y, ang, _SHTH_PATH, 7);
    end;
  end;

  procedure _do_sec_file;
  var
    ii: integer;
    speedvertexes: Pspeedvertex_tArray;
    numspeedvertexes: integer;
    speedlines: Pspeedline_tArray;
    numspeedlines: integer;
    speedsectors: Pspeedsector_tArray;
    numspeedsectors: integer;
    sc: TScriptEngine;
    stmp: string;
    token: string;
    ch: char;
    n, linecnt: integer;
    ll: integer;
    v1, v2: integer;
  begin
    stmp := '';
    for ii := 0 to bufsecsize - 1 do
    begin
      ch := Chr(PByteArray(bufsec)[ii]);
      if ch = #0 then
        ch := ' ';
      if (ch = '"') and (ii > 0) then
        if Chr(PByteArray(bufsec)[ii - 1]) = '"' then
          stmp := stmp + '-';
      stmp := stmp + ch;
    end;

    sc := TScriptEngine.Create(stmp);

    sc.MustGetInteger;
    numspeedvertexes := sc._Integer;
    speedvertexes := mallocz(numspeedvertexes * SizeOf(speedvertex_t));

    sc.MustGetInteger;
    numspeedsectors := sc._Integer;
    speedsectors := mallocz(numspeedsectors * SizeOf(speedsector_t));

    sc.MustGetInteger;
    numspeedlines := sc._Integer;
    speedlines := mallocz(numspeedlines * SizeOf(speedline_t));

    sc.MustGetString; // Vertices
    for ii := 0 to numspeedvertexes - 1 do
    begin
      sc.MustGetString;
      token := sc._String;
      speedvertexes[ii].y := 4096 - atoi(token) div 16;
      sc.MustGetString;
      token := sc._String;
      speedvertexes[ii].x := 4096 - atoi(token) div 16;
    end;

    sc.MustGetString; // Sectors
    linecnt := 0;
    for ii := 0 to numspeedsectors - 1 do
    begin
      sc.MustGetString;
      token := sc._String;
      speedsectors[ii].numlines := atoi(token); // Number of lines of sector
      sc.MustGetString;
      token := sc._String;
      speedsectors[ii].flags := atoi(token);
      speedsectors[ii].firstline := linecnt;
      for n := 0 to speedsectors[ii].numlines - 1 do
      begin
        sc.MustGetString;
        token := sc._String;
        speedlines[linecnt].v1 := atoi(token);
        sc.MustGetString;
        token := sc._String;
        speedlines[linecnt].v2 := atoi(token);
        sc.MustGetString;
        speedlines[linecnt].texture := sc._String;
        sc.MustGetString;
        token := sc._String;
        speedlines[linecnt].back := atoi(token);
        inc(linecnt);
      end;
    end;

    for ii := 0 to numspeedlines - 1 do
    begin
      if speedlines[ii].texture <> '-' then
      begin
        v1 := speedlines[ii].v1;
        v2 := speedlines[ii].v2;
        ll := AddLineToWAD(speedvertexes[v1].x, speedvertexes[v1].y, speedvertexes[v2].x, speedvertexes[v2].y);
        doomlinedefs[ll].sidenum[0] := AddSidedefToWAD('', '', SH_WALL_PREFIX + speedlines[ii].texture, sec1);
        doomlinedefs[ll].sidenum[1] := AddSidedefToWAD('', '', SH_WALL_PREFIX + speedlines[ii].texture, sec1);
        doomlinedefs[ll].flags := ML_BLOCKING or ML_TWOSIDED or ML_DONTPEGBOTTOM;
      end;
    end;

    memfree(pointer(speedvertexes), numspeedvertexes * SizeOf(speedvertex_t));
    memfree(pointer(speedsectors), numspeedsectors * SizeOf(speedsector_t));
    memfree(pointer(speedlines), numspeedlines * SizeOf(speedline_t));

    sc.Free;
  end;

begin
  doomthings := nil;
  numdoomthings := 0;
  doomlinedefs := nil;
  numdoomlinedefs := 0;
  doomsidedefs := nil;
  numdoomsidedefs := 0;
  doomvertexes := nil;
  numdoomvertexes := 0;
  doomsectors := nil;
  numdoomsectors := 0;

  _do_main_sector;
  _do_dat_file;
  _do_pth_file;
  _do_sec_file;

  wadwriter.AddSeparator(levelname);
  wadwriter.AddData('THINGS', doomthings, numdoomthings * SizeOf(mapthing_t));
  wadwriter.AddData('LINEDEFS', doomlinedefs, numdoomlinedefs * SizeOf(maplinedef_t));
  wadwriter.AddData('SIDEDEFS', doomsidedefs, numdoomsidedefs * SizeOf(mapsidedef_t));
  wadwriter.AddData('VERTEXES', doomvertexes, numdoomvertexes * SizeOf(mapvertex_t));
  wadwriter.AddSeparator('SEGS');
  wadwriter.AddSeparator('SSECTORS');
  wadwriter.AddSeparator('NODES');
  wadwriter.AddData('SECTORS', doomsectors, numdoomsectors * SizeOf(mapsector_t));
  wadwriter.AddSeparator('REJECT');
  wadwriter.AddSeparator('BLOCKMAP');
  wadwriter.AddData('PATH', @(PByteArray(bufpath)[$100]), bufpathsize - $100);

  // Free Doom data
  memfree(pointer(doomthings), numdoomthings * SizeOf(mapthing_t));
  memfree(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t));
  memfree(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t));
  memfree(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t));
  memfree(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t));

  result := true;
end;

end.
