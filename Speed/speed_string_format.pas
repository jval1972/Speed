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

unit speed_string_format;

interface

function SH_Meters2KM(const x: integer): string;

implementation

uses
  d_delphi;

function SH_Meters2KM(const x: integer): string;
var
  s: string;
  i: integer;
begin
  s := itoa(x);

  Result := '';
  for i := Length(s) downto 1 do
  begin
    Result := s[i] + Result;
    if Length(Result) = 3 then
      Result := '.' + Result;
  end;
  if Pos('.', Result) = 1 then
    Result := '0' + Result
  else if Pos('.', Result) = 0 then
  begin
    while Length(Result) < 3 do
      Result := '0' + Result;
    Result := '0.' + Result
  end;
  Result := Result + 'km';
end;

end.
 