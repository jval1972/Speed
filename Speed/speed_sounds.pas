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

unit speed_sounds;

interface

procedure SH_RawToWAV(const inp: pointer; const inpsize: integer; const hz: integer;
  out outp: pointer; out outsize: integer);

implementation

uses
  d_delphi;

procedure SH_RawToWAV(const inp: pointer; const inpsize: integer; const hz: integer;
  out outp: pointer; out outsize: integer);
var
  PA: PLongWordArray;
  PB: PByteArray;
  i: integer;
begin
  outsize := inpsize + 44;
  outp := malloc(outsize);
  PA := outp;

  PA[0] := $46464952; // RIFF
  PA[1] := outsize;
  PA[2] := $45564157; // WAVE
  PA[3] := $20746D66; // fmt_
  PA[4] := $00000010;
  PA[5] := $00010001;
  PA[6] := hz;
  PA[7] := hz;
  PA[8] := $00080001;
  PA[9] := $61746164; // data
  PA[10] := inpsize;
  memcpy(@PA[11], inp, inpsize);
  PB := @PA[11];
  for i := 0 to inpsize - 1 do
    PB[i] := 128 + PB[i];
end;

end.
