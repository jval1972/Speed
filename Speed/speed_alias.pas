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

unit speed_alias;

interface

procedure SH_InitSpeedAlias;

procedure SH_ShutDownSpeedAlias;

function SH_FindAliasLump(const lumpname: string): integer;

implementation

uses
  d_delphi,
  w_wad;

const
  NUM_ALIAS_LISTS = 16;

var
  sh_aliases: array[0..NUM_ALIAS_LISTS - 1] of TDStringList;

function SH_FindAliasList(const r_entry: string): integer;
begin
  if r_entry = '' then
    result := 0
  else
    result := Ord(r_entry[1]) mod NUM_ALIAS_LISTS;
end;

procedure SH_ParseAlias(const in_text: string);
var
  i: integer;
  lst: TDStringList;
  w_entry, r_entry: string;
  lump: integer;
  lid: integer;
begin
  lst := TDStringList.Create;
  try
    lst.Text := in_text;
    for i := lst.Count - 1 downto 0 do
    begin
      splitstring(lst.Strings[i], w_entry, r_entry, '=');
      lump := W_CheckNumForName(w_entry);
      if lump >= 0 then
      begin
        lid := SH_FindAliasList(r_entry);
        sh_aliases[lid].AddObject(strupper(r_entry), TInteger.Create(lump));
      end;
    end;
  finally
    lst.Free;
  end;
end;

procedure SH_InitSpeedAlias;
var
  i: integer;
begin
  for i := 0 to NUM_ALIAS_LISTS - 1 do
    sh_aliases[i] := TDStringList.Create;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = S_SPEEDINF then
      SH_ParseAlias(W_TextLumpNum(i));
end;

procedure SH_ShutDownSpeedAlias;
var
  i, j: integer;
begin
  for i := 0 to NUM_ALIAS_LISTS - 1 do
  begin
    for j := 0 to sh_aliases[i].Count - 1 do
      sh_aliases[i].Objects[j].Free;
    sh_aliases[i].Free;
  end;
end;

function SH_FindAliasLump(const lumpname: string): integer;
var
  lid: integer;
  idx: integer;
  ulumpname: string;
begin
  ulumpname := strupper(lumpname);
  lid := SH_FindAliasList(ulumpname);
  idx := sh_aliases[lid].IndexOf(ulumpname);
  if idx >= 0 then
    result := (sh_aliases[lid].Objects[idx] as TInteger).intnum
  else
    result := -1;
end;

end.
