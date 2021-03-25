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
//  Speed Score Table (laptimes)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_score;

interface

uses
  doomdef,
  d_player,
  speed_cars,
  speed_race;

type
  speedtimetableitem_t = record
    drivername: string[PILOTNAMESIZE];
    time: integer;
    carid: integer;
    skill: skill_t;
  end;
  Pspeedtimetableitem_t = ^speedtimetableitem_t;

const
  NUMSCORES = 10;

type
  speedtimetableitems_t = array[0..NUMSCORES - 1] of speedtimetableitem_t;
  Pspeedtimetableitems_t = ^speedtimetableitems_t;

  speedtimetable_t = array[1..4] of array[1..9] of array[ct_formula..ct_stock] of speedtimetableitems_t;
  Pspeedtimetable_t = ^speedtimetable_t;

  speedrecordtable_t = record
    laprecords: speedtimetable_t;
    courserecord: array[MINLAPS..MAXLAPS] of speedtimetable_t;
  end;

var
  recordtable: speedrecordtable_t;

procedure SH_UpdateScoreTable(const p: Pplayer_t; const epi, map: integer; skill: skill_t);

procedure SH_LoadScoreTable;

procedure SH_SaveScoreTable;

implementation

uses
  d_delphi,
  i_system,
  m_base,
  m_argv;

procedure SH_SortScoreTable(const laps: integer; const epi, map: integer; const ctyp: cartype_t);
var
  items: speedtimetableitems_t;
  pitems: pspeedtimetableitems_t;
  ii, pi: integer;

  procedure qsortI(l, r: Integer);
  var
    i, j: integer;
    t: speedtimetableitem_t;
    f: Pspeedtimetableitem_t;
  begin
    repeat
      i := l;
      j := r;
      f := @items[(l + r) shr 1];
      repeat
        while items[i].time < f.time do
          inc(i);
        while f.time > items[j].time do
          dec(j);
        if i <= j then
        begin
          t := items[i];
          items[i] := items[j];
          items[j] := t;
          inc(i);
          dec(j);
        end;
      until i > j;
      if l < j then
        qsortI(l, j);
      l := i;
    until i >= r;
  end;

begin
  if laps = 0 then
    pitems := @recordtable.laprecords[epi, map, ctyp]
  else if IsIntegerInRange(laps, MINLAPS, MAXLAPS) then
    pitems := @recordtable.courserecord[laps][epi, map, ctyp]
  else
    Exit;

  ZeroMemory(@items, SizeOf(speedtimetableitems_t));

  ii := 0;
  for pi := 0 to NUMSCORES - 1 do
    if pitems[pi].time <> 0 then
    begin
      items[ii] := pitems[pi];
      inc(ii);
    end;

  if ii > 1 then
    qsortI(0, ii - 1);

  for pi := 0 to NUMSCORES - 1 do
    pitems[pi] := items[pi];
end;

procedure SH_UpdateScoreTable(const p: Pplayer_t; const epi, map: integer; skill: skill_t);
var
  totalscore: integer;
  scorepos: integer;
  x: integer;
  ctyp: cartype_t;
  nlaps: integer;
begin
  if not IsIntegerInRange(epi, 1, 4) or not IsIntegerInRange(map, 1, 9) then
    Exit;

  nlaps := p.currentscore.numlaps;
  if not IsIntegerInRange(nlaps, MINLAPS, MAXLAPS) then
    Exit;

  ctyp := CARINFO[p.currentscore.carinfo].cartype;
  if not (ctyp in [ct_formula, ct_stock]) then
    Exit;

  // JVAL: 20210325 - Check for lap records
  SH_SortScoreTable(0, epi, map, ctyp);
  for x := 0 to p.currentscore.numlaps - 1 do
    if (recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].time = 0) or
       (recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].time > p.currentscore.laptimes[x]) then
    begin
      recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].drivername := p.playername;
      recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].time := p.currentscore.laptimes[x];
      recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].carid := p.currentscore.carinfo;
      recordtable.laprecords[epi, map, ctyp][NUMSCORES - 1].skill := skill;
      SH_SortScoreTable(0, epi, map, ctyp);
    end;

  // JVAL: 20210325 - Check for course records
  SH_SortScoreTable(nlaps, epi, map, ctyp);
  if (recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].time = 0) or
     (recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].time > p.currentscore.totaltime) then
  begin
    recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].drivername := p.playername;
    recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].time := p.currentscore.totaltime;
    recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].carid := p.currentscore.carinfo;
    recordtable.courserecord[nlaps][epi, map, ctyp][NUMSCORES - 1].skill := skill;
    SH_SortScoreTable(nlaps, epi, map, ctyp);
  end;

  SH_SaveScoreTable;
end;

procedure SH_LoadScoreTable;
var
  fname: string;
  handle: file;
  size: integer;
  count: integer;
  x: integer;
begin
  ZeroMemory(@recordtable, SizeOf(speedrecordtable_t));
  fname := M_SaveFileName(APPNAME + '.lap');
  if fexists(fname) then
  begin
    if not fopen(handle, fname, fOpenReadOnly) then
      I_Warning('SH_LoadScoreTable(): Could not read file %s for input'#13#10, [fname])
    else
    begin
      size := FileSize(handle);
      if size <> SizeOf(speedrecordtable_t) then
        I_Warning('SH_LoadScoreTable(): Invalid lap record file %s'#13#10, [fname])
      else
      begin
        BlockRead(handle, recordtable, size, count);
        if count <> size then
        begin
          I_Warning('SH_LoadScoreTable(): Read %d bytes instead of %d bytes'#13#10, [count, size]);
          ZeroMemory(@recordtable, SizeOf(speedrecordtable_t));
        end
        else
        begin
//          SH_SortScoreTable;
        end;
      end;
      close(handle);
    end;
  end;
end;

procedure SH_SaveScoreTable;
var
  fname: string;
  handle: file;
  size: integer;
  count: integer;
  x: integer;
begin
  fname := M_SaveFileName(APPNAME + '.lap');
  if not fopen(handle, fname, fCreate) then
    I_Warning('SH_SaveScoreTable(): Could not open file %s for output'#13#10, [fname])
  else
  begin
    size := SizeOf(speedrecordtable_t);
    BlockWrite(handle, recordtable, size, count);
    if count <> size then
      I_Warning('SH_SaveScoreTable(): Wrote %d bytes instead of %d bytes'#13#10, [count, size]);
    close(handle);
  end;
end;

end.
