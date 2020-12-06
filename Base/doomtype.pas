//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2020 by Jim Valavanis
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
//
// DESCRIPTION:
//  Simple basic typedefs, isolated here to make it easier
//   separating modules.
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit doomtype;

interface

const
  MAXINT = $7fffffff;
  MININT = integer($80000000);
  MAXSHORT = $7fff;

function smallintwarp1(var sm: Smallint): integer;
function smallintwarp2(var sm: Smallint): integer;

implementation

function smallintwarp1(var sm: Smallint): integer;
begin
  if sm = -1 then
    result := -1
  else
    Result := PWord(@sm)^;
end;

function smallintwarp2(var sm: Smallint): integer;
begin
  Result := PWord(@sm)^;
end;

end.

