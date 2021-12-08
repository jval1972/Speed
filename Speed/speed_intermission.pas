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
  speed_palette,
  v_data,
  v_video,
  w_wad;

var
  in_tic: integer;
  in_stage: integer;
  in_stage_tic: integer; // tics in stage
  in_struct: Pwbstartstruct_t;

procedure SH_CheckForInput;
var
  i: integer;
  player: Pplayer_t;
  score: Pplayerscore_t;
begin
  if in_stage_tic < TICRATE div 2 then // Do not allow very fast screen change
    Exit;

  score := @players[consoleplayer].currentscore;

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
         if gametype <> gt_championship then
            D_StartTitle;
        end
        else if in_stage = 4 then
        begin
          if (gametype = gt_championship) and (gamemap < 8) then
          begin
            if W_CheckNumForName('E' + itoa(score.episode) + 'M' + itoa(score.map + 1)) < 0 then
              D_StartTitle
            else
              G_WorldDone;
          end
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
      if race.gametype <> gt_practice then
        SH_UpdateScoreTable(@players[consoleplayer], score.episode, score.map, gameskill);
end;

// Race results
procedure SH_Intermission_Drawer0;
var
  score: Pplayerscore_t;
  mname: string;
  mpos: menupos_t;
  i: integer;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RESU');

  score := @players[consoleplayer].currentscore;

  mname := P_GetMapName(score.episode, score.map);

  mpos := M_WriteText(18, 55, 'Course: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, SH_MapData(mname).name, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, ' (', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, mname, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, ')', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  mpos := M_WriteText(18, 65, 'Player: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, players[consoleplayer].playername, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(mpos.x, mpos.y, '  Rank: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, SH_FmtRacePostion(score.raceposition), _MA_LEFT or _MC_NOCASE, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(18, 75, 'Car: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, CARINFO[score.carinfo].name, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(18, 85, 'Total time: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, SH_TicsToTimeStr(score.totaltime), _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, ' (', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, itoa(score.numlaps) + ' Laps', _MA_LEFT or _MC_NOCASE, @hu_fontW, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, ')', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  for i := 0 to players[consoleplayer].currentscore.numlaps - 1 do
  begin
    mpos := M_WriteText(18, 95 + 10 * i, 'Lap #' + itoa(i + 1) + ': ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
    M_WriteText(mpos.x, mpos.y, SH_TicsToTimeStr(score.laptimes[i]), _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  end;

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer1;
var
  score: Pplayerscore_t;
  stmp: string;
  mname: string;
  mpos: menupos_t;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');

  V_DrawPatch(161, 50, SCN_TMP, 'REC_TXT', false);
  SH_FixBufferPalette(screens[SCN_TMP], 1, 50 * 320);

  score := @players[consoleplayer].currentscore;

  mname := P_GetMapName(score.episode, score.map);
  mpos := M_WriteText(18, 55, 'Course: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, SH_MapData(mname).name, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, ' (', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, mname, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, ')', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  if CARINFO[score.carinfo].cartype = ct_formula then
    stmp := 'Formula 1: '
  else if CARINFO[score.carinfo].cartype = ct_stock then
    stmp := 'Stock car: '
  else
    Exit;

  mpos := M_WriteText(18, 65, stmp, _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, 'lap records', _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);

  SH_DrawScoreTableItems(
    @recordtable.laprecords[
      score.episode,
      score.map,
      CARINFO[score.carinfo].cartype]);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer2;
var
  score: Pplayerscore_t;
  stmp: string;
  mname: string;
  mpos: menupos_t;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');

  V_DrawPatch(161, 50, SCN_TMP, 'REC_TXT', false);
  SH_FixBufferPalette(screens[SCN_TMP], 1, 50 * 320);

  score := @players[consoleplayer].currentscore;

  mname := P_GetMapName(score.episode, score.map);
  mpos := M_WriteText(18, 55, 'Course: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, SH_MapData(mname).name, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, ' (', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, mname, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, ')', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  if CARINFO[score.carinfo].cartype = ct_formula then
    stmp := 'Formula 1: '
  else if CARINFO[score.carinfo].cartype = ct_stock then
    stmp := 'Stock car: '
  else
    Exit;

  mpos := M_WriteText(18, 65, stmp, _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, 'course records ', _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, '(', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, itoa(score.numlaps) + ' Laps', _MA_LEFT or _MC_NOCASE, @hu_fontW, @hu_fontB);
  M_WriteText(mpos.x, mpos.y, ')', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  SH_DrawScoreTableItems(
    @recordtable.courserecord[
      score.numlaps,
      score.episode,
      score.map,
      CARINFO[score.carinfo].cartype]);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

// Race results
procedure SH_Intermission_Drawer3;
var
  score: Pplayerscore_t;
  mpos: menupos_t;
  ypos: integer;
  i: integer;
  cname: string;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');

  V_DrawPatch(161, 50, SCN_TMP, 'REC_TXT', false);
  SH_FixBufferPalette(screens[SCN_TMP], 1, 50 * 320);

  score := @players[consoleplayer].currentscore;

  mpos := M_WriteText(18, 55, 'Championship: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, itoa(score.episode), _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);

  mpos := M_WriteText(18, 65, 'Player: ', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  mpos := M_WriteText(mpos.x, mpos.y, players[consoleplayer].playername, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);

  ypos := 80;
  M_WriteText(18, ypos, 'Course', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  M_WriteText(183, ypos, 'Rank', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);
  M_WriteText(254, ypos, 'Time', _MA_LEFT or _MC_UPPER, @hu_fontY, @hu_fontB);

  ypos := 95;
  for i := 1 to 8 do
  begin
    M_WriteText(16, ypos, itoa(i), _MA_RIGHT or _MC_UPPER, @hu_fontY, @hu_fontB);
    if players[consoleplayer].score[score.episode, i].totaltime > 0 then
    begin
      cname := SH_MapData(P_GetMapName(score.episode, i)).name;
      if Length(cname) > 20 then
        SetLength(cname, 20);
      M_WriteText(18, ypos, cname, _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
      M_WriteText(215, ypos, SH_FmtRacePostion(players[consoleplayer].score[score.episode, i].raceposition), _MA_RIGHT or _MC_NOCASE, @hu_fontW, @hu_fontB);
      M_WriteText(254, ypos, SH_TicsToTimeStr(players[consoleplayer].score[score.episode, i].totaltime), _MA_LEFT or _MC_UPPER, @hu_fontW, @hu_fontB);
    end;
    ypos := ypos + 10;
  end;

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

procedure SH_Intermission_Drawer;
var
  draw_stage: integer;
begin
  if gametype = gt_championship then
    draw_stage := in_stage
  else
    draw_stage := GetIntegerInRange(in_stage, 0, 2);
  case draw_stage of
    0: SH_Intermission_Drawer0;
    1: SH_Intermission_Drawer1;
    2: SH_Intermission_Drawer2;
    3: SH_Intermission_Drawer3;
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
