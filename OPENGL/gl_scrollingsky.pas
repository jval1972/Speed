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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit gl_scrollingsky;

interface

procedure gld_DrawSky(const map: integer);

implementation

uses
  d_delphi,
  dglOpenGL,
  gl_defs,
  gl_tex,
  w_wad;

const
  NUMSKIES = 8;

const
  sNUBES = 'NUBES%d';
  sMOUNT = 'MOUNT%d';

const
  SKYDIST = 4096;

procedure gld_DrawSky(const map: integer);
var
  i: integer;
  stmp: string;
  lump: integer;
  texnubes: PGLTexture;
  texmount: PGLTexture;
  x, y, y1, y2, z: float;
  u, v: float;
begin
  glColor4f(1.0, 1.0, 1.0, 1.0);

  i := (map - 1) mod NUMSKIES;

  sprintf(stmp, sNUBES, [i]);
  lump := W_CheckNumForName(stmp);
  if lump >= 0 then
  begin
    texnubes := gld_RegisterPatch(lump, Ord(CR_DEFAULT), True);
    gld_BindPatch(texnubes, Ord(CR_DEFAULT), False);

    x := 4 * SKYDIST * MAP_COEFF;
    y := 4 * SKYDIST * texnubes.realtexheight / texnubes.realtexwidth * MAP_COEFF;
    z := 2 * SKYDIST * MAP_COEFF;
    u := 3 * camera.rotation[1] / 360;
    v := 1.0;

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glRotatef(180.0 - camera.rotation[1], 0.0, 1.0, 0.0);

    glBegin(GL_QUADS);
      glTexCoord2f(u, v);         glVertex3f( x, 0.0, z);
      glTexCoord2f(u, 0.0);       glVertex3f( x,   y, z);
      glTexCoord2f(u + 2.0, 0.0); glVertex3f(-x,   y, z);
      glTexCoord2f(u + 2.0, v);   glVertex3f(-x, 0.0, z);

      glTexCoord2f(u, 0.0); glVertex3f( x, y,  z);
      glTexCoord2f(u, 0.0); glVertex3f(-x, y,  z);
      glTexCoord2f(u, 0.0); glVertex3f(-x, y, -z);
      glTexCoord2f(u, 0.0); glVertex3f( x, y, -z);
    glEnd;

    glPopMatrix;
  end;

  sprintf(stmp, sMOUNT, [i]);
  lump := W_CheckNumForName(stmp);
  if lump >= 0 then
  begin
    glEnable(GL_BLEND);
    texmount := gld_RegisterPatch(lump, Ord(CR_DEFAULT), True);
    gld_BindPatch(texmount, Ord(CR_DEFAULT), False, True);

    x := 2 * SKYDIST * MAP_COEFF;
    y1 := 2 * SKYDIST * texmount.realtexheight / texmount.realtexwidth * MAP_COEFF;
    y2 := -0.2 * SKYDIST * texmount.realtexheight / texmount.realtexwidth * MAP_COEFF;
    z := SKYDIST * MAP_COEFF;
    u := 2 * camera.rotation[1] / 360;
    v := 1.0;

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glRotatef(180.0 - camera.rotation[1], 0.0, 1.0, 0.0);

    glBegin(GL_QUADS);
      glTexCoord2f(u, v);         glVertex3f( x, y2, z);
      glTexCoord2f(u, 0.0);       glVertex3f( x, y1, z);
      glTexCoord2f(u + 1.0, 0.0); glVertex3f(-x, y1, z);
      glTexCoord2f(u + 1.0, v);   glVertex3f(-x, y2, z);
    glEnd;

    glPopMatrix;
  end;
end;

end.
