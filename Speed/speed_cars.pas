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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit speed_cars;

interface

uses
  doomdef,
  p_mobj_h,
  m_fixed,
  tables;

const
  KMH_TO_FIXED = 4370; // Speed in fixed point arithmetic

const
  MAX_RPM = 13000;
  RPM_FADE = 370; // ~1 sec to drop from 13000 rpm to zero

const
  MAX_RACE_CARS = 20;

type
  cartype_t = (ct_formula, ct_stock, ct_any);

  carinfo_t = record
    tex1old, tex1: string[64]; // Replacement textures
    tex2old, tex2: string[64]; // Replacement textures
    number: integer;  // Number (as seen in texture replacements)
    maxspeed: fixed_t;  // in Doom units (fixed_t)
    maxreversespeed: fixed_t; // Reverse speed (negative) in Doom units (fixed_t)
    baseaccel: fixed_t; // Acceleration speed (Doom units per TIC)
    basedeccel: fixed_t;  // Brake speed (Doom units per TIC)
    turnspeed: angle_t; // angle to turn per TIC
    model3d: string[64];
    cartype: cartype_t;
    maxdrift: integer;
    name: string[14];
  end;
  Pcarinfo_t = ^carinfo_t;
  carinfo_tArray = array[0..$FF] of carinfo_t;
  Pcarinfo_tArray = ^carinfo_tArray;

  drivingcmd_t = record
    turn: fixed_t;
    accelerate: fixed_t;
    deccelerate: fixed_t;
    brake: fixed_t;
  end;
  Pdrivingcmd_t = ^drivingcmd_t;

const
  NUMCARINFO_FORMULA = 20;
  NUMCARINFO_STOCK = 20;
  NUMCARINFO = NUMCARINFO_FORMULA + NUMCARINFO_STOCK;

  carinfo: array[0..NUMCARINFO - 1] of carinfo_t = (
    (
      tex1old: 'f_1_4';
      tex1: '';
      tex2old: 'f_1_5';
      tex2: '';
      number: 27;
      maxspeed: 305 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'PHOENIX ENGINE';
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_01_03.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 3;
      maxspeed: 310 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'SPEED-X';
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_02_56.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 56;
      maxspeed: 315 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'BAM BAM';
    ),
    (
      tex1old: 'f_1_4';
      tex1: 'f_1_4_03_30.png';
      tex2old: 'f_1_5';
      tex2: '';
      number: 30;
      maxspeed: 320 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N0A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'SNAP';
    ),

    (
      tex1old: 'f_2_4';
      tex1: '';
      tex2old: 'f_2_5';
      tex2: '';
      number: 1;
      maxspeed: 325 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'BLUE STEEL';
    ),
    (
      tex1old: 'f_2_4';
      tex1: 'f_2_4_01_33.png';
      tex2old: 'f_2_5';
      tex2: '';
      number: 33;
      maxspeed: 330 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'SONIC';
    ),
    (
      tex1old: 'f_2_4';
      tex1: 'f_2_4_02_12.png';
      tex2old: 'f_2_5';
      tex2: '';
      number: 12;
      maxspeed: 305 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N1A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'DORY';
    ),

    (
      tex1old: 'f_3_4';
      tex1: '';
      tex2old: 'f_3_5';
      tex2: '';
      number: 4;
      maxspeed: 310 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'DREAM MAKER';
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_01_09.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 9;
      maxspeed: 315 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'DARK KNIGHT';
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_02_22.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 22;
      maxspeed: 320 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'PANTHER';
    ),
    (
      tex1old: 'f_3_4';
      tex1: 'f_3_4_03_62.png';
      tex2old: 'f_3_5';
      tex2: '';
      number: 62;
      maxspeed: 325 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N2A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'ZORRO';
    ),

    (
      tex1old: 'f_4_4';
      tex1: '';
      tex2old: 'f_4_5';
      tex2: '';
      number: 7;
      maxspeed: 330 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'FROZEN SKY';
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_01_18.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 18;
      maxspeed: 305 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'DIABLO';
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_02_54.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 54;
      maxspeed: 310 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'HERCULES';
    ),
    (
      tex1old: 'f_4_4';
      tex1: 'f_4_4_03_88.png';
      tex2old: 'f_4_5';
      tex2: '';
      number: 88;
      maxspeed: 315 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N3A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'VAPOR';
    ),
    (
      tex1old: 'f_5_4';
      tex1: '';
      tex2old: 'f_5_5';
      tex2: '';
      number: 6;
      maxspeed: 320 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'SPEED DEMON';
    ),
    (
      tex1old: 'f_5_4';
      tex1: 'f_5_4_01_23.png';
      tex2old: 'f_5_5';
      tex2: '';
      number: 23;
      maxspeed: 325 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'BIG MAN';
    ),
    (
      tex1old: 'f_5_4';
      tex1: 'f_5_4_02_45.png';
      tex2old: 'f_5_5';
      tex2: '';
      number: 45;
      maxspeed: 330 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N4A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'GREAT ZEUS';
    ),

    (
      tex1old: 'f_6_4';
      tex1: '';
      tex2old: 'f_6_5';
      tex2: '';
      number: 73;
      maxspeed: 305 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N5A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'BLACK BULLET';
    ),
    (
      tex1old: 'f_6_4';
      tex1: 'f_6_4_01_99.png';
      tex2old: 'f_6_5';
      tex2: '';
      number: 99;
      maxspeed: 310 * KMH_TO_FIXED;
      maxreversespeed: -50 * KMH_TO_FIXED;
      baseaccel: 8 * 1024;
      basedeccel: 64 * 1024;
      turnspeed: 448 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR0N5A.I3D';
      cartype: ct_formula;
      maxdrift: 20;
      name: 'ICE CUBE';
    ),


    (
      tex1old: 'd_1_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 15;
      maxspeed: 245 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N0A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'ROAD STAR';
    ),
    (
      tex1old: 'd_1_5';
      tex1: 'd_1_5_01_17.png';
      tex2old: '';
      tex2: '';
      number: 17;
      maxspeed: 250 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N0A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'LEMON STAR';
    ),
    (
      tex1old: 'd_1_5';
      tex1: 'd_1_5_02_19.png';
      tex2old: '';
      tex2: '';
      number: 19;
      maxspeed: 255 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N0A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BUMBLE BEE';
    ),
    (
      tex1old: 'd_1_5';
      tex1: 'd_1_5_03_04.png';
      tex2old: '';
      tex2: '';
      number: 4;
      maxspeed: 260 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N0A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'SUNSHINE';
    ),
    (
      tex1old: 'd_2_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 77;
      maxspeed: 245 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N1A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'THE FLAME';
    ),
    (
      tex1old: 'd_2_5';
      tex1: 'd_2_5_01_94.png';
      tex2old: '';
      tex2: '';
      number: 94;
      maxspeed: 250 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N1A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'ROAD FROG';
    ),
    (
      tex1old: 'd_2_5';
      tex1: 'd_2_5_02_87.png';
      tex2old: '';
      tex2: '';
      number: 87;
      maxspeed: 255 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N1A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'THE HULK';
    ),
    (
      tex1old: 'd_3_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 6;
      maxspeed: 260 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N2A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'SKEIN';
    ),
    (
      tex1old: 'd_3_5';
      tex1: 'd_3_5_01_83.png';
      tex2old: '';
      tex2: '';
      number: 83;
      maxspeed: 245 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N2A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'ROAD FAME';
    ),
    (
      tex1old: 'd_3_5';
      tex1: 'd_3_5_02_07.png';
      tex2old: '';
      tex2: '';
      number: 7;
      maxspeed: 250 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N2A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BIG BIRD';
    ),
    (
      tex1old: 'd_3_5';
      tex1: 'd_3_5_03_32.png';
      tex2old: '';
      tex2: '';
      number: 32;
      maxspeed: 255 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N2A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'TORCH';
    ),
    (
      tex1old: 'd_4_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 43;
      maxspeed: 260 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N3A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BLACK FURY';
    ),
    (
      tex1old: 'd_4_5';
      tex1: 'd_4_5_01_48.png';
      tex2old: '';
      tex2: '';
      number: 48;
      maxspeed: 245 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N3A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BURNER';
    ),
    (
      tex1old: 'd_4_5';
      tex1: 'd_4_5_02_78.png';
      tex2old: '';
      tex2: '';
      number: 78;
      maxspeed: 250 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N3A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'SHADOW';
    ),
    (
      tex1old: 'd_5_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 18;
      maxspeed: 255 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N4A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'LUCKY HORSE';
    ),
    (
      tex1old: 'd_5_5';
      tex1: 'd_5_5_01_09.png';
      tex2old: '';
      tex2: '';
      number: 9;
      maxspeed: 260 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N4A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'DIAMOND';
    ),
    (
      tex1old: 'd_5_5';
      tex1: 'd_5_5_02_11.png';
      tex2old: '';
      tex2: '';
      number: 11;
      maxspeed: 245 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N4A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'POLAR BEAR';
    ),
    (
      tex1old: 'd_6_5';
      tex1: '';
      tex2old: '';
      tex2: '';
      number: 23;
      maxspeed: 250 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N5A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'THE MIRACLE';
    ),
    (
      tex1old: 'd_6_5';
      tex1: 'd_6_5_01_54.png';
      tex2old: '';
      tex2: '';
      number: 54;
      maxspeed: 255 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N5A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BLUEBERRY';
    ),
    (
      tex1old: 'd_6_5';
      tex1: 'd_6_5_02_92.png';
      tex2old: '';
      tex2: '';
      number: 92;
      maxspeed: 260 * KMH_TO_FIXED;
      maxreversespeed: -45 * KMH_TO_FIXED;
      baseaccel: 6 * 1024;
      basedeccel: 48 * 1024;
      turnspeed: 424 * FRACUNIT; // ~2.5 * ANG1
      model3d: 'CAR1N5A.I3D';
      cartype: ct_stock;
      maxdrift: 45;
      name: 'BOOM BOOM';
    )
  );

procedure SH_InitLevelCars;

procedure SH_MoveCarPlayer(const mo: Pmobj_t);

procedure SH_MoveCarAI(const mo: Pmobj_t);

procedure SH_EngineSound(const caller: Pmobj_t; const soundtarg: Pmobj_t);

procedure SH_BrakeSound(const caller: Pmobj_t);

procedure SH_InitCars;

var
  def_f1car: integer = 0;
  def_ncar: integer = 20;
  def_anycar: integer = 0;

const
  NUM_CAR_GEARS = 6;
  NUM_GEAR_ACCEL_FACTORS = 16;

const
  GEAR_ACCEL_FACTORS_MUL = 1024;
  GEAR_ACCEL_FACTORS: array[-1..NUM_CAR_GEARS] of array[0..NUM_GEAR_ACCEL_FACTORS - 1] of fixed_t = (
    ( 64, 56, 32,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0),
    (  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0),
    ( 64, 64, 64, 32, 16,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0),
    ( 32, 48, 64, 64, 64, 32, 16,  1,  0,  0,  0,  0,  0,  0,  0,  0),
    ( 16, 24, 32, 48, 64, 64, 64, 48, 32, 16,  2,  0,  0,  0,  0,  0),
    ( 12, 16, 24, 32, 48, 64, 64, 64, 64, 48, 32, 16,  4,  0,  0,  0),
    (  8, 12, 16, 24, 32, 40, 48, 54, 64, 64, 64, 48, 32, 16,  8,  0),
    (  4,  6,  8, 12, 16, 24, 32, 40, 48, 56, 64, 64, 64, 48, 32, 16)
  );

const
  AUTO_GEAR_CHANGE_TICS = TICRATE div 8;
  AUTO_NEXT_GEAR_CHANGE_TICS = TICRATE div 8;
  MANUAL_GEAR_CHANGE_TICS = TICRATE div 16;
  MANUAL_NEXT_GEAR_CHANGE_TICS = TICRATE div 16;

implementation

uses
  d_delphi,
  c_cmds,
  d_event,
  d_think,
  d_player,
  i_system,
  info_h,
  info,
  info_common,
  g_game,
  p_tick,
  p_maputl,
  p_mobj,
  m_rnd,
  r_main,
  speed_things,
  speed_race,
  speed_path,
  speed_particles,
  speed_sounds,
  s_sound,
  z_zone;

procedure SH_InitLevelCars;
var
  mo: Pmobj_t;
  think: Pthinker_t;
  lst: TDPointerList;
  carids: TDNumberList;
  i, id, idx: integer;
begin
  lst := TDPointerList.Create;
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 <> @P_MobjThinker then
    begin
      think := think.next;
      continue;
    end;

    mo := Pmobj_t(think);

    if mo.info.doomednum = _SHTH_STARPOSITION then
      lst.Add(mo);
    think := think.next;
  end;

  if lst.Count >= MAX_RACE_CARS then  // Keep 1 for player
    I_Error('SH_InitLevelCars(): Too many cars (%d)', [lst.Count]);

  carids := TDNumberList.Create;
  for i := 0 to NUMCARINFO - 1 do
    if (race.cartype = carinfo[i].cartype) or (race.cartype = ct_any) or (carinfo[i].cartype = ct_any) then
      carids.Add(i);

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      idx := carids.IndexOf(players[i].mo.carinfo);
      if idx >= 0 then
        carids.Delete(idx);
    end;

  for i := 0 to lst.Count - 1 do
  begin
    mo := lst.Pointers[i];
    mo.currPath := SH_GetNextPath(mo).id;
    mo.prevPath := rtlpaths[mo.currPath].prev;
    mo.destAngle := rtlpaths[mo.currPath].mo.angle;
    mo.destSpeed := rtlpaths[mo.currPath].speed;
    if carids.Count > 0 then
    begin
      idx := Sys_Random mod carids.Count;
      id := carids.Numbers[idx];
      carids.Delete(idx);
    end
    else
      id := i mod NUMCARINFO;

    mo.carinfo := id;
    mo.carid := i;
    P_SetMobjState(mo, statenum_t(mo.info.spawnstate + id));
  end;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      players[i].mo.currPath := SH_GetNextPath(players[i].mo).id;
      players[i].mo.prevPath := rtlpaths[players[i].mo.currPath].prev;
    end;

  carids.Free;
  lst.Free;
end;

procedure SH_SetGear(const mo: Pmobj_t; const g: integer);
begin
  if g <> mo.gear then
    if mo.nextgeartics = 0 then
    begin
      mo.destgear := g;
      mo.geartics := AUTO_GEAR_CHANGE_TICS;
      mo.nextgeartics := AUTO_NEXT_GEAR_CHANGE_TICS;
    end;
end;

procedure SH_ShiftGearUp(const mo: Pmobj_t; const gtics, nextgtics: integer);
begin
  mo.destgear := mo.gear + 1;
  mo.geartics := gtics;
  mo.nextgeartics := nextgtics;
end;

procedure SH_ShiftGearDown(const mo: Pmobj_t; const gtics, nextgtics: integer);
begin
  mo.destgear := mo.gear - 1;
  mo.geartics := gtics;
  mo.nextgeartics := nextgtics;
end;

procedure SH_AutoGearBox(const mo: Pmobj_t);
var
  cinfo: Pcarinfo_t;
  f: integer;

  function _gear_better_up: boolean;
  begin
    Result := False;
    if mo.gear < NUM_CAR_GEARS then
      Result := GEAR_ACCEL_FACTORS[mo.gear, f] < GEAR_ACCEL_FACTORS[mo.gear + 1, f];
  end;

  function _gear_better_down: boolean;
  begin
    Result := False;
    if mo.gear > 0 then
      Result := GEAR_ACCEL_FACTORS[mo.gear, f] < GEAR_ACCEL_FACTORS[mo.gear - 1, f];
  end;

begin
  if mo.enginespeed >= 0 then
    if mo.nextgeartics = 0 then
    begin
      cinfo := @CARINFO[mo.carinfo];
      f := mo.enginespeed div (cinfo.maxspeed div NUM_GEAR_ACCEL_FACTORS);
      if _gear_better_up then
        SH_ShiftGearUp(mo, AUTO_GEAR_CHANGE_TICS, AUTO_NEXT_GEAR_CHANGE_TICS)
      else if _gear_better_down then
        SH_ShiftGearDown(mo, AUTO_GEAR_CHANGE_TICS, AUTO_NEXT_GEAR_CHANGE_TICS)
    end;
end;

procedure SH_ManualGearBox(const p: Pplayer_t);
var
  f: integer;
begin
  if p.cmd.buttons2 and BT2_GEARUP <> 0 then
  begin
    if p.mo.gear < NUM_CAR_GEARS then
      SH_ShiftGearUp(p.mo, MANUAL_GEAR_CHANGE_TICS, MANUAL_NEXT_GEAR_CHANGE_TICS);
  end
  else if p.cmd.buttons2 and BT2_GEARDOWN <> 0 then
  begin
    if p.mo.gear > 1 then
    begin
      f := GetIntegerInRange(p.mo.enginespeed div (CARINFO[p.mo.carinfo].maxspeed div NUM_GEAR_ACCEL_FACTORS), 0, NUM_GEAR_ACCEL_FACTORS - 1);
      if GEAR_ACCEL_FACTORS[p.mo.gear - 1, f] > 0 then
        SH_ShiftGearDown(p.mo, MANUAL_GEAR_CHANGE_TICS, MANUAL_NEXT_GEAR_CHANGE_TICS);
    end;
  end;
end;

procedure SH_CalcRPM(const mo: Pmobj_t);
var
  f: integer;
  i: integer;
  maxgearspeed: integer;
  newrpm: integer;
begin
  if (mo.gear = 0) or (mo.geartics > 0) then
  begin
    if mo.rpm > RPM_FADE then
      mo.rpm := mo.rpm - RPM_FADE
    else
      mo.rpm := 0;
    Exit;
  end;

  f := 0;

  for i := 0 to NUM_GEAR_ACCEL_FACTORS - 1 do
    if GEAR_ACCEL_FACTORS[mo.gear, i] <> 0 then
      f := i
    else
      Break;

  maxgearspeed := ((1 + f) * CARINFO[mo.carinfo].maxspeed) div NUM_GEAR_ACCEL_FACTORS;
  if maxgearspeed = 0 then
  begin
    if mo.rpm > RPM_FADE then
      mo.rpm := mo.rpm - RPM_FADE
    else
      mo.rpm := 0;
    Exit;
  end;

  newrpm := (abs(mo.enginespeed) div KMH_TO_FIXED) * MAX_RPM div (maxgearspeed div KMH_TO_FIXED);
  if newrpm > MAX_RPM then
    newrpm := MAX_RPM;

  if mo.rpm > newrpm then
  begin
    mo.rpm := mo.rpm - RPM_FADE;
    if mo.rpm < newrpm then
      mo.rpm := newrpm;
  end
  else if mo.rpm < newrpm then
  begin
    mo.rpm := mo.rpm + RPM_FADE;
    if mo.rpm > newrpm then
      mo.rpm := newrpm;
  end
end;

function SH_GearAccelerationFactor(const mo: Pmobj_t): fixed_t;
var
  cinfo: Pcarinfo_t;
  f: integer;
begin
  if mo.geartics > 0 then
    Result := 0
  else if mo.gear < 0 then
    Result := FRACUNIT
  else
  begin
    cinfo := @CARINFO[mo.carinfo];
    f := mo.enginespeed div (cinfo.maxspeed div NUM_GEAR_ACCEL_FACTORS);
    Result := GEAR_ACCEL_FACTORS[mo.gear, f] * GEAR_ACCEL_FACTORS_MUL;
  end;
end;

procedure SH_BuildDrivingCmdAI(const mo: Pmobj_t; const cmd: Pdrivingcmd_t);
// JVAL: 20210318 - Accelerator & turn factor depending on skill
const
  ACCELERATOR_FACTOR: array[skill_t] of fixed_t = (57344, 59392, 61440, 63488, 65536);
  TURN_FACTOR: array[skill_t] of fixed_t = (63488, 64512, 65536, 66560, 67584);
var
  actualspeed: fixed_t;
  curx, cury, destx, desty: integer;
  dx, dy: fixed_t;
  destan: angle_t;
  destspeed: fixed_t;
  diff: fixed_t;
  maxaccel: fixed_t;
  maxturn: angle_t;
  decelstep: fixed_t;
  pth: integer;
begin
  if race.racestatus = rs_waiting then
    Exit;

  // Gear select
  SH_AutoGearBox(mo);

  // Retrieve current speed
  dx := mo.x - mo.oldx;
  dy := mo.y - mo.oldy;
  actualspeed := P_Distance(dx, dy);

  // Find next target (path)
  pth := SH_GetNextPath(mo).id;
  if pth <> mo.currPath then
  begin
    mo.prevPath := mo.currPath;
    mo.currPath := pth;
  end;

  curx := mo.x;
  cury := mo.y;
  destx := rtlpaths[mo.currPath].mo.x;
  desty := rtlpaths[mo.currPath].mo.y;
  destspeed := rtlpaths[mo.currPath].speed * KMH_TO_FIXED;
  // If target is reached then select the next target in line
  if (destx = curx) and (desty = cury) then
  begin
    destx := rtlpaths[rtlpaths[mo.currPath].next].mo.x;
    desty := rtlpaths[rtlpaths[mo.currPath].next].mo.y;
  end;

  // Destination angle
  destan := R_PointToAngle2(destx, desty, curx, cury) - mo.angle;
  // Turn car to reach destination angle
  maxturn := (carinfo[mo.carinfo].turnspeed div TURN_FACTOR[gameskill]) * FRACUNIT;
  if destan < ANG180 - maxturn then
    cmd.turn := -maxturn
  else if destan > ANG180 + maxturn then
    cmd.turn := maxturn
  else
    cmd.turn := 0;

  // Adjust speed
  cmd.accelerate := 0;
  cmd.deccelerate := 0;
  cmd.brake := 0;
  if actualspeed > destspeed then  // Breaking
  begin
    diff := actualspeed - destspeed;
    decelstep := diff div (TICRATE div 2);
    if decelstep < carinfo[mo.carinfo].basedeccel then
      cmd.brake := decelstep
    else if diff > carinfo[mo.carinfo].basedeccel then
      cmd.brake := carinfo[mo.carinfo].basedeccel
    else
      cmd.brake := diff;
  end
  else if actualspeed < destspeed then // Accelerating
  begin
    diff := destspeed - actualspeed;
    // JVAL: 20210318 - Accelerator factor depending on skill
    maxaccel := FixedMul(carinfo[mo.carinfo].baseaccel, ACCELERATOR_FACTOR[gameskill]);
    if diff > maxaccel then
      cmd.accelerate := maxaccel
    else
      cmd.accelerate := diff;
  end;
end;

const
  MAX_SPEED_TURN_DECREASE = 40;

procedure SH_StorePlayerLapTimes(const p: Pplayer_t);
var
  score: Pplayerscore_t;
  i: integer;
  tl: timelaps_t;
begin
  score := @p.currentscore;
  ZeroMemory(score, SizeOf(playerscore_t));

  score.episode := gameepisode;
  score.map := gamemap;
  score.carinfo := p.mo.carinfo;
  score.raceposition := p.mo.raceposition;
  score.numlaps := race.numlaps;
  SH_GetTimeLaps(p.mo, @tl);
  score.totaltime := 0;
  for i := 0 to score.numlaps - 1 do
  begin
    score.laptimes[i] := tl[i];
    score.totaltime := score.totaltime + tl[i];
  end;
end;

var
  MT_CHECKLAPRECORD: integer = -1;

procedure SH_BuildDrivingCmdPlayer(const mo: Pmobj_t; const cmd: Pdrivingcmd_t);
var
  p: Pplayer_t;
  t: integer;
  speedturndecrease: fixed_t;
  pth: integer;
  lcheck: Pmobj_t;
begin
  if race.racestatus = rs_waiting then
    Exit;

  p := mo.player;
  if IsIntegerInRange(mo.lapscompleted, 1, race.numlaps) then
    if not p.laprecordchecked[mo.lapscompleted - 1] then
    begin
      p.laprecordchecked[mo.lapscompleted - 1] := True;
      if MT_CHECKLAPRECORD < 0 then
        MT_CHECKLAPRECORD := Info_GetMobjNumForName('MT_CHECKLAPRECORD');
      if MT_CHECKLAPRECORD >= 0 then
      begin
        SH_StorePlayerLapTimes(mo.player);
        lcheck := P_SpawnMobj(0, 0, 0, MT_CHECKLAPRECORD);
        lcheck.target := mo;
      end;
    end;

  // If race completed use AI driving
  if mo.lapscompleted >= race.numlaps then
  begin
    SH_StorePlayerLapTimes(mo.player);
    SH_BuildDrivingCmdAI(mo, cmd);
    Exit;
  end;

  p := mo.player;

  pth := SH_GetNextPath(mo).id;
  if pth <> mo.currPath then
  begin
    mo.prevPath := mo.currPath;
    mo.currPath := pth;
  end;

  speedturndecrease := MinI(((mo.enginespeed div KMH_TO_FIXED) div 8) * FRACUNIT, MAX_SPEED_TURN_DECREASE * FRACUNIT);

  cmd.turn := p.cmd.angleturn * FRACUNIT;
  t := carinfo[mo.carinfo].turnspeed - 150 * FRACUNIT - speedturndecrease;
  if t < 128 * FRACUNIT then
    t := 128 * FRACUNIT;
  if cmd.turn < -t then
    cmd.turn := -t
  else if cmd.turn > t then
    cmd.turn := t;

  if p.cmd.forwardmove > 0 then
  begin
    // Gear select
    if mo.gear = -1 then
      SH_SetGear(mo, 1)
    else
    begin
      if race.transmissiontype = TT_AUTOMATIC then
        SH_AutoGearBox(mo)
      else
        SH_ManualGearBox(p);
    end;

    cmd.brake := 0;
    cmd.deccelerate := 0;
    cmd.accelerate := carinfo[mo.carinfo].baseaccel;
  end
  else if p.cmd.forwardmove < 0 then
  begin
    if mo.enginespeed <= 0 then
    begin
      // Reverse gear
      SH_SetGear(mo, -1);

      cmd.brake := 0;
      cmd.deccelerate := 0;
      cmd.accelerate := -carinfo[mo.carinfo].baseaccel div 6;
    end
    else
    begin
      // Gear select
      if race.transmissiontype = TT_AUTOMATIC then
        SH_AutoGearBox(mo)
      else
        SH_ManualGearBox(p);

      cmd.brake := carinfo[mo.carinfo].basedeccel div 4;
      cmd.deccelerate := 0;
      cmd.accelerate := 0;
    end;
  end
  else
  begin
    if mo.enginespeed > 0 then
    begin
      cmd.deccelerate := carinfo[mo.carinfo].basedeccel div 32;
      cmd.brake := 0;
      cmd.accelerate := 0;
    end
    else
    begin
      cmd.deccelerate := 0;
      cmd.brake := 0;
      cmd.accelerate := 0;
    end;
    if mo.enginespeed = 0 then
      SH_SetGear(mo, 0);
  end
end;

const
  TIRE_ANGLE_MAX = 20;

const
  MAX_SOUND_DISTANCE = 192 * FRACUNIT;

procedure SH_ExecuteDrivingCmd(const mo: Pmobj_t; const cmd: Pdrivingcmd_t);
var
  enginespeed: fixed_t;
  actualspeed: fixed_t;
  dx, dy: fixed_t;
  an: angle_t;
  turn64: int64;
  slipf: integer;
  dan: fixed_t;
  force: fixed_t;
  dangle: int64;
begin
  if race.racestatus = rs_waiting then
    Exit;

  if mo.geartics > 0 then
  begin
    dec(mo.geartics);
    if mo.geartics = 0 then
      mo.gear := mo.destgear;
//    mo.enginespeed := mo.enginespeed * 15 div 16;
  end
  else if mo.nextgeartics > 0 then
    dec(mo.nextgeartics);

  // Calculate actual speed
  dx := mo.x - mo.oldx;
  dy := mo.y - mo.oldy;
  actualspeed := FixedSqrt(FixedMul(dx, dx) + FixedMul(dy, dy));

  // Retrieve current speed
  enginespeed := mo.enginespeed;

  if cmd.accelerate = 0 then
    if enginespeed > actualspeed then
      enginespeed := actualspeed;

  SH_SpawnParticleCheck(mo, actualspeed, enginespeed);

  slipf := SH_SlipperFactorAtXY(mo.x, mo.y);

  force := FixedMul(cmd.accelerate, SH_GearAccelerationFactor(mo)) - cmd.brake - cmd.deccelerate;
  if cmd.accelerate < 0 then
    enginespeed := GetIntegerInRange(enginespeed + SH_SlipCalculation(force, slipf), carinfo[mo.carinfo].maxreversespeed, carinfo[mo.carinfo].maxspeed)
  else
    enginespeed := GetIntegerInRange(enginespeed + SH_SlipCalculation(force, slipf), 0, carinfo[mo.carinfo].maxspeed);
  if slipf < slipperinessinfo[gt_asphalt].smin then
    enginespeed := (7 * enginespeed + enginespeed * slipf div 255) div 8;

  if abs(enginespeed) > 0 then
  begin
    if actualspeed < abs(enginespeed) then
    begin
      turn64 := cmd.turn;
      turn64 := turn64 * actualspeed;
      turn64 := turn64 div abs(enginespeed);
      mo.angle := mo.angle + iSign(enginespeed) * (turn64 + cmd.turn) div 2;
    end
    else
      mo.angle := mo.angle + iSign(enginespeed) * cmd.turn;
  end;

  if cmd.turn <> 0 then
    mo.tireangle := mo.tireangle + cmd.turn div 2
  else if actualspeed > 0 then
  begin
    if actualspeed > carinfo[mo.carinfo].maxspeed div 2 then
      dan := 2 * ANG1
    else
      dan := ANG1;
    if mo.tireangle < 0 then
      mo.tireangle := GetIntegerInRange(mo.tireangle + dan, -ANG1 * TIRE_ANGLE_MAX, 0)
    else if mo.tireangle > 0 then
      mo.tireangle := GetIntegerInRange(mo.tireangle - dan, 0, ANG1 * TIRE_ANGLE_MAX);
  end;
  mo.tireangle := GetIntegerInRange(mo.tireangle, -ANG1 * TIRE_ANGLE_MAX, ANG1 * TIRE_ANGLE_MAX);

  // Adjust drift
  if mo.driftangle <> 0 then
  begin
    dangle := mo.driftangle;
    dangle := dangle * 15 div 16;
    mo.driftangle := dangle;
  end;

  if mo.tireangle <> 0 then
    if actualspeed > 10 * KMH_TO_FIXED then
    begin
      dangle := mo.tireangle;
      dangle := dangle * (actualspeed div KMH_TO_FIXED) div (carinfo[mo.carinfo].maxspeed div KMH_TO_FIXED);
      mo.driftangle := mo.driftangle + dangle div 16;
      if mo.driftangle > ANG1 * (carinfo[mo.carinfo].maxdrift * actualspeed div carinfo[mo.carinfo].maxspeed) then
        mo.driftangle := ANG1 * (carinfo[mo.carinfo].maxdrift * actualspeed div carinfo[mo.carinfo].maxspeed)
      else if mo.driftangle < -ANG1 * (carinfo[mo.carinfo].maxdrift * actualspeed div carinfo[mo.carinfo].maxspeed) then
        mo.driftangle := -ANG1 * (carinfo[mo.carinfo].maxdrift * actualspeed div carinfo[mo.carinfo].maxspeed)
    end;

  // Adjust momentum
  an := mo.angle shr ANGLETOFINESHIFT;
  if actualspeed < enginespeed then
  begin
    mo.momx := dx div 2 + FixedMul(enginespeed, finecosine[an]) div 2;
    mo.momy := dy div 2 + FixedMul(enginespeed, finesine[an]) div 2;
  end
  else
  begin
    mo.momx := FixedMul(enginespeed, finecosine[an]);
    mo.momy := FixedMul(enginespeed, finesine[an]);
  end;

  mo.enginespeed := enginespeed;

  if carinfo[mo.carinfo].cartype = ct_formula then  // 2WD
  begin
    mo.tiredistance[0] := mo.tiredistance[0] + iSign(enginespeed) * actualspeed / FRACUNIT;
    mo.tiredistance[1] := mo.tiredistance[1] + iSign(enginespeed) * actualspeed / FRACUNIT;
  end
  else // 4WD
  begin
    mo.tiredistance[0] := mo.tiredistance[0] + enginespeed / FRACUNIT;
    mo.tiredistance[1] := mo.tiredistance[1] + enginespeed / FRACUNIT;
  end;
  mo.tiredistance[2] := mo.tiredistance[2] + enginespeed / FRACUNIT;
  mo.tiredistance[3] := mo.tiredistance[3] + enginespeed / FRACUNIT;

  mo.carturn := cmd.turn;
  mo.caraccelerate := cmd.accelerate;
  mo.cardeccelerate := cmd.deccelerate;
  mo.carbrake := cmd.brake;

  SH_CalcRPM(mo);

  if P_AproxDistance(viewx - mo.x, viewy - mo.y) < MAX_SOUND_DISTANCE then
  begin
    if mo.player = nil then
      SH_EngineSound(mo, mo);
    SH_BrakeSound(mo);
  end;

  SH_NotifyPath(mo);
end;

procedure SH_MoveCarAI(const mo: Pmobj_t);
var
  cmd: drivingcmd_t;
begin
  SH_BuildDrivingCmdAI(mo, @cmd);
  SH_ExecuteDrivingCmd(mo, @cmd);
end;

var
  print_player_path: boolean = false;

const
  PRINT_PLAYER_PATH_TICS = 10;

procedure SH_MoveCarPlayer(const mo: Pmobj_t);
var
  cmd: drivingcmd_t;
begin
  SH_BuildDrivingCmdPlayer(mo, @cmd);
  SH_ExecuteDrivingCmd(mo, @cmd);

  if print_player_path then
    if racetime mod PRINT_PLAYER_PATH_TICS = 0 then
      printf('%d %d %d %d'#13#10, [mo.x div FRACUNIT, mo.y div FRACUNIT, mo.angle div ANG1, mo.enginespeed div KMH_TO_FIXED]);
end;

procedure SH_EngineSound(const caller: Pmobj_t; const soundtarg: Pmobj_t);
var
  frac: integer;
  sndid: integer;
  cinfo: Pcarinfo_t;
  speed: fixed_t;
begin
  if soundtarg.soundcountdown <= 0 then
  begin
    cinfo := @carinfo[caller.carinfo];
    speed := caller.enginespeed;
    if caller.caraccelerate <> 0 then
      frac := GetIntegerInRange(caller.rpm * 10 div MAX_RPM, 0, 9)
//      frac := GetIntegerInRange(speed * 10 div cinfo.maxspeed, 0, 9)
    else
      frac := 0;
    if cinfo.cartype = ct_formula then
      sndid := Ord(sfx_speedhaste_MOTOR0_0)
    else
      sndid := Ord(sfx_speedhaste_MOTOR1_0);
    sndid := sndid + frac;

    S_StartSound(soundtarg, speedsounds[sndid].name);
    soundtarg.soundcountdown := S_SpeedSoundDuration(sndid);
  end;

  dec(soundtarg.soundcountdown);
end;

procedure SH_BrakeSound(const caller: Pmobj_t);
var
  sndid: integer;
begin
  caller.brakesoundorg.x := caller.x;
  caller.brakesoundorg.y := caller.y;
  caller.brakesoundorg.z := caller.z;

  if caller.brakesoundcountdown <= 0 then
  begin
    if caller.carbrake > 0 then
    begin
      sndid := Ord(sfx_speedhaste_DERRAPE);
      S_StartSound(@caller.brakesoundorg, speedsounds[sndid].name);
      caller.brakesoundcountdown := S_SpeedSoundDuration(sndid);
    end;
  end
  else
    dec(caller.brakesoundcountdown);
end;

procedure CmdPrintPlayerPath(const parm: string);
begin
  if parm = '' then
  begin
    printf('print_player_path=' + decide(print_player_path, 'TRUE', 'FALSE') + #13#10);
    Exit;
  end;

  print_player_path := C_BoolEval(parm, print_player_path);
  CmdPrintPlayerPath('');
end;

procedure SH_InitCars;
begin
  C_AddCmd('print_player_path', @CmdprintPlayerPath);
end;

end.
