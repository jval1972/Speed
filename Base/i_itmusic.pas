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
//  IT music module detection
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit i_itmusic;

interface

//==============================================================================
//
// IsITMusicFile
//
//==============================================================================
function IsITMusicFile(const buf: pointer; const size: integer): boolean;

implementation

uses
  d_delphi;

//==============================================================================
//
// IsITMusicFile
//
//==============================================================================
function IsITMusicFile(const buf: pointer; const size: integer): boolean;
var
  pb: PByteArray;
begin
  Result := size > 4;
  if Result then
  begin
    pb := buf;
    Result := // "IMPM"
      (pb[0] = $49) and
      (pb[1] = $4D) and
      (pb[2] = $50) and
      (pb[3] = $4D);
  end;
end;

end.

