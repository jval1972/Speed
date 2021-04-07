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

unit speed_defs;

interface

uses
  SysUtils;
  
type
  speedlump_t = packed record
    filename: array[0..23] of char;
    start, size: integer;
  end;
  speedlump_p = ^speedlump_t;
  speedlump_tArray = packed array[0..$FFF] of speedlump_t;
  Pspeedlump_tArray = ^speedlump_tArray;

const
  JCL_MAGIC = $df73b489;

type
  speedheader_t = packed record
    magic: LongWord;
    nlumps1: integer;
    nlumps: integer;
    lastoffset: integer;
  end;

function getjcllumpname(const l: speedlump_p): string;

const
  SH_FLAT_PREFIX = 'FLAT';
  SH_TRANFLAT_PREFIX = 'FTRN';
  SH_WALL_PREFIX = 'WALL';

implementation

function getjcllumpname(const l: speedlump_p): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 23 do
  begin
    if l.filename[i] = #0 then
      break;
    result := result + l.filename[i];
  end;
  result := Trim(result);
end;

end.
