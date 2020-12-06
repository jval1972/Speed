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

unit i_mp3;

interface

uses
  d_delphi;

procedure I_InitMp3;

procedure I_StopMP3;

procedure I_PauseMP3;

procedure I_ResumeMP3;

procedure I_ShutDownMP3;

procedure I_PlayMP3(strm: TDStream);

var
  usemp3: boolean;
  preferemp3namesingamedirectory: boolean;

implementation

uses
  sounds,
  mp3_OBuffer_MCI,
  mp3_MPEGPlayer;

var
  mp3player: TMPEGPlayer;

procedure I_InitMp3;
begin
  mp3player := TMPEGPlayer.Create;
end;

procedure I_StopMP3;
begin
  if mp3player <> nil then
  begin
    if mp3player.IsPlaying then
      mp3player.Stop;
    FreeAndNil(mp3player);
  end;
end;

procedure I_PauseMP3;
begin
  if mp3player <> nil then
    mp3player.Pause;
end;

procedure I_ResumeMP3;
begin
  if mp3player <> nil then
    mp3player.Resume;
end;

procedure I_ShutDownMP3;
begin
  I_StopMP3;
  S_FreeMP3Streams;
end;

procedure I_PlayMP3(strm: TDStream);
begin
  I_StopMP3;
  I_InitMp3;
  mp3player.LoadStream(strm);
  mp3player.SetOutput(CreateMCIOBffer(mp3player));
  mp3player.DoRepeat := true;
  mp3player.Play;
end;

end.
