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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_sounds;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// SH_RawToWAV
//
//==============================================================================
procedure SH_RawToWAV(const inp: pointer; const inpsize: integer; const hz: integer;
  const vol: fixed_t; out outp: pointer; out outsize: integer);

type
  speedsound_t = (
    sfx_speedhaste_AUTOMATI,
    sfx_speedhaste_CIRCUIT,
    sfx_speedhaste_CRASH,
    sfx_speedhaste_DERRAPE,
    sfx_speedhaste_EXTTIME,
    sfx_speedhaste_GAMEOVER,
    sfx_speedhaste_GO,
    sfx_speedhaste_LAPREC,
    sfx_speedhaste_MANUAL,
    sfx_speedhaste_ONE,
    sfx_speedhaste_STARTECH,
    sfx_speedhaste_THREE,
    sfx_speedhaste_TIMEOVER,
    sfx_speedhaste_TWO,
    sfx_speedhaste_UNBELI,
    sfx_speedhaste_VIHECUL,
    sfx_speedhaste_MOTOR0_0,
    sfx_speedhaste_MOTOR0_1,
    sfx_speedhaste_MOTOR0_2,
    sfx_speedhaste_MOTOR0_3,
    sfx_speedhaste_MOTOR0_4,
    sfx_speedhaste_MOTOR0_5,
    sfx_speedhaste_MOTOR0_6,
    sfx_speedhaste_MOTOR0_7,
    sfx_speedhaste_MOTOR0_8,
    sfx_speedhaste_MOTOR0_9,
    sfx_speedhaste_MOTOR1_0,
    sfx_speedhaste_MOTOR1_1,
    sfx_speedhaste_MOTOR1_2,
    sfx_speedhaste_MOTOR1_3,
    sfx_speedhaste_MOTOR1_4,
    sfx_speedhaste_MOTOR1_5,
    sfx_speedhaste_MOTOR1_6,
    sfx_speedhaste_MOTOR1_7,
    sfx_speedhaste_MOTOR1_8,
    sfx_speedhaste_MOTOR1_9,
    sfx_NumSpeedSounds
  );

type
  speedoundinfo_t = record
    name: string[32];
    duration: integer; // in tics
  end;

const
  speedsounds: array[0..Ord(sfx_NumSpeedSounds) - 1] of speedoundinfo_t = (
    (name: 'speedhaste/AUTOMATI.RAW'; duration: -1),
    (name: 'speedhaste/CIRCUIT.RAW'; duration: -1),
    (name: 'speedhaste/CRASH.RAW'; duration: -1),
    (name: 'speedhaste/DERRAPE.RAW'; duration: -1),
    (name: 'speedhaste/EXTTIME.RAW'; duration: -1),
    (name: 'speedhaste/GAMEOVER.RAW'; duration: -1),
    (name: 'speedhaste/GO.RAW'; duration: -1),
    (name: 'speedhaste/LAPREC.RAW'; duration: -1),
    (name: 'speedhaste/MANUAL.RAW'; duration: -1),
    (name: 'speedhaste/ONE.RAW'; duration: -1),
    (name: 'speedhaste/STARTECH.RAW'; duration: -1),
    (name: 'speedhaste/THREE.RAW'; duration: -1),
    (name: 'speedhaste/TIMEOVER.RAW'; duration: -1),
    (name: 'speedhaste/TWO.RAW'; duration: -1),
    (name: 'speedhaste/UNBELI.RAW'; duration: -1),
    (name: 'speedhaste/VIHECUL.RAW'; duration: -1),
    (name: 'speedhaste/MOTOR0_0'; duration: -1),
    (name: 'speedhaste/MOTOR0_1'; duration: -1),
    (name: 'speedhaste/MOTOR0_2'; duration: -1),
    (name: 'speedhaste/MOTOR0_3'; duration: -1),
    (name: 'speedhaste/MOTOR0_4'; duration: -1),
    (name: 'speedhaste/MOTOR0_5'; duration: -1),
    (name: 'speedhaste/MOTOR0_6'; duration: -1),
    (name: 'speedhaste/MOTOR0_7'; duration: -1),
    (name: 'speedhaste/MOTOR0_8'; duration: -1),
    (name: 'speedhaste/MOTOR0_9'; duration: -1),
    (name: 'speedhaste/MOTOR1_0'; duration: -1),
    (name: 'speedhaste/MOTOR1_1'; duration: -1),
    (name: 'speedhaste/MOTOR1_2'; duration: -1),
    (name: 'speedhaste/MOTOR1_3'; duration: -1),
    (name: 'speedhaste/MOTOR1_4'; duration: -1),
    (name: 'speedhaste/MOTOR1_5'; duration: -1),
    (name: 'speedhaste/MOTOR1_6'; duration: -1),
    (name: 'speedhaste/MOTOR1_7'; duration: -1),
    (name: 'speedhaste/MOTOR1_8'; duration: -1),
    (name: 'speedhaste/MOTOR1_9'; duration: -1)
  );

//==============================================================================
//
// S_AmbientSound
//
//==============================================================================
function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;

//==============================================================================
//
// S_AmbientSoundFV
//
//==============================================================================
function S_AmbientSoundFV(const x, y: integer; const sndname: string): Pmobj_t;

//==============================================================================
// S_SpeedSoundDuration
//
// Returns duration of sound in tics
//
//==============================================================================
function S_SpeedSoundDuration(const speed_snd: integer): integer;

//==============================================================================
//
// A_AmbientSound
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);

//==============================================================================
//
// A_AmbientSoundFV
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);

implementation

uses
  d_delphi,
  doomdef,
  info_common,
  p_common,
  p_local,
  p_mobj,
  s_sound,
  w_wad,
  z_zone;

//==============================================================================
//
// SH_RawToWAV
//
//==============================================================================
procedure SH_RawToWAV(const inp: pointer; const inpsize: integer; const hz: integer;
  const vol: fixed_t; out outp: pointer; out outsize: integer);
var
  PA: PLongWordArray;
  PB: PByteArray;
  sample: fixed_t;
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
  begin
    sample := PB[i];
    sample := (sample * vol) div FRACUNIT;
    PB[i] := 128 + sample;
  end;
end;

var
  m_ambient: integer = -1;

const
  STR_AMBIENTSOUND = 'AMBIENTSOUND';

//==============================================================================
//
// S_AmbientSound
//
//==============================================================================
function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;
begin
  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if m_ambient = -1 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOORZ, m_ambient);
  S_StartSound(result, sndname);
end;

//==============================================================================
//
// S_AmbientSoundFV
//
//==============================================================================
function S_AmbientSoundFV(const x, y: integer; const sndname: string): Pmobj_t;
begin
  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if m_ambient = -1 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOORZ, m_ambient);
  S_StartSound(result, sndname, true);
end;

type
  char4_t = packed array[0..3] of char;

//==============================================================================
//
// char4tostring
//
//==============================================================================
function char4tostring(const c4: char4_t): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 3 do
  begin
    if c4[i] in [#0, ' '] then
      exit;
    result := result + c4[i];
  end;
end;

//==============================================================================
//
// S_GetWaveLength
//
//==============================================================================
function S_GetWaveLength(const wavename: string): integer;
var
  groupID: char4_t;
  riffType: char4_t;
  BytesPerSec: integer;
  Stream: TAttachableMemoryStream;
  dataSize: integer;
  lump: integer;
  p: pointer;
  size: integer;
  // chunk seeking function,
  // -1 means: chunk not found

  function GotoChunk(const ID: string): Integer;
  var
    chunkID: char4_t;
    chunkSize: integer;
  begin
    result := -1;

    Stream.Seek(12, sFromBeginning);
    repeat
      // read next chunk
      Stream.Read(chunkID, 4);
      Stream.Read(chunkSize, 4);
      if char4tostring(chunkID) <> ID then
      // skip chunk
        Stream.Seek(Stream.Position + chunkSize, sFromBeginning);
    until (char4tostring(chunkID) = ID) or (Stream.Position >= Stream.Size);
    if char4tostring(chunkID) = ID then
      result := chunkSize;
  end;

begin
  Result := -1;

  lump := W_CheckNumForName(wavename);
  if lump < 0 then
    exit;

  size := W_LumpLength(lump);
  if size < 12 then
    exit;

  p := W_CacheLumpNum(lump, PU_STATIC);

  Stream := TAttachableMemoryStream.Create;
  Stream.Attach(p, size);
  Stream.Read(groupID, 4);
  Stream.Seek(8, sFromBeginning); // skip four bytes (file size)
  Stream.Read(riffType, 4);

  if (char4tostring(groupID) = 'RIFF') and (char4tostring(riffType) = 'WAVE') then
  begin
    // search for format chunk
    if GotoChunk('fmt') <> -1 then
    begin
      // found it
      Stream.Seek(Stream.Position + 8, sFromBeginning);
      Stream.Read(BytesPerSec, 4);
      //search for data chunk
      dataSize := GotoChunk('data');

      if dataSize > 0 then
        result := round(dataSize / BytesPerSec * TICRATE);
    end;
  end;
  Stream.Free;
  Z_ChangeTag(p, PU_CACHE);
end;

//==============================================================================
// S_SpeedSoundDuration
//
// Returns duration of sound in tics
//
//==============================================================================
function S_SpeedSoundDuration(const speed_snd: integer): integer;
begin
  if (speed_snd < Ord(sfx_speedhaste_AUTOMATI)) or (speed_snd >= Ord(sfx_NumSpeedSounds)) then
  begin
    result := -1;
    exit;
  end;

  result := speedsounds[speed_snd].duration;
  if result < 0 then
  begin
    result := S_GetWaveLength(speedsounds[speed_snd].name);
    speedsounds[speed_snd].duration := result;
  end;
end;

//==============================================================================
//
// A_AmbientSound
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  // JVAL: 20200304 -
  //  Hack! Allow zero string length sound inside RANDOMPICK to avoid playing the sound :)
  snd := actor.state.params.StrVal[2];
  if snd <> '' then
    S_AmbientSound(actor.x + dx, actor.y + dy, snd);
end;

//==============================================================================
//
// A_AmbientSoundFV
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  // JVAL: 20200304 -
  //  Hack! Allow zero string length sound inside RANDOMPICK to avoid playing the sound :)
  snd := actor.state.params.StrVal[2];
  if snd <> '' then
    S_AmbientSoundFV(actor.x + dx, actor.y + dy, snd);
end;

end.

