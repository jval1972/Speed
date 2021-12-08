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

unit r_draw;

interface

uses
  d_delphi,
  doomdef,
  r_defs,
// Needs access to LFB (guess what).
  v_video;

procedure R_VideoErase(const ofs: integer; const count: integer);

procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);

procedure R_PlayerViewBlanc(const black: byte);

procedure R_InitBuffer(width, height: integer);

// Initialize color translation tables,
//  for player rendering etc.
procedure R_InitTranslationTables;

// If the view size is not full screen, draws a border around it.
procedure R_DrawViewBorder;

// Draw disk busy patch
procedure R_DrawDiskBusy;

var
  displaydiskbusyicon: boolean = true;

  translationtables: PByteArray;
  dc_translation: PByteArray;

  viewwidth: integer;
  viewheight: integer;
  scaledviewwidth: integer;

  viewwindowx: integer;
  viewwindowy: integer;

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
//

var
  columnofs: array[0..MAXWIDTH - 1] of integer;

type
  crange_idx_e = (
    CR_BRICK,   //0
    CR_TAN,     //1
    CR_GRAY,    //2
    CR_GREEN,   //3
    CR_BROWN,   //4
    CR_GOLD,    //5
    CR_RED,     //6
    CR_BLUE,    //7
    CR_ORANGE,  //8
    CR_YELLOW,  //9
    CR_BLUE2,   //10
    CR_LIMIT    //11
  );

var
  colorregions: array[0..Ord(CR_LIMIT) - 1] of PByteArray;
{$IFDEF OPENGL}
  diskbusy_height: integer = 0;
{$ENDIF}

implementation

uses
  am_map,
  m_argv,
  w_wad,
  z_zone,
  st_stuff,
  i_system,
{$IFDEF OPENGL}
  gl_render,
{$ELSE}
  r_hires,
{$ENDIF}
// State.
  doomstat,
  v_data;

//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//
procedure R_InitTranslationTables;
var
  i, j: integer;
  lump: integer;
begin
  translationtables := Z_Malloc(256 * 3 + 255, PU_STATIC, nil);
  translationtables := PByteArray((integer(translationtables) + 255 ) and (not 255));

  // translate just the 16 green colors
  for i := 0 to 255 do
    if (i >= $70) and (i <= $7f) then
    begin
      // map green ramp to gray, brown, red
      translationtables[i] := $60 + (i and $f);
      translationtables[i + 256] := $40 + (i and $f);
      translationtables[i + 512] := $20 + (i and $f);
    end
    else
    begin
      // Keep all other colors as is.
      translationtables[i] := i;
      translationtables[i + 256] := i;
      translationtables[i + 512] := i;
    end;

  // JVAL: Initialize ColorRegions
  lump := W_CheckNumForName('CR_START');
  for i := 0 to Ord(CR_LIMIT) - 1 do
    colorregions[i] := Z_Malloc(256, PU_STATIC, nil);
  if lump = -1 then
  begin
    printf(#13#10); // JVAL: keep stdout happy...
    I_Warning('Colormap extensions not found, using default translations'#13#10);
    for i := 0 to Ord(CR_LIMIT) - 1 do
      for j := 0 to 255 do
        colorregions[i][j] := j;
  end
  else
  begin
    for i := 0 to Ord(CR_LIMIT) - 1 do
    begin
      inc(lump);
      W_ReadLump(lump, colorregions[i]);
    end;
  end;

end;

//
// R_InitBuffer
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
procedure R_InitBuffer(width, height: integer);
var
  i: integer;
begin
  // Handle resize,
  //  e.g. smaller view windows
  //  with border and/or status bar.
  viewwindowx := (SCREENWIDTH - width) div 2;

  // Column offset. For windows.
  for i := 0 to width - 1 do
    columnofs[i] := viewwindowx + i;

  viewwindowy := 0;
end;

procedure R_ScreenBlanc(const scn: integer; const black: byte = 0);
var
  x, i: integer;
begin
  x := viewwindowy * SCREENWIDTH + viewwindowx;
  for i := 0 to viewheight - 1 do
  begin
    R_VideoBlanc(scn, x, scaledviewwidth, black);
    inc(x, SCREENWIDTH);
  end;
end;


//
// Copy a screen buffer.
//
procedure R_VideoErase(const ofs: integer; const count: integer);
var
  i: integer;
  src: PByte;
  dest: PLongWord;
begin
  // LFB copy.
  // This might not be a good idea if memcpy
  //  is not optiomal, e.g. byte by byte on
  //  a 32bit CPU, as GNU GCC/Linux libc did
  //  at one point.
{$IFNDEF OPENGL}
  if videomode = vm32bit then
  begin
{$ENDIF}
    src := PByte(integer(screens[SCN_BG]) + ofs);
    dest := @screen32[ofs];
    for i := 1 to count do
    begin
      dest^ := videopal[src^];
      inc(dest);
      inc(src);
    end;
{$IFNDEF OPENGL}
  end
  else
    memcpy(Pointer(integer(screens[SCN_FG]) + ofs), Pointer(integer(screens[SCN_BG]) + ofs), count);
{$ENDIF}
end;

procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);
var
  start: PByte;
  lstrart: PLongWord;
  i: integer;
  lblack: LongWord;
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scn = SCN_FG) then
  begin
    lblack := curpal[black];
    lstrart := @screen32[ofs];
    for i := 0 to count - 1 do
    begin
      lstrart^ := lblack;
      inc(lstrart);
    end;
  end
  else
  begin
    start := @screens[scn][ofs];
    memset(start, black, count);
  end;
end;

procedure R_PlayerViewBlanc(const black: byte);
begin
  R_ScreenBlanc(SCN_FG, black);
end;

//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//
procedure R_DrawViewBorder;
begin
  if scaledviewwidth < SCREENWIDTH then
    if (gamestate = GS_LEVEL) and (amstate <> am_only) then
      V_CopyScreenTransparent(SCN_BG, SCN_FG);
end;

var
  disklump: integer = -2;
  diskpatch: Ppatch_t = nil;

procedure R_DrawDiskBusy;
begin
  {$IFDEF OPENGL}
  diskbusy_height := 0;
  {$ENDIF}
  if not displaydiskbusyicon then
    exit;

// Draw disk busy patch
  if disklump = -2 then
  begin
    if M_CheckParmCDROM then
      disklump := W_CheckNumForName('STCDROM');
    if disklump < 0 then
      disklump := W_CheckNumForName('STDISK');
    if disklump >= 0 then
      diskpatch := W_CacheLumpNum(disklump, PU_STATIC)
    else
    begin
//      I_Warning('Disk busy lump not found!'#13#10);
      exit;
    end;
  end;

  if diskpatch <> nil then
    V_DrawPatch(318 - diskpatch.width, 2, SCN_FG,
      diskpatch, true);
  {$IFDEF OPENGL}
  if diskpatch <> nil then
    diskbusy_height := diskpatch.height + 3;
  {$ENDIF}
end;

end.
