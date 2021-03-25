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

unit p_common;

interface

uses
  m_fixed,
  info_h,
  p_mobj_h;

const
  CSP_AT_LEAST = 1;
  CSP_AT_MOST = 2;

function P_CheckStateParams(actor: Pmobj_t; const numparms: integer = -1; const flags: LongWord = 0): boolean;

{$IFDEF HEXEN}
procedure P_BulletSlope(mo: Pmobj_t);
{$ENDIF}

procedure A_GoTo(actor: Pmobj_t);

procedure A_GoToIfCloser(actor: Pmobj_t);

procedure A_GoToIfHealthLower(actor: Pmobj_t);

procedure A_ConsoleCommand(actor: Pmobj_t);

procedure A_SetFrightened(actor: Pmobj_t);

procedure A_UnSetFrightened(actor: Pmobj_t);

procedure A_SetNoDamage(actor: Pmobj_t);

procedure A_UnSetNoDamage(actor: Pmobj_t);

procedure A_SetCustomParam(actor: Pmobj_t);

procedure A_AddCustomParam(actor: Pmobj_t);

procedure A_SubtractCustomParam(actor: Pmobj_t);

procedure A_SetTargetCustomParam(actor: Pmobj_t);

procedure A_AddTargetCustomParam(actor: Pmobj_t);

procedure A_SubtractTargetCustomParam(actor: Pmobj_t);

procedure A_JumpIf(actor: Pmobj_t);

procedure A_JumpIfCustomParam(actor: Pmobj_t);

procedure A_JumpIfCustomParamLess(actor: Pmobj_t);

procedure A_JumpIfCustomParamGreater(actor: Pmobj_t);

procedure A_JumpIfTargetCustomParam(actor: Pmobj_t);

procedure A_JumpIfTargetCustomParamLess(actor: Pmobj_t);

procedure A_JumpIfTargetCustomParamGreater(actor: Pmobj_t);

procedure A_JumpIfMapStringEqual(actor: Pmobj_t);
procedure A_JumpIfMapStringLess(actor: Pmobj_t);
procedure A_JumpIfMapStringGreater(actor: Pmobj_t);

procedure A_JumpIfMapIntegerEqual(actor: Pmobj_t);
procedure A_JumpIfMapIntegerLess(actor: Pmobj_t);
procedure A_JumpIfMapIntegerGreater(actor: Pmobj_t);

procedure A_JumpIfMapFloatEqual(actor: Pmobj_t);
procedure A_JumpIfMapFloatLess(actor: Pmobj_t);
procedure A_JumpIfMapFloatGreater(actor: Pmobj_t);

procedure A_JumpIfWorldStringEqual(actor: Pmobj_t);
procedure A_JumpIfWorldStringLess(actor: Pmobj_t);
procedure A_JumpIfWorldStringGreater(actor: Pmobj_t);

procedure A_JumpIfWorldIntegerEqual(actor: Pmobj_t);
procedure A_JumpIfWorldIntegerLess(actor: Pmobj_t);
procedure A_JumpIfWorldIntegerGreater(actor: Pmobj_t);

procedure A_JumpIfWorldFloatEqual(actor: Pmobj_t);
procedure A_JumpIfWorldFloatLess(actor: Pmobj_t);
procedure A_JumpIfWorldFloatGreater(actor: Pmobj_t);

procedure A_GoToIfCustomParam(actor: Pmobj_t);

procedure A_GoToIfCustomParamLess(actor: Pmobj_t);

procedure A_GoToIfCustomParamGreater(actor: Pmobj_t);

procedure A_GoToIfTargetCustomParam(actor: Pmobj_t);

procedure A_GoToIfTargetCustomParamLess(actor: Pmobj_t);

procedure A_GoToIfTargetCustomParamGreater(actor: Pmobj_t);

procedure A_GoToIfMapStringEqual(actor: Pmobj_t);
procedure A_GoToIfMapStringLess(actor: Pmobj_t);
procedure A_GoToIfMapStringGreater(actor: Pmobj_t);

procedure A_GoToIfMapIntegerEqual(actor: Pmobj_t);
procedure A_GoToIfMapIntegerLess(actor: Pmobj_t);
procedure A_GoToIfMapIntegerGreater(actor: Pmobj_t);

procedure A_GoToIfMapFloatEqual(actor: Pmobj_t);
procedure A_GoToIfMapFloatLess(actor: Pmobj_t);
procedure A_GoToIfMapFloatGreater(actor: Pmobj_t);

procedure A_GoToIfWorldStringEqual(actor: Pmobj_t);
procedure A_GoToIfWorldStringLess(actor: Pmobj_t);
procedure A_GoToIfWorldStringGreater(actor: Pmobj_t);

procedure A_GoToIfWorldIntegerEqual(actor: Pmobj_t);
procedure A_GoToIfWorldIntegerLess(actor: Pmobj_t);
procedure A_GoToIfWorldIntegerGreater(actor: Pmobj_t);

procedure A_GoToIfWorldFloatEqual(actor: Pmobj_t);
procedure A_GoToIfWorldFloatLess(actor: Pmobj_t);
procedure A_GoToIfWorldFloatGreater(actor: Pmobj_t);

procedure A_CustomSound1(mo: Pmobj_t);

procedure A_CustomSound2(mo: Pmobj_t);

procedure A_CustomSound3(mo: Pmobj_t);

procedure P_RandomSound(const actor: Pmobj_t; const soundnum: integer);

procedure A_RandomPainSound(actor: Pmobj_t);

procedure A_RandomSeeSound(actor: Pmobj_t);

procedure A_RandomAttackSound(actor: Pmobj_t);

procedure A_RandomDeathSound(actor: Pmobj_t);

procedure A_RandomActiveSound(actor: Pmobj_t);

procedure A_RandomCustomSound1(actor: Pmobj_t);

procedure A_RandomCustomSound2(actor: Pmobj_t);

procedure A_RandomCustomSound3(actor: Pmobj_t);

procedure A_RandomCustomSound(actor: Pmobj_t);

procedure A_RandomMeleeSound(actor: Pmobj_t);

procedure A_Playsound(actor: Pmobj_t);

procedure A_PlaysoundFullVolume(actor: Pmobj_t);

procedure A_PlayWeaponsound(actor: Pmobj_t);

procedure A_RandomSound(actor: Pmobj_t);

procedure A_Stop(actor: Pmobj_t);

procedure A_Jump(actor: Pmobj_t);

procedure A_CustomMissile(actor: Pmobj_t);

procedure A_RandomMissile(actor: Pmobj_t);

procedure A_SpawnItem(actor: Pmobj_t);

procedure A_SpawnItemEx(actor: Pmobj_t);

procedure A_SeekerMissile(actor: Pmobj_t);

procedure A_CStaffMissileSlither(actor: Pmobj_t);

procedure A_SetTranslucent(actor: Pmobj_t);

procedure A_FadeOut(actor: Pmobj_t);

procedure A_FadeOut10(actor: Pmobj_t);

procedure A_FadeOut20(actor: Pmobj_t);

procedure A_FadeOut30(actor: Pmobj_t);

procedure A_FadeIn(actor: Pmobj_t);

procedure A_FadeIn10(actor: Pmobj_t);

procedure A_FadeIn20(actor: Pmobj_t);

procedure A_FadeIn30(actor: Pmobj_t);

procedure A_MissileAttack(actor: Pmobj_t);

procedure A_AdjustSideSpot(actor: Pmobj_t);

procedure A_ThrustZ(actor: Pmobj_t);

procedure A_ThrustXY(actor: Pmobj_t);

procedure A_Turn(actor: Pmobj_t);

procedure A_JumpIfCloser(actor: Pmobj_t);

procedure A_JumpIfHealthLower(actor: Pmobj_t);

procedure A_ScreamAndUnblock(actor: Pmobj_t);

procedure A_Missile(actor: Pmobj_t);

procedure A_NoMissile(actor: Pmobj_t);

procedure A_Wander(actor: Pmobj_t);

procedure A_GhostOn(actor: Pmobj_t);

procedure A_GhostOff(actor: Pmobj_t);

procedure A_Turn5(actor: Pmobj_t);

procedure A_Turn10(actor: Pmobj_t);

procedure A_Blocking(actor: Pmobj_t);

procedure A_DoNotRunScripts(actor: Pmobj_t);

procedure A_DoRunScripts(actor: Pmobj_t);

procedure A_SetDropItem(actor: Pmobj_t);

procedure A_SetDefaultDropItem(actor: Pmobj_t);

procedure A_TargetDropItem(actor: Pmobj_t);

procedure A_DefaultTargetDropItem(actor: Pmobj_t);

function P_ActorTarget(const actor: Pmobj_t): Pmobj_t;

procedure A_GlobalEarthQuake(actor: Pmobj_t);

procedure A_SetMapStr(actor: Pmobj_t);

procedure A_SetWorldStr(actor: Pmobj_t);

procedure A_SetMapInt(actor: Pmobj_t);

procedure A_SetWorldInt(actor: Pmobj_t);

procedure A_SetMapFloat(actor: Pmobj_t);

procedure A_SetWorldFloat(actor: Pmobj_t);

procedure A_RandomGoto(actor: Pmobj_t);

procedure A_ResetHealth(actor: Pmobj_t);

procedure A_SetHealth(actor: Pmobj_t);

procedure A_ResetTargetHealth(actor: Pmobj_t);

procedure A_SetTargetHealth(actor: Pmobj_t);

procedure A_Recoil(actor: Pmobj_t);

procedure A_SetSolid(actor: Pmobj_t);

procedure A_UnSetSolid(actor: Pmobj_t);

procedure A_SetFloat(actor: Pmobj_t);

procedure A_UnSetFloat(actor: Pmobj_t);

procedure A_ScaleVelocity(actor: Pmobj_t);

procedure A_ChangeVelocity(actor: Pmobj_t);

procedure A_SetPushFactor(actor: Pmobj_t);

procedure A_SetScale(actor: Pmobj_t);

procedure A_SetGravity(actor: Pmobj_t);

procedure A_SetFloorBounce(actor: Pmobj_t);

procedure A_UnSetFloorBounce(actor: Pmobj_t);

procedure A_SetCeilingBounce(actor: Pmobj_t);

procedure A_UnSetCeilingBounce(actor: Pmobj_t);

procedure A_SetWallBounce(actor: Pmobj_t);

procedure A_UnSetWallBounce(actor: Pmobj_t);

procedure A_GlowLight(actor: Pmobj_t);

procedure A_TraceNearestPlayer(actor: Pmobj_t);

procedure A_ChangeFlag(actor: Pmobj_t);

const
  FLOATBOBSIZE = 64;
  FLOATBOBMASK = FLOATBOBSIZE - 1;

  FloatBobOffsets: array[0..FLOATBOBSIZE - 1] of fixed_t = (
         0,  51389, 102283, 152192,
    200636, 247147, 291278, 332604,
    370727, 405280, 435929, 462380,
    484378, 501712, 514213, 521763,
    524287, 521763, 514213, 501712,
    484378, 462380, 435929, 405280,
    370727, 332604, 291278, 247147,
    200636, 152192, 102283,  51389,
        -1, -51390,-102284,-152193,
   -200637,-247148,-291279,-332605,
   -370728,-405281,-435930,-462381,
   -484380,-501713,-514215,-521764,
   -524288,-521764,-514214,-501713,
   -484379,-462381,-435930,-405280,
   -370728,-332605,-291279,-247148,
   -200637,-152193,-102284, -51389
  );

const
// Sector Flags
// Ladder
  SF_LADDER = 1;
// Slip while descenting if sloped
  SF_SLIPSLOPEDESCENT = 2;

function P_TicsFromState(const st: Pstate_t): integer;

implementation

uses
  d_delphi,
  doomdef,
  deh_main,
  d_player,
  m_vectors,
  i_system,
  c_con,
  g_game,
  info,
  info_common,
  p_enemy,
  p_extra,
  p_mobj,
  p_pspr,
  p_map,
  p_maputl,
  p_params,
  psi_globals,
  r_renderstyle,
  r_main,
  sc_engine,
  sc_tokens,
  sc_states,
  tables,
  s_sound,
  sounds,
  m_rnd;

{$IFDEF HEXEN}
//
// P_BulletSlope
// Sets a slope so a near miss is at aproximately
// the height of the intended target
//
var
  bulletslope: fixed_t;


procedure P_BulletSlope(mo: Pmobj_t);
var
  an: angle_t;
begin
  // see which target is to be aimed at
  an := mo.angle;
  bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    bulletslope := P_AimLineAttack (mo, an, 16 * 64 * FRACUNIT);
    if linetarget = nil then
    begin
      an := an - $8000000;
      bulletslope := P_AimLineAttack(mo, an, 16 * 64 * FRACUNIT);
      if linetarget = nil then
        bulletslope := (Pplayer_t(mo.player).lookdir * FRACUNIT) div 173;
    end;
  end;
end;
{$ENDIF}

function P_CheckStateParams(actor: Pmobj_t; const numparms: integer = -1; const flags: LongWord = 0): boolean;
begin
  if numparms = 0 then
  begin
    if actor.state.flags_ex and MF_EX_STATE_PARAMS_ERROR = 0 then
    begin
      I_Warning('P_CheckStateParams(): Expected params can not be 0'#13#10);
      actor.state.flags_ex := actor.state.flags_ex or MF_EX_STATE_PARAMS_ERROR;
    end;
    result := false;
    exit;
  end;

  if actor.state.params = nil then
  begin
    if actor.state.flags_ex and MF_EX_STATE_PARAMS_ERROR = 0 then
    begin
      I_Warning('P_CheckStateParams(): Parameter list is null');
      if numparms > 0 then
        I_Warning(', %d parameters expected', [numparms]);
      I_Warning(#13#10);
      actor.state.flags_ex := actor.state.flags_ex or MF_EX_STATE_PARAMS_ERROR;
    end;
    result := false;
    exit;
  end;

  if numparms <> -1 then
  begin
    if (flags = 0) and (actor.state.params.Count <> numparms) then
    begin
      if actor.state.flags_ex and MF_EX_STATE_PARAMS_ERROR = 0 then
      begin
        I_Warning('P_CheckStateParams(): Parameter list has %d parameters, but %d parameters expected'#13#10, [actor.state.params.Count, numparms]);
        actor.state.flags_ex := actor.state.flags_ex or MF_EX_STATE_PARAMS_ERROR;
      end;
      result := false;
      exit;
    end
    else if (flags and CSP_AT_LEAST <> 0) and (actor.state.params.Count < numparms) then
    begin
      if actor.state.flags_ex and MF_EX_STATE_PARAMS_ERROR = 0 then
      begin
        I_Warning('P_CheckStateParams(): Parameter list has %d parameters, but at least %d parameters expected'#13#10, [actor.state.params.Count, numparms]);
        actor.state.flags_ex := actor.state.flags_ex or MF_EX_STATE_PARAMS_ERROR;
      end;
      result := false;
      exit;
    end
    else if (flags and CSP_AT_MOST <> 0) and (actor.state.params.Count > numparms) then
    begin
      if actor.state.flags_ex and MF_EX_STATE_PARAMS_ERROR = 0 then
      begin
        I_Warning('P_CheckStateParams(): Parameter list has %d parameters, but at most %d parameters expected'#13#10, [actor.state.params.Count, numparms]);
        actor.state.flags_ex := actor.state.flags_ex or MF_EX_STATE_PARAMS_ERROR;
      end;
      result := false;
      exit;
    end;
  end;

  result := true;
end;

//
// JVAL
// Change state
// A_GoTo(propability, newstate)
//
procedure A_GoTo(actor: Pmobj_t);
var
  propability: integer;
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  propability := actor.state.params.IntVal[0];  // JVAL simple integer values are precalculated

  if N_Random < propability then
  begin
    if not actor.state.params.IsComputed[1] then
      actor.state.params.IntVal[1] := P_GetStateFromName(actor, actor.state.params.StrVal[1]);
    newstate := actor.state.params.IntVal[1];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// A_GoToIfCloser(distancetotarget: float, newstate: integer)
// Jump conditionally to another state if distance to target is closer to first parameter
//
procedure A_GoToIfCloser(actor: Pmobj_t);
var
  dist: fixed_t;
  target: Pmobj_t;
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.player = nil then
    target := actor.target
  else
  begin
    // Does the player aim at something that can be shot?
    P_BulletSlope(actor);
    target := linetarget;
  end;

  // No target - no jump
  if target = nil then
    exit;

  dist := actor.state.params.FixedVal[0];
  if P_AproxDistance(actor.x - target.x, actor.y - target.y) < dist then
  begin
    if not actor.state.params.IsComputed[1] then
      actor.state.params.IntVal[1] := P_GetStateFromName(actor, actor.state.params.StrVal[1]);
    newstate := actor.state.params.IntVal[1];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// A_GoToIfHealthLower(health: integer; newstate: integer)
// Jump conditionally to another state if health is lower to first parameter
//
procedure A_GoToIfHealthLower(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.health < actor.state.params.IntVal[0] then
  begin
    if not actor.state.params.IsComputed[1] then
      actor.state.params.IntVal[1] := P_GetStateFromName(actor, actor.state.params.StrVal[1]);
    newstate := actor.state.params.IntVal[1];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_ConsoleCommand(actor: Pmobj_t);
var
  cmd: string;
  i: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  cmd := actor.state.params.StrVal[0];
  for i := 1 to actor.state.params.Count - 1 do
    cmd := cmd + ' ' + actor.state.params.StrVal[i];

  C_AddCommand(cmd);
end;

procedure A_SetFrightened(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex or MF2_EX_FRIGHTENED;
end;

procedure A_UnSetFrightened(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex and not MF2_EX_FRIGHTENED;
end;

procedure A_SetNoDamage(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex or MF2_EX_NODAMAGE;
end;

procedure A_UnSetNoDamage(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex and not MF2_EX_NODAMAGE;
end;

procedure A_SetCustomParam(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  P_SetMobjCustomParam(actor, actor.state.params.StrVal[0], actor.state.params.IntVal[1]);
end;

procedure A_AddCustomParam(actor: Pmobj_t);
var
  parm: Pmobjcustomparam_t;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  parm := P_GetMobjCustomParam(actor, actor.state.params.StrVal[0]);
  if parm = nil then
    P_SetMobjCustomParam(actor, actor.state.params.StrVal[0], actor.state.params.IntVal[1])
  else
    P_SetMobjCustomParam(actor, actor.state.params.StrVal[0], parm.value + actor.state.params.IntVal[1])
end;

procedure A_SubtractCustomParam(actor: Pmobj_t);
var
  parm: Pmobjcustomparam_t;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  parm := P_GetMobjCustomParam(actor, actor.state.params.StrVal[0]);
  if parm <> nil then
    P_SetMobjCustomParam(actor, actor.state.params.StrVal[0], parm.value - actor.state.params.IntVal[1])
  else
    P_SetMobjCustomParam(actor, actor.state.params.StrVal[0], - actor.state.params.IntVal[1])
end;

procedure A_SetTargetCustomParam(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.target = nil then
    exit;

  P_SetMobjCustomParam(actor.target, actor.state.params.StrVal[0], actor.state.params.IntVal[1]);
end;

procedure A_AddTargetCustomParam(actor: Pmobj_t);
var
  parm: Pmobjcustomparam_t;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.target = nil then
    exit;

  parm := P_GetMobjCustomParam(actor.target, actor.state.params.StrVal[0]);
  if parm = nil then
    P_SetMobjCustomParam(actor.target, actor.state.params.StrVal[0], actor.state.params.IntVal[1])
  else
    P_SetMobjCustomParam(actor.target, actor.state.params.StrVal[0], parm.value + actor.state.params.IntVal[1])
end;

procedure A_SubtractTargetCustomParam(actor: Pmobj_t);
var
  parm: Pmobjcustomparam_t;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.target = nil then
    exit;

  parm := P_GetMobjCustomParam(actor.target, actor.state.params.StrVal[0]);
  if parm <> nil then
    P_SetMobjCustomParam(actor.target, actor.state.params.StrVal[0], parm.value - actor.state.params.IntVal[1])
  else
    P_SetMobjCustomParam(actor.target, actor.state.params.StrVal[0], - actor.state.params.IntVal[1])
end;

//
// JVAL
// Conditionally change state offset
// A_JumpIf(logical expression, offset to jump when true)
//
procedure A_JumpIf(actor: Pmobj_t);
var
  offset: integer;
  boolret: boolean;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  boolret := actor.state.params.BoolVal[0];
  if boolret then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[1]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfCustomParam(customparam, value of customparam, offset)
//
procedure A_JumpIfCustomParam(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) = actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfCustomParamLess(customparam, value of customparam, offset)
//
procedure A_JumpIfCustomParamLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) < actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfCustomParamGreater(customparam, value of customparam, offset)
//
procedure A_JumpIfCustomParamGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) > actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfTargetCustomParam(customparam, value of customparam, offset)
//
procedure A_JumpIfTargetCustomParam(actor: Pmobj_t);
var
  offset: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) = actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfTargetCustomParamLess(customparam, value of customparam, offset)
//
procedure A_JumpIfTargetCustomParamLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) < actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state offset
// A_JumpIfTargetCustomParamGreater(customparam, value of customparam, offset)
//
procedure A_JumpIfTargetCustomParamGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) > actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapStringEqual(actor: Pmobj_t);
var
  offset: integer;
  cur: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] = actor.state.params.StrVal[1] then
  begin
    offset := actor.state.params.IntVal[2];

    cur := (integer(actor.state) - integer(states)) div SizeOf(state_t);

    P_SetMobjState(actor, statenum_t(cur + offset));
  end;
end;

procedure A_JumpIfMapStringLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] < actor.state.params.StrVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapStringGreater(actor: Pmobj_t);
var
  offset: integer;
  cur: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] > actor.state.params.StrVal[1] then
  begin
    offset := actor.state.params.IntVal[2];

    cur := (integer(actor.state) - integer(states)) div SizeOf(state_t);

    P_SetMobjState(actor, statenum_t(cur + offset));
  end;
end;

procedure A_JumpIfMapIntegerEqual(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] = actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapIntegerLess(actor: Pmobj_t);
var
  offset: integer;
  cur: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] < actor.state.params.IntVal[1] then
  begin
    offset := actor.state.params.IntVal[2];

    cur := (integer(actor.state) - integer(states)) div SizeOf(state_t);

    P_SetMobjState(actor, statenum_t(cur + offset));
  end;
end;

procedure A_JumpIfMapIntegerGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] > actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapFloatEqual(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] = actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapFloatLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] < actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfMapFloatGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] > actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldStringEqual(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] = actor.state.params.StrVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldStringLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] < actor.state.params.StrVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldStringGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] > actor.state.params.StrVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldIntegerEqual(actor: Pmobj_t);
var
  offset: integer;
  cur: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] = actor.state.params.IntVal[1] then
  begin
    offset := actor.state.params.IntVal[2];

    cur := (integer(actor.state) - integer(states)) div SizeOf(state_t);

    P_SetMobjState(actor, statenum_t(cur + offset));
  end;
end;

procedure A_JumpIfWorldIntegerLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] < actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldIntegerGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] > actor.state.params.IntVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldFloatEqual(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] = actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldFloatLess(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] < actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_JumpIfWorldFloatGreater(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] > actor.state.params.FloatVal[1] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[2]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfCustomParam(customparam, value of customparam, newstate)
//
procedure A_GoToIfCustomParam(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) = actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfCustomParamLess(customparam, value of customparam, newstate)
//
procedure A_GoToIfCustomParamLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) < actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfCustomParamGreater(customparam, value of customparam, newstate)
//
procedure A_GoToIfCustomParamGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor, actor.state.params.StrVal[0]) > actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfTargetCustomParam(customparam, value of customparam, newstate)
//
procedure A_GoToIfTargetCustomParam(actor: Pmobj_t);
var
  newstate: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) = actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfTargetCustomParamLess(customparam, value of customparam, newstate)
//
procedure A_GoToIfTargetCustomParamLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) < actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfTargetCustomParamGreater(customparam, value of customparam, newstate)
//
procedure A_GoToIfTargetCustomParamGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 3) then
    exit;

  if P_GetMobjCustomParamValue(actor.target, actor.state.params.StrVal[0]) > actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfMapStringEqual(map variable, value of map variable, newstate)
//
procedure A_GoToIfMapStringEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] = actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfMapStringLess(map variable, value of map variable, newstate)
//
procedure A_GoToIfMapStringLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] < actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfMapStringGreater(map variable, value of map variable, newstate)
//
procedure A_GoToIfMapStringGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.StrVal[actor.state.params.StrVal[0]] > actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapIntegerEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] = actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapIntegerLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] < actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapIntegerGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.IntVal[actor.state.params.StrVal[0]] > actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapFloatEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] = actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapFloatLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] < actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfMapFloatGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if mapvars.FloatVal[actor.state.params.StrVal[0]] > actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfWorldStringEqual(World variable, value of World variable, newstate)
//
procedure A_GoToIfWorldStringEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] = actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfWorldStringLess(World variable, value of World variable, newstate)
//
procedure A_GoToIfWorldStringLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] < actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

//
// JVAL
// Change state
// A_GoToIfWorldStringGreater(World variable, value of World variable, newstate)
//
procedure A_GoToIfWorldStringGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.StrVal[actor.state.params.StrVal[0]] > actor.state.params.StrVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldIntegerEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] = actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldIntegerLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] < actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldIntegerGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.IntVal[actor.state.params.StrVal[0]] > actor.state.params.IntVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldFloatEqual(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] = actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldFloatLess(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] < actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_GoToIfWorldFloatGreater(actor: Pmobj_t);
var
  newstate: integer;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  if Worldvars.FloatVal[actor.state.params.StrVal[0]] > actor.state.params.FloatVal[1] then
  begin
    if not actor.state.params.IsComputed[2] then
      actor.state.params.IntVal[2] := P_GetStateFromName(actor, actor.state.params.StrVal[2]);
    newstate := actor.state.params.IntVal[2];

    P_SetMobjState(actor, statenum_t(newstate));
  end;
end;

procedure A_CustomSound1(mo: Pmobj_t);
begin
  if mo.info.customsound1 <> 0 then
  begin
    if mo.info.flags_ex and MF_EX_RANDOMCUSTOMSOUND1 <> 0 then
      A_RandomCustomSound1(mo)
    else
      S_StartSound(mo, mo.info.customsound1);
  end;
end;

procedure A_CustomSound2(mo: Pmobj_t);
begin
  if mo.info.customsound2 <> 0 then
  begin
    if mo.info.flags_ex and MF_EX_RANDOMCUSTOMSOUND2 <> 0 then
      A_RandomCustomSound2(mo)
    else
      S_StartSound(mo, mo.info.customsound2);
  end;
end;

procedure A_CustomSound3(mo: Pmobj_t);
begin
  if mo.info.customsound3 <> 0 then
  begin
    if mo.info.flags_ex and MF_EX_RANDOMCUSTOMSOUND3 <> 0 then
      A_RandomCustomSound3(mo)
    else
      S_StartSound(mo, mo.info.customsound3);
  end;
end;

procedure P_RandomSound(const actor: Pmobj_t; const soundnum: integer);
var
  randomlist: TDNumberList;
  rndidx: integer;
begin
  if soundnum <> 0 then
  begin
    randomlist := S_GetRandomSoundList(soundnum);
    if randomlist <> nil then
    begin
      if randomlist.Count > 0 then
      begin
        rndidx := N_Random mod randomlist.Count;
        S_StartSound(actor, randomlist[rndidx]);
      end
      else
      // JVAL: This should never happen, see S_GetRandomSoundList() in sounds.pas
        I_Error('P_RandomSound(): Random list is empty for sound no %d', [soundnum]);
    end;
  end;
end;

procedure A_RandomPainSound(actor: Pmobj_t);
begin
  if actor.flags2_ex and MF2_EX_FULLVOLPAIN <> 0 then
    P_RandomSound(nil, actor.info.painsound)
  else
    P_RandomSound(actor, actor.info.painsound);
end;

procedure A_RandomSeeSound(actor: Pmobj_t);
begin
  if actor.flags2_ex and MF2_EX_FULLVOLSEE <> 0 then
    P_RandomSound(nil, actor.info.seesound)
  else
    P_RandomSound(actor, actor.info.seesound);
end;

procedure A_RandomAttackSound(actor: Pmobj_t);
begin
  if actor.flags2_ex and MF2_EX_FULLVOLATTACK <> 0 then
    P_RandomSound(nil, actor.info.attacksound)
  else
    P_RandomSound(actor, actor.info.attacksound);
end;

procedure A_RandomDeathSound(actor: Pmobj_t);
begin
  if actor.flags2_ex and MF2_EX_FULLVOLDEATH <> 0 then
    P_RandomSound(nil, actor.info.deathsound)
  else
    P_RandomSound(actor, actor.info.deathsound);
end;

procedure A_RandomActiveSound(actor: Pmobj_t);
begin
  if actor.flags2_ex and MF2_EX_FULLVOLACTIVE <> 0 then
    P_RandomSound(nil, actor.info.activesound)
  else
    P_RandomSound(actor, actor.info.activesound);
end;

procedure A_RandomCustomSound1(actor: Pmobj_t);
begin
  P_RandomSound(actor, actor.info.customsound1);
end;

procedure A_RandomCustomSound2(actor: Pmobj_t);
begin
  P_RandomSound(actor, actor.info.customsound2);
end;

procedure A_RandomCustomSound3(actor: Pmobj_t);
begin
  P_RandomSound(actor, actor.info.customsound3);
end;

procedure A_RandomCustomSound(actor: Pmobj_t);
var
  list: TDNumberList;
  rndidx: integer;
begin
  list := TDNumberList.Create;
  try
    if actor.info.customsound1 > 0 then
      list.Add(actor.info.customsound1);
    if actor.info.customsound2 > 0 then
      list.Add(actor.info.customsound2);
    if actor.info.customsound3 > 0 then
      list.Add(actor.info.customsound3);
    if list.Count > 0 then
    begin
      rndidx := N_Random mod list.Count;
      P_RandomSound(actor, list[rndidx]);
    end;
  finally
    list.Free;
  end;
end;

procedure A_RandomMeleeSound(actor: Pmobj_t);
begin
  P_RandomSound(actor, actor.info.meleesound);
end;

//
// JVAL
// Play a sound
// A_Playsound(soundname)
//
procedure A_Playsound(actor: Pmobj_t);
var
  sndidx: integer;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  if actor.state.params.IsComputed[0] then
    sndidx := actor.state.params.IntVal[0]
  else
  begin
    sndidx := S_GetSoundNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := sndidx;
  end;

  S_StartSound(actor, sndidx);
end;

//
// JVAL
// Play a sound at full volume
// A_PlaysoundFullVolume(soundname)
//
procedure A_PlaysoundFullVolume(actor: Pmobj_t);
var
  sndidx: integer;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  if actor.state.params.IsComputed[0] then
    sndidx := actor.state.params.IntVal[0]
  else
  begin
    sndidx := S_GetSoundNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := sndidx;
  end;

  S_StartSound(nil, sndidx);
end;

procedure A_PlayWeaponsound(actor: Pmobj_t);
begin
  A_Playsound(actor);
end;

//
// JVAL
// Random sound
// A_RandomSound(sound1, sound2, ...)
//
procedure A_RandomSound(actor: Pmobj_t);
var
  sidxs: TDNumberList;
  sndidx: integer;
  i: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  if actor.state.params.Count = 0 then // Should never happen
    exit;

  sidxs := TDNumberList.Create;
  try
    for i := 0 to actor.state.params.Count - 1 do
    begin
      if actor.state.params.IsComputed[i] then
        sndidx := actor.state.params.IntVal[i]
      else
      begin
        sndidx := S_GetSoundNumForName(actor.state.params.StrVal[i]);
        actor.state.params.IntVal[i] := sndidx;
      end;
      sidxs.Add(sndidx);
    end;
    sndidx := N_Random mod sidxs.Count;
    S_StartSound(actor, sidxs[sndidx]);
  finally
    sidxs.Free;
  end;
end;

//
// JVAL
// Set all momentum to zero
//
procedure A_Stop(actor: Pmobj_t);
begin
  actor.momx := 0;
  actor.momy := 0;
  actor.momz := 0;
end;

//
// JVAL
// Change state offset
// A_Jump(propability, offset)
//
procedure A_Jump(actor: Pmobj_t);
var
  propability: integer;
  offset: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  propability := actor.state.params.IntVal[0];  // JVAL simple integer values are precalculated

  if N_Random < propability then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[1]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// Custom missile, based on A_CustomMissile() of ZDoom
// A_CustomMissile(type, height, offset, angle, aimmode, pitch)
//
procedure A_CustomMissile(actor: Pmobj_t);
var
  mobj_no: integer;
  spawnheight: fixed_t;
  spawnoffs: integer;
  angle: angle_t;
  aimmode: integer;
  pitch: angle_t;
  missile: Pmobj_t;
  ang: angle_t;
  x, y, z: fixed_t;
  vx, vz: fixed_t;
  velocity: vec3_t;
  missilespeed: fixed_t;
  owner: Pmobj_t;
begin
  if not P_CheckStateParams(actor) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_CustomMissile(): Unknown missile %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  if mobjinfo[mobj_no].speed < 2048 then
    mobjinfo[mobj_no].speed := mobjinfo[mobj_no].speed * FRACUNIT;  // JVAL fix me!!!
  spawnheight := actor.state.params.IntVal[1];
  spawnoffs := actor.state.params.IntVal[2];
  angle := ANG1 * actor.state.params.IntVal[3];
  aimmode := actor.state.params.IntVal[4] and 3;
  pitch := ANG1 * actor.state.params.IntVal[5];

  if (actor.target <> nil) or (aimmode = 2) then
  begin
    ang := (actor.angle - ANG90) shr ANGLETOFINESHIFT;
    x := spawnoffs * finecosine[ang];
    y := spawnoffs * finesine[ang];
    if aimmode <> 0 then
      z := spawnheight * FRACUNIT
    else
      z := (spawnheight - 32) * FRACUNIT;
    case aimmode of
      1:
        begin
          missile := P_SpawnMissileXYZ(actor.x + x, actor.y + y, actor.z + z, actor, actor.target, mobj_no);
        end;
      2:
        begin
          missile := P_SpawnMissileAngleZ(actor, actor.z + z, mobj_no, actor.angle, 0, 0);

          // It is not necessary to use the correct angle here.
          // The only important thing is that the horizontal momentum is correct.
          // Therefore use 0 as the missile's angle and simplify the calculations accordingly.
          // The actual momentum vector is set below.
          if missile <> nil then
          begin
            pitch := pitch shr ANGLETOFINESHIFT;
            vx := finecosine[pitch];
            vz := finesine[pitch];
            missile.momx := FixedMul(vx, missile.info.speed);
            missile.momy := 0;
            missile.momz := FixedMul(vz, missile.info.speed);
          end;
        end;
      else
      begin
        inc(actor.x, x);
        inc(actor.y, y);
        inc(actor.z, z);
        missile := P_SpawnMissile(actor, actor.target, mobj_no);
        dec(actor.x, x);
        dec(actor.y, y);
        dec(actor.z, z);

      end;
    end;  // case

    if missile <> nil then
    begin
      // Use the actual momentum instead of the missile's Speed property
      // so that this can handle missiles with a high vertical velocity
      // component properly.
      velocity[0] := missile.momx;
      velocity[1] := missile.momy;
      velocity[2] := 0.0;

      missilespeed := round(VectorLength(@velocity));

      missile.angle := missile.angle + angle;
      ang := missile.angle shr ANGLETOFINESHIFT;
      missile.momx := FixedMul(missilespeed, finecosine[ang]);
      missile.momy := FixedMul(missilespeed, finesine[ang]);

      // handle projectile shooting projectiles - track the
      // links back to a real owner
      if (actor.info.flags and MF_MISSILE <> 0) or (aimmode and 4 <> 0) then
      begin
        owner := actor;
        while (owner.info.flags and MF_MISSILE <> 0) and (owner.target <> nil) do
          owner := owner.target;
         missile.target := owner;
        // automatic handling of seeker missiles
        if actor.info.flags_ex and missile.info.flags_ex and MF_EX_SEEKERMISSILE <> 0 then
          missile.tracer := actor.tracer;
      end
      else if missile.info.flags_ex and MF_EX_SEEKERMISSILE <> 0 then
      // automatic handling of seeker missiles
        missile.tracer := actor.target;

    end;
  end;
end;

//
// JVAL
// Standard random missile procedure
// A_RandomMissile(type1, type2, type3, ...)
//
procedure A_RandomMissile(actor: Pmobj_t);
var
  ridx: integer;
  mobj_no: integer;
  spawnheight: fixed_t;
  spawnoffs: integer;
  angle: angle_t;
  missile: Pmobj_t;
  ang: angle_t;
  x, y, z: fixed_t;
  velocity: vec3_t;
  missilespeed: fixed_t;
  owner: Pmobj_t;
begin
  if not P_CheckStateParams(actor) then
    exit;

  // Random index
  ridx := N_Random mod actor.state.params.Count;

  if actor.state.params.IsComputed[ridx] then
    mobj_no := actor.state.params.IntVal[ridx]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[ridx]);
    actor.state.params.IntVal[ridx] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_RandomMissile(): Unknown missile %s'#13#10, [actor.state.params.StrVal[ridx]]);
    exit;
  end;

  if mobjinfo[mobj_no].speed < 2048 then
    mobjinfo[mobj_no].speed := mobjinfo[mobj_no].speed * FRACUNIT;  // JVAL fix me!!!
  spawnheight := 0;
  spawnoffs := 0;
  angle := 0;

  if actor.target <> nil then
  begin
    ang := (actor.angle - ANG90) shr ANGLETOFINESHIFT;
    x := spawnoffs * finecosine[ang];
    y := spawnoffs * finesine[ang];
    z := (spawnheight - 32) * FRACUNIT;
    inc(actor.x, x);
    inc(actor.y, y);
    inc(actor.z, z);
    missile := P_SpawnMissile(actor, actor.target, mobj_no);
    dec(actor.x, x);
    dec(actor.y, y);
    dec(actor.z, z);

    if missile <> nil then
    begin
      // Use the actual momentum instead of the missile's Speed property
      // so that this can handle missiles with a high vertical velocity
      // component properly.
      velocity[0] := missile.momx;
      velocity[1] := missile.momy;
      velocity[2] := 0.0;

      missilespeed := round(VectorLength(@velocity));

      missile.angle := missile.angle + angle;
      ang := missile.angle shr ANGLETOFINESHIFT;
      missile.momx := FixedMul(missilespeed, finecosine[ang]);
      missile.momy := FixedMul(missilespeed, finesine[ang]);

      owner := actor;
      while (owner.info.flags and MF_MISSILE <> 0) and (owner.target <> nil) do
        owner := owner.target;
       missile.target := owner;
      // automatic handling of seeker missiles
      if actor.info.flags_ex and missile.info.flags_ex and MF_EX_SEEKERMISSILE <> 0 then
        missile.tracer := actor.tracer;

    end;
  end;
end;

//
// A_SpawnItem(type, distance, zheight, angle)
//
procedure A_SpawnItem(actor: Pmobj_t);
var
  mobj_no: integer;
  distance: fixed_t;
  zheight: fixed_t;
  mo: Pmobj_t;
  ang: angle_t;
begin
  if not P_CheckStateParams(actor) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_SpawnItem(): Unknown item %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  distance := actor.state.params.FixedVal[1] + actor.radius + mobjinfo[mobj_no].radius;

  zheight := actor.state.params.FixedVal[2];
  ang := ANG1 * actor.state.params.IntVal[3];

  ang := (ang + actor.angle) shr ANGLETOFINESHIFT;
  mo := P_SpawnMobj(actor.x + FixedMul(distance, finecosine[ang]),
                    actor.y + FixedMul(distance, finesine[ang]),
                    actor.z{ - actor.floorz }+ zheight, mobj_no);
  if mo <> nil then
    mo.angle := actor.angle;
end;

// A_SpawnItemEx Flags
const
  SIXF_TRANSFERTRANSLATION = 1;
  SIXF_ABSOLUTEPOSITION = 2;
  SIXF_ABSOLUTEANGLE = 4;
  SIXF_ABSOLUTEMOMENTUM = 8;
  SIXF_SETMASTER = 16;
  SIXF_NOCHECKPOSITION = 32;
  SIXF_TELEFRAG = 64;
  // 128 is used by Skulltag!
  SIXF_TRANSFERAMBUSHFLAG = 256;

//
// A_SpawnItemEx(type, xofs, yofs, zofs, momx, momy, momz, Angle, flags, chance)
//
// type -> parm0
// xofs -> parm1
// yofs -> parm2
// zofs -> parm3
// momx -> parm4
// momy -> parm5
// momz -> parm6
// Angle -> parm7
// flags -> parm8
// chance -> parm9
//
procedure A_SpawnItemEx(actor: Pmobj_t);
var
  mobj_no: integer;
  x, y: fixed_t;
  xofs, yofs, zofs: fixed_t;
  momx, momy, momz: fixed_t;
  newxmom: fixed_t;
  mo: Pmobj_t;
  ang, ang1: angle_t;
  flags: integer;
  chance: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  chance := actor.state.params.IntVal[9];

  if (chance > 0) and (chance < N_Random) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_SpawnItemEx(): Unknown item %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  // JVAL 20180222 -> IntVal changed to FixedVal
  xofs := actor.state.params.FixedVal[1];
  yofs := actor.state.params.FixedVal[2];
  zofs := actor.state.params.FixedVal[3];
  momx := actor.state.params.FixedVal[4];
  momy := actor.state.params.FixedVal[5];
  momz := actor.state.params.FixedVal[6];
  ang1 := actor.state.params.IntVal[7];
  flags := actor.state.params.IntVal[8];

  if (flags and SIXF_ABSOLUTEANGLE) = 0 then
    ang1 := ang1 + Actor.angle;

  ang := ang1 shr ANGLETOFINESHIFT;

  if (flags and SIXF_ABSOLUTEPOSITION) <> 0 then
  begin
    x := actor.x + xofs;
    y := actor.y + yofs;
  end
  else
  begin
    // in relative mode negative y values mean 'left' and positive ones mean 'right'
    // This is the inverse orientation of the absolute mode!
    x := actor.x + FixedMul(xofs, finecosine[ang]) + FixedMul(yofs, finesine[ang]);
    y := actor.y + FixedMul(xofs, finesine[ang]) - FixedMul(yofs, finecosine[ang]);
  end;

  if (flags and SIXF_ABSOLUTEMOMENTUM) = 0 then
  begin
    // Same orientation issue here!
    newxmom := FixedMul(momx, finecosine[ang]) + FixedMul(momy, finesine[ang]);
    momy := FixedMul(momx, finesine[ang]) - FixedMul(momy, finecosine[ang]);
    momx := newxmom;
  end;

  mo := P_SpawnMobj(x, y, actor.z{ - actor.floorz} + zofs, mobj_no);

  if mo <> nil then
  begin
    mo.momx := momx;
    mo.momy := momy;
    mo.momz := momz;
    mo.angle := ang1;
    if (flags and SIXF_TRANSFERAMBUSHFLAG) <> 0 then
      mo.flags := (mo.flags and not MF_AMBUSH) or (actor.flags and MF_AMBUSH);
  end;
end;

//
// Generic seeker missile function
//
// A_SeekerMissile(threshold: angle; turnMax: angle)
procedure A_SeekerMissile(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor) then
    exit;

  P_SeekerMissile(actor, actor.state.params.IntVal[0] * ANG1, actor.state.params.IntVal[1] * ANG1);
end;

procedure A_CStaffMissileSlither(actor: Pmobj_t);
var
  newX, newY: fixed_t;
  weaveXY: integer;
  angle: angle_t;
begin
  weaveXY := actor.bob;
  angle := (actor.angle + ANG90) shr ANGLETOFINESHIFT;
  newX := actor.x - FixedMul(finecosine[angle], FloatBobOffsets[weaveXY]);
  newY := actor.y - FixedMul(finesine[angle], FloatBobOffsets[weaveXY]);
  weaveXY := (weaveXY + 3) and 63;
  newX := newX + FixedMul(finecosine[angle], FloatBobOffsets[weaveXY]);
  newY := newY + FixedMul(finesine[angle], FloatBobOffsets[weaveXY]);
  P_TryMove(actor, newX, newY);
  actor.bob := weaveXY;
end;

procedure A_SetTranslucent(actor: Pmobj_t);
var
  newstyle: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  actor.alpha := actor.state.params.FixedVal[0];

  if actor.alpha <= 0 then
  begin
    actor.renderstyle := mrs_normal;
    actor.flags := actor.flags or MF_SHADOW;
    actor.alpha := 0;
  end
  else if actor.alpha >= FRACUNIT then
  begin
    actor.renderstyle := mrs_normal;
    actor.flags := actor.flags and not MF_SHADOW;
    actor.alpha := FRACUNIT;
  end
  else
  begin
    if actor.renderstyle = mrs_normal then
      actor.renderstyle := mrs_translucent;
  end;

  if actor.state.params.Count = 1 then
    Exit;

  if not actor.state.params.IsComputed[1] then
    actor.state.params.IntVal[1] := Ord(R_GetRenderstyleForName(actor.state.params.StrVal[1]));

  newstyle := actor.state.params.IntVal[1];
  if newstyle = Ord(mrs_translucent) then
  begin
    actor.renderstyle := mrs_translucent;
    actor.flags := actor.flags and not MF_SHADOW;
  end
  else if newstyle = Ord(mrs_add) then
  begin
    actor.renderstyle := mrs_add;
    actor.flags := actor.flags and not MF_SHADOW;
  end
  else if newstyle = Ord(mrs_subtract) then
  begin
    actor.renderstyle := mrs_subtract;
    actor.flags := actor.flags and not MF_SHADOW;
  end
  else if newstyle = Ord(mrs_normal) then
  begin
    actor.renderstyle := mrs_normal;
    actor.flags := actor.flags and not MF_SHADOW;
  end;

end;

//
// FadeOut(reduce = 10%)
//
procedure A_FadeOut(actor: Pmobj_t);
var
  reduce: fixed_t;
begin
  reduce := FRACUNIT div 10;

  if actor.state.params <> nil then
    if actor.state.params.Count > 0 then
      reduce := actor.state.params.FixedVal[0];

  if actor.renderstyle = mrs_normal then
  begin
    actor.renderstyle := mrs_translucent;
    actor.alpha := FRACUNIT;
  end;

  actor.alpha := actor.alpha - reduce;
  if actor.alpha <= 0 then
    P_RemoveMobj(actor);
end;

// reduce -> percentage to reduce fading
procedure Do_FadeOut(actor: Pmobj_t; const reduce: integer);
begin
  if actor.renderstyle = mrs_normal then
  begin
    actor.renderstyle := mrs_translucent;
    actor.alpha := FRACUNIT;
  end;

  actor.alpha := actor.alpha - (reduce * FRACUNIT) div 100;
  if actor.alpha <= 0 then
    P_RemoveMobj(actor);
end;

procedure A_FadeOut10(actor: Pmobj_t);
begin
  Do_FadeOut(actor, 10);
end;

procedure A_FadeOut20(actor: Pmobj_t);
begin
  Do_FadeOut(actor, 20);
end;

procedure A_FadeOut30(actor: Pmobj_t);
begin
  Do_FadeOut(actor, 30);
end;

//
// FadeIn(incriment = 10%)
//
procedure A_FadeIn(actor: Pmobj_t);
var
  incriment: fixed_t;
begin
  if actor.renderstyle = mrs_normal then
    exit;

  incriment := FRACUNIT div 10;

  if actor.state.params <> nil then
    if actor.state.params.Count > 0 then
      incriment := actor.state.params.FixedVal[0];

  actor.alpha := actor.alpha + incriment;
  if actor.alpha >= FRACUNIT then
  begin
    actor.renderstyle := mrs_normal;
    actor.alpha := FRACUNIT;
  end;
end;

// incriment -> percentage to inscrease fading
procedure Do_FadeIn(actor: Pmobj_t; const incriment: integer);
begin
  actor.renderstyle := mrs_translucent;
  actor.alpha := actor.alpha + (incriment * FRACUNIT) div 100;
  if actor.alpha > FRACUNIT then
  begin
    actor.alpha := FRACUNIT;
    actor.renderstyle := mrs_normal
  end;
end;

procedure A_FadeIn10(actor: Pmobj_t);
begin
  Do_FadeIn(actor, 10);
end;

procedure A_FadeIn20(actor: Pmobj_t);
begin
  Do_FadeIn(actor, 20);
end;

procedure A_FadeIn30(actor: Pmobj_t);
begin
  Do_FadeIn(actor, 30);
end;

//
// A_MissileAttack(missilename = actor.info.missiletype)
//
procedure A_MissileAttack(actor: Pmobj_t);
var
  missile: Pmobj_t;
  mobj_no: integer;
begin
  mobj_no := actor.info.missiletype;

  if actor.state.params <> nil then
  begin
    if actor.state.params.IsComputed[0] then
      mobj_no := actor.state.params.IntVal[0]
    else
    begin
      mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
      actor.state.params.IntVal[0] := mobj_no;
    end;
    if mobj_no = -1 then
    begin
      I_Warning('A_MissileAttack(): Unknown missile %s'#13#10, [actor.state.params.StrVal[0]]);
      exit;
    end;
  end
  else if mobj_no <= 0 then
  begin
    I_Warning('A_MissileAttack(): Unknown missile'#13#10);
    exit;
  end;

  if mobjinfo[mobj_no].speed < 256 then
    mobjinfo[mobj_no].speed := mobjinfo[mobj_no].speed * FRACUNIT;  // JVAL fix me!!!

  missile := P_SpawnMissile(actor, actor.target, mobj_no);

  if missile <> nil then
  begin
    if missile.info.flags_ex and MF_EX_SEEKERMISSILE <> 0 then
      missile.tracer := actor.target;
  end;

end;

//
// A_AdjustSideSpot(sideoffset: float)
//
procedure A_AdjustSideSpot(actor: Pmobj_t);
var
  offs: fixed_t;
  ang: angle_t;
  x, y: fixed_t;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  offs := actor.state.params.Fixedval[0];

  ang := actor.angle shr ANGLETOFINESHIFT;

  x := FixedMul(offs, finecosine[ang]);
  y := FixedMul(offs, finesine[ang]);

  actor.x := actor.x + x;
  actor.y := actor.y + y;
end;

//
// JVAL
// A_ThrustZ(momz: float)
// Changes z momentum
//
procedure A_ThrustZ(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  actor.momz := actor.momz + actor.state.params.FixedVal[0];
end;

//
// JVAL
// A_ThrustXY(mom: float; ang: angle)
// Changes x, y momentum
//
procedure A_ThrustXY(actor: Pmobj_t);
var
  ang: angle_t;
  thrust: fixed_t;
begin
  if not P_CheckStateParams(actor) then
    exit;

  thrust := actor.state.params.FixedVal[0];

  ang := actor.angle + round(actor.state.params.FloatVal[1] * ANG1);
  ang := ang shr ANGLETOFINESHIFT;

  actor.momx := actor.momx + FixedMul(thrust, finecosine[ang]);
  actor.momy := actor.momy + FixedMul(thrust, finesine[ang]);
end;

//
// JVAL
// A_Turn(angle: float)
// Changes the actor's angle
//
procedure A_Turn(actor: Pmobj_t);
var
  ang: angle_t;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  ang := round(actor.state.params.FloatVal[0] * ANG1);
  actor.angle := actor.angle + ang;
end;

//
// JVAL
// A_JumpIfCloser(distancetotarget: float, offset: integer)
// Jump conditionally to another state if distance to target is closer to first parameter
//
procedure A_JumpIfCloser(actor: Pmobj_t);
var
  dist: fixed_t;
  target: Pmobj_t;
  offset: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.player = nil then
    target := actor.target
  else
  begin
    // Does the player aim at something that can be shot?
    P_BulletSlope(actor);
    target := linetarget;
  end;

  // No target - no jump
  if target = nil then
    exit;

  dist := actor.state.params.FixedVal[0];
  if P_AproxDistance(actor.x - target.x, actor.y - target.y) < dist then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[1]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

//
// JVAL
// A_JumpIfHealthLower(health: integer; offset: integer)
// Jump conditionally to another state if health is lower to first parameter
//
procedure A_JumpIfHealthLower(actor: Pmobj_t);
var
  offset: integer;
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  if actor.health < actor.state.params.IntVal[0] then
  begin
    offset := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[1]);
    if @states[offset] <> actor.state then
      P_SetMobjState(actor, statenum_t(offset));
  end;
end;

procedure A_ScreamAndUnblock(actor: Pmobj_t);
begin
  A_Scream(actor);
  A_NoBlocking(actor);
end;

procedure A_Missile(actor: Pmobj_t);
begin
  actor.flags := actor.flags or MF_MISSILE;
end;

procedure A_NoMissile(actor: Pmobj_t);
begin
  actor.flags := actor.flags and not MF_MISSILE;
end;

//=============================================================================
//
// P_DoNewChaseDir
//
// killough 9/8/98:
//
// Most of P_NewChaseDir(), except for what
// determines the new direction to take
//
//=============================================================================

const
  opposite: array[0..8] of dirtype_t = (
    DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST,
    DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR
  );

  diags: array[0..3] of dirtype_t = (
    DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST
  );

procedure P_DoNewChaseDir(actor: Pmobj_t; deltax, deltay: fixed_t);
var
  d: array[0..2] of dirtype_t;
  dt: dirtype_t;
  tdir: integer;
  olddir, turnaround: dirtype_t;
begin
  olddir := dirtype_t(actor.movedir);
  turnaround := opposite[Ord(olddir)];

  if deltax > 10 * FRACUNIT then
    d[1] := DI_EAST
  else if deltax < -10 * FRACUNIT then
    d[1] := DI_WEST
  else
    d[1] := DI_NODIR;

  if deltay < -10 * FRACUNIT then
    d[2] := DI_SOUTH
  else if deltay > 10 * FRACUNIT then
    d[2] := DI_NORTH
  else
    d[2] := DI_NODIR;

  // try direct route
  if (d[1] <> DI_NODIR) and (d[2] <> DI_NODIR) then
  begin
    actor.movedir := Ord(diags[(intval(deltay < 0) shl 1) + intval(deltax > 0)]);
    if (actor.movedir <> Ord(turnaround)) and P_TryWalk(actor) then
      exit;
  end;

  // try other directions
  if (N_Random > 200) or (abs(deltay) > abs(deltax)) then
  begin
    dt := d[1];
    d[1] := d[2];
    d[2] := dt;
  end;

  if d[1] = turnaround then
    d[1] := DI_NODIR;
  if d[2] = turnaround then
    d[2] := DI_NODIR;

  if d[1] <> DI_NODIR then
  begin
    actor.movedir := Ord(d[1]);
    if P_TryWalk(actor) then
      exit; // either moved forward or attacked
  end;

  if d[2] <> DI_NODIR then
  begin
    actor.movedir := Ord(d[2]);
    if P_TryWalk(actor) then
      exit;
  end;

  // there is no direct path to the player, so pick another direction.
  if olddir <> DI_NODIR then
  begin
    actor.movedir := Ord(olddir);
    if P_TryWalk(actor) then
      exit;
  end;

  // randomly determine direction of search
  if N_Random and 1 <> 0 then
  begin
    for tdir := Ord(DI_EAST) to Ord(DI_SOUTHEAST) do
    begin
      if tdir <> Ord(turnaround) then
      begin
        actor.movedir := tdir;
        if P_TryWalk(actor) then
          exit;
      end;
    end;
  end
  else
  begin
    for tdir := Ord(DI_SOUTHEAST) downto Ord(DI_EAST) - 1 do
    begin
      if tdir <> Ord(turnaround) then
      begin
        actor.movedir := tdir;
        if P_TryWalk(actor) then
          exit;
      end;
    end;
  end;

  if turnaround <> DI_NODIR then
  begin
    actor.movedir := Ord(turnaround);
    if P_TryWalk(actor) then
      exit;
  end;

  actor.movedir := Ord(DI_NODIR);  // can not move
end;

//=============================================================================
//
// P_RandomChaseDir
//
//=============================================================================

procedure P_RandomChaseDir(actor: Pmobj_t);
var
  turndir, tdir: integer;
  olddir: integer;
  turnaround: dirtype_t;
begin
  olddir := actor.movedir;
  turnaround := opposite[olddir];

  // If the actor elects to continue in its current direction, let it do
  // so unless the way is blocked. Then it must turn.
  if N_Random < 150 then
  begin
    if P_TryWalk(actor) then
      exit;
  end;

  turndir := 1 - 2 * (N_Random and 1);

  if olddir = Ord(DI_NODIR) then
    olddir := N_Random and 7;

  tdir := (Ord(olddir) + turndir) and 7;
  while tdir <> olddir do
  begin
    if tdir <> Ord(turnaround) then
    begin
      actor.movedir := tdir;
      if P_TryWalk(actor) then
        exit;
    end;
    tdir := (tdir + turndir) and 7;
  end;

  if turnaround <> DI_NODIR then
  begin
    actor.movedir := Ord(turnaround);
    if P_TryWalk(actor) then
    begin
      actor.movecount := N_Random and 15;
      exit;
    end;
  end;

  actor.movedir := Ord(DI_NODIR);  // cannot move
end;

//
// A_Wander
//
procedure A_Wander(actor: Pmobj_t);
var
  delta: integer;
begin
  // modify target threshold
  if actor.threshold <> 0 then
    actor.threshold := actor.threshold - 1;

  // turn towards movement direction if not there yet
  if actor.movedir < 8 then
  begin
    actor.angle := actor.angle and $E0000000;
    delta := actor.angle - _SHLW(actor.movedir, 29);

    if delta > 0 then
      actor.angle := actor.angle - ANG45
    else if delta < 0 then
      actor.angle := actor.angle + ANG45;
  end;

  dec(actor.movecount);
  if (actor.movecount < 0) or P_Move(actor) then
  begin
    P_RandomChaseDir(actor);
    actor.movecount := actor.movecount + 5;
  end;
end;

procedure A_GhostOn(actor: Pmobj_t);
begin
  actor.flags := actor.flags or MF_SHADOW;
end;

procedure A_GhostOff(actor: Pmobj_t);
begin
  actor.flags := actor.flags and not MF_SHADOW;
end;

procedure A_Turn5(actor: Pmobj_t);
var
  ang: angle_t;
begin
  ang := 5 * ANG1;
  actor.angle := actor.angle + ang;
end;

procedure A_Turn10(actor: Pmobj_t);
var
  ang: angle_t;
begin
  ang := 10 * ANG1;
  actor.angle := actor.angle + ang;
end;

//
// JVAL
// Set blocking flag
//
procedure A_Blocking(actor: Pmobj_t);
begin
  actor.flags := actor.flags or MF_SOLID;
end;

procedure A_DoNotRunScripts(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex or MF2_EX_DONTRUNSCRIPTS;
end;

procedure A_DoRunScripts(actor: Pmobj_t);
begin
  actor.flags2_ex := actor.flags2_ex and (not MF2_EX_DONTRUNSCRIPTS);
end;

procedure A_SetDropItem(actor: Pmobj_t);
var
  mobj_no: integer;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_SetDropItem(): Unknown item %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  actor.dropitem := mobj_no;
  actor.flags2_ex := actor.flags2_ex or MF2_EX_CUSTOMDROPITEM;
end;

procedure A_SetDefaultDropItem(actor: Pmobj_t);
begin
  actor.dropitem := 0;
  actor.flags2_ex := actor.flags2_ex and not MF2_EX_CUSTOMDROPITEM;
end;

procedure A_TargetDropItem(actor: Pmobj_t);
var
  mobj_no: integer;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  if actor.target = nil then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('A_TargetDropItem(): Unknown item %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  actor.target.dropitem := mobj_no;
  actor.target.flags2_ex := actor.target.flags2_ex or MF2_EX_CUSTOMDROPITEM;
end;

procedure A_DefaultTargetDropItem(actor: Pmobj_t);
begin
  if actor.target = nil then
    exit;

  actor.target.dropitem := 0;
  actor.target.flags2_ex := actor.target.flags2_ex and not MF2_EX_CUSTOMDROPITEM;
end;

function P_ActorTarget(const actor: Pmobj_t): Pmobj_t;
begin
  if actor = nil then
  begin
    result := nil;
    exit;
  end;

  if actor.player = nil then
    result := actor.target
  else
  begin
    // Does the player aim at something that can be shot?
    P_BulletSlope(actor);
    result := linetarget;
  end;
end;

//
// A_GlobalEarthQuake (tics: integer);
//
procedure A_GlobalEarthQuake(actor: Pmobj_t);
var
  qtics: integer;
  i: integer;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  qtics := actor.state.params.IntVal[0] * FRACUNIT;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      players[i].quaketics := qtics;
end;

// A_SetMapStr(var: string; value1: string; [value2: string],...)
procedure A_SetMapStr(actor: Pmobj_t);
var
  s: string;
  i: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  s := '';
  for i := 1 to actor.state.params.Count - 1 do
  begin
    s := s + actor.state.params.StrVal[i];
    if i < actor.state.params.Count - 1 then
      s := s + ' ';
  end;                     

  PS_SetMapStr(actor.state.params.StrVal[0], s);
end;

// A_SetWorldStr(var: string; value1: string; [value2: string],...)
procedure A_SetWorldStr(actor: Pmobj_t);
var
  s: string;
  i: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  s := '';
  for i := 1 to actor.state.params.Count - 1 do
  begin
    s := s + actor.state.params.StrVal[i];
    if i < actor.state.params.Count - 1 then
      s := s + ' ';
  end;

  PS_SetWorldStr(actor.state.params.StrVal[0], s);
end;

// A_SetMapInt(var: string; value: integer);
procedure A_SetMapInt(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  PS_SetMapInt(actor.state.params.StrVal[0], actor.state.params.IntVal[1]);
end;

// A_SetWorldInt(var: string; value: integer);
procedure A_SetWorldInt(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  PS_SetWorldInt(actor.state.params.StrVal[0], actor.state.params.IntVal[1]);
end;

// A_SetMapFloat(var: string; value: float);
procedure A_SetMapFloat(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  PS_SetMapFloat(actor.state.params.StrVal[0], actor.state.params.FloatVal[1]);
end;

// A_SetWorldFloat(var: string; value: float);
procedure A_SetWorldFloat(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 2) then
    exit;

  PS_SetWorldFloat(actor.state.params.StrVal[0], actor.state.params.FloatVal[1]);
end;

//
// A_RandomGoto(state1, state2, ....)
//
procedure A_RandomGoto(actor: Pmobj_t);
var
  newstate: integer;
  idx: integer;
begin
  if not P_CheckStateParams(actor) then
    exit;

  idx := N_Random mod actor.state.params.Count;

  if not actor.state.params.IsComputed[idx] then
    actor.state.params.IntVal[idx] := P_GetStateFromName(actor, actor.state.params.StrVal[idx]);
  newstate := actor.state.params.IntVal[idx];

  P_SetMobjState(actor, statenum_t(newstate));
end;

procedure P_SetHealth(const mo: Pmobj_t; const h: integer);
var
  p: Pplayer_t;
begin
  if mo.health <= 0 then
    exit;

  mo.health := h;
  p := mo.player;
  if p <> nil then
    p.health := h;
end;

procedure A_ResetHealth(actor: Pmobj_t);
begin
  P_SetHealth(actor, actor.info.spawnhealth);
end;

procedure A_SetHealth(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  P_SetHealth(actor, actor.state.params.IntVal[0]);
end;

procedure A_ResetTargetHealth(actor: Pmobj_t);
begin
  if actor.target <> nil then
    P_SetHealth(actor.target, actor.target.info.spawnhealth);
end;

procedure A_SetTargetHealth(actor: Pmobj_t);
begin
  if actor.target = nil then
    exit;

  if not P_CheckStateParams(actor, 1) then
    exit;

  P_SetHealth(actor.target, actor.state.params.IntVal[0]);
end;

procedure A_Recoil(actor: Pmobj_t);
var
  xymom: fixed_t;
  angle: angle_t;
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  xymom := actor.state.params.FixedVal[0];

  angle := (actor.angle + ANG180) shr ANGLETOFINESHIFT;
  actor.momx := actor.momx + FixedMul(xymom, finecosine[angle]);
  actor.momy := actor.momy + FixedMul(xymom, finesine[angle]);
end;

procedure A_SetSolid(actor: Pmobj_t);
begin
  actor.flags := actor.flags or MF_SOLID;
end;

procedure A_UnSetSolid(actor: Pmobj_t);
begin
  actor.flags := actor.flags and not MF_SOLID;
end;

procedure A_SetFloat(actor: Pmobj_t);
begin
  actor.flags := actor.flags or MF_FLOAT;
end;

procedure A_UnSetFloat(actor: Pmobj_t);
begin
  actor.flags := actor.flags and not (MF_FLOAT or MF_INFLOAT);
end;

//
// A_ScaleVelocity(scale: float)
// zDoom compatibility
//
procedure A_ScaleVelocity(actor: Pmobj_t);
var
  scale: fixed_t;
begin
  if not P_CheckStateParams(actor) then
    exit;

  scale := actor.state.params.FixedVal[0];

  actor.momx := FixedMul(actor.momx, scale);
  actor.momy := FixedMul(actor.momy, scale);
  actor.momz := FixedMul(actor.momz, scale);
end;

//
// A_ChangeVelocity(velx, vely, velz: float; flags: integer)
// zDoom compatibility
//
procedure A_ChangeVelocity(actor: Pmobj_t);
var
  vx, vy, vz: fixed_t;
  vx1, vy1: fixed_t;
  an: angle_t;
  sina, cosa: fixed_t;
  flags: integer;
  stmp: string;
  sc: TSCriptEngine;
  i: integer;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  vx := actor.state.params.FixedVal[0];
  vy := actor.state.params.FixedVal[1];
  vz := actor.state.params.FixedVal[2];

  if not actor.state.params.IsComputed[3] then
  begin
    stmp := actor.state.params.StrVal[3];
    for i := 1 to Length(stmp) do
      if stmp[i] = '|' then
        stmp[i] := ' ';
    flags := 0;
    sc := TSCriptEngine.Create(stmp);
    while sc.GetString do
      flags := flags or SC_EvalueateIntToken(sc._String, ['CVF_RELATIVE', 'CVF_REPLACE']);
    sc.Free;
    actor.state.params.IntVal[3] := flags;
  end
  else
    flags := actor.state.params.IntVal[3];

  if flags and 1 <> 0 then
  begin
    an := actor.angle shr ANGLETOFINESHIFT;
    sina := finesine[an];
    cosa := finecosine[an];
    vx1 := vx;
    vy1 := vy;
    vx := FixedMul(vx1, cosa) - FixedMul(vy1, sina);
    vy := FixedMul(vx1, sina) + FixedMul(vy1, cosa);
  end;

  if flags and 2 <> 0 then
  begin
    actor.momx := vx;
    actor.momy := vy;
    actor.momz := vz;
  end
  else
  begin
    actor.momx := actor.momx + vx;
    actor.momy := actor.momy + vy;
    actor.momz := actor.momz + vz;
  end;
end;

procedure A_SetPushFactor(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  actor.pushfactor := actor.state.params.FixedVal[0];
end;

procedure A_SetScale(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  actor.scale := actor.state.params.FixedVal[0];
end;

procedure A_SetGravity(actor: Pmobj_t);
begin
  if not P_CheckStateParams(actor, 1) then
    exit;

  actor.gravity := actor.state.params.FixedVal[0];
end;


procedure A_SetFloorBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex or MF3_EX_FLOORBOUNCE;
end;

procedure A_UnSetFloorBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex and not MF3_EX_FLOORBOUNCE;
end;

procedure A_SetCeilingBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex or MF3_EX_CEILINGBOUNCE;
end;

procedure A_UnSetCeilingBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex and not MF3_EX_CEILINGBOUNCE;
end;

procedure A_SetWallBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex or MF3_EX_WALLBOUNCE;
end;

procedure A_UnSetWallBounce(actor: Pmobj_t);
begin
  actor.flags3_ex := actor.flags3_ex and not MF3_EX_WALLBOUNCE;
end;

procedure A_GlowLight(actor: Pmobj_t);
const
  ACL_NONE = 0;
  ACL_WHITE = 1;
  ACL_RED = 2;
  ACL_GREEN = 3;
  ACL_BLUE = 4;
  ACL_YELLOW = 5;
var
  scolor: string;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  if not actor.state.params.IsComputed[0] then
  begin
    scolor := strupper(strtrim(actor.state.params.StrVal[0]));
    if scolor = 'WHITE' then
      actor.state.params.IntVal[0] := ACL_WHITE
    else if scolor = 'RED' then
      actor.state.params.IntVal[0] := ACL_RED
    else if scolor = 'GREEN' then
      actor.state.params.IntVal[0] := ACL_GREEN
    else if scolor = 'BLUE' then
      actor.state.params.IntVal[0] := ACL_BLUE
    else if scolor = 'YELLOW' then
      actor.state.params.IntVal[0] := ACL_YELLOW
    else
      actor.state.params.IntVal[0] := ACL_NONE;
  end;

  actor.flags_ex := actor.flags_ex and not MF_EX_LIGHT;
  case actor.state.params.IntVal[0] of
    ACL_WHITE: actor.flags_ex := actor.flags_ex or MF_EX_WHITELIGHT;
    ACL_RED: actor.flags_ex := actor.flags_ex or MF_EX_REDLIGHT;
    ACL_GREEN: actor.flags_ex := actor.flags_ex or MF_EX_GREENLIGHT;
    ACL_BLUE: actor.flags_ex := actor.flags_ex or MF_EX_BLUELIGHT;
    ACL_YELLOW: actor.flags_ex := actor.flags_ex or MF_EX_YELLOWLIGHT;
  end;
end;

function P_TicsFromState(const st: Pstate_t): integer;
begin
  if st.flags_ex and MF_EX_STATE_RANDOM_SELECT <> 0 then
  begin
    if P_Random < 128 then
      result := st.tics
    else
      result := st.tics2;
  end
  else if st.flags_ex and MF_EX_STATE_RANDOM_RANGE <> 0 then
  begin
    if st.tics2 > st.tics then
      result := st.tics + P_Random mod (st.tics2 - st.tics + 1)
    else if st.tics2 < st.tics then
      result := st.tics + P_Random mod (st.tics - st.tics2 + 1)
    else
      result := st.tics;
  end
  else
    result := st.tics;
end;

const
  DEFTRACEANGLE = 15 * ANG1;

//
// A_TraceNearestPlayer(pct: integer, [maxturn: angle])
// pct -> propability
procedure A_TraceNearestPlayer(actor: Pmobj_t);
var
  pct: integer;
  exact: angle_t;
  dist: fixed_t;
  slope: fixed_t;
  dest: Pmobj_t;
  i: integer;
  nearest: integer;
  mindist: integer;
  maxturn: angle_t;
begin
  if not P_CheckStateParams(actor, 1, CSP_AT_LEAST) then
    exit;

  pct := actor.state.params.IntVal[0];
  if pct < P_Random then
    exit;

  dest := nil;
  nearest := MAXINT;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if players[i].mo <> nil then
        if players[i].mo.health >= 0 then
        begin
          mindist := P_AproxDistance(players[i].mo.x - actor.x, players[i].mo.y - actor.y);
          if mindist < nearest then
          begin
            nearest := mindist;
            dest := players[i].mo;
          end;
        end;

  if dest = nil then
    exit;

  // change angle
  exact := R_PointToAngle2(actor.x, actor.y, dest.x, dest.y);

  if actor.state.params.Count >= 2 then
    maxturn := actor.state.params.IntVal[1] * ANG1
  else
    maxturn := DEFTRACEANGLE;

  if exact <> actor.angle then
  begin
    if exact - actor.angle > ANG180 then
    begin
      actor.angle := actor.angle - maxturn;
      if exact - actor.angle < ANG180 then
        actor.angle := exact;
    end
    else
    begin
      actor.angle := actor.angle + maxturn;
      if exact - actor.angle > ANG180 then
        actor.angle := exact;
    end;
  end;

  {$IFDEF FPC}
  exact := _SHRW(actor.angle, ANGLETOFINESHIFT);
  {$ELSE}
  exact := actor.angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  actor.momx := FixedMul(actor.info.speed, finecosine[exact]);
  actor.momy := FixedMul(actor.info.speed, finesine[exact]);

  // change slope
  dist := P_AproxDistance(dest.x - actor.x, dest.y - actor.y);

  dist := dist div actor.info.speed;

  if dist < 1 then
    dist := 1;
  slope := (dest.z + 40 * FRACUNIT - actor.z) div dist;

  if slope < actor.momz then
    actor.momz := actor.momz - FRACUNIT div 8
  else
    actor.momz := actor.momz + FRACUNIT div 8;
end;

procedure A_ChangeFlag(actor: Pmobj_t);
var
  sflag: string;
  change: boolean;
  flg: LongWord;
  idx: integer;
begin
  if not P_CheckStateParams(actor, 2, CSP_AT_LEAST) then
    exit;

  sflag := strupper(actor.state.params.StrVal[0]);
  change := actor.state.params.BoolVal[1];

  idx := mobj_flags.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags.IndexOf('MF_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags := actor.flags or flg
    else
      actor.flags := actor.flags and not flg;
    exit;
  end;

  {$IFDEF HERETIC_OR_HEXEN}
  idx := mobj_flags2.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags2.IndexOf('MF2_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags2 := actor.flags2 or flg
    else
      actor.flags2 := actor.flags2 and not flg;
    exit;
  end;
  {$ENDIF}

  idx := mobj_flags_ex.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags_ex.IndexOf('MF_EX_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags_ex := actor.flags_ex or flg
    else
      actor.flags_ex := actor.flags_ex and not flg;
    exit;
  end;

  idx := mobj_flags2_ex.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags2_ex.IndexOf('MF2_EX_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags2_ex := actor.flags2_ex or flg
    else
      actor.flags2_ex := actor.flags2_ex and not flg;
    exit;
  end;

  idx := mobj_flags3_ex.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags3_ex.IndexOf('MF3_EX_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags3_ex := actor.flags3_ex or flg
    else
      actor.flags3_ex := actor.flags3_ex and not flg;
    exit;
  end;

  idx := mobj_flags4_ex.IndexOf(sflag);
  if idx < 0 then
    idx := mobj_flags4_ex.IndexOf('MF4_EX_' + sflag);
  if idx >= 0 then
  begin
    flg := 1 shl idx;
    if change then
      actor.flags4_ex := actor.flags4_ex or flg
    else
      actor.flags4_ex := actor.flags4_ex and not flg;
    exit;
  end;

end;

end.

