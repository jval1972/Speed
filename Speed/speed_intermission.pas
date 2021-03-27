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
//  Speed Intermission Screen
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_intermission;

interface

// Called by main loop
procedure SH_Intermission_Ticker;

// Called by main loop,
// draws the intermission directly into the screen buffer.
procedure SH_Intermission_Drawer;

// Setup for an intermission screen.
procedure SH_Intermission_Start;

implementation

uses
  d_delphi,
  doomdef,
  d_main,
  m_fixed,
  d_player,
  d_event,
  g_game,
  hu_stuff,
  mn_textwrite,
  p_setup,
  sounds,
  s_sound,
  speed_cars,
  speed_mapdata,
  speed_score,
  speed_score_draw,
  speed_race,
  speed_path,
  speed_string_format,
  v_data,
  v_video;

var
  in_tic: integer;
  in_stage: integer;
  in_stage_tic: integer; // tics in stage
  in_struct: Pwbstartstruct_t;

procedure SH_CheckForInput;
var
  i: integer;
  player: Pplayer_t;
begin
  if in_stage_tic < TICRATE div 2 then // Do not allow very fast screen change
    Exit;

  // check for button presses to skip delays
  for i := 0 to MAXPLAYERS - 1 do
  begin
    player := @players[i];

    if playeringame[i] then
      if (player.cmd.buttons and BT_ATTACK <> 0) or (player.cmd.buttons and BT_USE <> 0) then
      begin
        inc(in_stage);
        in_stage_tic := 0;
        if in_stage = 3 then
        begin
          if gametype = gt_championship then
            G_WorldDone
          else
            D_StartTitle;
        end;
      end;
  end;
end;

// Updates stuff each tick
procedure SH_Intermission_Ticker;
begin
  inc(in_tic);
  inc(in_stage_tic);

  if in_tic = 1 then
  begin
    // intermission music
    S_ChangeMusic(Ord(mus_intro), true);
  end;

  SH_CheckForInput;
end;

procedure SH_StorePlayerScore;
var
  score: Pplayerscore_t;
begin
  if gametype = gt_practice then
    Exit;

  score := @players[consoleplayer].currentscore;

  if IsIntegerInRange(score.episode, 1, 4) then
    if IsIntegerInRange(score.map, 1, 9) then
      players[consoleplayer].score[score.episode, score.map] := score^;

  if not netgame then
    if not demoplayback then
      SH_UpdateScoreTable(@players[consoleplayer], score.episode, score.map, gameskill);
end;

// Race results
procedure SH_Intermission_Drawer0;
var
  mpos: menupos_t;
  i: integer;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RESU');

  mpos := M_WriteText(30, 50, 'Player: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, players[consoleplayer].playername, ma_left, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(30, 60, 'Car: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, CARINFO[players[consoleplayer].currentscore.carinfo].name, ma_left, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(30, 70, 'Total time: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, SH_TicsToTimeStr(players[consoleplayer].currentscore.totaltime), ma_left, @hu_fontW, @hu_fontB);

  for i := 0 to players[consoleplayer].currentscore.numlaps - 1 do
  begin
    mpos := M_WriteText(30, 80 + 10 * i, 'Lap #' + itoa(i + 1) + ': ', ma_left, @hu_fontY, @hu_fontB);
    M_WriteText(mpos.x, mpos.y, SH_TicsToTimeStr(players[consoleplayer].currentscore.laptimes[i]), ma_left, @hu_fontW, @hu_fontB);
  end;

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer1;
var
  stmp: string;
  mname: string;
  mpos: menupos_t;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');

  V_DrawPatch(161, 50, SCN_TMP, 'REC_TXT', false);

  if CARINFO[players[consoleplayer].currentscore.carinfo].cartype = ct_formula then
    stmp := 'Formula 1 lap records'
  else if CARINFO[players[consoleplayer].currentscore.carinfo].cartype = ct_stock then
    stmp := 'Stock car lap records'
  else
    Exit;

  M_WriteText(160, 51, stmp, ma_center, @hu_fontY, @hu_fontB);

  mname := P_GetMapName(players[consoleplayer].currentscore.episode, players[consoleplayer].currentscore.map);

  mpos := M_WriteText(18, 64, 'Course: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, SH_MapData(mname).name, ma_left, @hu_fontW, @hu_fontB);

  SH_DrawScoreTableItems(
    @recordtable.laprecords[
      players[consoleplayer].currentscore.episode,
      players[consoleplayer].currentscore.map,
      CARINFO[players[consoleplayer].currentscore.carinfo].cartype]);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer2;
var
  stmp: string;
  mname: string;
  mpos: menupos_t;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');

  V_DrawPatch(161, 50, SCN_TMP, 'REC_TXT', false);

  if CARINFO[players[consoleplayer].currentscore.carinfo].cartype = ct_formula then
    stmp := 'Formula 1 track records'
  else if CARINFO[players[consoleplayer].currentscore.carinfo].cartype = ct_stock then
    stmp := 'Stock car track records'
  else
    Exit;

  M_WriteText(160, 51, stmp, ma_center, @hu_fontY, @hu_fontB);

  mname := P_GetMapName(players[consoleplayer].currentscore.episode, players[consoleplayer].currentscore.map);

  mpos := M_WriteText(18, 64, 'Course: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, SH_MapData(mname).name, ma_left, @hu_fontW, @hu_fontB);

  SH_DrawScoreTableItems(
    @recordtable.courserecord[
      players[consoleplayer].currentscore.numlaps,
      players[consoleplayer].currentscore.episode,
      players[consoleplayer].currentscore.map,
      CARINFO[players[consoleplayer].currentscore.carinfo].cartype]);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer;
begin
  case in_stage of
    0: SH_Intermission_Drawer0;
    1: SH_Intermission_Drawer1;
    2: SH_Intermission_Drawer2;
  end;
end;

procedure SH_Intermission_Start;
begin
  in_struct := @wminfo;
  in_tic := 0;
  in_stage_tic := 0;
  in_stage := 0;
  SH_StorePlayerScore;
end;

end.
