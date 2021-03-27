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

function SH_TicsToTimeStr(const t: integer): string;

function SH_FmtRacePostion(const p: integer): string;

implementation

uses
  d_delphi,
  doomdef,
  speed_cars;

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

function SH_TicsToTimeStr(const t: integer): string;
var
  shour, smin, ssec, smsec: string;
  t1: integer;
  tmp: integer;
begin
  t1 := t * 100 div TICRATE;
  tmp := t1 mod 100;
  t1 := (t1 - tmp) div 100;
  smsec := IntToStrzFill(2, tmp);
  tmp := t1 mod 60;
  t1 := t1 div 60;
  ssec := IntToStrzFill(2, tmp);
  tmp := t1 mod 60;
  t1 := t1 div 60;
  smin := IntToStrzFill(2, tmp);
  if t1 <> 0 then
  begin
    shour := itoa(t1);
    Result := shour + '''' + smin + '''' + ssec + '"' + smsec;
  end
  else
    Result := smin + '''' + ssec + '"' + smsec;
end;

function SH_FmtRacePostion(const p: integer): string;
const
  PFMT: array[1..3] of string[2] = ('st', 'nd', 'rd');
begin
  if IsIntegerInRange(p, 1, 3) then
    Result := itoa(p) + PFMT[p]
  else if IsIntegerInRange(p, 4, MAX_RACE_CARS) then
    Result := itoa(p) + 'th'
  else
    Result := '-';
end;

end.
