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
// DESCRIPTION:
//    FLATSIZE lump
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_flatsize;

interface

uses
  d_delphi;

procedure SH_InitFlatSize;

procedure SH_ShutDownFlatSize;

function SH_GetFlatSize(const flatname: string): integer;

const
  FLATSIZELUMPNAME = 'FLATSIZE';

implementation

uses
  w_wad;

var
  flatsize: TDStringList;

procedure SH_ParseFlatSizeLump(const lump: integer);
var
  lst: TDStringList;
  s1, s2: string;
  sz: integer;
  i: integer;
  idx: integer;
begin
  lst := TDStringList.Create;
  lst.Text := W_TextLumpNum(lump);
  for i := 0 to lst.Count - 1 do
  begin
    splitstring(lst.Strings[i], s1, s2, '=');
    s1 := strupper(strtrim(s1));
    s2 := strtrim(s2);
    sz := atoi(s2, -1);
    if sz > 0 then
    begin
      idx := flatsize.IndexOf(s1);
      if idx < 0 then
        flatsize.AddObject(s1, TInteger.Create(sz))
      else
        (flatsize.Objects[idx] as TInteger).intnum := sz;
    end;
  end;
end;

procedure SH_InitFlatSize;
var
  i: integer;
begin
  flatsize := TDStringList.Create;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = FLATSIZELUMPNAME then
      SH_ParseFlatSizeLump(i);
end;

procedure SH_ShutDownFlatSize;
var
  i: integer;
begin
  for i := 0 to flatsize.Count - 1 do
    flatsize.Objects[i].Free;
  flatsize.Free;
end;

function SH_GetFlatSize(const flatname: string): integer;
var
  idx: integer;
begin
  idx := flatsize.IndexOf(strupper(flatname));
  if idx < 0 then
    Result := 64
  else
    Result := (flatsize.Objects[idx] as TInteger).intnum;
end;

end.
