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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Savegame I/O, archiving, persistence.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit p_saveg;

interface

uses
  d_delphi;

// Persistent storage/archiving.
// These are the load / save game routines.
procedure P_ArchivePlayers;

procedure P_UnArchivePlayers;

procedure P_ArchiveWorld;

procedure P_UnArchiveWorld;

procedure P_ArchiveThinkers;

procedure P_UnArchiveThinkers;

procedure P_ArchiveSpecials;

procedure P_UnArchiveSpecials;

procedure P_ArchiveVariables;

procedure P_UnArchiveVariables;

procedure P_ArchivePSMapScript;

procedure P_UnArchivePSMapScript;

procedure P_ArchiveOverlay;

procedure P_UnArchiveOverlay;

procedure P_ArchiveRace;

procedure P_UnArchiveRace;

procedure P_ArchivePaths;

procedure P_UnArchivePaths;

procedure P_ArchiveChampionShip;

procedure P_UnArchiveChampionShip;

var
  save_p: PByteArray;
  savegameversion: integer;

implementation

uses
  doomdef,
  d_ticcmd,
  d_player,
  d_think,
  g_game,
  m_fixed,
  info_h,
  info,
  i_tmp,
  i_system,
  p_3dfloors, // JVAL: 3d floors
  p_local,    // JVAL: sector gravity (VERSION 204)
  p_pspr_h,
  p_setup,
  p_mobj_h,
  p_mobj,
  p_mobjlist,
  p_tick,
  p_maputl,
  p_spec,
  p_ceilng,
  p_doors,
  p_floor,
  p_plats,
  p_lights,
  p_scroll,
  p_params,
  p_levelinfo,
  ps_main,
  psi_globals,
  psi_overlay,
  speed_path,
  speed_race,
  speed_championship,
  r_defs,
  r_data,
  r_colormaps,
  r_renderstyle,
  w_wad,
  z_zone;

//
// P_ArchivePlayers
//
procedure P_ArchivePlayers;
var
  i: integer;
  j: integer;
  dest: Pplayer_t;
begin
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if not playeringame[i] then
      continue;

    dest := Pplayer_t(save_p);
    memcpy(dest, @players[i], SizeOf(player_t));
    save_p := PByteArray(integer(save_p) + SizeOf(player_t));
    for j := 0 to Ord(NUMPSPRITES) - 1 do
      if dest.psprites[j].state <> nil then
        dest.psprites[j].state := Pstate_t(pDiff(dest.psprites[j].state, @states[0], SizeOf(dest.psprites[j].state^)));
    if dest.enginesoundtarget <> nil then
      dest.enginesoundtarget := Pmobj_t(dest.enginesoundtarget.key);
    if dest.messagesoundtarget <> nil then
      dest.messagesoundtarget := Pmobj_t(dest.messagesoundtarget.key);

  end;
end;

//
// P_UnArchivePlayers
//
procedure P_UnArchivePlayers;
var
  i: integer;
  j: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
  begin
    if not playeringame[i] then
      continue;

    memcpy(@players[i], save_p, SizeOf(player_t));
    incp(pointer(save_p), SizeOf(player_t));

    // will be set when unarc thinker
    players[i].mo := nil;
    players[i]._message := '';
    players[i].attacker := nil;

    for j := 0 to Ord(NUMPSPRITES) - 1 do
      if players[i].psprites[j].state <> nil then
        players[i].psprites[j].state := @states[integer(players[i].psprites[j].state)];
  end;
end;

//
// P_ArchiveWorld
//
procedure P_ArchiveWorld;
var
  i: integer;
  j: integer;
  sec: Psector_t;
  li: Pline_t;
  si: Pside_t;
  put: PSmallIntArray;
  levelinf: Plevelinfo_t;
begin
  put := PSmallIntArray(save_p);

  levelinf := P_GetLevelInfo(P_GetMapName(gameepisode, gamemap));
  Pchar8_t(put)^ := levelinf.musname;
  put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
  Pchar8_t(put)^ := levelinf.skyflat;
  put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];

  // do sectors
  i := 0;
  while i < numsectors do
  begin
    sec := Psector_t(@sectors[i]);
    PInteger(put)^ := sec.floorheight;
    put := @put[2];
    PInteger(put)^ := sec.ceilingheight;
    put := @put[2];
    Pchar8_t(put)^ := flats[sec.floorpic].name;
    put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
    Pchar8_t(put)^ := flats[sec.ceilingpic].name;
    put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
    put[0] := sec.lightlevel;
    put := @put[1];
    put[0] := sec.special; // needed?
    put := @put[1];
    put[0] := sec.tag;  // needed?
    put := @put[1];
    PInteger(put)^ := sec.floor_xoffs;
    put := @put[2];
    PInteger(put)^ := sec.floor_yoffs;
    put := @put[2];
    PInteger(put)^ := sec.ceiling_xoffs;
    put := @put[2];
    PInteger(put)^ := sec.ceiling_yoffs;
    put := @put[2];
    PLongWord(put)^ := sec.renderflags;
    put := @put[2];
    PLongWord(put)^ := sec.flags;
    put := @put[2];
    // JVAL: 3d Floors
    PInteger(put)^ := sec.midsec;
    put := @put[2];
    PInteger(put)^ := sec.midline;
    put := @put[2];
    // JVAL: sector gravity (VERSION 204)
    PInteger(put)^ := sec.gravity;
    put := @put[2];

    // JVAL: 20200522 - Slope values
    Pfloat(put)^ := sec.fa;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.fb;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.fd;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.fic;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.ca;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.cb;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.cd;
    put := @put[SizeOf(float) div 2];
    Pfloat(put)^ := sec.cic;
    put := @put[SizeOf(float) div 2];

    PInteger(put)^ := sec.num_saffectees;
    put := @put[2];
    for j := 0 to sec.num_saffectees - 1 do
    begin
      PInteger(put)^ := sec.saffectees[j];
      put := @put[2];
    end;

    inc(i);
  end;

  // do lines
  i := 0;
  while i < numlines do
  begin
    li := Pline_t(@lines[i]);
    put[0] := li.flags;
    put := @put[1];
    put[0] := li.special;
    put := @put[1];
    put[0] := li.tag;
    put := @put[1];
    PLongWord(put)^ := li.renderflags;
    put := @put[2];
    for j := 0 to 1 do
    begin
      if li.sidenum[j] = -1 then
        continue;

      si := @sides[li.sidenum[j]];

      PInteger(put)^ := si.textureoffset;
      put := @put[2];
      PInteger(put)^ := si.rowoffset;
      put := @put[2];
      Pchar8_t(put)^ := R_NameForSideTexture(si.toptexture);
      put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
      Pchar8_t(put)^ := R_NameForSideTexture(si.bottomtexture);
      put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
      Pchar8_t(put)^ := R_NameForSideTexture(si.midtexture);
      put := @put[SizeOf(char8_t) div SizeOf(SmallInt)];
    end;
    inc(i);
  end;

  save_p := PByteArray(put);
end;

//
// P_UnArchiveWorld
//
procedure P_UnArchiveWorld;
var
  i: integer;
  j: integer;
  sec: Psector_t;
  li: Pline_t;
  si: Pside_t;
  get: PSmallIntArray;
  levelinf: Plevelinfo_t;
begin
  get := PSmallIntArray(save_p);

  levelinf := P_GetLevelInfo(P_GetMapName(gameepisode, gamemap));
  levelinf.musname := Pchar8_t(get)^;
  get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];
  levelinf.skyflat := Pchar8_t(get)^;
  get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];

  // do sectors
  i := 0;
  while i < numsectors do
  begin
    sec := Psector_t(@sectors[i]);
    sec.floorheight := PInteger(get)^;
    get := @get[2];
    sec.ceilingheight := PInteger(get)^;
    get := @get[2];
    sec.floorpic := R_FlatNumForName(Pchar8_t(get)^);
    get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];
    sec.ceilingpic := R_FlatNumForName(Pchar8_t(get)^);
    get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];
    sec.lightlevel := get[0];
    get := @get[1];
    sec.special := get[0]; // needed?
    get := @get[1];
    sec.tag := get[0]; // needed?
    get := @get[1];
    sec.floordata := nil;
    sec.ceilingdata := nil;
    sec.lightingdata := nil;
    sec.soundtarget := nil;

    sec.floor_xoffs := PInteger(get)^;
    get := @get[2];
    sec.floor_yoffs := PInteger(get)^;
    get := @get[2];
    sec.ceiling_xoffs := PInteger(get)^;
    get := @get[2];
    sec.ceiling_yoffs := PInteger(get)^;
    get := @get[2];
    sec.renderflags := PLongWord(get)^;
    get := @get[2];
    sec.flags := PLongWord(get)^;
    get := @get[2];

    // JVAL: 3d Floors
    sec.midsec := PInteger(get)^;
    get := @get[2];
    sec.midline := PInteger(get)^;
    get := @get[2];

    // JVAL: sector gravity (VERSION 204)
    sec.gravity := PInteger(get)^;
    get := @get[2];

    // JVAL: 20200522 - Slope values
    sec.fa := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.fb := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.fd := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.fic := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.ca := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.cb := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.cd := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.cic := Pfloat(get)^;
    get := @get[SizeOf(float) div 2];
    sec.num_saffectees := PInteger(get)^;
    get := @get[2];
    Z_Realloc(sec.saffectees, sec.num_saffectees * SizeOf(integer), PU_LEVEL, nil);
    for j := 0 to sec.num_saffectees - 1 do
    begin
      sec.saffectees[j] := PInteger(get)^;
      get := @get[2];
    end;

    sec.touching_thinglist := nil;
    sec.iSectorID := i; // JVAL: 3d Floors
    inc(i);
  end;

  // do lines
  i := 0;
  while i < numlines do
  begin
    li := Pline_t(@lines[i]);
    li.flags := get[0];
    get := @get[1];
    li.special := get[0];
    get := @get[1];
    li.tag := get[0];
    get := @get[1];
    li.renderflags := PLongWord(get)^;
    get := @get[2];

    for j := 0 to 1 do
    begin
      if li.sidenum[j] = -1 then
        continue;
      si := @sides[li.sidenum[j]];

      si.textureoffset := PInteger(get)^;
      get := @get[2];
      si.rowoffset := PInteger(get)^;
      get := @get[2];

      si.toptexture := R_SafeTextureNumForName(Pchar8_t(get)^);
      if si.toptexture = 0 then
        si.toptexture := -1 - R_CustomColorMapForName(Pchar8_t(get)^);
      get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];

      si.bottomtexture := R_SafeTextureNumForName(Pchar8_t(get)^);
      if si.bottomtexture = 0 then
        si.bottomtexture := -1 - R_CustomColorMapForName(Pchar8_t(get)^);
      get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];

      si.midtexture := R_SafeTextureNumForName(Pchar8_t(get)^);
      if si.midtexture = 0 then
        si.midtexture := -1 - R_CustomColorMapForName(Pchar8_t(get)^);
      get := @get[SizeOf(char8_t) div SizeOf(SmallInt)];
    end;
    inc(i);
  end;
  save_p := PByteArray(get);
end;

//
// Thinkers
//
type
  thinkerclass_t = (tc_end, tc_mobj);

//
// P_ArchiveThinkers
//
procedure P_ArchiveThinkers;
var
  th: Pthinker_t;
  mobj: Pmobj_t;
  parm, parm1: Pmobjcustomparam_t;
begin
  // save off the current thinkers
  th := thinkercap.next;
  while th <> @thinkercap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      save_p[0] := Ord(tc_mobj);
      save_p := @save_p[1];
      mobj := Pmobj_t(save_p);
      memcpy(mobj, th, SizeOf(mobj_t));
      incp(pointer(save_p), SizeOf(mobj_t));
      mobj.state := Pstate_t(pDiff(mobj.state, @states[0], SizeOf(state_t)));
      mobj.prevstate := Pstate_t(pDiff(mobj.prevstate, @states[0], SizeOf(state_t)));

      if mobj.player <> nil then
        mobj.player := Pplayer_t(pDiff(mobj.player, @players[0], SizeOf(player_t)) + 1);

      parm := mobj.customparams;
      while parm <> nil do
      begin
        parm1 := Pmobjcustomparam_t(save_p);
        memcpy(parm1, parm, SizeOf(mobjcustomparam_t));
        incp(pointer(save_p), SizeOf(mobjcustomparam_t));
        parm := parm.next;
      end;

    end;
  // I_Error ("P_ArchiveThinkers: Unknown thinker function");
    th := th.next;
  end;

  // add a terminating marker
  save_p[0] := Ord(tc_end);
  save_p := @save_p[1];
end;

// P_UnArchiveThinkers
//
procedure P_UnArchiveThinkers;
var
  tclass: byte;
  currentthinker: Pthinker_t;
  next: Pthinker_t;
  mobj: Pmobj_t;
  parm: mobjcustomparam_t;
  i: integer;
begin
  // remove all the current thinkers
  currentthinker := thinkercap.next;
  while currentthinker <> @thinkercap do
  begin
    next := currentthinker.next;

    if @currentthinker._function.acp1 = @P_MobjThinker then
      P_RemoveMobj(Pmobj_t(currentthinker))
    else
      Z_Free(currentthinker);

    currentthinker := next;
  end;
  P_InitThinkers;

  // read in saved thinkers
  while true do
  begin
    tclass := save_p[0];
    save_p := @save_p[1];
    case tclass of
      Ord(tc_end):
        begin
          // Retrieve player's enginesoundtarget & messagesoundtarget
          for i := 0 to MAXPLAYERS - 1 do
            if playeringame[i] then
            begin
              players[i].enginesoundtarget := P_FindMobjFromKey(integer(players[i].enginesoundtarget));
              players[i].messagesoundtarget := P_FindMobjFromKey(integer(players[i].messagesoundtarget));
            end;

          exit; // end of list
        end;

      Ord(tc_mobj):
        begin
          mobj := Z_Malloc(SizeOf(mobj_t), PU_LEVEL, nil);

          memcpy(mobj, save_p, SizeOf(mobj_t));
          incp(pointer(save_p), SizeOf(mobj_t));

          if mobj.key < 1 then
            mobj.key := P_GenGlobalMobjKey;
          P_NotifyMobjKey(mobj);

          mobj.state := @states[integer(mobj.state)];
          mobj.prevstate := @states[integer(mobj.prevstate)];
          mobj.info := @mobjinfo[Ord(mobj._type)];
          mobj.target := nil;
          mobj.tracer := nil;
          mobj.touching_sectorlist := nil;

          if mobj.customparams <> nil then
          begin
            mobj.customparams := nil;
            repeat
              memcpy(@parm, save_p, SizeOf(mobjcustomparam_t));
              incp(pointer(save_p), SizeOf(mobjcustomparam_t));
              P_SetMobjCustomParam(mobj, parm.name, parm.value);
            until parm.next = nil;
          end;

          if mobj.player <> nil then
          begin
            mobj.player := @players[integer(mobj.player) - 1];

            Pplayer_t(mobj.player).mo := mobj;
          end;

          P_SetThingPosition(mobj);
          mobj.floorz := P_3dFloorHeight(mobj); // JVAL: 3d floors
          mobj.ceilingz := P_3dCeilingHeight(mobj); // JVAL: 3d floors
          @mobj.thinker._function.acp1 := @P_MobjThinker;
          P_AddThinker(@mobj.thinker);
        end;
      else
        I_Error('P_UnArchiveThinkers(): Unknown tclass %d in savegame', [tclass]);
    end;
  end;
end;

//
// P_ArchiveSpecials
//
type
  specials_e = (
    tc_ceiling,
    tc_door,
    tc_floor,
    tc_plat,
    tc_flash,
    tc_strobe,
    tc_glow,
    tc_scroll,
    tc_friction,    // phares 3/18/98:  new friction effect thinker
    tc_pusher,      // phares 3/22/98:  new push/pull effect thinker
    tc_fireflicker, // JVAL correct T_FireFlicker savegame bug
    tc_endspecials
  );



//
// Things to handle:
//
// T_MoveCeiling, (ceiling_t: sector_t * swizzle), - active list
// T_VerticalDoor, (vldoor_t: sector_t * swizzle),
// T_MoveFloor, (floormove_t: sector_t * swizzle),
// T_LightFlash, (lightflash_t: sector_t * swizzle),
// T_StrobeFlash, (strobe_t: sector_t *),
// T_Glow, (glow_t: sector_t *),
// T_PlatRaise, (plat_t: sector_t *), - active list
//
procedure P_ArchiveSpecials;
var
  th: Pthinker_t;
  th1: Pthinker_t;
  ceiling: Pceiling_t;
  door: Pvldoor_t;
  floor: Pfloormove_t;
  plat: Pplat_t;
  flash: Plightflash_t;
  strobe: Pstrobe_t;
  glow: Pglow_t;
  scroll: Pscroll_t;
  friction: Pfriction_t;
  pusher: Ppusher_t;
  flicker: Pfireflicker_t;
  i: integer;
begin
  // save off the current thinkers
  th1 := thinkercap.next;
  while th1 <> @thinkercap do
  begin
    th := th1;
    th1 := th1.next;
    if not Assigned(th._function.acv) then
    begin
      i := 0;
      while i < MAXCEILINGS do
      begin
        if activeceilings[i] = Pceiling_t(th) then
          break;
        inc(i);
      end;

      if i < MAXCEILINGS then
      begin
        save_p[0] := Ord(tc_ceiling);
        save_p := @save_p[1];
        ceiling := Pceiling_t(save_p);
        memcpy(ceiling, th, SizeOf(ceiling_t));
        incp(pointer(save_p), SizeOf(ceiling_t));
        ceiling.sector := Psector_t(pDiff(ceiling.sector, sectors, SizeOf(sector_t)));
      end;
      continue;
    end;

    if @th._function.acp1 = @T_MoveCeiling then
    begin
      save_p[0] := Ord(tc_ceiling);
      save_p := @save_p[1];
      ceiling := Pceiling_t(save_p);
      memcpy(ceiling, th, SizeOf(ceiling_t));
      incp(pointer(save_p), SizeOf(ceiling_t));
      ceiling.sector := Psector_t(pDiff(ceiling.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_VerticalDoor then
    begin
      save_p[0] := Ord(tc_door);
      save_p := @save_p[1];
      door := Pvldoor_t(save_p);
      memcpy(door, th, SizeOf(vldoor_t));
      incp(pointer(save_p), SizeOf(vldoor_t));
      door.sector := Psector_t(pDiff(door.sector, sectors, SizeOf(sector_t)));
      if door.line = nil then
        door.line := Pline_t(-1)
      else
        door.line := Pline_t(pDiff(door.line, lines, SizeOf(line_t)));
      continue;
    end;

    if @th._function.acp1 = @T_MoveFloor then
    begin
      save_p[0] := Ord(tc_floor);
      save_p := @save_p[1];
      floor := Pfloormove_t(save_p);
      memcpy(floor, th, SizeOf(floormove_t));
      incp(pointer(save_p), SizeOf(floormove_t));
      floor.sector := Psector_t(pDiff(floor.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_PlatRaise then
    begin
      save_p[0] := Ord(tc_plat);
      save_p := @save_p[1];
      plat := Pplat_t(save_p);
      memcpy(plat, th, SizeOf(plat_t));
      incp(pointer(save_p), SizeOf(plat_t));
      plat.sector := Psector_t(pDiff(plat.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_LightFlash then
    begin
      save_p[0] := Ord(tc_flash);
      save_p := @save_p[1];
      flash := Plightflash_t(save_p);
      memcpy(flash, th, SizeOf(lightflash_t));
      incp(pointer(save_p), SizeOf(lightflash_t));
      flash.sector := Psector_t(pDiff(flash.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_StrobeFlash then
    begin
      save_p[0] := Ord(tc_strobe);
      save_p := @save_p[1];
      strobe := Pstrobe_t(save_p);
      memcpy(strobe, th, SizeOf(strobe_t));
      incp(pointer(save_p), SizeOf(strobe_t));
      strobe.sector := Psector_t(pDiff(strobe.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_Glow then
    begin
      save_p[0] := Ord(tc_glow);
      save_p := @save_p[1];
      glow := Pglow_t(save_p);
      memcpy(glow, th, SizeOf(glow_t));
      incp(pointer(save_p), SizeOf(glow_t));
      glow.sector := Psector_t(pDiff(glow.sector, sectors, SizeOf(sector_t)));
      continue;
    end;

    if @th._function.acp1 = @T_Scroll then
    begin
      save_p[0] := Ord(tc_scroll);
      save_p := @save_p[1];
      scroll := Pscroll_t(save_p);
      memcpy(scroll, th, SizeOf(scroll_t));
      incp(pointer(save_p), SizeOf(scroll_t));
      continue;
    end;

    if @th._function.acp1 = @T_Friction then
    begin
      save_p[0] := Ord(tc_friction);
      save_p := @save_p[1];
      friction := Pfriction_t(save_p);
      memcpy(friction, th, SizeOf(friction_t));
      incp(pointer(save_p), SizeOf(friction_t));
      continue;
    end;

    if @th._function.acp1 = @T_Pusher then
    begin
      save_p[0] := Ord(tc_pusher);
      save_p := @save_p[1];
      pusher := Ppusher_t(save_p);
      memcpy(pusher, th, SizeOf(pusher_t));
      incp(pointer(save_p), SizeOf(pusher_t));
      continue;
    end;

    if @th._function.acp1 = @T_FireFlicker then
    begin
      save_p[0] := Ord(tc_fireflicker);
      save_p := @save_p[1];
      flicker := Pfireflicker_t(save_p);
      memcpy(flicker, th, SizeOf(fireflicker_t));
      incp(pointer(save_p), SizeOf(fireflicker_t));
      flicker.sector := Psector_t(flicker.sector.iSectorID);
      continue;
    end;

  end;
  // add a terminating marker
  save_p[0] := Ord(tc_endspecials);
  save_p := @save_p[1];
end;

//
// P_UnArchiveSpecials
//
procedure P_UnArchiveSpecials;
var
  tclass: byte;
  ceiling: Pceiling_t;
  door: Pvldoor_t;
  floor: Pfloormove_t;
  plat: Pplat_t;
  flash: Plightflash_t;
  strobe: Pstrobe_t;
  glow: Pglow_t;
  scroll: Pscroll_t;
  friction: Pfriction_t;
  pusher: Ppusher_t;
  flicker: Pfireflicker_t;
begin
  // read in saved thinkers
  while true do
  begin
    tclass := save_p[0];
    save_p := @save_p[1];
    case tclass of
      Ord(tc_endspecials):
        exit; // end of list

      Ord(tc_ceiling):
        begin
          ceiling := Z_Malloc(SizeOf(ceiling_t), PU_LEVEL, nil);
          memcpy(ceiling, save_p, SizeOf(ceiling_t));
          incp(pointer(save_p), SizeOf(ceiling_t));
          ceiling.sector := @sectors[integer(ceiling.sector)];
          ceiling.sector.ceilingdata := ceiling;

          if Assigned(ceiling.thinker._function.acp1) then // JVAL works ???
            @ceiling.thinker._function.acp1 := @T_MoveCeiling;

          P_AddThinker(@ceiling.thinker);
          P_AddActiveCeiling(ceiling);
        end;

      Ord(tc_door):
        begin
          door := Z_Malloc(SizeOf(vldoor_t), PU_LEVEL, nil);
          memcpy(door, save_p, SizeOf(vldoor_t));
          incp(pointer(save_p), SizeOf(vldoor_t));
          door.sector := @sectors[integer(door.sector)];
          door.sector.ceilingdata := door;
          if integer(door.line) = -1 then
            door.line := nil
          else
            door.line := @lines[integer(door.line)];

          @door.thinker._function.acp1 := @T_VerticalDoor;
          P_AddThinker(@door.thinker);
        end;

      Ord(tc_floor):
        begin
          floor := Z_Malloc(SizeOf(floormove_t), PU_LEVEL, nil);
          memcpy(floor, save_p, SizeOf(floormove_t));
          incp(pointer(save_p), SizeOf(floormove_t));
          floor.sector := @sectors[integer(floor.sector)];
          floor.sector.floordata := floor;
          @floor.thinker._function.acp1 := @T_MoveFloor;
          P_AddThinker(@floor.thinker);
        end;

      Ord(tc_plat):
        begin
          plat := Z_Malloc(SizeOf(plat_t), PU_LEVEL, nil);
          memcpy(plat, save_p, SizeOf(plat_t));
          incp(pointer(save_p), SizeOf(plat_t));
          plat.sector := @sectors[integer(plat.sector)];
          plat.sector.floordata := plat;

          if Assigned(plat.thinker._function.acp1) then
            @plat.thinker._function.acp1 := @T_PlatRaise;

          P_AddThinker(@plat.thinker);
          P_AddActivePlat(plat);
        end;

      Ord(tc_flash):
        begin
          flash := Z_Malloc(Sizeof(lightflash_t), PU_LEVEL, nil);
          memcpy(flash, save_p, SizeOf(lightflash_t));
          incp(pointer(save_p), SizeOf(lightflash_t));
          flash.sector := @sectors[integer(flash.sector)];
          @flash.thinker._function.acp1 := @T_LightFlash;
          P_AddThinker(@flash.thinker);
        end;

      Ord(tc_strobe):
        begin
          strobe := Z_Malloc(SizeOf(strobe_t), PU_LEVEL, nil);
          memcpy(strobe, save_p, SizeOf(strobe_t));
          incp(pointer(save_p), SizeOf(strobe_t));
          strobe.sector := @sectors[integer(strobe.sector)];
          @strobe.thinker._function.acp1 := @T_StrobeFlash;
          P_AddThinker(@strobe.thinker);
        end;

      Ord(tc_glow):
        begin
          glow := Z_Malloc(SizeOf(glow_t), PU_LEVEL, nil);
          memcpy(glow, save_p, SizeOf(glow_t));
          incp(pointer(save_p), SizeOf(glow_t));
          glow.sector := @sectors[integer(glow.sector)];
          @glow.thinker._function.acp1 := @T_Glow;
          P_AddThinker(@glow.thinker);
        end;

      Ord(tc_scroll):
        begin
          scroll := Z_Malloc(SizeOf(scroll_t), PU_LEVEL, nil);
          memcpy(scroll, save_p, SizeOf(scroll_t));
          incp(pointer(save_p), SizeOf(scroll_t));
          @scroll.thinker._function.acp1 := @T_Scroll;
          P_AddThinker(@scroll.thinker);
        end;

      Ord(tc_friction):
        begin
          friction := Z_Malloc(SizeOf(friction_t), PU_LEVEL, nil);
          memcpy(friction, save_p, SizeOf(friction_t));
          incp(pointer(save_p), SizeOf(friction_t));
          @friction.thinker._function.acp1 := @T_Friction;
          P_AddThinker(@friction.thinker);
        end;

      Ord(tc_pusher):
        begin
          pusher := Z_Malloc(SizeOf(pusher_t), PU_LEVEL, nil);
          memcpy(pusher, save_p, SizeOf(pusher_t));
          incp(pointer(save_p), SizeOf(pusher_t));
          @pusher.thinker._function.acp1 := @T_Pusher;
          pusher.source := P_GetPushThing(pusher.affectee);
          P_AddThinker(@pusher.thinker);
        end;

      Ord(tc_fireflicker):
        begin
          flicker := Z_Malloc(SizeOf(fireflicker_t), PU_LEVEL, nil);
          memcpy(flicker, save_p, SizeOf(fireflicker_t));
          incp(pointer(save_p), SizeOf(fireflicker_t));
          @flicker.thinker._function.acp1 := @T_FireFlicker;
          flicker.sector := @sectors[integer(flicker.sector)];
          P_AddThinker(@flicker.thinker);
        end;

      else
        I_Error('P_UnarchiveSpecials(): Unknown tclass %d in savegame', [tclass]);
    end;
  end;
end;

procedure P_ArchiveGlobalVariables(const vars: TGlobalVariablesList);
var
  sz: integer;
begin
  sz := vars.StructureSize;
  PInteger(save_p)^ := sz;
  incp(pointer(save_p), SizeOf(integer));
  vars.SaveToBuffer(save_p);
  incp(pointer(save_p), sz);
end;

procedure P_ArchiveVariables;
begin
  P_ArchiveGlobalVariables(mapvars);
  P_ArchiveGlobalVariables(worldvars);
end;

procedure P_ArchivePSMapScript;
var
  fname: string;
  sz: Integer;
begin
  fname := I_NewTempFile('mapscript' + itoa(Random(1000)));
  PS_MapScriptSaveToFile(fname);
  sz := fsize(fname);
  PInteger(save_p)^ := sz;
  incp(pointer(save_p), SizeOf(integer));
  with TFile.Create(fname, fOpenReadOnly) do
  try
    Read(save_p^, sz);
  finally
    Free;
  end;
  fdelete(fname);
  incp(Pointer(save_p), sz);
end;

procedure P_UnArchiveGlobalVariables(const vars: TGlobalVariablesList);
var
  sz: integer;
begin
  sz := PInteger(save_p)^;
  incp(pointer(save_p), SizeOf(integer));
  vars.LoadFromBuffer(save_p);
  incp(pointer(save_p), sz);
end;

procedure P_UnArchiveVariables;
begin
  P_UnArchiveGlobalVariables(mapvars);
  P_UnArchiveGlobalVariables(worldvars);
end;

procedure P_UnArchivePSMapScript;
var
  fname: string;
  sz: Integer;
begin
  sz := PInteger(save_p)^;
  incp(pointer(save_p), SizeOf(integer));

  fname := I_NewTempFile('mapscript' + itoa(Random(1000)));
  with TFile.Create(fname, fCreate) do
  try
    Write(save_p^, sz);
  finally
    Free;
  end;
  PS_MapScriptLoadFromFile(fname);
  fdelete(fname);
  incp(Pointer(save_p), sz);
end;

procedure P_ArchiveOverlay;
begin
  overlay.SaveToBuffer(Pointer(save_p));
end;

procedure P_UnArchiveOverlay;
begin
  overlay.LoadFromBuffer(Pointer(save_p));
end;

procedure P_ArchiveRace;
begin
  Prace_t(save_p)^ := race;
  incp(pointer(save_p), SizeOf(race_t));
end;

procedure P_UnArchiveRace;
begin
  race := Prace_t(save_p)^;
  incp(pointer(save_p), SizeOf(race_t));
end;

procedure P_ArchivePaths;
var
  i, sz: integer;
begin
  sz := numpaths;
  PInteger(save_p)^ := sz;
  incp(pointer(save_p), SizeOf(integer));
  for i := 0 to sz - 1 do
  begin
    Prtlpath_t(save_p)^ := rtlpaths[i];
    Prtlpath_t(save_p).mo := Pmobj_t(rtlpaths[i].mo.key);
    incp(pointer(save_p), SizeOf(rtlpath_t));
  end;
end;

procedure P_UnArchivePaths;
var
  i, sz: integer;
begin
  sz := PInteger(save_p)^;
  incp(pointer(save_p), SizeOf(integer));
  if sz <> numpaths then
    I_Error('P_UnArchivePaths(): Path is has invalid size %d, instead of %d', [sz, numpaths]);
  for i := 0 to sz - 1 do
  begin
    rtlpaths[i] := Prtlpath_t(save_p)^;
    rtlpaths[i].mo := P_FindMobjFromKey(integer(rtlpaths[i].mo));
    incp(pointer(save_p), SizeOf(rtlpath_t));
  end;
end;

procedure P_ArchiveChampionShip;
begin
  Pchampionship_t(save_p)^ := championship;
  incp(pointer(save_p), SizeOf(championship_t));
end;

procedure P_UnArchiveChampionShip;
begin
  championship := Pchampionship_t(save_p)^;
  incp(pointer(save_p), SizeOf(championship_t));
end;

end.
