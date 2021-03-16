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

unit speed_mapdata;

interface

uses
  d_delphi;

procedure SH_InitMapData;

procedure SH_ShutDownMapData;

type
  mapdata_t = record
    mapsprite: string[8];
    skytex: string[8];
    mountaintex: string[8];
    groundtex: string[8];
  end;

  TMapData = class
    mapdata: mapdata_t;
    constructor Create;
  end;

function SH_MapData(const lname: string): mapdata_t;

var
  mapdatalst: TDStringList;

implementation

uses
  doomdata,
  speed_xlat_wad,
  w_wad,
  z_zone;

constructor TMapData.Create;
begin
  Inherited Create;
  mapdata.mapsprite := '';
  mapdata.skytex := '';
  mapdata.mountaintex := '';
  mapdata.groundtex := '';
end;

procedure SH_InitMapData;
var
  i, j, k: integer;
  lname: string;
  lump, mlump: integer;
  sl: TDStringList;
  idx: integer;
  mrec: mapdata_t;
  mclass: TMapData;
begin
  mapdatalst := TDStringList.Create;
  for i := 1 to 4 do
    for j := 1 to 9 do
    begin
      sprintf(lname, 'E%dM%d', [i, j]);
      lump := W_CheckNumForName(lname);
      if lump >= 0 then
      begin
        mlump := -1;
        for k := lump to lump + Ord(ML_MAPDATA) - 1 do
        begin
          if k >= W_NumLumps then
            Break;
          if W_GetNameForNum(k) = 'MAPDATA' then
          begin
            mlump := k;
            Break;
          end;
        end;
        if mlump >= 0 then
        begin
          mrec.mapsprite := '';
          mrec.skytex := '';
          mrec.mountaintex := '';
          mrec.groundtex := '';
          sl := TDStringList.Create;
          try
            sl.Text := W_TextLumpNum(lump);
            idx := sl.IndexOfName(sMAPDATA_sprite);
            if idx >= 0 then
              mrec.mapsprite := sl.ValuesIdx[idx];
            idx := sl.IndexOfName(sMAPDATA_sky);
            if idx >= 0 then
              mrec.skytex := sl.ValuesIdx[idx];
            idx := sl.IndexOfName(sMAPDATA_mountain);
            if idx >= 0 then
              mrec.mountaintex := sl.ValuesIdx[idx];
            idx := sl.IndexOfName(sMAPDATA_ground);
            if idx >= 0 then
              mrec.groundtex := sl.ValuesIdx[idx];
          finally
            sl.Free;
          end;

          mclass := TMapData.Create;
          mclass.mapdata := mrec;
          mapdatalst.AddObject(lname, mclass);
        end;
      end;
    end;
end;

procedure SH_ShutDownMapData;
var
  i: integer;
begin
  for i := 0 to mapdatalst.Count - 1 do
    mapdatalst.Objects[i].Free;
  mapdatalst.Free;
end;

function SH_MapData(const lname: string): mapdata_t;
var
  idx: integer;
  mclass: TMapData;
begin
  idx := mapdatalst.IndexOf(strupper(lname));
  if idx >= 0 then
  begin
    mclass := mapdatalst.Objects[idx] as TMapData;
    result := mclass.mapdata;
  end
  else
  begin
    result.mapsprite := '';
    result.skytex := '';
    result.mountaintex := '';
    result.groundtex := '';
  end;
end;

end.
