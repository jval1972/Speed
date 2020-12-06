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
// DESCRIPTION:
//   JVAL: Zone Memory Replacement
//
//------------------------------------------------------------------------------
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

unit z_memmgr;

interface

uses
  d_delphi;

type
  memmanageritem_t = record
    size: integer;
    user: PPointer;
    tag: integer;
    index: integer;
  end;
  Pmemmanageritem_t = ^memmanageritem_t;

  memmanageritems_t = array[0..$FFF] of Pmemmanageritem_t;
  Pmemmanageritems_t = ^memmanageritems_t;

type
  TMemManager = class
  private
    fitems: Pmemmanageritems_t;
    fnumitems: integer;
    realsize: integer;
    function item2ptr(const id: integer): Pointer;
    function ptr2item(const ptr: Pointer): integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure M_Free(ptr: Pointer);
    procedure M_FreeTags(lowtag, hightag: integer);
    procedure M_ChangeTag(ptr: Pointer; tag: integer);
    function M_Malloc(size: integer; tag: integer; user: Pointer): pointer;
    function M_Realloc(ptr: Pointer; size: integer; tag: integer; user: Pointer): pointer;
    property items: Pmemmanageritems_t read fitems write fitems;
    property numitems: integer read fnumitems write fnumitems;
  end;


implementation

constructor TMemManager.Create;
begin
  fitems := nil;
  fnumitems := 0;
  realsize := 0;
end;

destructor TMemManager.Destroy;
var
  i: integer;
begin
  for i := fnumitems - 1 downto 0 do
    memfree(Pointer(fitems[i]), fitems[i].size + SizeOf(memmanageritem_t));
  memfree(pointer(fitems), realsize * SizeOf(Pmemmanageritem_t));
  inherited;
end;

function TMemManager.item2ptr(const id: integer): Pointer;
begin
  result := pointer(integer(fitems[id]) + SizeOf(memmanageritem_t));
end;

function TMemManager.ptr2item(const ptr: Pointer): integer;
begin
  result := Pmemmanageritem_t(Integer(ptr) - SizeOf(memmanageritem_t)).index;
end;

procedure TMemManager.M_Free(ptr: Pointer);
var
  i: integer;
begin
  i := ptr2item(ptr);
  if fitems[i].user <> nil then
    fitems[i].user^ := nil;
  memfree(pointer(fitems[i]), fitems[i].size + SizeOf(memmanageritem_t));
  if i < fnumitems - 1 then
  begin
    fitems[i] := fitems[fnumitems - 1];
    fitems[fnumitems - 1] := nil;
    fitems[i].index := i;
  end
  else
    fitems[i] := nil;
  dec(fnumitems);
end;

procedure TMemManager.M_FreeTags(lowtag, hightag: integer);
var
  i: integer;
begin
  for i := fnumitems - 1 downto 0 do
    if (fitems[i].tag >= lowtag) and (fitems[i].tag <= hightag) then
      M_Free(item2ptr(i));
end;

procedure TMemManager.M_ChangeTag(ptr: Pointer; tag: integer);
begin
  fitems[ptr2item(ptr)].tag := tag;
end;

function TMemManager.M_Malloc(size: integer; tag: integer; user: Pointer): pointer;
var
  i: integer;
begin
  if realsize <= fnumitems then
  begin
    realsize := (realsize * 4 div 3 + 64) and (not 7);
    realloc(pointer(fitems), fnumitems * SizeOf(Pmemmanageritem_t), realsize * SizeOf(Pmemmanageritem_t));
    for i := fnumitems + 1 to realsize - 1 do
      fitems[i] := nil;
  end;

  fitems[fnumitems] := malloc(size + SizeOf(memmanageritem_t));
  fitems[fnumitems].size := size;
  fitems[fnumitems].tag := tag;
  fitems[fnumitems].index := fnumitems;
  fitems[fnumitems].user := user;
  result := item2ptr(fnumitems);
  inc(fnumitems);
  if user <> nil then
    PPointer(user)^ := result;
end;

function TMemManager.M_Realloc(ptr: Pointer; size: integer; tag: integer; user: Pointer): pointer;
var
  tmp: pointer;
  copysize: integer;
  i: integer;
begin
  if size = 0 then
  begin
    M_Free(ptr);
    result := nil;
    exit;
  end;

  if ptr = nil then
  begin
    result := M_Malloc(size, tag, user);
    exit;
  end;

  i := ptr2item(ptr);
  if fitems[i].size = size then
  begin
    result := ptr;
    exit;
  end;

  if size > fitems[i].size then
    copysize := fitems[i].size
  else
    copysize := size;

  tmp := malloc(copysize);
  memcpy(tmp, ptr, copysize);
  M_Free(ptr);
  result := M_Malloc(size, tag, user);
  memcpy(result, tmp, copysize);
  memfree(tmp, copysize);
end;

end.

