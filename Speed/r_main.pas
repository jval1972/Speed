//
//  Speed
//  Engine remake of the game "Speed Haste" based on the DelphiDoom engine
//
//  Copyright (C) 1995 by Noriaworks
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
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
// DESCRIPTION:
//  System specific interface stuff.
//  Rendering main loop and setup functions,
//  utility functions (BSP, geometry, trigonometry).
//  See tables.c, too.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit r_main;

interface

uses
  d_delphi,
  doomdef,
  d_player,
  m_fixed,
  tables,
  r_data,
  r_defs;

const
//
// Lighting LUT.
// Used for z-depth cuing per column/row,
//  and other lighting effects (sector ambient, flash).
//

// Lighting constants.
// Now why not 32 levels here?
  LIGHTSEGSHIFT = 4;
  LIGHTLEVELS = (256 div (1 shl LIGHTSEGSHIFT));

  MAXLIGHTSCALE = 48;
  LIGHTSCALESHIFT = 12;
  HLL_MAXLIGHTSCALE = MAXLIGHTSCALE * 64;

  MAXLIGHTZ = 128;
  LIGHTZSHIFT = 20;

  HLL_MAXLIGHTZ = MAXLIGHTZ * 64; // Hi resolution light level for z depth
  HLL_LIGHTZSHIFT = 12;
  HLL_LIGHTSCALESHIFT = 3;
  HLL_ZDISTANCESHIFT = 14;

  LIGHTDISTANCESHIFT = 12;

// Colormap constants
// Number of diminishing brightness levels.
// There a 0-31, i.e. 32 LUT in the COLORMAP lump.
// Index of the special effects (INVUL inverse) map.
  INVERSECOLORMAP = 32;

  DISTMAP = 2;

var
  forcecolormaps: boolean;
  use32bitfuzzeffect: boolean;
  diher8bittransparency: boolean;

//==============================================================================
// R_ApplyColormap
//
// Utility functions.
//
//==============================================================================
procedure R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer);

//==============================================================================
//
// R_PointOnSide
//
//==============================================================================
function R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;

//==============================================================================
//
// R_PointOnSegSide
//
//==============================================================================
function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;

//==============================================================================
//
// R_PointToAngle
//
//==============================================================================
function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;

//==============================================================================
//
// R_PointToAngleEx
//
//==============================================================================
function R_PointToAngleEx(x: fixed_t; y: fixed_t): angle_t;

//==============================================================================
//
// R_PointToAngle2
//
//==============================================================================
function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;

//==============================================================================
//
// R_PointToDist
//
//==============================================================================
function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;

//==============================================================================
//
// R_PointInSubsectorClassic
//
//==============================================================================
function R_PointInSubsectorClassic(const x: fixed_t; const y: fixed_t): Psubsector_t;

//==============================================================================
//
// R_PointInSubsector
//
//==============================================================================
function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;

//==============================================================================
//
// R_AddPointToBox
//
//==============================================================================
procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);

//==============================================================================
// R_RenderPlayerView
//
// REFRESH - the actual rendering functions.
//
// Called by G_Drawer.
//
//==============================================================================
procedure R_RenderPlayerView(player: Pplayer_t);

//==============================================================================
// R_Init
//
// Called by startup code.
//
//==============================================================================
procedure R_Init;

//==============================================================================
//
// R_ShutDown
//
//==============================================================================
procedure R_ShutDown;

//==============================================================================
// R_SetViewSize
//
// Called by M_Responder.
//
//==============================================================================
procedure R_SetViewSize;

//==============================================================================
//
// R_ExecuteSetViewSize
//
//==============================================================================
procedure R_ExecuteSetViewSize;

//==============================================================================
//
// R_SetViewAngleOffset
//
//==============================================================================
procedure R_SetViewAngleOffset(const angle: angle_t);

var
  centerxfrac: fixed_t;
  centeryfrac: fixed_t;
  centerxshift: fixed_t;

  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

  viewangle: angle_t;

  shiftangle: byte;

  viewcos: fixed_t;
  viewsin: fixed_t;

  projection: fixed_t;
  projectiony: fixed_t; // JVAL For correct aspect

  centerx: integer;
  centery: integer;

  fixedcolormap: PByteArray;
  fixedcolormapnum: integer = 0;

// increment every time a check is made
  validcount: integer = 1;

// bumped light from gun blasts
  extralight: integer;

type
  scalelight_t = array[0..LIGHTLEVELS - 1, 0..MAXLIGHTSCALE - 1] of PByteArray;
  Pscalelight_t = ^scalelight_t;

var
  def_scalelight: scalelight_t;
  scalelight: Pscalelight_t;

var
  scalelightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTSCALE - 1] of fixed_t;
  scalelightfixed: array[0..MAXLIGHTSCALE - 1] of PByteArray;

type
  zlight_t = array[0..LIGHTLEVELS - 1, 0..MAXLIGHTZ - 1] of PByteArray;
  Pzlight_t = ^zlight_t;

var
  def_zlight: zlight_t;
  zlight: Pzlight_t;

var
  zlightlevels: array[0..LIGHTLEVELS - 1, 0..HLL_MAXLIGHTZ - 1] of fixed_t;

var
  viewplayer: Pplayer_t;

// The viewangletox[viewangle + FINEANGLES/4] lookup
// maps the visible view angles to screen X coordinates,
// flattening the arc to a flat projection plane.
// There will be many angles mapped to the same X.
  viewangletox: array[0..FINEANGLES div 2 - 1] of integer;

// The xtoviewangleangle[] table maps a screen pixel
// to the lowest viewangle that maps back to x ranges
// from clipangle to -clipangle.
  xtoviewangle: array[0..MAXWIDTH] of angle_t;

//
// precalculated math tables
//
  clipangle: angle_t;

// UNUSED.
// The finetangentgent[angle+FINEANGLES/4] table
// holds the fixed_t tangent values for view angles,
// ranging from MININT to 0 to MAXINT.
// fixed_t    finetangent[FINEANGLES/2];

// fixed_t    finesine[5*FINEANGLES/4];
// fixed_t*    finecosine = &finesine[FINEANGLES/4]; // JVAL -> moved to tables.pas

  linecount: integer;
  loopcount: integer;

  viewangleoffset: angle_t = 0; // Net drone angle

  setsizeneeded: boolean;

//==============================================================================
//
// R_GetColormapLightLevel
//
//==============================================================================
function R_GetColormapLightLevel(const cmap: PByteArray): fixed_t;

//==============================================================================
//
// R_GetColormap32
//
//==============================================================================
function R_GetColormap32(const cmap: PByteArray): PLongWordArray;

//==============================================================================
//
// R_Ticker
//
//==============================================================================
procedure R_Ticker;

var
  viewpitch: integer;
  absviewpitch: integer;

var
  monitor_relative_aspect: Double = 1.0;
  fov: fixed_t; // JVAL: 3d Floors (Made global - moved from R_InitTextureMapping)

var
  rendervalidcount: integer = 0; // Don't bother reseting this // version 205

implementation

uses
  Math,
  doomdata,
  c_cmds,
  d_net,
  i_io,
  m_bbox,
  m_misc,
  p_setup,
  r_colormaps,
  r_aspect,
  r_draw,
  r_bsp,
  r_earthquake,
  r_things,
  r_plane,
  r_sky,
  r_hires,
  r_camera,
  r_precalc,
  r_lights,
  r_intrpl,
  r_ripple,
  gl_render, // JVAL OPENGL
  gl_clipper,
  gl_tex,
  r_subsectors,
  v_data,
  z_zone;

var
// just for profiling purposes
  framecount: integer;

//==============================================================================
//
// R_ApplyColormap
//
//==============================================================================
procedure R_ApplyColormap(const ofs, count: integer; const scrn: integer; const cmap: integer);
var
  src: PByte;
  cnt: integer;
  colormap: PByteArray;
begin
  src := PByte(screens[scrn]);
  inc(src, ofs);
  cnt := count;
  colormap := @def_colormaps[cmap * 256];

  while cnt > 0 do
  begin
    src^ := colormap[src^];
    inc(src);
    dec(cnt);
  end;
end;

//==============================================================================
//
// R_AddPointToBox
// Expand a given bbox
// so that it encloses a given point.
//
//==============================================================================
procedure R_AddPointToBox(const x: integer; const y: integer; box: Pfixed_tArray);
begin
  if x < box[BOXLEFT] then
    box[BOXLEFT] := x;
  if x > box[BOXRIGHT] then
    box[BOXRIGHT] := x;
  if y < box[BOXBOTTOM] then
    box[BOXBOTTOM] := y;
  if y > box[BOXTOP] then
    box[BOXTOP] := y;
end;

//==============================================================================
//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//
//==============================================================================
function R_PointOnSide(const x: fixed_t; const y: fixed_t; const node: Pnode_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  if node.dx = 0 then
  begin
    if x <= node.x then
      result := node.dy > 0
    else
      result := node.dy < 0;
    exit;
  end;

  if node.dy = 0 then
  begin
    if y <= node.y then
      result := node.dx < 0
    else
      result := node.dx > 0;
    exit;
  end;

  dx := x - node.x;
  dy := y - node.y;

  // Try to quickly decide by looking at sign bits.
  if ((node.dy xor node.dx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((node.dy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(node.dy, dx);
  right := FixedIntMul(dy, node.dx);

  result := right >= left;
end;

//==============================================================================
//
// R_PointOnSegSide
//
//==============================================================================
function R_PointOnSegSide(x: fixed_t; y: fixed_t; line: Pseg_t): boolean;
var
  lx: fixed_t;
  ly: fixed_t;
  ldx: fixed_t;
  ldy: fixed_t;
  dx: fixed_t;
  dy: fixed_t;
  left: fixed_t;
  right: fixed_t;
begin
  lx := line.v1.x;
  ly := line.v1.y;

  ldx := line.v2.x - lx;
  ldy := line.v2.y - ly;

  if ldx = 0 then
  begin
    if x <= lx then
      result := ldy > 0
    else
      result := ldy < 0;
    exit;
  end;

  if ldy = 0 then
  begin
    if y <= ly then
      result := ldx < 0
    else
      result := ldx > 0;
    exit;
  end;

  dx := x - lx;
  dy := y - ly;

  // Try to quickly decide by looking at sign bits.
  if ((ldy xor ldx xor dx xor dy) and $80000000) <> 0 then
  begin
    result := ((ldy xor dx) and $80000000) <> 0;
    exit;
  end;

  left := IntFixedMul(ldy, dx);
  right := FixedIntMul(dy, ldx);

  result := left <= right;
end;

//==============================================================================
//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.
//
// JVAL  -> Calculates: result := round(683565275 * (arctan2(y, x)));
//
//==============================================================================
function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if (x = 0) and (y = 0) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle[SlopeDiv(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle[SlopeDiv(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

//==============================================================================
//
// R_PointToAngleEx
//
//==============================================================================
function R_PointToAngleEx(x: fixed_t; y: fixed_t): angle_t;
begin
  x := x - viewx;
  y := y - viewy;

  if (x = 0) and (y = 0) then
  begin
    result := 0;
    exit;
  end;

  if x >= 0 then
  begin
    // x >=0
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 0
        result := tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 1
        result := ANG90 - 1 - tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 8
        result := -tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 7
        result := ANG270 + tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end;
  end
  else
  begin
    // x<0
    x := -x;
    if y >= 0 then
    begin
      // y>= 0
      if x > y then
      begin
        // octant 3
        result := ANG180 - 1 - tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 2
        result := ANG90 + tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end
    else
    begin
      // y<0
      y := -y;
      if x > y then
      begin
        // octant 4
        result := ANG180 + tantoangle_ex[SlopeDivEx(y, x)];
        exit;
      end
      else
      begin
        // octant 5
        result := ANG270 - 1 - tantoangle_ex[SlopeDivEx(x, y)];
        exit;
      end;
    end;
  end;

  result := 0;
end;

//==============================================================================
//
// R_PointToAngleDbl
// JVAL: very slow, do not use
//
//==============================================================================
function R_PointToAngleDbl(const x: fixed_t; const y: fixed_t): angle_t;
var
  xx, yy: fixed_t;
begin
  xx := x - viewx;
  yy := y - viewy;
  result := Round(arctan2(yy, xx) * (ANG180 / D_PI));
end;

//==============================================================================
//
// R_PointToAngle2
//
//==============================================================================
function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;
begin
  result := R_PointToAngle(x2 - x1 + viewx, y2 - y1 + viewy);
end;

//==============================================================================
//
// R_PointToDist
//
//==============================================================================
function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;
var
  angle: integer;
  dx: fixed_t;
  dy: fixed_t;
  temp: fixed_t;
begin
  dx := abs(x - viewx);
  dy := abs(y - viewy);
  if dx = 0 then
  begin
    result := dy;
    exit;
  end;
  if dy = 0 then
  begin
    result := dx;
    exit;
  end;

  if dy > dx then
  begin
    temp := dx;
    dx := dy;
    dy := temp;
  end;

  angle := tantoangle[FixedDiv(dy, dx) shr DBITS] shr ANGLETOFINESHIFT;

  result := FixedDiv(dx, finecosine[angle]);
end;

//==============================================================================
//
// R_InitPointToAngle
//
//==============================================================================
procedure R_InitPointToAngle;
{var
  i: integer;
  t: angle_t;
  f: extended;}
begin
//
// slope (tangent) to angle lookup
//
{  for i := 0 to SLOPERANGE do
  begin
    f := arctan(i / SLOPERANGE) / (D_PI * 2);
    t := round(LongWord($ffffffff) * f);
    tantoangle[i] := t;
  end;}
end;

//==============================================================================
//
// R_InitTables
//
//==============================================================================
procedure R_InitTables;
// JVAL: Caclulate tables constants
{var
  i: integer;
  a: extended;
  fv: extended;
  t: integer;}
begin              {
// viewangle tangent table
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    a := (i - FINEANGLES / 4 + 0.5) * D_PI * 2 / FINEANGLES;
    fv := FRACUNIT * tan(a);
    t := round(fv);
    finetangent[i] := t;
  end;

  // finesine table
  for i := 0 to 5 * FINEANGLES div 4 - 1 do
  begin
    // OPTIMIZE: mirror...
    a := (i + 0.5) * D_PI * 2 / FINEANGLES;
    t := round(FRACUNIT * sin(a));
    finesine[i] := t;
  end;              }

  finecosine := Pfixed_tArray(@finesine[FINEANGLES div 4]);
  fixedcosine := Pfixed_tArray(@fixedsine[FIXEDANGLES div 4]);
end;

//==============================================================================
//
// R_InitTextureMapping
//
//==============================================================================
procedure R_InitTextureMapping;
var
  i: integer;
  x: integer;
  t: integer;
  focallength: fixed_t;
  an: angle_t;
begin
  // Use tangent table to generate viewangletox:
  //  viewangletox will give the next greatest x
  //  after the view angle.
  //
  // Calc focallength

// JVAL: Widescreen support
  if monitor_relative_aspect = 1.0 then
    fov := ANG90 shr ANGLETOFINESHIFT
  else
    fov := round(arctan(monitor_relative_aspect) * FINEANGLES / D_PI);
  focallength := FixedDiv(centerxfrac, finetangent[FINEANGLES div 4 + fov div 2]);

  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if finetangent[i] > FRACUNIT * 2 then
      t := -1
    else if finetangent[i] < -FRACUNIT * 2 then
      t := viewwidth + 1
    else
    begin
      t := FixedMul(finetangent[i], focallength);
      t := (centerxfrac - t + (FRACUNIT - 1)) div FRACUNIT;

      if t < -1 then
        t := -1
      else if t > viewwidth + 1 then
        t := viewwidth + 1;
    end;
    viewangletox[i] := t;
  end;

  // Scan viewangletox[] to generate xtoviewangle[]:
  //  xtoviewangle will give the smallest view angle
  //  that maps to x.
  for x := 0 to viewwidth do
  begin
    an := 0;
    while viewangletox[an] > x do
      inc(an);
    xtoviewangle[x] := an * ANGLETOFINEUNIT - ANG90;
  end;

  // Take out the fencepost cases from viewangletox.
  for i := 0 to FINEANGLES div 2 - 1 do
  begin
    if viewangletox[i] = -1 then
      viewangletox[i] := 0
    else if viewangletox[i] = viewwidth + 1 then
      viewangletox[i] := viewwidth;
  end;
  clipangle := xtoviewangle[0];
end;

//==============================================================================
//
// R_InitLightTables
// Only inits the zlight table,
//  because the scalelight table changes with view size.
//
//==============================================================================
procedure R_InitLightTables;
var
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
  scale: integer;
  levelhi: integer;
  startmaphi: integer;
  scalehi: integer;
begin
  // Calculate the light levels to use
  //  for each level / distance combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2 * NUMCOLORMAPS) div LIGHTLEVELS;
    for j := 0 to MAXLIGHTZ - 1 do
    begin
      scale := FixedDiv(160 * FRACUNIT, _SHL(j + 1, LIGHTZSHIFT));
      scale := _SHR(scale, LIGHTSCALESHIFT);
      level := startmap - scale div DISTMAP;

      if level < 0 then
        level := 0
      else if level >= NUMCOLORMAPS then
        level := NUMCOLORMAPS - 1;

      def_zlight[i][j] := PByteArray(integer(def_colormaps) + level * 256);
    end;

    startmaphi := ((LIGHTLEVELS - 1 - i) * 2 * FRACUNIT) div LIGHTLEVELS;
    for j := 0 to HLL_MAXLIGHTZ - 1 do
    begin

      scalehi := FixedDiv(160 * FRACUNIT, _SHL(j + 1, HLL_LIGHTZSHIFT));
      scalehi := _SHR(scalehi, HLL_LIGHTSCALESHIFT);
      levelhi := FRACUNIT - startmaphi + scalehi div DISTMAP;

      if levelhi < 0 then
        levelhi := 0
      else if levelhi >= FRACUNIT then
        levelhi := FRACUNIT - 1;

      zlightlevels[i][j] := levelhi;
    end;
  end;

end;

//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//
var
  olddetail: integer = -1;

//==============================================================================
//
// R_SetViewSize
//
//==============================================================================
procedure R_SetViewSize;
begin
  if not allowlowdetails then
    if detailLevel < DL_MEDIUM then
      detailLevel := DL_MEDIUM;
  if not allowhidetails then
    if detailLevel > DL_NORMAL then
    begin
      if allowlowdetails then
        detailLevel := DL_LOWEST
      else
        detailLevel := DL_MEDIUM;
    end;

  if setdetail <> detailLevel then
  begin
    if setdetail <> detailLevel then
    begin
      recalctables32needed := true;
    end;
    setsizeneeded := true;
    setdetail := detailLevel;
  end;
end;

//==============================================================================
//
// R_ExecuteSetViewSize
//
//==============================================================================
procedure R_ExecuteSetViewSize;
var
  i: integer;
  j: integer;
  level: integer;
  startmap: integer;
  levelhi: integer;
  startmaphi: integer;
begin
  setsizeneeded := false;

  scaledviewwidth := SCREENWIDTH;
  viewheight := SCREENHEIGHT;

  viewwidth := scaledviewwidth;
  centery := viewheight div 2;
  centerx := viewwidth div 2;

  centerxfrac := centerx * FRACUNIT;
  centeryfrac := centery * FRACUNIT;

// JVAL: Widescreen support
  monitor_relative_aspect := R_GetRelativeAspect;
  projection := Round(centerx / monitor_relative_aspect * FRACUNIT);
  projectiony := (((SCREENHEIGHT * centerx * 320) div 200) div SCREENWIDTH * FRACUNIT); // JVAL for correct aspect

  if olddetail <> setdetail then
  begin
    olddetail := setdetail;
    videomode := vm32bit;
  end;

  R_InitBuffer(scaledviewwidth, viewheight);

  R_InitTextureMapping;

// psprite scales
// JVAL: Widescreen support
  pspritescale := Round((centerx / monitor_relative_aspect * FRACUNIT) / 160);
  pspriteyscale := Round((((SCREENHEIGHT * viewwidth) / SCREENWIDTH) * FRACUNIT) / 200);
  pspriteiscale := FixedDiv(FRACUNIT, pspritescale);

  if excludewidescreenplayersprites then
    pspritescalep := Round((centerx * FRACUNIT) / 160)
  else
    pspritescalep := Round((centerx / R_GetRelativeAspect * FRACUNIT) / 160);
  pspriteiscalep := FixedDiv(FRACUNIT, pspritescalep);

  // thing clipping
  for i := 0 to viewwidth - 1 do
    screenheightarray[i] := viewheight;

  // Calculate the light levels to use
  //  for each level / scale combination.
  for i := 0 to LIGHTLEVELS - 1 do
  begin
    startmap := ((LIGHTLEVELS - 1 - i) * 2) * NUMCOLORMAPS div LIGHTLEVELS;
    for j := 0 to MAXLIGHTSCALE - 1 do
    begin
      level := startmap - j * SCREENWIDTH div viewwidth div DISTMAP;

      if level < 0 then
        level := 0
      else
      begin
        if level >= NUMCOLORMAPS then
          level := NUMCOLORMAPS - 1;
      end;

      def_scalelight[i][j] := PByteArray(integer(def_colormaps) + level * 256);
    end;
  end;

  if setdetail >= DL_NORMAL then
    for i := 0 to LIGHTLEVELS - 1 do
    begin
      startmaphi := ((LIGHTLEVELS - 1 - i) * 2 * FRACUNIT) div LIGHTLEVELS;
      for j := 0 to HLL_MAXLIGHTSCALE - 1 do
      begin
        levelhi := startmaphi - (j * SCREENWIDTH) div viewwidth * 16;

        if levelhi < 0 then
          scalelightlevels[i][j] := FRACUNIT
        else if levelhi >= FRACUNIT then
          scalelightlevels[i][j] := 1
        else
          scalelightlevels[i][j] := FRACUNIT - levelhi;
      end;
    end;

  R_RecalcColormaps;
end;

//==============================================================================
//
// R_CmdZAxisShift
//
//==============================================================================
procedure R_CmdZAxisShift(const parm1: string = '');
var
  newz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: zaxisshift = %s.'#13#10, [truefalseStrings[zaxisshift]]);
    exit;
  end;

  newz := C_BoolEval(parm1, zaxisshift);
  if newz <> zaxisshift then
  begin
    zaxisshift := newz;
    setsizeneeded := true;
  end;
  R_CmdZAxisShift;
end;

//==============================================================================
//
// R_CmdUse32bitfuzzeffect
//
//==============================================================================
procedure R_CmdUse32bitfuzzeffect(const parm1: string = '');
var
  newusefz: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: use32bitfuzzeffect = %s.'#13#10, [truefalseStrings[use32bitfuzzeffect]]);
    exit;
  end;

  newusefz := C_BoolEval(parm1, use32bitfuzzeffect);
  if newusefz <> use32bitfuzzeffect then
    use32bitfuzzeffect := newusefz;
  R_CmdUse32bitfuzzeffect;
end;

//==============================================================================
//
// R_CmdDiher8bitTransparency
//
//==============================================================================
procedure R_CmdDiher8bitTransparency(const parm1: string = '');
var
  newdih: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: diher8bittransparency = %s.'#13#10, [truefalseStrings[diher8bittransparency]]);
    exit;
  end;

  newdih := C_BoolEval(parm1, diher8bittransparency);
  if newdih <> diher8bittransparency then
  begin
    diher8bittransparency := newdih;
  end;
  R_CmdDiher8bitTransparency;
end;

//==============================================================================
//
// R_CmdScreenWidth
//
//==============================================================================
procedure R_CmdScreenWidth;
begin
  printf('ScreenWidth = %d.'#13#10, [SCREENWIDTH]);
end;

//==============================================================================
//
// R_CmdScreenHeight
//
//==============================================================================
procedure R_CmdScreenHeight;
begin
  printf('ScreenHeight = %d.'#13#10, [SCREENHEIGHT]);
end;

//==============================================================================
//
// R_CmdClearCache
//
//==============================================================================
procedure R_CmdClearCache;
begin
  gld_ClearTextureMemory;
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache clear'#13#10);
end;

//==============================================================================
//
// R_CmdResetCache
//
//==============================================================================
procedure R_CmdResetCache;
begin
  Z_FreeTags(PU_CACHE, PU_CACHE);
  printf('Texture cache reset'#13#10);
end;

//==============================================================================
//
// R_Init
//
//==============================================================================
procedure R_Init;
begin
  printf('R_InitAspect'#13#10);
  R_InitAspect;
  printf('R_InitData'#13#10);
  R_InitData;
  printf('R_InitCustomColormaps'#13#10);
  R_InitCustomColormaps;
  printf('R_InitRippleEffects'#13#10);
  R_InitRippleEffects;
  printf('R_InitInterpolations'#13#10);
  R_InitInterpolations;
  printf('R_InitPointToAngle'#13#10);
  R_InitPointToAngle;
  printf('R_InitTables'#13#10);
  R_InitTables;
  printf('R_SetViewSize'#13#10);
  // viewwidth / viewheight / detailLevel are set by the defaults
  R_SetViewSize;
  printf('R_InitLightTables'#13#10);
  R_InitLightTables;
  printf('R_InitSkyMap'#13#10);
  R_InitSkyMap;
  printf('R_InitTranslationsTables'#13#10);
  R_InitTranslationTables;
  printf('R_InitPrecalc'#13#10);
  R_InitPrecalc;

  framecount := 0;

  C_AddCmd('zaxisshift', @R_CmdZAxisShift);
  C_AddCmd('lowestres, lowestresolution', @R_CmdLowestRes);
  C_AddCmd('lowres, lowresolution', @R_CmdLowRes);
  C_AddCmd('mediumres, mediumresolution', @R_CmdMediumRes);
  C_AddCmd('normalres, normalresolution', @R_CmdNormalRes);
  C_AddCmd('hires, hiresolution', @R_CmdHiRes);
  C_AddCmd('ultrares, ultraresolution', @R_CmdUltraRes);
  C_AddCmd('detaillevel, displayresolution', @R_CmdDetailLevel);
  C_AddCmd('fullscreen', @R_CmdFullScreen);
  C_AddCmd('extremeflatfiltering', @R_CmdExtremeflatfiltering);
  C_AddCmd('32bittexturepaletteeffects, use32bittexturepaletteeffects', @R_Cmd32bittexturepaletteeffects);
  C_AddCmd('useexternaltextures', @R_CmdUseExternalTextures);
  C_AddCmd('use32bitfuzzeffect', @R_CmdUse32bitfuzzeffect);
  C_AddCmd('diher8bittransparency', @R_CmdDiher8bitTransparency);
  C_AddCmd('lightboostfactor', @R_CmdLightBoostFactor);
  C_AddCmd('screenwidth', @R_CmdScreenWidth);
  C_AddCmd('screenheight', @R_CmdScreenHeight);
  C_AddCmd('clearcache, cleartexturecache', @R_CmdClearCache);
  C_AddCmd('resetcache, resettexturecache', @R_CmdResetCache);
end;

//==============================================================================
//
// R_ShutDown
//
//==============================================================================
procedure R_ShutDown;
begin
  printf(#13#10 + 'R_ShutDownLightBoost');
  R_ShutDownLightBoost;
  printf(#13#10 + 'R_ShutDownInterpolation');
  R_ResetInterpolationBuffer;
  printf(#13#10 + 'R_ShutDownPrecalc');
  R_ShutDownPrecalc;
  printf(#13#10 + 'R_ShutDownCustomColormaps');
  R_ShutDownCustomColormaps;
  printf(#13#10 + 'R_ShutDownSprites');
  R_ShutDownSprites;
  printf(#13#10 + 'R_FreeMemory');
  R_FreeMemory;
  printf(#13#10 + 'R_ShutDownOpenGL');
  R_ShutDownOpenGL;
  printf(#13#10);
end;

//==============================================================================
// R_PointInSubsectorClassic
//
// R_PointInSubsector
//
//==============================================================================
function R_PointInSubsectorClassic(const x: fixed_t; const y: fixed_t): Psubsector_t;
var
  node: Pnode_t;
  nodenum: LongWord;
begin
  // single subsector is a special case
  if numnodes = 0 then
  begin
    result := @subsectors[0];
    exit;
  end;

  nodenum := numnodes - 1;

  while nodenum and NF_SUBSECTOR_V5 = 0 do
  begin
    node := @nodes[nodenum];
    if R_PointOnSide(x, y, node) then
      nodenum := node.children[1]
    else
      nodenum := node.children[0]
  end;

  result := @subsectors[nodenum and (not NF_SUBSECTOR_V5)]; // JVAL: glbsp
end;

//==============================================================================
//
// R_PointInSubsector
//
//==============================================================================
function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;
begin
  result := R_PointInSubsectorPrecalc(x, y);
  if result = nil then
    result := R_PointInSubSectorClassic(x, y);
end;

var
  lastcm: integer = -2;

//==============================================================================
//
// R_SetupFrame
//
//==============================================================================
procedure R_SetupFrame(player: Pplayer_t);
var
  i: integer;
  cy: fixed_t;
  sblocks: integer;
  sec: Psector_t;
  cm: integer;
  vangle: angle_t;
begin
  viewplayer := player;
  viewx := player.mo.x;
  viewy := player.mo.y;
  shiftangle := player.lookdir2;
  viewangle := player.mo.angle + shiftangle * DIR256TOANGLEUNIT + viewangleoffset;
  extralight := player.extralight;

  viewz := player.viewz;

  R_AdjustTeleportZoom(player);
  R_AdjustChaseCamera;
  R_AdjustGlobalEarthQuake(player);

  viewpitch := 0;
  absviewpitch := 0;

//******************************
// JVAL Enabled z axis shift
  if zaxisshift and ((player.lookdir16 <> 0) or p_justspawned) and (viewangleoffset = 0) then
  begin
    sblocks := 11;
    cy := Round((viewheight + ((player.lookdir16 * sblocks) / 16) * SCREENHEIGHT / 1000) / 2);   // JVAL Smooth Look Up/Down
    if centery <> cy then
    begin
      centery := cy;
      centeryfrac := centery * FRACUNIT;
    end;

    viewpitch := player.lookdir;
    absviewpitch := abs(viewpitch);
  end
  else
    p_justspawned := false;
//******************************

  vangle := viewangle div FRACUNIT;
  viewsin := fixedsine[vangle];
  viewcos := fixedcosine[vangle];

  cm := -1;
  if Psubsector_t(player.mo.subsector).sector.heightsec > -1 then
  begin
    sec := @sectors[Psubsector_t(player.mo.subsector).sector.heightsec];
    if viewz < sec.floorheight then
      cm := sec.bottommap
    else if viewz > sec.ceilingheight then
      cm := sec.topmap
    else
      cm := sec.midmap;
  end;

  if cm >= 0 then
  begin
    customcolormap := @customcolormaps[cm];
    R_RecalcColormaps;
    if cm <> lastcm then
    begin
      zlight := @customcolormap.zlight;
      scalelight := @customcolormap.scalelight;
      colormaps := customcolormap.colormap;
      lastcm := cm;
      recalctables32needed := true;
    end;
  end
  else
  begin
    if cm <> lastcm then
    begin
      customcolormap := nil;
      zlight := @def_zlight;
      scalelight := @def_scalelight;
      colormaps := def_colormaps;
      lastcm := cm;
      recalctables32needed := true;
    end;
  end;

  fixedcolormapnum := player.fixedcolormap;
  if fixedcolormapnum <> 0 then
  begin
    if customcolormap <> nil then
      fixedcolormap := PByteArray(
        integer(customcolormap.colormap) + fixedcolormapnum * 256)
    else
      fixedcolormap := PByteArray(
        integer(colormaps) + fixedcolormapnum * 256);

    for i := 0 to MAXLIGHTSCALE - 1 do
      scalelightfixed[i] := fixedcolormap;
  end
  else
  begin
    fixedcolormap := nil;
  end;

  inc(framecount);
  inc(validcount);
end;

//==============================================================================
//
// R_SetViewAngleOffset
//
//==============================================================================
procedure R_SetViewAngleOffset(const angle: angle_t);
begin
  viewangleoffset := angle;
end;

//==============================================================================
//
// R_GetColormapLightLevel
//
//==============================================================================
function R_GetColormapLightLevel(const cmap: PByteArray): fixed_t;
begin
  if cmap = nil then
    result := -1
  else
    result := FRACUNIT - (integer(cmap) - integer(colormaps)) div 256 * FRACUNIT div NUMCOLORMAPS;
end;

//==============================================================================
//
// R_GetColormap32
//
//==============================================================================
function R_GetColormap32(const cmap: PByteArray): PLongWordArray;
begin
  if cmap = nil then
    result := @colormaps32[6 * 256] // FuzzLight
  else
    result := @colormaps32[(integer(cmap) - integer(colormaps))];
end;

//==============================================================================
// R_DoRenderPlayerView_SingleThread
//
// R_RenderView
//
//==============================================================================
procedure R_DoRenderPlayerView_SingleThread(player: Pplayer_t);
begin
  R_SetupFrame(player);

  R_ClearPlanes;
  R_ClearSprites;

  gld_StartDrawScene; // JVAL OPENGL

  // check for new console commands.
  NetUpdate;

  gld_ClipperAddViewRange;

  // The head node is the last node output.
  R_RenderBSPNode(numnodes - 1);

  R_ProjectAdditionalThings;

  // Check for new console commands.
  NetUpdate;

  gld_DrawScene(player);

  NetUpdate;

  gld_EndDrawScene;

  // Check for new console commands.
  NetUpdate;
end;

//==============================================================================
//
// R_RenderPlayerView
//
//==============================================================================
procedure R_RenderPlayerView(player: Pplayer_t);
begin
  // new render validcount
  Inc(rendervalidcount);

  R_DoRenderPlayerView_SingleThread(player);
end;

//==============================================================================
//
// R_Ticker
//
//==============================================================================
procedure R_Ticker;
begin
  R_InterpolateTicker;
end;

end.

