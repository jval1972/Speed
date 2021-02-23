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

unit speed_is2;

interface

const
  IS2F_HORIZONTAL = 1;
  IS2_MAGIC = 844319022; // .IS2

type
  IS2_TSprite_t = packed record
    sign: LongWord;   // Must be IS2_MAGIC
    w, h: word;
    dx, dy: smallint; // Offset to apply to x, y coords, like a hot spot.
                      // Given from top-left (0,0) corner.
    xRatio: word;
    yRatio: word;     // Ratio specified when created. 8.8.
    flags: LongWord;
    len: integer;
    offsets: packed array[0..0] of word;  // More than one. Add them to (byte*)&sprite.
  end;
  IS2_TSprite_p = ^IS2_TSprite_t;

implementation

end.
