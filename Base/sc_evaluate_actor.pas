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

unit sc_evaluate_actor;

interface

uses
  p_mobj_h;

//==============================================================================
//
// SC_InitActorEvaluator
//
//==============================================================================
procedure SC_InitActorEvaluator;

//==============================================================================
//
// SC_ShutDownActorEvaluator
//
//==============================================================================
procedure SC_ShutDownActorEvaluator;

//==============================================================================
//
// SC_EvaluateActorExpression
//
//==============================================================================
function SC_EvaluateActorExpression(const actor: Pmobj_t; const aexpr: string): string;

//==============================================================================
//
// SC_DeclareActorEvaluatorSingleToken
//
//==============================================================================
procedure SC_DeclareActorEvaluatorSingleToken(const token: string);

//==============================================================================
//
// SC_IsActorEvaluatorSingleToken
//
//==============================================================================
function SC_IsActorEvaluatorSingleToken(const token: string): boolean;

implementation

uses
  d_delphi,
  m_fixed,
  {$IFDEF HERETIC}
  r_defs,
  {$ENDIF}
  p_common,
  p_params,
  psi_globals,
  sc_evaluate,
  m_rnd;

type
  TActorEvaluator = class(TEvaluator)
  private
    factor: Pmobj_t;
    // Random functions
    function PF_rand(p: TDStrings): string;
    function PF_sysrand(p: TDStrings): string;
    function PF_random(p: TDStrings): string;
    function PF_random2(p: TDStrings): string;
    function PF_frandom(p: TDStrings): string;
    function PF_randompick(p: TDStrings): string;
    // Actor position and movement
    function PF_X(p: TDStrings): string;
    function PF_Y(p: TDStrings): string;
    function PF_Z(p: TDStrings): string;
    function PF_MOMX(p: TDStrings): string;
    function PF_MOMY(p: TDStrings): string;
    function PF_MOMZ(p: TDStrings): string;
    function PF_FLOORZ(p: TDStrings): string;
    function PF_CEILINGZ(p: TDStrings): string;
    function PF_ANGLE(p: TDStrings): string;
    // Actor properties
    function PF_flag(p: TDStrings): string;
    function PF_radius(p: TDStrings): string;
    function PF_height(p: TDStrings): string;
    function PF_alpha(p: TDStrings): string;
    function PF_health(p: TDStrings): string;
    function PF_reactiontime(p: TDStrings): string;
    function PF_threshold(p: TDStrings): string;
    function PF_fastchasetics(p: TDStrings): string;
    function PF_key(p: TDStrings): string;
    function PF_floorclip(p: TDStrings): string;
    function PF_gravity(p: TDStrings): string;
    function PF_pushfactor(p: TDStrings): string;
    function PF_scale(p: TDStrings): string;
    // Pascalscript map & world variables
    function PF_MAPSTR(p: TDStrings): string;
    function PF_WORLDSTR(p: TDStrings): string;
    function PF_MAPINT(p: TDStrings): string;
    function PF_WORLDINT(p: TDStrings): string;
    function PF_MAPFLOAT(p: TDStrings): string;
    function PF_WORLDFLOAT(p: TDStrings): string;
    // Custom params
    function PF_CUSTOMPARAM(p: TDStrings): string;
    function PF_TARGETCUSTOMPARAM(p: TDStrings): string;
    // States
    function PF_SPAWN(p: TDStrings): string;
    function PF_SEE(p: TDStrings): string;
    function PF_MELEE(p: TDStrings): string;
    function PF_MISSILE(p: TDStrings): string;
    function PF_PAIN(p: TDStrings): string;
    function PF_DEATH(p: TDStrings): string;
    function PF_XDEATH(p: TDStrings): string;
    function PF_HEAL(p: TDStrings): string;
    function PF_CRASH(p: TDStrings): string;
    function PF_INTERACT(p: TDStrings): string;
    function PF_RAISE(p: TDStrings): string;
  public
    constructor Create; override;
    function EvaluateActor(const actor: pmobj_t; const aexpr: string): string;
    procedure AddFunc(aname: string; afunc: TObjFunc; anump: integer); overload; override;
    procedure AddFunc(aname: string; afunc: TExtFunc; anump: integer); overload; override;
  end;

//==============================================================================
// TActorEvaluator.Create
//
////////////////////////////////////////////////////////////////////////////////
// TActorEvaluator
//
//==============================================================================
constructor TActorEvaluator.Create;
begin
  Inherited Create;
  // Ramdom functions
  AddFunc('RAND', PF_rand, 0);
  AddFunc('SYSRAND', PF_sysrand, -1);
  AddFunc('RANDOM', PF_random, -1);
  AddFunc('RANDOM2', PF_random2, -1);
  AddFunc('FLOATRANDOM', PF_frandom, -1);
  AddFunc('FRANDOM', PF_frandom, -1);
  AddFunc('RANDOMPICK', PF_randompick, -1);
  AddFunc('FRANDOMPICK', PF_randompick, -1);
  // Actor position and movement
  AddFunc('X', PF_X, 0);
  AddFunc('Y', PF_Y, 0);
  AddFunc('Z', PF_Z, 0);
  AddFunc('MOMX', PF_MOMX, 0);
  AddFunc('VELX', PF_MOMX, 0);
  AddFunc('MOMY', PF_MOMY, 0);
  AddFunc('VELY', PF_MOMY, 0);
  AddFunc('MOMZ', PF_MOMZ, 0);
  AddFunc('VELZ', PF_MOMZ, 0);
  AddFunc('FLOORZ', PF_FLOORZ, 0);
  AddFunc('CEILINGZ', PF_CEILINGZ, 0);
  AddFunc('ANGLE', PF_ANGLE, 0);
  // Actor properties
  AddFunc('FLAG', PF_flag, 1);
  AddFunc('RADIUS', PF_radius, 0);
  AddFunc('HEIGHT', PF_height, 0);
  AddFunc('ALPHA', PF_alpha, 0);
  AddFunc('HEALTH', PF_health, 0);
  AddFunc('REACTIONTIME', PF_reactiontime, 0);
  AddFunc('THRESHOLD', PF_threshold, 0);
  AddFunc('FASTCHASETICS', PF_fastchasetics, 0);
  AddFunc('KEY', PF_key, 0);
  AddFunc('FLOORCLIP', PF_floorclip, 0);
  AddFunc('GRAVITY', PF_gravity, 0);
  AddFunc('PUSHFACTOR', PF_pushfactor, 0);
  AddFunc('SCALE', PF_scale, 0);
  // Pascalscript map & world variables
  AddFunc('MAPSTR', PF_MAPSTR, 1);
  AddFunc('WORLDSTR', PF_WORLDSTR, 1);
  AddFunc('MAPINT', PF_MAPINT, 1);
  AddFunc('WORLDINT', PF_WORLDINT, 1);
  AddFunc('MAPFLOAT', PF_MAPFLOAT, 1);
  AddFunc('WORLDFLOAT', PF_WORLDFLOAT, 1);
  // Custom params
  AddFunc('CUSTOMPARAM', PF_CUSTOMPARAM, 1);
  AddFunc('PARAM', PF_CUSTOMPARAM, 1);
  AddFunc('TARGETCUSTOMPARAM', PF_TARGETCUSTOMPARAM, 1);
  AddFunc('TARGETPARAM', PF_TARGETCUSTOMPARAM, 1);
  // States
  AddFunc('SPAWN', PF_SPAWN, 0);
  AddFunc('SEE', PF_SEE, 0);
  AddFunc('MELEE', PF_MELEE, 0);
  AddFunc('MISSILE', PF_MISSILE, 0);
  AddFunc('PAIN', PF_PAIN, 0);
  AddFunc('DEATH', PF_DEATH, 0);
  AddFunc('XDEATH', PF_XDEATH, 0);
  AddFunc('HEAL', PF_HEAL, 0);
  AddFunc('CRASH', PF_CRASH, 0);
  AddFunc('INTERACT', PF_INTERACT, 0);
  AddFunc('RAISE', PF_RAISE, 0);
end;

//==============================================================================
//
// TActorEvaluator.AddFunc
//
//==============================================================================
procedure TActorEvaluator.AddFunc(aname: string; afunc: TObjFunc; anump: integer);
begin
  if anump = 0 then
    SC_DeclareActorEvaluatorSingleToken(aname);
  Inherited;
end;

//==============================================================================
//
// TActorEvaluator.AddFunc
//
//==============================================================================
procedure TActorEvaluator.AddFunc(aname: string; afunc: TExtFunc; anump: integer);
begin
  if anump = 0 then
    SC_DeclareActorEvaluatorSingleToken(aname);
  Inherited;
end;

//==============================================================================
// TActorEvaluator.PF_rand
//
// Ramdom functions
//
//==============================================================================
function TActorEvaluator.PF_rand(p: TDStrings): string;
begin
  result := ftoa(P_Random / 255);
end;

//==============================================================================
//
// TActorEvaluator.PF_sysrand
//
//==============================================================================
function TActorEvaluator.PF_sysrand(p: TDStrings): string;
var
  f1, f2: float;
begin
  if p.Count = 0 then
    result := itoa(Sys_Random)
  else if p.Count = 1 then
  begin
    f1 := atof(p[0]);
    result := itoa(Sys_Random * round(f1) div 256)
  end
  else
  begin
    f1 := atof(p[0]);
    f2 := atof(p[1]);
    result := itoa(round(f1) + Sys_Random * (round(f2) - round(f1) + 1) div 256);
  end;
end;

//==============================================================================
//
// TActorEvaluator.PF_random
//
//==============================================================================
function TActorEvaluator.PF_random(p: TDStrings): string;
var
  f1, f2: float;
begin
  if p.Count = 0 then
    result := itoa(N_Random)
  else if p.Count = 1 then
  begin
    f1 := atof(p[0]);
    result := itoa(N_Random * round(f1) div 256)
  end
  else
  begin
    f1 := atof(p[0]);
    f2 := atof(p[1]);
    result := itoa(round(f1) + N_Random * (round(f2) - round(f1) + 1) div 256);
  end;
end;

//==============================================================================
//
// TActorEvaluator.PF_random2
//
//==============================================================================
function TActorEvaluator.PF_random2(p: TDStrings): string;
var
  mask: integer;
begin
  if p.Count > 0 then
    mask := round(atof(p[0]))
  else
    mask := 255;
  result := itoa((N_Random and mask) - (N_Random and mask));
end;

//==============================================================================
//
// TActorEvaluator.PF_frandom
//
//==============================================================================
function TActorEvaluator.PF_frandom(p: TDStrings): string;
var
  f1, f2: float;
begin
  if p.Count = 0 then
    result := ftoa(N_Random)
  else if p.Count = 1 then
  begin
    f1 := atof(p[0]);
    result := ftoa(N_Random / 255 * f1)
  end
  else
  begin
    f1 := atof(p[0]);
    f2 := atof(p[1]);
    result := ftoa(f1 + N_Random / 255 * (f2 - f1 + 1));
  end;
end;

//==============================================================================
//
// TActorEvaluator.PF_randompick
//
//==============================================================================
function TActorEvaluator.PF_randompick(p: TDStrings): string;
begin
  if p.Count = 0 then
  begin
    result := '';
    exit;
  end;
  result := p[N_Random mod p.count];
end;

//==============================================================================
// TActorEvaluator.PF_X
//
// Actor position and movement
//
//==============================================================================
function TActorEvaluator.PF_X(p: TDStrings): string;
begin
  result := ftoa(factor.x / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_Y
//
//==============================================================================
function TActorEvaluator.PF_Y(p: TDStrings): string;
begin
  result := ftoa(factor.y / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_Z
//
//==============================================================================
function TActorEvaluator.PF_Z(p: TDStrings): string;
begin
  result := ftoa(factor.z / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_MOMX
//
//==============================================================================
function TActorEvaluator.PF_MOMX(p: TDStrings): string;
begin
  result := ftoa(factor.momx / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_MOMY
//
//==============================================================================
function TActorEvaluator.PF_MOMY(p: TDStrings): string;
begin
  result := ftoa(factor.momy / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_MOMZ
//
//==============================================================================
function TActorEvaluator.PF_MOMZ(p: TDStrings): string;
begin
  result := ftoa(factor.momz / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_FLOORZ
//
//==============================================================================
function TActorEvaluator.PF_FLOORZ(p: TDStrings): string;
begin
  result := ftoa(factor.floorz / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_CEILINGZ
//
//==============================================================================
function TActorEvaluator.PF_CEILINGZ(p: TDStrings): string;
begin
  result := ftoa(factor.ceilingz / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_ANGLE
//
//==============================================================================
function TActorEvaluator.PF_ANGLE(p: TDStrings): string;
begin
  result := ftoa(factor.angle / $FFFFFFFF * 360);
end;

//==============================================================================
// TActorEvaluator.PF_flag
//
// Actor properties
//
//==============================================================================
function TActorEvaluator.PF_flag(p: TDStrings): string;
begin
  if p.Count = 0 then
  begin
    result := 'FALSE';
    exit;
  end;
  if P_CheckFlag(factor, p[0]) then
    result := 'TRUE'
  else
    result := 'FALSE';
end;

//==============================================================================
//
// TActorEvaluator.PF_radius
//
//==============================================================================
function TActorEvaluator.PF_radius(p: TDStrings): string;
begin
  result := ftoa(factor.radius / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_height
//
//==============================================================================
function TActorEvaluator.PF_height(p: TDStrings): string;
begin
  result := ftoa(factor.height / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_alpha
//
//==============================================================================
function TActorEvaluator.PF_alpha(p: TDStrings): string;
begin
  result := ftoa(factor.alpha / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_health
//
//==============================================================================
function TActorEvaluator.PF_health(p: TDStrings): string;
begin
  result := itoa(factor.health);
end;

//==============================================================================
//
// TActorEvaluator.PF_reactiontime
//
//==============================================================================
function TActorEvaluator.PF_reactiontime(p: TDStrings): string;
begin
  result := itoa(factor.reactiontime);
end;

//==============================================================================
//
// TActorEvaluator.PF_threshold
//
//==============================================================================
function TActorEvaluator.PF_threshold(p: TDStrings): string;
begin
  result := itoa(factor.threshold);
end;

//==============================================================================
//
// TActorEvaluator.PF_fastchasetics
//
//==============================================================================
function TActorEvaluator.PF_fastchasetics(p: TDStrings): string;
begin
  result := itoa(factor.fastchasetics);
end;

//==============================================================================
//
// TActorEvaluator.PF_key
//
//==============================================================================
function TActorEvaluator.PF_key(p: TDStrings): string;
begin
  result := itoa(factor.key);
end;

//==============================================================================
//
// TActorEvaluator.PF_floorclip
//
//==============================================================================
function TActorEvaluator.PF_floorclip(p: TDStrings): string;
begin
{$IFDEF HERETIC}
  if (factor.flags2 and MF2_FEETARECLIPPED <> 0) and (factor.z <=
    Psubsector_t(factor.subsector).sector.floorheight) then
    result := '10.0'
  else
    result := '0.0';
{$ELSE}
  result := ftoa(factor.floorclip / FRACUNIT);
{$ENDIF}
end;

//==============================================================================
//
// TActorEvaluator.PF_gravity
//
//==============================================================================
function TActorEvaluator.PF_gravity(p: TDStrings): string;
begin
  result := ftoa(factor.gravity / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_pushfactor
//
//==============================================================================
function TActorEvaluator.PF_pushfactor(p: TDStrings): string;
begin
  result := ftoa(factor.pushfactor / FRACUNIT);
end;

//==============================================================================
//
// TActorEvaluator.PF_scale
//
//==============================================================================
function TActorEvaluator.PF_scale(p: TDStrings): string;
begin
  result := ftoa(factor.scale / FRACUNIT);
end;

//==============================================================================
// TActorEvaluator.PF_MAPSTR
//
// Pascalscript map & world variables
//
//==============================================================================
function TActorEvaluator.PF_MAPSTR(p: TDStrings): string;
begin
  result := PS_GetMapStr(p[0]);
end;

//==============================================================================
//
// TActorEvaluator.PF_WORLDSTR
//
//==============================================================================
function TActorEvaluator.PF_WORLDSTR(p: TDStrings): string;
begin
  result := PS_GetWorldStr(p[0]);
end;

//==============================================================================
//
// TActorEvaluator.PF_MAPINT
//
//==============================================================================
function TActorEvaluator.PF_MAPINT(p: TDStrings): string;
begin
  result := itoa(PS_GetMapInt(p[0]));
end;

//==============================================================================
//
// TActorEvaluator.PF_WORLDINT
//
//==============================================================================
function TActorEvaluator.PF_WORLDINT(p: TDStrings): string;
begin
  result := itoa(PS_GetWorldInt(p[0]));
end;

//==============================================================================
//
// TActorEvaluator.PF_MAPFLOAT
//
//==============================================================================
function TActorEvaluator.PF_MAPFLOAT(p: TDStrings): string;
begin
  result := ftoa(PS_GetMapFloat(p[0]));
end;

//==============================================================================
//
// TActorEvaluator.PF_WORLDFLOAT
//
//==============================================================================
function TActorEvaluator.PF_WORLDFLOAT(p: TDStrings): string;
begin
  result := ftoa(PS_GetWorldFloat(p[0]));
end;

//==============================================================================
// TActorEvaluator.PF_CUSTOMPARAM
//
// Custom params
//
//==============================================================================
function TActorEvaluator.PF_CUSTOMPARAM(p: TDStrings): string;
var
  parm: Pmobjcustomparam_t;
begin
  parm := P_GetMobjCustomParam(factor, p[0]);
  if parm <> nil then
    result := itoa(parm.value)
  else
    result := '0';
end;

//==============================================================================
//
// TActorEvaluator.PF_TARGETCUSTOMPARAM
//
//==============================================================================
function TActorEvaluator.PF_TARGETCUSTOMPARAM(p: TDStrings): string;
var
  parm: Pmobjcustomparam_t;
begin
  if factor.target <> nil then
  begin
    parm := P_GetMobjCustomParam(factor.target, p[0]);
    if parm <> nil then
    begin
      result := itoa(parm.value);
      exit;
    end;
  end;
  result := '0';
end;

//==============================================================================
// TActorEvaluator.PF_SPAWN
//
// States
//
//==============================================================================
function TActorEvaluator.PF_SPAWN(p: TDStrings): string;
begin
  result := itoa(factor.info.spawnstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_SEE
//
//==============================================================================
function TActorEvaluator.PF_SEE(p: TDStrings): string;
begin
  result := itoa(factor.info.seestate);
end;

//==============================================================================
//
// TActorEvaluator.PF_MELEE
//
//==============================================================================
function TActorEvaluator.PF_MELEE(p: TDStrings): string;
begin
  result := itoa(factor.info.meleestate);
end;

//==============================================================================
//
// TActorEvaluator.PF_MISSILE
//
//==============================================================================
function TActorEvaluator.PF_MISSILE(p: TDStrings): string;
begin
  result := itoa(factor.info.missilestate);
end;

//==============================================================================
//
// TActorEvaluator.PF_PAIN
//
//==============================================================================
function TActorEvaluator.PF_PAIN(p: TDStrings): string;
begin
  result := itoa(factor.info.painstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_DEATH
//
//==============================================================================
function TActorEvaluator.PF_DEATH(p: TDStrings): string;
begin
  result := itoa(factor.info.deathstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_XDEATH
//
//==============================================================================
function TActorEvaluator.PF_XDEATH(p: TDStrings): string;
begin
  result := itoa(factor.info.xdeathstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_HEAL
//
//==============================================================================
function TActorEvaluator.PF_HEAL(p: TDStrings): string;
begin
  result := itoa(factor.info.healstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_CRASH
//
//==============================================================================
function TActorEvaluator.PF_CRASH(p: TDStrings): string;
begin
  result := itoa(factor.info.crashstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_INTERACT
//
//==============================================================================
function TActorEvaluator.PF_INTERACT(p: TDStrings): string;
begin
  result := itoa(factor.info.interactstate);
end;

//==============================================================================
//
// TActorEvaluator.PF_RAISE
//
//==============================================================================
function TActorEvaluator.PF_RAISE(p: TDStrings): string;
begin
  result := itoa(factor.info.raisestate);
end;

//==============================================================================
//
// TActorEvaluator.EvaluateActor
//
//==============================================================================
function TActorEvaluator.EvaluateActor(const actor: pmobj_t; const aexpr: string): string;
begin
  factor := actor;
  Result := EvaluateExpression(aexpr);
end;

var
  actorevaluator: TActorEvaluator;
  actorevaluatorsingletokens: TDStringList;

//==============================================================================
//
// SC_InitActorEvaluator
//
//==============================================================================
procedure SC_InitActorEvaluator;
begin
  actorevaluatorsingletokens := TDStringList.Create;
  actorevaluator := TActorEvaluator.Create;
end;

//==============================================================================
//
// SC_ShutDownActorEvaluator
//
//==============================================================================
procedure SC_ShutDownActorEvaluator;
begin
  actorevaluator.Free;
  actorevaluatorsingletokens.Free;
end;

//==============================================================================
//
// SC_EvaluateActorExpression
//
//==============================================================================
function SC_EvaluateActorExpression(const actor: Pmobj_t; const aexpr: string): string;
begin
  try
    Result := actorevaluator.EvaluateActor(actor, aexpr);
  except
    result := aexpr;
  end;
end;

//==============================================================================
//
// SC_DeclareActorEvaluatorSingleToken
//
//==============================================================================
procedure SC_DeclareActorEvaluatorSingleToken(const token: string);
var
  check: string;
begin
  check := strupper(token);
  if actorevaluatorsingletokens.IndexOf(check) < 0 then
    actorevaluatorsingletokens.Add(check);
end;

//==============================================================================
//
// SC_IsActorEvaluatorSingleToken
//
//==============================================================================
function SC_IsActorEvaluatorSingleToken(const token: string): boolean;
var
  check: string;
begin
  check := strupper(token);
  result := actorevaluatorsingletokens.IndexOf(check) >= 0;
end;

end.
