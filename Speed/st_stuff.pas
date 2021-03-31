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
//  Status bar code.
//  Does the face/direction indicator animatin.
//  Does palette indicators as well (red pain/berserk, bright pickup)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit st_stuff;

interface

uses
  doomdef,
  d_event;

// Size of statusbar.
// Now sensitive for scaling.
const
  ST_HEIGHT = 32;
  ST_WIDTH = 320;
  ST_Y = 200 - ST_HEIGHT;

var
  st_palette: integer;
// lump number for PLAYPAL
  lu_palette: integer;

//
// STATUS BAR
//

// Called by main loop.
function ST_Responder(ev: Pevent_t): boolean;

// Called by main loop.
procedure ST_Drawer;

// Called when the console player is spawned on each level.
procedure ST_Start;

// Called by startup code.
procedure ST_Init;



// States for status bar code.
type
  st_stateenum_t = (
    st_automapstate,
    st_firstpersonstate
  );

// States for the chat code.
  st_chatstateenum_t = (
    StartChatState,
    WaitDestState,
    GetChatState
  );

implementation

uses
  d_delphi,
  d_net,
  m_menu,
  tables,
  c_cmds,
  d_items,
  z_zone,
  w_wad,
  info,
  info_h,
{$IFDEF OPENGL}
  gl_main,
  gl_render,
{$ELSE}
  r_hires,
  i_video,
{$ENDIF}
  g_game,
  st_lib,
  p_inter,
  p_setup,
  p_enemy,
  d_player,
  r_defs,
  r_main,
  r_draw,
  am_map,
  m_cheat,
  m_rnd,
  m_fixed,
  s_sound,
// Needs access to LFB.
  v_data,
  v_video,
// State.
  doomstat,
// Data.
  dstrings,
  d_englsh,
  sounds,
// for mapnames
  hu_stuff;

//
// STATUS BAR DATA
//

const
// Palette indices.
// For damage/bonus red-/gold-shifts
  STARTREDPALS = 1;
  STARTBONUSPALS = 9;
  NUMREDPALS = 8;
  NUMBONUSPALS = 4;
// Radiation suit, green shift.
  RADIATIONPAL = 13;

var

// main player in game
  plyr: Pplayer_t;

// whether in automap or first-person
  st_gamestate: st_stateenum_t;

const
// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
  cheat_mus_seq: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ae), Chr($ea),
    Chr($1),  Chr($0),  Chr($0),  Chr($ff)
  ); // idmus

  cheat_choppers_seq: array[0..10] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($32), Chr($f6),
    Chr($2a), Chr($2a), Chr($a6), Chr($6a), Chr($ea),
    Chr($ff) // id...
  );

  cheat_god_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($26), Chr($aa), Chr($26),
    Chr($ff)  // iddqd
  );

  cheat_ammo_seq: array[0..5] of char = (
    Chr($b2), Chr($26), Chr($f2), Chr($66), Chr($a2),
    Chr($ff)  // idkfa
  );

  cheat_ammonokey_seq: array[0..4] of char = (
    Chr($b2), Chr($26), Chr($66), Chr($a2), Chr($ff) // idfa
  );

// Smashing Pumpkins Into Samml Piles Of Putried Debris.
  cheat_noclip_seq: array[0..10] of char = (
    Chr($b2), Chr($26), Chr($ea), Chr($2a), Chr($b2), // idspispopd
    Chr($ea), Chr($2a), Chr($f6), Chr($2a), Chr($26),
    Chr($ff)
  );

//
  cheat_commercial_noclip_seq: array[0..6] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($b2),
    Chr($2a), Chr($ff)  // idclip
  );



  cheat_powerup_seq0: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6e), Chr($ff)  // beholdv
  );

  cheat_powerup_seq1: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ea), Chr($ff)  // beholds
  );

  cheat_powerup_seq2: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($b2), Chr($ff)  // beholdi
  );

  cheat_powerup_seq3: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($6a), Chr($ff)  // beholdr
  );

  cheat_powerup_seq4: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($a2), Chr($ff)  // beholda
  );

  cheat_powerup_seq5: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($36), Chr($ff)  // beholdl
  );

  cheat_powerup_seq6: array[0..8] of char = (
    Chr($b2), Chr($26), Chr($62), Chr($a6), Chr($32),
    Chr($f6), Chr($36), Chr($26), Chr($ff)  // behold
  );


  cheat_clev_seq: array[0..9] of char = (
    Chr($b2), Chr($26), Chr($e2), Chr($36), Chr($a6),
    Chr($6e), Chr($1),  Chr($0),  Chr($0),  Chr($ff)  // idclev
  );

// my position cheat
  cheat_mypos_seq: array[0..7] of char = (
    Chr($b2), Chr($26), Chr($b6), Chr($ba), Chr($2a),
    Chr($f6), Chr($ea), Chr($ff) // idmypos
  );

// JVAL: Give All Keys cheat
  cheat_idkeys_seq: array[0..6] of char = (
    Chr($b2), Chr($26), Chr($f2), Chr($a6), Chr($ba),
    Chr($ea), Chr($ff) // idkeys
  );


var
// Now what?
  cheat_mus: cheatseq_t;
  cheat_god: cheatseq_t;
  cheat_ammo: cheatseq_t;
  cheat_ammonokey: cheatseq_t;
  cheat_keys: cheatseq_t;
  cheat_noclip: cheatseq_t;
  cheat_commercial_noclip: cheatseq_t;

  cheat_powerup: array[0..6] of cheatseq_t;

  cheat_choppers: cheatseq_t;
  cheat_clev: cheatseq_t;
  cheat_mypos: cheatseq_t;

//
// Commands
//
function ST_CmdCheckPlayerStatus: boolean;
begin
  if (plyr = nil) or (plyr.mo = nil) or (gamestate <> GS_LEVEL) or demoplayback or netgame then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    result := false;
  end
  else
    result := true;
end;

procedure ST_CmdGod;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  if plyr.playerstate <> PST_DEAD then
  begin
    plyr.cheats := plyr.cheats xor CF_GODMODE;
    if plyr.cheats and CF_GODMODE <> 0 then
    begin
      if plyr.mo <> nil then
        plyr.mo.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;

      plyr.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
      plyr._message := STSTR_DQDON;
    end
    else
      plyr._message := STSTR_DQDOFF;
  end
  else
  begin
    C_ExecuteCmd('closeconsole');
    plyr.playerstate := PST_REBORN;
  end;
end;

procedure ST_CmdMassacre;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  if (gamestate = GS_LEVEL) and (plyr.mo <> nil) then
  begin
    P_Massacre;
    plyr._message := STSTR_MASSACRE;
  end;
end;

procedure ST_CmdLowGravity;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.cheats := plyr.cheats xor CF_LOWGRAVITY;
  if plyr.cheats and CF_LOWGRAVITY <> 0 then
    plyr._message := STSTR_LGON
  else
    plyr._message := STSTR_LGOFF;
end;

procedure ST_CmdIDFA;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.armorpoints := 200;
  plyr.armortype := 2;

  if gamemode = shareware then
  begin
    for i := 0 to Ord(wp_missile) do
      plyr.weaponowned[i] := 1;

    for i := 0 to Ord(NUMAMMO) - 1 do
      if i <> Ord(am_cell) then
        plyr.ammo[i] := plyr.maxammo[i];
  end
  else
  begin
    for i := 0 to Ord(NUMWEAPONS) - 1 do
      plyr.weaponowned[i] := 1;

    for i := 0 to Ord(NUMAMMO) - 1 do
      plyr.ammo[i] := plyr.maxammo[i];
  end;

  plyr._message := STSTR_FAADDED;
end;

procedure ST_CmdIDKFA;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.armorpoints := 200;
  plyr.armortype := 2;

  if gamemode = shareware then
  begin
    for i := 0 to Ord(wp_missile) - 1 do
      plyr.weaponowned[i] := 1;

    for i := 0 to Ord(NUMAMMO) - 1 do
      if i <> Ord(am_cell) then
        plyr.ammo[i] := plyr.maxammo[i];
  end
  else
  begin
    for i := 0 to Ord(NUMWEAPONS) - 1 do
      plyr.weaponowned[i] := 1;

    for i := 0 to Ord(NUMAMMO) - 1 do
      plyr.ammo[i] := plyr.maxammo[i];
  end;

  for i := 0 to Ord(NUMCARDS) - 1 do
    plyr.cards[i] := true;

  plyr._message := STSTR_KFAADDED;
end;

procedure ST_CmdIDKEYS;
var
  i: integer;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  for i := 0 to Ord(NUMCARDS) - 1 do
    plyr.cards[i] := true;

  plyr._message := STSTR_KEYSADDED;
end;

procedure ST_CmdIDDT;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  am_cheating := (am_cheating + 1) mod 3;
end;

procedure ST_CmdIDNoClip;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  plyr.cheats := plyr.cheats xor CF_NOCLIP;

  if plyr.cheats and CF_NOCLIP <> 0 then
    plyr._message := STSTR_NCON
  else
    plyr._message := STSTR_NCOFF;
end;

procedure ST_CmdIDMyPos;
var
  buf: string;
begin
  if not ST_CmdCheckPlayerStatus then
    exit;

  sprintf(buf, 'ang = %d, (x, y, z) = (%d, %d, %d)', [
          plyr.mo.angle div $B60B60,
          plyr.mo.x div FRACUNIT,
          plyr.mo.y div FRACUNIT,
          plyr.mo.z div FRACUNIT]);
  plyr._message := buf;
end;

// Respond to keyboard input events,
//  intercept cheats.
function ST_Responder(ev: Pevent_t): boolean;
var
  i: integer;
  buf: string;
  musnum: integer;
  epsd: integer;
  map: integer;
  ateit: boolean; // JVAL Cheats ate the event

  function check_cheat(cht: Pcheatseq_t; key: char): boolean;
  var
    cht_ret: cheatstatus_t;
  begin
    cht_ret := cht_CheckCheat(cht, key);
    result := cht_ret = cht_acquired;
    if not ateit then
      ateit := (cht_ret in [cht_pending, cht_acquired])
  end;

begin
  result := false;
  ateit := false;
  // Filter automap on/off.
  if (ev._type = ev_keyup) and
     ((ev.data1 and $ffff0000) = AM_MSGHEADER) then
  begin
    case ev.data1 of
      AM_MSGENTERED:
        begin
          st_gamestate := st_automapstate;
        end;

      AM_MSGEXITED:
        begin
          //  fprintf(stderr, "AM exited\n");
          st_gamestate := st_firstpersonstate;
        end;
    end;
  end
  // if a user keypress...
  else if ev._type = ev_keydown then
  begin
    if plyr = nil then
    begin
      result := false;
      exit;
    end;

    if plyr.mo = nil then
    begin
      result := false;
      exit;
    end;

    if not netgame then
    begin
      // b. - enabled for more debug fun.
      // if (gameskill != sk_nightmare) {

      // 'dqd' cheat for toggleable god mode
      if check_cheat(@cheat_god, Chr(ev.data1)) then
      begin
        ST_CmdGod;
      end
      // 'fa' cheat for killer fucking arsenal
      else if check_cheat(@cheat_ammonokey, Chr(ev.data1)) then
      begin
        ST_CmdIDFA;
      end
      // JVAL: 'keys' cheat
      else if check_cheat(@cheat_keys, Chr(ev.data1)) then
      begin
        ST_CmdIDKEYS;
      end
      // 'kfa' cheat for key full ammo
      else if check_cheat(@cheat_ammo, Chr(ev.data1)) then
      begin
        ST_CmdIDKFA;
      end
      else if check_cheat(@cheat_amap, Chr(ev.data1)) then
      begin
        ST_CmdIDDT;
      end
      // 'mus' cheat for changing music
      else if check_cheat(@cheat_mus, Chr(ev.data1)) then
      begin
        plyr._message := STSTR_MUS;
        cht_GetParam(@cheat_mus, buf);

        musnum := Ord(mus_e1m1) + (Ord(buf[1]) - Ord('1')) * 9 + Ord(buf[2]) - Ord('1');

        if (musnum > 0) and (buf[2] <> '0') and
           ( ((musnum < 28) and (gamemode <> shareware)) or
             ((musnum < 10) and (gamemode = shareware))) then
          S_ChangeMusic(musnum, true)
        else
          plyr._message := STSTR_NOMUS;
      end
      // Simplified, accepting both "noclip" and "idspispopd".
      // no clipping mode cheat
      else if check_cheat(@cheat_noclip, Chr(ev.data1)) or
              check_cheat(@cheat_commercial_noclip, Chr(ev.data1)) then
      begin
        ST_CmdIDNoClip;
      end;
      // 'behold?' power-up cheats
      for i := 0 to 5 do
      begin
        if check_cheat(@cheat_powerup[i], Chr(ev.data1)) then
        begin
          if plyr.powers[i] = 0 then
            P_GivePower(plyr, i)
          else if i <> Ord(pw_strength) then
            plyr.powers[i] := 1
          else
            plyr.powers[i] := 0;

          plyr._message := STSTR_BEHOLDX;
        end;
      end;

      // 'behold' power-up menu
      if check_cheat(@cheat_powerup[6], Chr(ev.data1)) then
      begin
        plyr._message := STSTR_BEHOLD;
      end
      // 'choppers' invulnerability & chainsaw
      else if check_cheat(@cheat_choppers, Chr(ev.data1)) then
      begin
        plyr.weaponowned[Ord(wp_chainsaw)] := 1;
        plyr.powers[Ord(pw_invulnerability)] := INVULNTICS;
        plyr._message := STSTR_CHOPPERS;
      end
      // 'mypos' for player position
      else if check_cheat(@cheat_mypos, Chr(ev.data1)) then
      begin
        ST_CmdIDMyPos;
      end;
    end;

    // 'clev' change-level cheat
    if check_cheat(@cheat_clev, Chr(ev.data1)) then
    begin
      cht_GetParam(@cheat_clev, buf);
      plyr._message := STSTR_WLEV;

      epsd := Ord(buf[1]) - Ord('0');
      map := Ord(buf[2]) - Ord('0');
      // Catch invalid maps.
      if epsd < 1 then
        exit;

      if map < 1 then
        exit;

      // Ohmygod - this is not going to work.
      if (gamemode = retail) and
         ((epsd > 4) or (map > 9)) then
        exit;

      if (gamemode = registered) and
         ((epsd > 3) or (map > 9)) then
        exit;

      if (gamemode = shareware) and
         ((epsd > 1) or (map > 9)) then
        exit;

      // So be it.
      if W_CheckNumForName(P_GetMapName(epsd, map)) > -1 then
      begin
        plyr._message := STSTR_CLEV;
        G_DeferedInitNew(gameskill, gametype, epsd, map);
      end;
    end;
  end;
  result := result or ateit;
end;

procedure ST_DoPaletteStuff;
var
  palette: integer;
  pal: PByteArray;
  cnt: integer;
  bzc: integer;
  p: pointer;
begin
  if plyr = nil then
    exit;

  cnt := plyr.damagecount;

  if plyr.powers[Ord(pw_strength)] <> 0 then
  begin
    // slowly fade the berzerk out
    bzc := 12 - _SHR(plyr.powers[Ord(pw_strength)], 6);

    if bzc > cnt then
      cnt := bzc;
  end;

  if cnt <> 0 then
  begin
    palette := _SHR(cnt + 7, 3);

    if palette >= NUMREDPALS then
      palette := NUMREDPALS - 1;

    palette := palette + STARTREDPALS;
  end
  else if plyr.bonuscount <> 0 then
  begin
    palette := _SHR(plyr.bonuscount + 7, 3);

    if palette >= NUMBONUSPALS then
      palette := NUMBONUSPALS - 1;

    palette := palette + STARTBONUSPALS;
  end
  else if (plyr.powers[Ord(pw_ironfeet)] > 4 * 32) or
          (plyr.powers[Ord(pw_ironfeet)] and 8 <> 0) then
    palette := RADIATIONPAL
  else
    palette := 0;

  if palette <> st_palette then
  begin
    st_palette := palette;
    {$IFDEF OPENGL}
    gld_SetPalette(palette);
    {$ELSE}
    R_SetPalette(palette);
    {$ENDIF}
    p := W_CacheLumpNum(lu_palette, PU_STATIC);
    pal := PByteArray(integer(p) + palette * 768);
    {$IFDEF OPENGL}
    I_SetPalette(pal);
    V_SetPalette(pal);
    {$ELSE}
    IV_SetPalette(pal);
    {$ENDIF}
    Z_ChangeTag(p, PU_CACHE);
  end;
end;

procedure ST_Drawer;
begin
  ST_DoPaletteStuff;
end;

procedure ST_LoadData;
begin
  lu_palette := W_GetNumForName(PLAYPAL);
end;

var
  st_stopped: boolean;

procedure ST_Stop;
var
  pal: PByteArray;
begin
  if st_stopped then
    exit;

  pal := PByteArray(W_CacheLumpNum(lu_palette, PU_STATIC));
  I_SetPalette(pal);
  V_SetPalette(pal);
  Z_ChangeTag(pal, PU_CACHE);

  st_stopped := true;
end;

procedure ST_Start;
begin
  if not st_stopped then
    ST_Stop;

  st_stopped := false;

  plyr := @players[consoleplayer];
end;

procedure ST_Init;
begin
////////////////////////////////////////////////////////////////////////////////
// Now what?
  cheat_mus.sequence := get_cheatseq_string(cheat_mus_seq);
  cheat_mus.p := get_cheatseq_string(0);
  cheat_god.sequence := get_cheatseq_string(cheat_god_seq);
  cheat_god.p := get_cheatseq_string(0);
  cheat_ammo.sequence := get_cheatseq_string(cheat_ammo_seq);
  cheat_ammo.p := get_cheatseq_string(0);
  cheat_ammonokey.sequence := get_cheatseq_string(cheat_ammonokey_seq);
  cheat_ammonokey.p := get_cheatseq_string(0);
  cheat_keys.sequence := get_cheatseq_string(cheat_idkeys_seq);
  cheat_keys.p := get_cheatseq_string(0);
  cheat_noclip.sequence := get_cheatseq_string(cheat_noclip_seq);
  cheat_noclip.p := get_cheatseq_string(0);
  cheat_commercial_noclip.sequence := get_cheatseq_string(cheat_commercial_noclip_seq);
  cheat_commercial_noclip.p := get_cheatseq_string(0);

  cheat_powerup[0].sequence := get_cheatseq_string(cheat_powerup_seq0);
  cheat_powerup[0].p := get_cheatseq_string(0);
  cheat_powerup[1].sequence := get_cheatseq_string(cheat_powerup_seq1);
  cheat_powerup[1].p := get_cheatseq_string(0);
  cheat_powerup[2].sequence := get_cheatseq_string(cheat_powerup_seq2);
  cheat_powerup[2].p := get_cheatseq_string(0);
  cheat_powerup[3].sequence := get_cheatseq_string(cheat_powerup_seq3);
  cheat_powerup[3].p := get_cheatseq_string(0);
  cheat_powerup[4].sequence := get_cheatseq_string(cheat_powerup_seq4);
  cheat_powerup[4].p := get_cheatseq_string(0);
  cheat_powerup[5].sequence := get_cheatseq_string(cheat_powerup_seq5);
  cheat_powerup[5].p := get_cheatseq_string(0);
  cheat_powerup[6].sequence := get_cheatseq_string(cheat_powerup_seq6);
  cheat_powerup[6].p := get_cheatseq_string(0);

  cheat_choppers.sequence := get_cheatseq_string(cheat_choppers_seq);
  cheat_choppers.p := get_cheatseq_string(0);
  cheat_clev.sequence := get_cheatseq_string(cheat_clev_seq);
  cheat_clev.p := get_cheatseq_string(0);
  cheat_mypos.sequence := get_cheatseq_string(cheat_mypos_seq);
  cheat_mypos.p := get_cheatseq_string(0);

  st_palette := 0;

  st_stopped := true;
////////////////////////////////////////////////////////////////////////////////

  ST_LoadData;
  C_AddCmd('god, iddqd', @ST_CmdGod);
  C_AddCmd('massacre', @ST_CmdMassacre);
  C_AddCmd('givefullammo, rambo, idfa', @ST_CmdIDFA);
  C_AddCmd('giveallkeys, idkeys', @ST_CmdIDKEYS);
  C_AddCmd('lowgravity', @ST_CmdLowGravity);
  C_AddCmd('givefullammoandkeys, idkfa', @ST_CmdIDKFA);
  C_AddCmd('iddt', @ST_CmdIDDT);
  C_AddCmd('idspispopd, idclip', @ST_CmdIDNoClip);
  C_AddCmd('idmypos', @ST_CmdIDMyPos);
end;

end.
