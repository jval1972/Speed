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
//   Menu widget stuff, episode selection and such.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit m_menu;

interface

uses
  d_event;

//
// MENUS
//

{ Called by main loop, }
{ saves config file and calls I_Quit when user exits. }
{ Even when the menu is not displayed, }
{ this can resize the view and change game parameters. }
{ Does all the real work of the menu interaction. }

function M_Responder(ev: Pevent_t): boolean;

{ Called by main loop, }
{ only used for menu (skull cursor) animation. }
procedure M_Ticker;

{ Called by main loop, }
{ draws the menus directly into the screen buffer. }
procedure M_Drawer;

{ Called by D_DoomMain, }
{ loads the config file. }
procedure M_Init;

{ Called by intro code to force menu up upon a keypress, }
{ does nothing if menu is already up. }
procedure M_StartControlPanel;

var
//
// defaulted values
//
  mouseSensitivity: integer;  // has default
  mouseSensitivityX: integer;
  mouseSensitivityY: integer;

// Show messages has default, 0 = off, 1 = on
  showMessages: integer;

  shademenubackground: integer;

  keepsavegamename: boolean;

  menuactive: boolean;

  inhelpscreens: boolean;

procedure M_ShutDownMenus;

procedure M_InitMenus;

procedure M_SetKeyboardMode(const mode: integer);

implementation

uses
  d_delphi,
  doomstat,
  doomdef,
  am_map,
  c_cmds,
  dstrings,
  d_englsh,
  d_main,
  d_player,
  d_notifications,
  g_game,
  m_argv,
  m_misc,
  m_fixed,
  mn_textwrite,
  mn_drawmodel,
  mt_utils,
  i_system,
  i_threads,
  i_io,
  i_mp3,
  i_sound,
  i_displaymodes,
  gl_main,
  gl_defs,
  gl_models,
  gl_voxels,
  gl_lightmaps,
  gl_shadows,
  gl_tex,
  e_endoom,
  p_setup,
  p_mobj_h,
  p_terrain,
  p_enemy,
  p_user,
  p_adjust,
  r_aspect,
  r_data,
  r_main,
  r_hires,
  r_lights,
  r_intrpl,
  r_camera,
  r_draw,
  t_main,
  vx_voxelsprite,
  v_data,
  v_video,
  hu_stuff,
  s_sound,
  sounds,
  w_wad,
  z_zone;

var
// -1 = no quicksave slot picked!
  quickSaveSlot: integer;

 // 1 = message to be printed
  messageToPrint: integer;
// ...and here is the message string!
  messageString: string;

  messageLastMenuActive: boolean;

// timed message = no input from user
  messageNeedsInput: boolean;

type
  PmessageRoutine = function(i: integer): pointer;

var
  messageRoutine: PmessageRoutine;


const
  SAVESTRINGSIZE = 24;

var
  gammamsg: array[0..GAMMASIZE - 1] of string;

// we are going to be entering a savegame string
  saveStringEnter: integer = 0;
  saveSlot: integer;  // which slot to save in
  saveCharIndex: integer; // which char we're editing
// old save description before edit
  saveOldString: string;

const
  SKULLXOFF = -32;
  SKULLYOFF = -5;
  ARROWXOFF = -8;
  LINEHEIGHT = 16;
  LINEHEIGHT2 = 8;


var
  savegamestrings: array[0..9] of string;
  endstring: string;

type
  menuitem_t = record
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    status: smallint;

    name: string;
    cmd: string;

    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    routine: PmessageRoutine;

    // Yes/No location
    pBoolVal: PBoolean;
    // hotkey in menu
    alphaKey: char;
  end;
  Pmenuitem_t = ^menuitem_t;
  menuitem_tArray = packed array[0..$FFFF] of menuitem_t;
  Pmenuitem_tArray = ^menuitem_tArray;

  Pmenu_t = ^menu_t;
  menu_t = record
    numitems: smallint;         // # of menu items
    prevMenu: Pmenu_t;          // previous menu
    leftMenu: Pmenu_t;          // left menu
    rightMenu: Pmenu_t;         // right menu
    menuitems: Pmenuitem_tArray;// menu items
    drawproc: PProcedure;       // draw routine
    x: smallint;
    y: smallint;                // x,y of menu
    lastOn: smallint;           // last item user was on in menu
    itemheight: integer;
    texturebk: boolean;
  end;

var
  itemOn: smallint;             // menu item skull is on

// current menudef
  currentMenu: Pmenu_t;

//
//      Menu Functions
//
procedure M_HorzLine(const x1, x2, y: integer; const color: byte);
var
  i: integer;
begin
  for i := y * 320 + x1 to y * 320 + x2 do
    screens[SCN_TMP][i] := color;
end;

procedure M_VertLine(const x, y1, y2: integer; const color: byte);
var
  i: integer;
begin
  for i := y1 to y2 do
    screens[SCN_TMP][i * 320 + x] := color;
end;

procedure M_Frame3d(const x1, y1, x2, y2: integer; const color1, color2, color3: byte);
var
  i: integer;
begin
  M_HorzLine(x1, x2, y1, color1);
  M_HorzLine(x1, x2, y2, color2);
  M_VertLine(x1, y1, y2, color2);
  M_VertLine(x2, y1, y2, color1);
  for i := y1 + 1 to y2 - 1 do
    M_HorzLine(x1 + 1, x2 - 1, i, color3);
end;

procedure M_DrawHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 121);
  M_HorzLine(0, 319, y + 15, 123);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, 118);

  M_WriteText(160, y + 3, str, ma_center, @big_fontR, @big_fontB);
end;

procedure M_DrawSubHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 121);
  M_HorzLine(0, 319, y + 15, 123);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, 118);

  M_WriteText(25, y + 3, str, ma_left, @big_fontW, @big_fontB);
end;

procedure M_DrawSmallLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 121);
  M_HorzLine(0, 319, y + 9, 123);
  for i := y + 1 to y + 8 do
    M_HorzLine(0, 319, i, 118);

  M_WriteText(160, y + 2, str, ma_center, @hu_fontW, @big_fontB);
end;

const
  DEF_MENU_ITEMS_START_X = 32;
  DEF_MENU_ITEMS_START_Y = 65;

procedure M_DrawThermo(x, y, thermWidth, thermDot: integer; numdots: integer = -1);
var
  i: integer;
  p: integer;
begin
  M_Frame3d(x, y, x + thermWidth * 8 + 2, y + 10, 121, 123, 118);

  if numdots <= 1 then
    numdots := thermWidth;
  if numdots < 2 then
    numdots := 2;
  p := Round(thermDot / (numdots - 1) * thermWidth * 8 + 1);
  for i := 2 to thermWidth * 8 do
  begin
    if i < p then
      M_VertLine(x + i, y + 2, y + 8, 53)
    else
      M_VertLine(x + i, y + 2, y + 8, 118);
  end;
end;

procedure M_StartMessage(const str: string; routine: PmessageRoutine; const input: boolean);
begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := str;
  if Assigned(routine) then
    @messageRoutine := @routine
  else
    messageRoutine := nil;
  messageNeedsInput := input;
  menuactive := true;
end;

procedure M_StopMessage;
begin
  menuactive := messageLastMenuActive;
  messageToPrint := 0;
end;

//
// M_ClearMenus
//
procedure M_ClearMenus;
begin
  menuactive := false;
end;

//
// M_SetupNextMenu
//
procedure M_SetupNextMenu(menudef: Pmenu_t);
begin
  currentMenu := menudef;
  itemOn := currentMenu.lastOn;
end;

//
// MENU DEFINITIONS
//
type
//
// DOOM MENU
//
  main_e = (
    mm_newgame,
    mm_options,
    mm_loadgame,
    mm_savegame,
    mm_readthis,
    mm_quitspeed,
    main_end
  );

var
  MainMenu: array[0..5] of menuitem_t;
  MainDef: menu_t;

type
//
// EPISODE SELECT
//
  episodes_e = (
    mn_ep1,
    mn_ep2,
    mn_ep3,
    mn_ep4,
    ep_end
  );

var
  EpisodeMenu: array[0..Ord(ep_end) - 1] of menuitem_t;
  EpiDef: menu_t;

type
//
// NEW GAME
//
  newgame_e = (
    newg_killthings,
    newg_toorough,
    newg_hurtme,
    newg_violence,
    newg_nightmare,
    newg_end
  );

var
  NewGameMenu: array[0..Ord(newg_end) - 1] of menuitem_t;
  NewDef: menu_t;

type
//
// OPTIONS MENU
//
  options_e = (
    opt_general,
    opt_display,
    opt_sound,
    opt_compatibility,
    opt_controls,
    opt_system,
    opt_end
  );

var
  OptionsMenu: array[0..Ord(opt_end) - 1] of menuitem_t;
  OptionsDef: menu_t;

// GENERAL MENU
type
  optionsgeneral_e = (
    mn_endgame,
    mn_messages,
    optgen_end
  );

var
  OptionsGeneralMenu: array[0..Ord(optgen_end) - 1] of menuitem_t;
  OptionsGeneralDef: menu_t;

// DISPLAY MENU
type
  optionsdisplay_e = (
    od_opengl,
    od_automap,
    od_appearance,
    od_advanced,
    od_32bitsetup,
    optdisp_end
  );

var
  OptionsDisplayMenu: array[0..Ord(optdisp_end) - 1] of menuitem_t;
  OptionsDisplayDef: menu_t;

// DISPLAY DETAIL MENU
type
  optionsdisplaydetail_e = (
    od_setvideomode,
    od_detaillevel,
    od_allowlowdetails,
    od_allowhidetails,
    optdispdetail_end
  );

var
  OptionsDisplayDetailMenu: array[0..Ord(optdispdetail_end) - 1] of menuitem_t;
  OptionsDisplayDetailDef: menu_t;

type
  optionsdisplayvideomode_e = (
    odm_fullscreen,
    odm_screensize,
    odm_filler1,
    odm_filler2,
    odm_setvideomode,
    optdispvideomode_end
  );

var
  OptionsDisplayVideoModeMenu: array[0..Ord(optdispvideomode_end) - 1] of menuitem_t;
  OptionsDisplayVideoModeDef: menu_t;

// DISPLAY APPEARANCE MENU
type
  optionsdisplayappearance_e = (
    od_drawfps,
    od_shademenubackground,
    od_displaydiskbusyicon,
    od_displayendscreen,
    od_showdemoplaybackprogress,
    optdispappearance_end
  );

var
  OptionsDisplayAppearanceMenu: array[0..Ord(optdispappearance_end) - 1] of menuitem_t;
  OptionsDisplayAppearanceDef: menu_t;

// DISPLAY AUTOMAP MENU
type
  optionsdisplayautomap_e = (
    od_allowautomapoverlay,
    od_allowautomaprotate,
    od_texturedautomap,
    od_automapgrid,
    optdispautomap_end
  );

var
  OptionsDisplayAutomapMenu: array[0..Ord(optdispautomap_end) - 1] of menuitem_t;
  OptionsDisplayAutomapDef: menu_t;

// DISPLAY ADVANCED MENU
type
  optionsdisplayadvanced_e = (
    od_aspect,
    od_camera,
    od_usetransparentsprites,
    od_interpolate,
    od_interpolateoncapped,
    od_fixstallhack,
    od_autoadjustmissingtextures,
    optdispadvanced_end
  );

var
  OptionsDisplayAdvancedMenu: array[0..Ord(optdispadvanced_end) - 1] of menuitem_t;
  OptionsDisplayAdvancedDef: menu_t;

// DISPLAY ASPECT RATIO MENU
type
  optionsdisplayaspectratio_e = (
    oda_widescreensupport,
    oda_excludewidescreenplayersprites,
    oda_forceaspectratio,
    oda_intermissionaspect,
    optdispaspect_end
  );

var
  OptionsDisplayAspectRatioMenu: array[0..Ord(optdispaspect_end) - 1] of menuitem_t;
  OptionsDisplayAspectRatioDef: menu_t;

//
// DISPLAY CAMERA MENU
type
  optionsdisplaycamera_e = (
    odc_zaxisshift,
    odc_chasecamera,
    odc_chasecameraxy,
    odc_filler3,
    odc_filler4,
    odc_chasecameraz,
    odc_filler5,
    odc_filler6,
    optdispcamera_end
  );

var
  OptionsDisplayCameraMenu: array[0..Ord(optdispcamera_end) - 1] of menuitem_t;
  OptionsDisplayCameraDef: menu_t;

// DISPLAY 32 BIT RENDERING MENU
type
  optionsdisplay32bit_e = (
    od_uselightboost,
    od_forcecolormaps,
    od_32bittexturepaletteeffects,
    od_use32bitfuzzeffect,
    od_useexternaltextures,
    od_preferetexturesnamesingamedirectory,
    od_flatfiltering,
    optdisp32bit_end
  );

var
  OptionsDisplay32bitMenu: array[0..Ord(optdisp32bit_end) - 1] of menuitem_t;
  OptionsDisplay32bitDef: menu_t;

// DISPLAY OPENGL RENDERING MENU
type
  optionsdisplayopengl_e = (
    od_glsetvideomode,
    od_glmodels,
    od_glvoxels,
    od_filter,
    od_usefog,
    {$IFDEF DEBUG}
    od_gl_drawsky,
    {$ENDIF}
    od_gl_stencilsky,
    od_gl_renderwireframe,
    od_gl_uselightmaps,
    od_gl_drawshadows,
    od_gl_add_all_lines,
    od_gl_useglnodesifavailable,
    od_gl_screensync,
    optdispopengl_end
  );

var
  OptionsDisplayOpenGLMenu: array[0..Ord(optdispopengl_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLDef: menu_t;

// OpenGL Models
type
  optionsopenglmodels_e = (
    od_glm_smoothmodelmovement,
    od_glm_precachemodeltextures,
    optglmodels_end
  );

var
  OptionsDisplayOpenGLModelsMenu: array[0..Ord(optglmodels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLModelsDef: menu_t;

// OpenGL Voxels
type
  optionsopenglvoxels_e = (
    od_glv_drawvoxels,
    od_glv_optimize,
    {$IFDEF DEBUG}
    od_glv_pritesfromvoxels,
    {$ENDIF}
    optglvoxels_end
  );

var
  OptionsDisplayOpenGLVoxelsMenu: array[0..Ord(optglvoxels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLVoxelsDef: menu_t;

// OpenGL Texture Filtering
type
  optionsopenglfilter_e = (
    od_glf_texture_filter,
    od_glf_texture_filter_anisotropic,
    od_glf_linear_hud,
    optglfilter_end
  );

var
  OptionsDisplayOpenGLFilterMenu: array[0..Ord(optglfilter_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLFilterDef: menu_t;

type
//
// Read This! MENU 1 & 2
//
  read_e = (
    rdthsempty1,
    read1_end
  );

var
  ReadMenu1: array[0..0] of menuitem_t;
  ReadDef1: menu_t;

type
  read_e2 = (
    rdthsempty2,
    read2_end
  );

var
  ReadMenu2: array[0..0] of menuitem_t;
  ReadDef2: menu_t;

//  https://www.doomworld.com/forum/topic/111465-boom-extended-help-screens-an-undocumented-feature/
// JVAL 20200122 - Extended help screens
var
  extrahelpscreens: TDNumberList;
  extrahelpscreens_idx: integer = -1;

type
  read_ext = (
    rdthsemptyext,
    readext_end
  );

var
  ReadMenuExt: array[0..0] of menuitem_t;
  ReadDefExt: menu_t;


type
//
// SOUND MENU
//
  sound_e = (
    snd_volume,
    snd_usemp3,
    snd_preferemp3namesingamedirectory,
    snd_usewav,
    snd_preferewavnamesingamedirectory,
    sound_end
  );

var
  SoundMenu: array[0..Ord(sound_end) - 1] of menuitem_t;
  SoundDef: menu_t;

type
//
// SOUND VOLUME MENU
//
  soundvol_e = (
    sfx_vol,
    sfx_empty1,
    sfx_empty1b,
    music_vol,
    sfx_empty2,
    sfx_empty2b,
    soundvol_end
  );

var
  SoundVolMenu: array[0..Ord(soundvol_end) - 1] of menuitem_t;
  SoundVolDef: menu_t;

type
//
// COMPATIBILITY MENU
//
  compatibility_e = (
    cmp_allowplayerjumps,
    cmp_allowplayerbreath,
    cmp_keepcheatsinplayerrebord,
    cmp_majorbossdeathendsdoom1level,
    cmp_spawnrandommonsters,
    cmp_allowterrainsplashes,
    cmp_continueafterplayerdeath,
    cmp_dogs,
    cmp_end
  );

var
  CompatibilityMenu: array[0..Ord(cmp_end) - 1] of menuitem_t;
  CompatibilityDef: menu_t;

type
//
// CONTROLS MENU
//
  controls_e = (
    ctrl_usemouse,
    ctrl_invertmouselook,
    ctrl_invertmouseturn,
    cttl_mousesensitivity,
    ctrl_usejoystic,
    ctrl_autorun,
    ctrl_keyboardmode,
    ctrl_keybindings,
    ctrl_end
  );

var
  ControlsMenu: array[0..Ord(ctrl_end) - 1] of menuitem_t;
  ControlsDef: menu_t;

type
//
// MOUSE SENSITIVITY MENU
//
  sensitivity_e = (
    sens_mousesensitivity,
    sens_empty1,
    sens_empty2,
    sens_mousesensitivityx,
    sens_empty3,
    sens_empty4,
    sens_mousesensitivityy,
    sens_empty5,
    sens_empty6,
    sens_end
  );

var
  SensitivityMenu: array[0..Ord(sens_end) - 1] of menuitem_t;
  SensitivityDef: menu_t;


type
//
// KEY BINDINGS MENU
//
  keybindings_e = (
    kb_up,
    kb_down,
    kb_left,
    kb_right,
    kb_strafeleft,
    kb_straferight,
    kb_jump,
    kb_fire,
    kb_use,
    kb_strafe,
    kb_speed,
    kb_lookup,
    kb_lookdown,
    kb_lookcenter,
    kb_lookleft,
    kb_lookright,
    kb_weapon0,
    kb_weapon1,
    kb_weapon2,
    kb_weapon3,
    kb_weapon4,
    kb_weapon5,
    kb_weapon6,
    kb_weapon7,
    kb_end
  );

var
  KeyBindingsMenu1: array[0..Ord(kb_weapon0) - 1] of menuitem_t;
  KeyBindingsDef1: menu_t;
  KeyBindingsMenu2: array[0..Ord(kb_end) - Ord(kb_weapon0) - 1] of menuitem_t;
  KeyBindingsDef2: menu_t;

type
  bindinginfo_t = record
    text: string[25];
    pkey: PInteger;
  end;

const
  KeyBindingsInfo: array [0..Ord(kb_end) - 1] of bindinginfo_t = (
    (text: 'Move forward'; pkey: @key_up),
    (text: 'Move backward'; pkey: @key_down),
    (text: 'Turn left'; pkey: @key_left),
    (text: 'Turn right'; pkey: @key_right),
    (text: 'Strafe left'; pkey: @key_strafeleft),
    (text: 'Strafe right'; pkey: @key_straferight),
    (text: 'Jump'; pkey: @key_jump),
    (text: 'Fire'; pkey: @key_fire),
    (text: 'Use'; pkey: @key_use),
    (text: 'Strafe'; pkey: @key_strafe),
    (text: 'Run'; pkey: @key_speed),
    (text: 'Look up'; pkey: @key_lookup),
    (text: 'Look down'; pkey: @key_lookdown),
    (text: 'Look center'; pkey: @key_lookcenter),
    (text: 'Look left'; pkey: @key_lookleft),
    (text: 'Look right'; pkey: @key_lookright),
    (text: 'Fists/Chainsaw'; pkey: @key_weapon0),
    (text: 'Pistol'; pkey: @key_weapon1),
    (text: 'Shotgun'; pkey: @key_weapon2),
    (text: 'Chaingun'; pkey: @key_weapon3),
    (text: 'Rocket launcher'; pkey: @key_weapon4),
    (text: 'Plasma gun'; pkey: @key_weapon5),
    (text: 'BFG 9000'; pkey: @key_weapon6),
    (text: 'Chainsaw'; pkey: @key_weapon7)
  );

var
  bindkeyEnter: boolean;
  bindkeySlot: integer;
  saveOldkey: integer;

function M_KeyToString(const k: integer): string;
begin
  if (k >= 33) and (k <= 126) then
  begin
    result := Chr(k);
    if result = '=' then
      result := '+'
    else if result = ',' then
      result := '<'
    else if result = '.' then
      result := '>';
    exit;
  end;

  case k of
    32: result := 'SPACE';
    KEY_RIGHTARROW: result := 'RIGHTARROW';
    KEY_LEFTARROW: result := 'LEFTARROW';
    KEY_UPARROW: result := 'UPARROW';
    KEY_DOWNARROW: result := 'DOWNARROW';
    KEY_ESCAPE: result := 'ESCAPE';
    KEY_ENTER: result := 'ENTER';
    KEY_TAB: result := 'TAB';
    KEY_F1: result := 'F1';
    KEY_F2: result := 'F2';
    KEY_F3: result := 'F3';
    KEY_F4: result := 'F4';
    KEY_F5: result := 'F5';
    KEY_F6: result := 'F6';
    KEY_F7: result := 'F7';
    KEY_F8: result := 'F8';
    KEY_F9: result := 'F9';
    KEY_F10: result := 'F10';
    KEY_F11: result := 'F11';
    KEY_F12: result := 'F12';
    KEY_PRNT: result := 'PRNT';
    KEY_CON: result := 'CON';
    KEY_BACKSPACE: result := 'BACKSPACE';
    KEY_PAUSE: result := 'PAUSE';
    KEY_EQUALS: result := 'EQUALS';
    KEY_MINUS: result := 'MINUS';
    KEY_RSHIFT: result := 'SHIFT';
    KEY_RCTRL: result := 'CTRL';
    KEY_RALT: result := 'ALT';
    KEY_PAGEDOWN: result := 'PAGEDOWN';
    KEY_PAGEUP: result := 'PAGEUP';
    KEY_INS: result := 'INS';
    KEY_HOME: result := 'HOME';
    KEY_END: result := 'END';
    KEY_DELETE: result := 'DELETE';
  else
    result := '';
  end;
end;

function M_SetKeyBinding(const slot: integer; key: integer): boolean;
var
  i: integer;
  oldk: integer;
begin
  if (slot < 0) or (slot >= Ord(kb_end)) then
  begin
    result := false;
    exit;
  end;

  if key = 16 then
    key := KEY_RSHIFT
  else if key = 17 then
    key := KEY_RCTRL
  else if key = 18 then
    key := KEY_RALT;

  result := key in [32..125,
    KEY_RIGHTARROW,
    KEY_LEFTARROW,
    KEY_UPARROW,
    KEY_DOWNARROW,
    KEY_BACKSPACE,
    KEY_RSHIFT,
    KEY_RCTRL,
    KEY_RALT,
    KEY_PAGEDOWN,
    KEY_PAGEUP,
    KEY_INS,
    KEY_HOME,
    KEY_END,
    KEY_DELETE
  ];

  if not result then
    exit;

  oldk := KeyBindingsInfo[slot].pkey^;
  for i := 0 to Ord(kb_end) - 1 do
    if i <> slot then
     if KeyBindingsInfo[i].pkey^ = key then
       KeyBindingsInfo[i].pkey^ := oldk;
  KeyBindingsInfo[slot].pkey^ := key;
end;

procedure M_DrawBindings(const m: menu_t; const start, stop: integer);
var
  i: integer;
  len: integer;
  s: string;
  drawkey: boolean;
begin
  M_DrawHeadLine(15, 'Controls');
  M_DrawSubHeadLine(40, 'Key Bindings');

  for i := 0 to stop - start - 1 do
  begin
    s := KeyBindingsInfo[start + i].text + ': ';
    len := M_StringWidth(s, @hu_fontY);
    M_WriteText(m.x, m.y + m.itemheight * i, s, ma_left, @hu_fontY, @hu_fontB);
    drawkey := true;
    if bindkeyEnter then
      if i = bindkeySlot - start then
        if (gametic div 18) mod 2 <> 0 then
          drawkey := false;
    if drawkey then
      M_WriteText(m.x + len, m.y + m.itemheight * i, M_KeyToString(KeyBindingsInfo[start + i].pkey^), ma_left, @hu_fontW, @hu_fontB);
  end;
end;

procedure M_DrawBindings1;
begin
  M_DrawBindings(KeyBindingsDef1, 0, Ord(kb_weapon0));
end;

procedure M_DrawBindings2;
begin
  KeyBindingsInfo[Ord(kb_weapon0)].text := 'Fists/Chainsaw';
  KeyBindingsInfo[Ord(kb_weapon1)].text := 'Pistol';
  KeyBindingsInfo[Ord(kb_weapon2)].text := 'Shotgun';
  KeyBindingsInfo[Ord(kb_weapon3)].text := 'Chaingun';
  KeyBindingsInfo[Ord(kb_weapon4)].text := 'Rocket launcher';
  KeyBindingsInfo[Ord(kb_weapon5)].text := 'Plasma gun';
  KeyBindingsInfo[Ord(kb_weapon6)].text := 'BFG 9000';
  KeyBindingsInfo[Ord(kb_weapon7)].text := 'Chainsaw';

  M_DrawBindings(KeyBindingsDef2, Ord(kb_weapon0), Ord(kb_end));
end;

//
// Select key binding
//
procedure M_KeyBindingSelect1(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := choice;

  saveOldkey := KeyBindingsInfo[choice].pkey^;
end;

procedure M_KeyBindingSelect2(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_weapon0) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_weapon0) + choice].pkey^;
end;

type
//
// SYSTEM  MENU
//
  system_e = (
    sys_safemode,
    sys_usemmx,
    sys_criticalcpupriority,
    sys_usemultithread,
    sys_screenshottype,
    sys_end
  );

var
  SystemMenu: array[0..Ord(sys_end) - 1] of menuitem_t;
  SystemDef: menu_t;

var
  LoadMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  LoadDef: menu_t;
  SaveMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  SaveDef: menu_t;

//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
procedure M_ReadSaveStrings;
var
  handle: file;
  i: integer;
  name: string;
begin
  for i := 0 to Ord(load_end) - 1 do
  begin
    sprintf(name, M_SaveFileName(SAVEGAMENAME) + '%d.dsg', [i]);

    if not fopen(handle, name, fOpenReadOnly) then
    begin
      savegamestrings[i] := '';
      LoadMenu[i].status := 0;
      continue;
    end;
    SetLength(savegamestrings[i], SAVESTRINGSIZE);
    BlockRead(handle, (@savegamestrings[i][1])^, SAVESTRINGSIZE);
    close(handle);
    LoadMenu[i].status := 1;
  end;
end;

//
// Draw border for the savegame description
//
procedure M_DrawSaveLoadBorder(x, y: integer);
begin
  M_Frame3d(x, y - 3, 320 - x, y + 11, 121, 123, 118);
end;

//
// M_LoadGame & Cie.
//
procedure M_DrawLoad;
var
  i: integer;
begin
  M_DrawHeadLine(15, 'Load Game');

  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(LoadDef.x, LoadDef.y + LoadDef.itemheight * i);
    M_WriteText(LoadDef.x + 4, LoadDef.y + LoadDef.itemheight * i, savegamestrings[i], ma_left, @hu_fontY, @hu_fontB);
    if i = itemOn then
      M_WriteText(LoadDef.x + ARROWXOFF, LoadDef.y + i * LoadDef.itemheight, '-', ma_left, @hu_fontW, @hu_fontB);
  end;
end;

//
// User wants to load this game
//
procedure M_LoadSelect(choice: integer);
var
  name: string;
begin
  sprintf(name, M_SaveFileName(SAVEGAMENAME) + '%d.dsg', [choice]);
  G_LoadGame(name);
  M_ClearMenus;
end;

//
// Selected from DOOM menu
//
procedure M_LoadGame(choice: integer);
begin
  if netgame then
  begin
    M_StartMessage(LOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_SetupNextMenu(@LoadDef);
  M_ReadSaveStrings;
end;

//
//  M_SaveGame & Cie.
//
procedure M_DrawSave;
var
  i: integer;
begin
  M_DrawHeadLine(15, 'Save Game');

  for i := 0 to Ord(load_end) - 1 do
  begin
    M_DrawSaveLoadBorder(SaveDef.x, SaveDef.y + SaveDef.itemheight * i);
    M_WriteText(SaveDef.x + 4, SaveDef.y + SaveDef.itemheight * i, savegamestrings[i], ma_left, @hu_fontY, @hu_fontB);
    if i = itemOn then
      M_WriteText(SaveDef.x + ARROWXOFF, SaveDef.y + i * SaveDef.itemheight, '-', ma_left, @hu_fontW, @hu_fontB);
  end;

  if saveStringEnter <> 0 then
  begin
    i := M_StringWidth(savegamestrings[saveSlot], @hu_fontY);
    if (gametic div 18) mod 2 = 0 then
      M_WriteText(SaveDef.x + i + 4, SaveDef.y + SaveDef.itemheight * saveSlot, '_', ma_left, @hu_fontY, @hu_fontB);
  end;
end;

//
// M_Responder calls this when user is finished
//
procedure M_DoSave(slot: integer);
begin
  G_SaveGame(slot, savegamestrings[slot]);
  M_ClearMenus;

  // PICK QUICKSAVE SLOT YET?
  if (quickSaveSlot = -2) then
    quickSaveSlot := slot;
end;

//
// User wants to save. Start string input for M_Responder
//
procedure M_SaveSelect(choice: integer);
var
  s: string;
  i: integer;
  c: char;
begin
  // we are going to be intercepting all chars
  saveStringEnter := 1;

  saveSlot := choice;
  saveOldString := savegamestrings[choice];
  // JVAL 21/4/2017
  if keepsavegamename then
  begin
    s := '';
    for i := 1 to Length(savegamestrings[choice]) do
    begin
      c := savegamestrings[choice][i];
      if c in [#0, #13, #10, ' '] then
        Break
      else
        s := s + c;
    end;
    savegamestrings[choice] := s;
  end
  else if savegamestrings[choice] <> '' then
    savegamestrings[choice] := '';
  saveCharIndex := Length(savegamestrings[choice]);
end;

//
// Selected from DOOM menu
//
procedure M_SaveGame(choice: integer);
begin
  if not usergame then
  begin
    M_StartMessage(SAVEDEAD + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  M_SetupNextMenu(@SaveDef);
  M_ReadSaveStrings;
end;

procedure M_MenuSound;
begin
  if gamestate = GS_ENDOOM then
    exit;
  S_StartSound(nil, 'DSMENU');
end;

//
//      M_QuickSave
//
procedure M_QuickSaveResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_DoSave(quickSaveSlot);
    M_MenuSound;
  end;
end;

procedure M_QuickSave;
var
  tempstring: string;
begin
  if not usergame then
  begin
    M_MenuSound;
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  if quickSaveSlot < 0 then
  begin
    M_StartControlPanel;
    M_ReadSaveStrings;
    M_SetupNextMenu(@SaveDef);
    quickSaveSlot := -2;  // means to pick a slot now
    exit;
  end;

  sprintf(tempstring, QSPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickSaveResponse, true);
end;

//
// M_QuickLoad
//
procedure M_QuickLoadResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_LoadSelect(quickSaveSlot);
    M_MenuSound;
  end;
end;

procedure M_QuickLoad;
var
  tempstring: string;
begin
  if netgame then
  begin
    M_StartMessage(QLOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if quickSaveSlot < 0 then
  begin
    M_StartMessage(QSAVESPOT + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  sprintf(tempstring, QLPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickLoadResponse, true);
end;

//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
procedure M_DrawReadThis1;
begin
  inhelpscreens := true;
  case gamemode of
    shareware,
    registered,
    retail:
      V_PageDrawer(pg_HELP1);
  end;
end;

//
// Read This Menus - optional second page.
//
procedure M_DrawReadThis2;
begin
  inhelpscreens := true;
  case gamemode of
    retail:
      // This hack keeps us from having to change menus.
      V_PageDrawer(pg_CREDIT);
    shareware,
    registered:
      V_PageDrawer(pg_HELP2);
  end;
end;

procedure M_DrawReadThisExt;
begin
  inhelpscreens := true;
  V_PageDrawer(char8tostring(W_GetNameForNum(extrahelpscreens.Numbers[extrahelpscreens_idx])));
end;

//
// Change Sfx & Music volumes
//
procedure M_DrawSoundVol;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Volume Control');

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(sfx_vol) + 1), 16, snd_SfxVolume);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(music_vol) + 1), 16, snd_MusicVolume);
end;

procedure M_ChangeDogs(choice: integer);
begin
  dogs := GetIntegerInRange(dogs, 0, MAXPLAYERS - 1);
  inc(dogs);
  if dogs >= MAXPLAYERS then
    dogs := 0;
end;

procedure M_DrawCompatibility;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Compatibility');

  dogs := GetIntegerInRange(dogs, 0, MAXPLAYERS - 1);
  ppos.x := CompatibilityDef.x;
  ppos.y := CompatibilityDef.y + CompatibilityDef.itemheight * Ord(cmp_dogs);
  ppos := M_WriteText(ppos.x, ppos.y, 'Dogs (Marine Best Friend): ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, itoa(dogs), ma_left, @hu_fontW, @hu_fontB);
end;

const
  mkeyboardmodes: array[0..3] of string = ('ARROWS', 'WASD', 'ESDF', 'CUSTOM');

procedure M_SetKeyboardMode(const mode: integer);
begin
  if mode = 0 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 173;
    key_down := 175;
    key_strafeleft := 44;
    key_straferight := 46;
    key_jump := 97;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
  end
  else if mode = 1 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 119;
    key_down := 115;
    key_strafeleft := 97;
    key_straferight := 100;
    key_jump := 101;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
  end
  else if mode = 2 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 101;
    key_down := 100;
    key_strafeleft := 115;
    key_straferight := 102;
    key_jump := 97;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
  end;
end;

function M_GetKeyboardMode: integer;
begin
  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 173) and
     (key_down = 175) and
     (key_strafeleft = 44) and
     (key_straferight = 46) and
     (key_jump = 97) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) then
  begin
    result := 0;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 119) and
     (key_down = 115) and
     (key_strafeleft = 97) and
     (key_straferight = 100) and
     (key_jump = 101) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) then
  begin
    result := 1;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 101) and
     (key_down = 100) and
     (key_strafeleft = 115) and
     (key_straferight = 102) and
     (key_jump = 97) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) then
  begin
    result := 2;
    exit;
  end;

  result := 3;
end;

procedure M_KeyboardModeArrows(choice: integer);
begin
  M_SetKeyboardMode(0);
end;

procedure M_KeyboardModeWASD(choice: integer);
begin
  M_SetKeyboardMode(1);
end;

procedure M_KeyboardModeESDF(choice: integer);
begin
  M_SetKeyboardMode(2);
end;

procedure M_SwitchKeyboardMode(choice: integer);
var
  old: integer;
begin
  old := M_GetKeyboardMode;
  case old of
    0: M_KeyboardModeWASD(choice);
    1: M_KeyboardModeESDF(choice);
  else
    M_KeyboardModeArrows(choice);
  end;
end;

procedure M_CmdKeyboardMode(const parm1, parm2: string);
var
  wrongparms: boolean;
  sparm1: string;
begin
  wrongparms := false;

  if (parm1 = '') or (parm2 <> '') then
    wrongparms := true;

  sparm1 := strupper(parm1);

  if (parm1 <> '0') and (parm1 <> '1') and (parm1 <> '2') and
     (sparm1 <> 'ARROWS') and (sparm1 <> 'WASD') and (sparm1 <> 'ESDF') then
    wrongparms := true;

  if wrongparms then
  begin
    printf('Specify the keyboard mode:'#13#10);
    printf('  0: Arrows'#13#10);
    printf('  1: WASD'#13#10);
    printf('  2: ESDF'#13#10);
    exit;
  end;

  if (parm1 = '0') or (sparm1 = 'ARROWS') then
    M_SetKeyboardMode(0)
  else if (parm1 = '1') or (sparm1 = 'WASD') then
    M_SetKeyboardMode(1)
  else
    M_SetKeyboardMode(2);
end;

procedure M_DrawControls;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Controls');

  ppos.x := ControlsDef.x;
  ppos.y := ControlsDef.y + ControlsDef.itemheight * Ord(ctrl_keyboardmode);
  ppos := M_WriteText(ppos.x, ppos.y, 'Keyboard preset: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, mkeyboardmodes[M_GetKeyboardMode], ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_DrawSound;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Sound');
end;

procedure M_DrawSystem;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'System');

  M_FixScreenshotFormat;
  ppos.x := SystemDef.x;
  ppos.y := SystemDef.y + SystemDef.itemheight * Ord(sys_screenshottype);
  ppos := M_WriteText(ppos.x, ppos.y, 'Screenshot format: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, screenshotformat, ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_OptionsSound(choice: integer);
begin
  M_SetupNextMenu(@SoundDef);
end;

procedure M_SoundVolume(choice: integer);
begin
  M_SetupNextMenu(@SoundVolDef);
end;

procedure M_OptionsConrols(choice: integer);
begin
  M_SetupNextMenu(@ControlsDef);
end;

procedure M_OptionsSensitivity(choice: integer);
begin
  M_SetupNextMenu(@SensitivityDef);
end;

procedure M_OptionsCompatibility(choice: integer);
begin
  M_SetupNextMenu(@CompatibilityDef);
end;

procedure M_OptionsSystem(choice: integer);
begin
  M_SetupNextMenu(@SystemDef);
end;

procedure M_OptionsGeneral(choice: integer);
begin
  M_SetupNextMenu(@OptionsGeneralDef);
end;

procedure M_OptionsDisplay(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDef);
end;

procedure M_OptionsDisplayDetail(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDetailDef);
end;

var
  mdisplaymode_idx: integer = 0;

procedure M_SetVideoMode(choice: integer);
var
  idx: integer;
begin
  idx := I_NearestDisplayModeIndex(SCREENWIDTH, SCREENHEIGHT);
  if idx >= 0 then
    mdisplaymode_idx := idx;
  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;
  M_SetupNextMenu(@OptionsDisplayVideoModeDef);
end;

procedure M_OptionsDisplayAutomap(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAutomapDef);
end;

procedure M_OptionsDisplayAppearance(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_OptionAspectRatio(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAspectRatioDef);
end;

procedure M_OptionCameraShift(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayCameraDef);
end;

procedure M_ChangeCameraXY(choice: integer);
begin
  case choice of
    0: chasecamera_viewxy := chasecamera_viewxy - 8;
    1: chasecamera_viewxy := chasecamera_viewxy + 8;
  end;
  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
end;

procedure M_ChangeCameraZ(choice: integer);
begin
  case choice of
    0: chasecamera_viewz := chasecamera_viewz - 4;
    1: chasecamera_viewz := chasecamera_viewz + 4;
  end;
  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
end;

const
  NUMSTRASPECTRATIOS = 5;
  straspectratios: array[0..NUMSTRASPECTRATIOS - 1] of string =
    ('AUTO', '4:3', '16:10', '16:9', '1.85:1');

var
  aspectratioidx: integer;

procedure M_SwitchForcedAspectRatio(choice: integer);
begin
  aspectratioidx := (aspectratioidx + 1) mod NUMSTRASPECTRATIOS;
  if aspectratioidx = 0 then
    forcedaspectstr := '0'
  else
  begin
    widescreensupport := true;
    forcedaspectstr := straspectratios[aspectratioidx];
  end;
  setsizeneeded := true;
end;

function _nearest_aspect_index: integer;
var
  asp: single;
  i: integer;
  diff, test, mx: single;
  ar, par: string;
begin
  result := 0;

  asp := R_ForcedAspect;
  if asp < 1.0 then
    exit;

  mx := 100000000.0;

  for i := 1 to NUMSTRASPECTRATIOS - 1 do
  begin
    splitstring(straspectratios[i], ar, par, [':', '/']);
    if par = '' then
      test := atof(ar)
    else
      test := atof(ar) / atof(par);
    diff := fabs(test - asp);
    if diff = 0 then
    begin
      result := i;
      exit;
    end;
    if diff < mx then
    begin
      result := i;
      mx := diff;
    end;
  end;
end;

procedure M_OptionsDisplayAdvanced(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_OptionsDisplay32bit(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplay32bitDef);
end;

procedure M_OptionsDisplayOpenGL(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLDef);
end;

procedure M_OptionsDisplayOpenGLModels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLModelsDef);
end;

procedure M_OptionsDisplayOpenGLVoxels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLVoxelsDef);
end;

procedure M_OptionsDisplayOpenGLFilter(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLFilterDef);
end;

procedure M_SfxVol(choice: integer);
begin
  case choice of
    0: if snd_SfxVolume <> 0 then dec(snd_SfxVolume);
    1: if snd_SfxVolume < 15 then inc(snd_SfxVolume);
  end;
  S_SetSfxVolume(snd_SfxVolume);
end;

procedure M_MusicVol(choice: integer);
begin
  case choice of
    0: if snd_MusicVolume <> 0 then dec(snd_MusicVolume);
    1: if snd_MusicVolume < 15 then inc(snd_MusicVolume);
  end;
  S_SetMusicVolume(snd_MusicVolume);
end;

//
// M_DrawMainMenu
//
procedure M_DrawMainMenu;
var
  i, y: integer;
begin
  V_DrawPatch(160, 40, SCN_TMP, 'DEMOLOGO', false);

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(mm_newgame) to Ord(mm_quitspeed) do
  begin
    if itemOn = i then
      M_WriteText(160, y, MainMenu[i].name, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, MainMenu[i].name, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

//
// M_NewGame
//
procedure M_DrawNewGame;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'New Game');
  M_DrawSubHeadLine(40, 'Select Skill Level');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(newg_killthings) to Ord(newg_nightmare) do
  begin
    if itemOn = i then
      M_WriteText(160, y, NewGameMenu[i].name, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, NewGameMenu[i].name, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_NewGame(choice: integer);
begin
  if netgame and not demoplayback then
  begin
    M_StartMessage(SNEWGAME + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_SetupNextMenu(@EpiDef);
end;

//
//      M_Episode
//
var
  epi: integer;

procedure M_DrawEpisode;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Select Course');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(mn_ep1) to Ord(ep_end) - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, EpisodeMenu[i].name, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, EpisodeMenu[i].name, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_VerifyNightmare(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  G_DeferedInitNew(sk_nightmare, epi + 1, 1); // JVAL nightmare become sk_nightmare
  M_ClearMenus;
end;

procedure M_ChooseSkill(choice: integer);
begin
  if choice = Ord(newg_nightmare) then
  begin
    M_StartMessage(SNIGHTMARE + #13#10 + PRESSYN, @M_VerifyNightmare, true);
    exit;
  end;

  G_DeferedInitNew(skill_t(choice), epi + 1, 1);
  M_ClearMenus;
end;

procedure M_Episode(choice: integer);
begin
  if (gamemode = shareware) and (choice <> 0) then
  begin
    M_StartMessage(SWSTRING + #13#10 + PRESSKEY, nil, false);
    M_SetupNextMenu(@ReadDef1);
    exit;
  end;

  // Yet another hack...
  if (gamemode = registered) and (choice > 2) then
  begin
    I_Warning('M_Episode(): 4th episode requires UltimateDOOM'#13#10);
    choice := 0;
  end;

  epi := choice;

  M_SetupNextMenu(@NewDef);
end;

//
// M_Options
//
procedure M_DrawOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := 0 to Ord(opt_end) - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, OptionsMenu[i].name, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, OptionsMenu[i].name, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_DrawGeneralOptions;
var
  i, y: integer;
  str: string;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'General');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(mn_endgame) to Ord(mn_messages) do
  begin
    str := OptionsGeneralMenu[i].name;
    if i = Ord(mn_messages) then
      if showMessages = 1 then
        str := str + ': ON'
      else
        str := str + ': OFF';
    if itemOn = i then
      M_WriteText(160, y, str, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, str, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

procedure M_DrawSensitivity;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Mouse Sensitivity');

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivity) + 1), 20, mouseSensitivity);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityx) + 1), 11, mouseSensitivityX);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityy) + 1), 11, mouseSensitivityY);
end;

procedure M_DrawDisplayOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Display Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := 0 to Ord(optdisp_end) - 1 do
  begin
    if itemOn = i then
      M_WriteText(160, y, OptionsDisplayMenu[i].name, ma_center, @big_fontY, @big_fontB)
    else
      M_WriteText(160, y, OptionsDisplayMenu[i].name, ma_center, @big_fontW, @big_fontB);
    y := y + 14;
  end;
end;

var
  colordepths: array[boolean] of string = ('8bit', '32bit');

procedure M_DrawDisplayDetailOptions;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Detail');

  ppos.x := OptionsDisplayDetailDef.x;
  ppos.y := OptionsDisplayDetailDef.y + OptionsDisplayDetailDef.itemheight * Ord(od_detaillevel);
  ppos := M_WriteText(ppos.x, ppos.y, 'Detail level: ', ma_left, @hu_fontY, @hu_fontB);
  sprintf(stmp, '%s (%dx%dx32)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT]);
  M_WriteText(ppos.x, ppos.y, stmp, ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_ChangeFullScreen(choice: integer);
begin
  GL_ChangeFullScreen(not fullscreen);
end;

procedure M_DrawDisplaySetVideoMode;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Set Video Mode');


  ppos.x := OptionsDisplayVideoModeDef.x;
  ppos.y := OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_fullscreen);
  ppos := M_WriteText(ppos.x, ppos.y, 'FullScreen: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, yesnoStrings[fullscreen], ma_left, @hu_fontW, @hu_fontB);

  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;
  ppos.x := OptionsDisplayVideoModeDef.x;
  ppos.y := OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_screensize);
  ppos := M_WriteText(ppos.x, ppos.y, 'Screen Size: ', ma_left, @hu_fontY, @hu_fontB);
  sprintf(stmp, '(%dx%d)', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteText(ppos.x, ppos.y, stmp, ma_left, @hu_fontW, @hu_fontB);

  M_DrawThermo(
    OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * (Ord(odm_screensize) + 1), 30, mdisplaymode_idx, numdisplaymodes);

  if (displaymodes[mdisplaymode_idx].width = SCREENWIDTH) and (displaymodes[mdisplaymode_idx].height = SCREENHEIGHT) then
    stmp := 'No change'
  else
    sprintf(stmp, 'Set video mode to %dx%d...', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteText(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_setvideomode), stmp, ma_left, @hu_fontY, @hu_fontB);
end;

procedure M_SwitchShadeMode(choice: integer);
begin
  shademenubackground := (shademenubackground + 1) mod 3;
end;

const
  menubackrounds: array[0..2] of string =
    ('NONE', 'SHADOW', 'TEXTURE');

procedure M_DrawDisplayAppearanceOptions;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Appearence');

  ppos.x := OptionsDisplayAppearanceDef.x;
  ppos.y := OptionsDisplayAppearanceDef.y + OptionsDisplayAppearanceDef.itemheight * Ord(od_shademenubackground);
  ppos := M_WriteText(ppos.x, ppos.y, 'Menu background: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, menubackrounds[shademenubackground mod 3], ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_DrawDisplayAutomapOptions;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Automap');
end;

procedure M_DrawOptionsDisplayAdvanced;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Advanced');
end;

procedure M_DrawOptionsDisplayAspectRatio;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Aspect Ratio');

  aspectratioidx := _nearest_aspect_index;
  ppos.x := OptionsDisplayAspectRatioDef.x;
  ppos.y := OptionsDisplayAspectRatioDef.y + OptionsDisplayAspectRatioDef.itemheight * Ord(oda_forceaspectratio);
  ppos := M_WriteText(ppos.x, ppos.y, 'Force Aspect Ratio: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, straspectratios[_nearest_aspect_index], ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_DrawOptionsDisplayCamera;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Camera');

  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
  ppos.x := OptionsDisplayCameraDef.x;
  ppos.y := OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraxy);
  ppos := M_WriteText(ppos.x, ppos.y, 'Chase Camera XY position: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, itoa(chasecamera_viewxy), ma_left, @hu_fontW, @hu_fontB);

  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
  ppos.x := OptionsDisplayCameraDef.x;
  ppos.y := OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraz);
  ppos := M_WriteText(ppos.x, ppos.y, 'Chase Camera Z position: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, itoa(chasecamera_viewz), ma_left, @hu_fontY, @hu_fontB);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraxy) + 1), 21, (chasecamera_viewxy - CHASECAMERA_XY_MIN) div 8, (CHASECAMERA_XY_MAX - CHASECAMERA_XY_MIN) div 8 + 1);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraz) + 1), 21, (chasecamera_viewz - CHASECAMERA_Z_MIN) div 4, (CHASECAMERA_Z_MAX - CHASECAMERA_Z_MIN) div 4 + 1);
end;

procedure M_DrawOptionsDisplay32bit;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'True Color Options');

  ppos.x := OptionsDisplay32bitDef.x;
  ppos.y := OptionsDisplay32bitDef.y + OptionsDisplay32bitDef.itemheight * Ord(od_flatfiltering);
  ppos := M_WriteText(ppos.x, ppos.y, 'Flat filtering: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, flatfilteringstrings[extremeflatfiltering], ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_DrawOptionsDisplayOpenGL;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'OpenGL');
end;

procedure M_DrawOptionsDisplayOpenGLModels;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Models');
end;

procedure M_ChangeVoxelOptimization(choice: integer);
begin
  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  if vx_maxoptimizerpasscount = MAX_VX_OPTIMIZE then
    vx_maxoptimizerpasscount := 0
  else
    vx_maxoptimizerpasscount := vx_maxoptimizerpasscount + 1;
end;

const
  str_voxeloptimizemethod: array[0..MAX_VX_OPTIMIZE] of string = (
    'FAST', 'GOOD', 'BETTER', 'BEST'
  );

procedure M_DrawOptionsDisplayOpenGLVoxels;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Voxels');

  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  ppos.x := OptionsDisplayOpenGLVoxelsDef.x;
  ppos.y := OptionsDisplayOpenGLVoxelsDef.y + OptionsDisplayOpenGLVoxelsDef.itemheight * Ord(od_glv_optimize);
  ppos := M_WriteText(ppos.x, ppos.y, 'Voxel mesh optimization: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, str_voxeloptimizemethod[vx_maxoptimizerpasscount], ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_ChangeTextureFiltering(choice: integer);
begin
  gld_SetCurrTexFiltering(gl_filter_t((Ord(gld_GetCurrTexFiltering) + 1) mod Ord(NUM_GL_FILTERS)));
  gld_ClearTextureMemory;
end;

procedure M_DrawOptionsDisplayOpenGLFilter;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Texture Filtering');

  ppos.x := OptionsDisplayOpenGLFilterDef.x;
  ppos.y := OptionsDisplayOpenGLFilterDef.y + OptionsDisplayOpenGLFilterDef.itemheight * Ord(od_glf_texture_filter);
  ppos := M_WriteText(ppos.x, ppos.y, 'Filter: ', ma_left, @hu_fontY, @hu_fontB);
  M_WriteText(ppos.x, ppos.y, gl_tex_filter_string, ma_left, @hu_fontW, @hu_fontB);
end;

procedure M_Options(choice: integer);
begin
  M_SetupNextMenu(@OptionsDef);
end;

//
//      Toggle messages on/off
//
procedure M_ChangeMessages(choice: integer);
begin
  showMessages := 1 - showMessages;

  if showMessages = 0 then
    players[consoleplayer]._message := MSGOFF
  else
    players[consoleplayer]._message := MSGON;

  message_dontfuckwithme := true;
end;

//
// M_EndGame
//
procedure M_EndGameResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  currentMenu.lastOn := itemOn;
  M_ClearMenus;
  D_StartTitle;
end;

procedure M_CmdEndGame;
begin
  if not usergame then
  begin
    M_MenuSound;
    exit;
  end;

  if netgame then
  begin
    M_StartMessage(NETEND + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_StartMessage(SENDGAME + #13#10 + PRESSYN, @M_EndGameResponse, true);
  C_ExecuteCmd('closeconsole', '1');
end;

procedure M_EndGame(choice: integer);
begin
  M_CmdEndGame;
end;

//
// M_ReadThis
//
procedure M_ReadThis(choice: integer);
begin
  M_SetupNextMenu(@ReadDef1);
end;

procedure M_ReadThis2(choice: integer);
begin
  M_SetupNextMenu(@ReadDef2);
end;

procedure M_FinishReadThis(choice: integer);
begin
  if extrahelpscreens.Count > 0 then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@ReadDefExt);
  end
  else
    M_SetupNextMenu(@MainDef);
end;

procedure M_FinishReadExtThis(choice: integer);
begin
  inc(extrahelpscreens_idx);
  if extrahelpscreens_idx >= extrahelpscreens.Count then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@MainDef);
  end;
end;

//
// M_QuitSpeed
//
const
  quitsounds: array[0..7] of integer = (
    Ord(sfx_pldeth),
    Ord(sfx_dmpain),
    Ord(sfx_popain),
    Ord(sfx_slop),
    Ord(sfx_telept),
    Ord(sfx_posit1),
    Ord(sfx_posit3),
    Ord(sfx_sgtatk)
  );

procedure M_CmdQuit;
begin
  if not netgame then
  begin
    M_MenuSound;
    I_WaitVBL(1000);
  end;
  G_Quit;
end;


procedure M_QuitResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  M_CmdQuit;
end;

procedure M_QuitSpeed(choice: integer);
begin
  // We pick index 0 which is language sensitive,
  //  or one at random, between 1 and maximum number.
  if language <> english then
    sprintf(endstring, '%s'#13#10#13#10 + DOSY, [endmsg[0]])
  else
    sprintf(endstring,'%s'#13#10#13#10 + DOSY, [endmsg[(gametic mod (NUM_QUITMESSAGES - 2)) + 1]]);

  M_StartMessage(endstring, @M_QuitResponse, true);
end;

procedure M_ChangeSensitivity(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivity > 0 then
        dec(mouseSensitivity);
    1:
      if mouseSensitivity < 19 then
        inc(mouseSensitivity);
  end;
end;

procedure M_ChangeSensitivityX(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityX > 0 then
        dec(mouseSensitivityX);
    1:
      if mouseSensitivityX < 10 then
        inc(mouseSensitivityX);
  end;
end;

procedure M_ChangeSensitivityY(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityY > 0 then
        dec(mouseSensitivityY);
    1:
      if mouseSensitivityY < 10 then
        inc(mouseSensitivityY);
  end;
end;

procedure M_KeyBindings(choice: integer);
begin
  M_SetupNextMenu(@KeyBindingsDef1);
end;

procedure M_ScreenShotCmd(choice: integer);
begin
  M_FixScreenshotFormat;
  if strupper(screenshotformat) = 'PNG' then
    screenshotformat := 'JPG'
  else if strupper(screenshotformat) = 'JPG' then
    screenshotformat := 'TGA'
  else if strupper(screenshotformat) = 'TGA' then
    screenshotformat := 'PNG'
  else
    screenshotformat := 'PNG';
end;

procedure M_ChangeDetail(choice: integer);
begin
  detailLevel := (detailLevel + 1) mod DL_NUMRESOLUTIONS;

  R_SetViewSize;

  case detailLevel of
    DL_LOWEST:
      players[consoleplayer]._message := DETAILLOWEST;
    DL_LOW:
      players[consoleplayer]._message := DETAILLOW;
    DL_MEDIUM:
      players[consoleplayer]._message := DETAILMED;
    DL_NORMAL:
      players[consoleplayer]._message := DETAILNORM;
    DL_HIRES:
      players[consoleplayer]._message := DETAILHI;
    DL_ULTRARES:
      players[consoleplayer]._message := DETAILULTRA;
  end;

end;

procedure M_ChangeScreenSize(choice: integer);
begin
  case choice of
    0:
      if mdisplaymode_idx > 0 then
        dec(mdisplaymode_idx);
    1:
      if mdisplaymode_idx < numdisplaymodes - 1 then
        inc(mdisplaymode_idx);
  end;
end;

procedure M_ApplyScreenSize(choice: integer);
begin
  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;

  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;

  D_NotifyVideoModeChange(displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height);
end;

procedure M_ChangeFlatFiltering(choice: integer);
begin
  C_ExecuteCmd('extremeflatfiltering', yesnoStrings[not extremeflatfiltering]);
end;

procedure M_BoolCmd(choice: integer);
var
  s: string;
begin
  s := currentMenu.menuitems[choice].cmd;
  if length(s) = 0 then
    I_Error('M_BoolCmd(): Unknown option');
  C_ExecuteCmd(s, yesnoStrings[not currentMenu.menuitems[choice].pBoolVal^]);
end;

procedure M_BoolCmdSetSize(choice: integer);
begin
  M_BoolCmd(choice);
  setsizeneeded := true;
end;

//
// CONTROL PANEL
//

//
// M_Responder
//
var
  joywait: integer;
  mousewait: integer;
  mmousex: integer;
  mmousey: integer;
  mlastx: integer;
  mlasty: integer;
  m_altdown: boolean = false;

function M_Responder(ev: Pevent_t): boolean;
var
  ch: integer;
  i: integer;
  palette: PByteArray;
begin
  if gamestate = GS_ENDOOM then
  begin
    result := false;
    exit;
  end;

  if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    m_altdown := ev._type = ev_keydown;
    result := false;
    exit;
  end;

  ch := -1;

  if (ev._type = ev_joystick) and (joywait < I_GetTime) then
  begin
    if ev.data3 < 0 then
    begin
      ch := KEY_UPARROW;
      joywait := I_GetTime + 5;
    end
    else if ev.data3 > 0 then
    begin
      ch := KEY_DOWNARROW;
      joywait := I_GetTime + 5;
    end;

    if ev.data2 < 0 then
    begin
      ch := KEY_LEFTARROW;
      joywait := I_GetTime + 2;
    end
    else if ev.data2 > 0 then
    begin
      ch := KEY_RIGHTARROW;
      joywait := I_GetTime + 2;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      joywait := I_GetTime + 5;
    end;
    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      joywait := I_GetTime + 5;
    end;
  end
  else if (ev._type = ev_mouse) and (mousewait < I_GetTime) then
  begin
    mmousey := mmousey + ev.data3;
    if mmousey < mlasty - 30 then
    begin
      ch := KEY_DOWNARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty - 30;
      mmousey := mlasty;
    end
    else if mmousey > mlasty + 30 then
    begin
      ch := KEY_UPARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty + 30;
      mmousey := mlasty;
    end;

    mmousex := mmousex + ev.data2;
    if mmousex < mlastx - 30 then
    begin
      ch := KEY_LEFTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx - 30;
      mmousex := mlastx;
    end
    else if mmousex > mlastx + 30 then
    begin
      ch := KEY_RIGHTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx + 30;
      mmousex := mlastx;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      mousewait := I_GetTime + 15;
    end;

    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      mousewait := I_GetTime + 15;
    end
  end
  else if ev._type = ev_keydown then
    ch := ev.data1;

  if ch = -1 then
  begin
    result := false;
    exit;
  end;

  // Save Game string input
  if saveStringEnter <> 0 then
  begin
    case ch of
      KEY_BACKSPACE:
        begin
          if saveCharIndex > 0 then
          begin
            dec(saveCharIndex);
            SetLength(savegamestrings[saveSlot], saveCharIndex);
          end;
        end;
      KEY_ESCAPE:
        begin
          saveStringEnter := 0;
          savegamestrings[saveSlot] := saveOldString;
        end;
      KEY_ENTER:
        begin
          saveStringEnter := 0;
          if savegamestrings[saveSlot] <> '' then
            M_DoSave(saveSlot);
        end
    else
      begin
        ch := Ord(toupper(Chr(ch)));
        if ch <> 32 then
        if (ch - Ord(HU_FONTSTART) < 0) or (ch - Ord(HU_FONTSTART) >= HU_FONTSIZE) then
        else
        begin
          if (ch >= 32) and (ch <= 127) and
             (saveCharIndex < SAVESTRINGSIZE - 1) and
             (M_StringWidth(savegamestrings[saveSlot], @hu_fontY) < (SAVESTRINGSIZE - 2) * 8) then
          begin
            inc(saveCharIndex);
            savegamestrings[saveSlot] := savegamestrings[saveSlot] + Chr(ch);
          end;
        end;
      end;
    end;
    result := true;
    exit;
  end;

  // Key bindings
  if bindkeyEnter then
  begin
    case ch of
      KEY_ESCAPE:
        begin
          bindkeyEnter := false;
          KeyBindingsInfo[bindkeySlot].pkey^ := saveOldkey;
        end;
      KEY_ENTER:
        begin
          bindkeyEnter := false;
        end;
    else
      M_SetKeyBinding(bindkeySlot, ch);
      bindkeyEnter := false;
    end;
    result := true;
    exit;
  end;

  // Take care of any messages that need input
  if messageToPrint <> 0 then
  begin
    if messageNeedsInput and ( not(
      (ch = Ord(' ')) or (ch = Ord('n')) or (ch = Ord('y')) or (ch = KEY_ESCAPE))) then
    begin
      result := false;
      exit;
    end;

    menuactive := messageLastMenuActive;
    messageToPrint := 0;
    if Assigned(messageRoutine) then
      messageRoutine(ch);

    result := true;

    if I_GameFinished then
      exit;

    menuactive := false;
    M_MenuSound;
    exit;
  end;

  // F-Keys
  if not menuactive then
    case ch of
      KEY_F1:      // Help key
        begin
          M_StartControlPanel;
          if gamemode = retail then
            currentMenu := @ReadDef2
          else
            currentMenu := @ReadDef1;

          itemOn := 0;
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F2:  // Save
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_SaveGame(0);
          result := true;
          exit;
        end;
      KEY_F3:  // Load
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_LoadGame(0);
          result := true;
          exit;
        end;
      KEY_F4:   // Sound Volume
        begin
          M_StartControlPanel;
          currentMenu := @SoundVolDef;
          itemOn := Ord(sfx_vol);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F5:   // Detail toggle
        begin
          M_ChangeDetail(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F6:   // Quicksave
        begin
          M_MenuSound;
          M_QuickSave;
          result := true;
          exit;
        end;
      KEY_F7:   // End game
        begin
          M_MenuSound;
          M_EndGame(0);
          result := true;
          exit;
        end;
      KEY_F8:   // Toggle messages
        begin
          M_ChangeMessages(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F9:   // Quickload
        begin
          M_MenuSound;
          M_QuickLoad;
          result := true;
          exit;
        end;
      KEY_F10:  // Quit DOOM
        begin
          M_MenuSound;
          M_QuitSpeed(0);
          result := true;
          exit;
        end;
      KEY_F11:  // gamma toggle
        begin
          inc(usegamma);
          if usegamma >= GAMMASIZE then
            usegamma := 0;
          players[consoleplayer]._message := gammamsg[usegamma];
          palette := V_ReadPalette(PU_STATIC);
          I_SetPalette(palette);
          V_SetPalette(palette);
          Z_ChangeTag(palette, PU_CACHE);
          result := true;
          exit;
        end;
      KEY_ENTER:
        begin
          if m_altdown then
          begin
            GL_ChangeFullScreen(not fullscreen);
            result := true;
            exit;
          end;
        end;
    end;

  // Pop-up menu?
  if not menuactive then
  begin
    if ch = KEY_ESCAPE then
    begin
      M_StartControlPanel;
      M_MenuSound;
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  // Keys usable within menu
  case ch of
    KEY_PAGEUP:
      begin
        itemOn := -1;
        repeat
          inc(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_PAGEDOWN:
      begin
        itemOn := currentMenu.numitems;
        repeat
          dec(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_DOWNARROW:
      begin
        repeat
          if itemOn + 1 > currentMenu.numitems - 1 then
            itemOn := 0
          else
            inc(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_UPARROW:
      begin
        repeat
          if itemOn = 0 then
            itemOn := currentMenu.numitems - 1
          else
            dec(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_LEFTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(0);
        end
        else if (currentMenu.leftMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.leftMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_RIGHTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(1);
        end
        else if (currentMenu.rightMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.rightMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_ENTER:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status <> 0) then
        begin
          currentMenu.lastOn := itemOn;
          if currentMenu.menuitems[itemOn].status = 2 then
          begin
            currentMenu.menuitems[itemOn].routine(1); // right arrow
            M_MenuSound;
          end
          else
          begin
            currentMenu.menuitems[itemOn].routine(itemOn);
            M_MenuSound;
          end;
        end;
        result := true;
        exit;
      end;
    KEY_ESCAPE:
      begin
        currentMenu.lastOn := itemOn;
        M_ClearMenus;
        M_MenuSound;
        result := true;
        exit;
      end;
    KEY_BACKSPACE:
      begin
        currentMenu.lastOn := itemOn;
        // JVAL 20200122 - Extended help screens
        if (currentMenu = @ReadDefExt) and (extrahelpscreens_idx > 0) then
        begin
          dec(extrahelpscreens_idx);
          M_MenuSound;
        end
        else if currentMenu.prevMenu <> nil then
        begin
          currentMenu := currentMenu.prevMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
  else
    begin
      for i := itemOn + 1 to currentMenu.numitems - 1 do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          M_MenuSound;
          result := true;
          exit;
        end;
      for i := 0 to itemOn do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          M_MenuSound;
          result := true;
          exit;
        end;
    end;
  end;

  result := false;
end;

//
// M_StartControlPanel
//
procedure M_StartControlPanel;
begin
  // intro might call this repeatedly
  if menuactive then
    exit;

  menuactive := true;
  currentMenu := @MainDef;// JDC
  itemOn := currentMenu.lastOn; // JDC
end;

//

//
// JVAL
// Threaded shades the half screen
//
function M_Thr_ShadeScreen(p: pointer): integer; stdcall;
var
  half: integer;
begin
  half := V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2;
  V_ShadeBackground(half, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) - half);
  result := 0;
end;

var
  threadmenushader: TDThread;

procedure M_MenuShader;
begin
  shademenubackground := shademenubackground mod 3;
  if not wipedisplay and (shademenubackground >= 1) then
  begin
    if usemultithread then
    begin
    // JVAL
      threadmenushader.Activate(nil);
      V_ShadeBackground(0, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2);
      // Wait for extra thread to terminate.
      threadmenushader.Wait;
    end
    else
      V_ShadeBackground;
  end;
end;

procedure M_FinishUpdate(const height: integer);
begin
  // JVAL
  // Menu is no longer drawn to primary surface,
  // Instead we use SCN_TMP and after the drawing we blit to primary surface
  if inhelpscreens then
  begin
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
    inhelpscreens := false;
  end
  else
  begin
    M_MenuShader;
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, height, 0, 0, SCN_FG, true);
  end;
end;

procedure M_DrawMenuBackground(const pg: string);
begin
  V_DrawPatchFullScreenTMP320x200(pg);
end;

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
procedure M_Drawer;
var
  i: integer;
  max: integer;
  str: string;
  len: integer;
  x, y: integer;
  mheight: integer;
  ppos: menupos_t;
  rstr: string;
  rlen: integer;
begin
  // Horiz. & Vertically center string and print it.
  if messageToPrint <> 0 then
  begin

    mheight := M_StringHeight(messageString, @hu_fontY);
    y := (200 - mheight) div 2;
    mheight := y + mheight + 20;
    MT_ZeroMemory(screens[SCN_TMP], 320 * mheight);
    len := Length(messageString);
    str := '';
    for i := 1 to len do
    begin
      if messageString[i] = #13 then
        y := y + hu_fontY[0].height
      else if messageString[i] = #10 then
      begin
        M_WriteText(160, y, str, ma_center, @hu_fontY, @hu_fontB);
        str := '';
      end
      else
        str := str + messageString[i];
    end;
    if str <> '' then
    begin
      y := y + hu_fontY[0].height;
      M_WriteText(160, y, str, ma_center, @hu_fontY, @hu_fontB);
    end;

    M_FinishUpdate(mheight);
    exit;
  end;

  if not menuactive then
    exit;

  MT_ZeroMemory(screens[SCN_TMP], 320 * 200);

  if (shademenubackground = 2) and currentMenu.texturebk then
    M_DrawMenuBackground('MBG_RECO');

  if Assigned(currentMenu.drawproc) then
    currentMenu.drawproc; // call Draw routine

  // DRAW MENU
  x := currentMenu.x;
  y := currentMenu.y;
  max := currentMenu.numitems;

  for i := 0 to max - 1 do
  begin
    str := currentMenu.menuitems[i].name;
    if str <> '' then
    begin
      if str[1] = '!' then // Draw text with Yes/No
      begin
        delete(str, 1, 1);
        if currentMenu.menuitems[i].pBoolVal <> nil then
        begin
          ppos := M_WriteText(x, y, str + ': ', ma_left, @hu_fontY, @hu_fontB);
          M_WriteText(ppos.x, ppos.y, yesnoStrings[currentMenu.menuitems[i].pBoolVal^], ma_left, @hu_fontW, @hu_fontB);
        end
        else
          M_WriteText(x, y, str, ma_left, @hu_fontY, @hu_fontB);
      end;
    end;
    y := y + currentMenu.itemheight;
  end;

  if currentMenu.leftMenu <> nil then
    M_WriteText(5, 44, '<<', ma_left, @hu_fontW, @hu_fontB);

  if currentMenu.rightMenu <> nil then
  begin
    rstr := '>>';
    rlen := M_StringWidth(rstr, @hu_fontY);
    M_WriteText(315 - rlen, 44, rstr, ma_left, @hu_fontW, @hu_fontB);
  end;

  if currentMenu.itemheight <= LINEHEIGHT2 then
    M_WriteText(x + ARROWXOFF, currentMenu.y + itemOn * currentMenu.itemheight, '-', ma_left, @hu_fontW, @hu_fontB);

  M_FinishUpdate(200);
end;

//
// M_Ticker
//
procedure M_Ticker;
begin
end;

procedure M_CmdSetupNextMenu(menudef: Pmenu_t);
begin
  menuactive := true;
  if (menudef = @LoadDef) or (menudef = @SaveDef) then
    M_ReadSaveStrings;
  M_SetupNextMenu(menudef);
  C_ExecuteCmd('closeconsole');
end;

procedure M_CmdMenuMainDef;
begin
  M_CmdSetupNextMenu(@MainDef);
end;

procedure M_CmdMenuNewDef;
begin
  M_CmdSetupNextMenu(@NewDef);
end;

procedure M_CmdMenuOptionsDef;
begin
  M_CmdSetupNextMenu(@OptionsDef);
end;

procedure M_CmdMenuOptionsGeneralDef;
begin
  M_CmdSetupNextMenu(@OptionsGeneralDef);
end;

procedure M_CmdMenuOptionsDisplayDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDef);
end;

procedure M_CmdMenuOptionsDisplayDetailDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDetailDef);
end;

procedure M_CmdMenuOptionsDisplayAppearanceDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_CmdMenuOptionsDisplayAdvancedDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_CmdMenuOptionsDisplay32bitDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplay32bitDef);
end;

procedure M_CmdOptionsDisplayOpenGL;
begin
  M_CmdSetupNextMenu(@OptionsDisplayOpenGLDef);
end;

procedure M_CmdMenuSoundDef;
begin
  M_CmdSetupNextMenu(@SoundDef);
end;

procedure M_CmdMenuSoundVolDef;
begin
  M_CmdSetupNextMenu(@SoundVolDef);
end;

procedure M_CmdMenuCompatibilityDef;
begin
  M_CmdSetupNextMenu(@CompatibilityDef);
end;

procedure M_CmdMenuControlsDef;
begin
  M_CmdSetupNextMenu(@ControlsDef);
end;

procedure M_CmdMenuSystemDef;
begin
  M_CmdSetupNextMenu(@SystemDef);
end;

procedure M_CmdMenuLoadDef;
begin
  M_CmdSetupNextMenu(@LoadDef);
end;

procedure M_CmdMenuSaveDef;
begin
  M_CmdSetupNextMenu(@SaveDef);
end;

//
// M_Init
//
procedure M_Init;
var
  i: integer;
  lump: integer;
begin
  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu.lastOn;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  quickSaveSlot := -1;

  // Here we could catch other version dependencies,
  //  like HELP1/2, and four episodes.

  case gamemode of
    shareware:
      begin
        ReadDef2.x := 280;
        ReadDef2.y := 185; // x,y of menu
        // We need to remove the fourth episode.
        // Episode 2 and 3 are handled,
        // branching to an ad screen.
        dec(EpiDef.numitems);
      end;
    registered:
      begin
        // We need to remove the fourth episode.
        dec(EpiDef.numitems);
      end;
  end;

  // JVAL 20200122 - Extended help screens
  extrahelpscreens := TDNumberList.Create;
  for i := 1 to 99 do
  begin
    lump := W_CheckNumForName('HELP' + IntToStrzFill(2, i));
    if lump >= 0 then
      extrahelpscreens.Add(lump);
  end;
  extrahelpscreens_idx := 0;

  C_AddCmd('keyboardmode', @M_CmdKeyboardMode);
  C_AddCmd('exit, quit', @M_CmdQuit);
  C_AddCmd('halt', @I_Quit);
  C_AddCmd('set', @Cmd_Set);
  C_AddCmd('get', @Cmd_Get);
  C_AddCmd('typeof', @Cmd_TypeOf);
  C_AddCmd('endgame', @M_CmdEndGame);
  C_AddCmd('defaults, setdefaults', @M_SetDefaults);
  C_AddCmd('default, setdefault', @M_SetDefaults);
  C_AddCmd('menu_main', @M_CmdMenuMainDef);
  C_AddCmd('menu_newgame, menu_new', @M_CmdMenuNewDef);
  C_AddCmd('menu_options', @M_CmdMenuOptionsDef);
  C_AddCmd('menu_optionsgeneral, menu_generaloptions', @M_CmdMenuOptionsGeneralDef);
  C_AddCmd('menu_optionsdisplay, menu_displayoptions, menu_display', @M_CmdMenuOptionsDisplayDef);
  C_AddCmd('menu_optionsdisplayopengl, menu_optionsopengl, menu_opengl', @M_CmdOptionsDisplayOpenGL);
  C_AddCmd('menu_optionsdisplayappearence, menu_displayappearenceoptions, menu_displayappearence', @M_CmdMenuOptionsDisplayAppearanceDef);
  C_AddCmd('menu_optionsdisplayadvanced, menu_displayadvancedoptions, menu_displayadvanced', @M_CmdMenuOptionsDisplayAdvancedDef);
  C_AddCmd('menu_optionsdisplay32bit, menu_display32bitoptions, menu_display32bit', @M_CmdMenuOptionsDisplay32bitDef);
  C_AddCmd('menu_optionssound, menu_soundoptions, menu_sound', @M_CmdMenuSoundDef);
  C_AddCmd('menu_optionssoundvol, menu_soundvoloptions, menu_soundvol', @M_CmdMenuSoundVolDef);
  C_AddCmd('menu_optionscompatibility, menu_compatibilityoptions, menu_compatibility', @M_CmdMenuCompatibilityDef);
  C_AddCmd('menu_optionscontrols, menu_controlsoptions, menu_controls', @M_CmdMenuControlsDef);
  C_AddCmd('menu_optionssystem, menu_systemoptions, menu_system', @M_CmdMenuSystemDef);
  C_AddCmd('menu_load, menu_loadgame', @M_CmdMenuLoadDef);
  C_AddCmd('menu_save, menu_savegame', @M_CmdMenuSaveDef);
end;

procedure M_ShutDownMenus;
begin
  threadmenushader.Free;
  extrahelpscreens.Free;
end;

procedure M_InitMenus;
var
  i: integer;
  pmi: Pmenuitem_t;
begin
  threadmenushader := TDThread.Create(@M_Thr_ShadeScreen);

////////////////////////////////////////////////////////////////////////////////
//gammamsg
  gammamsg[0] := GAMMALVL0;
  gammamsg[1] := GAMMALVL1;
  gammamsg[2] := GAMMALVL2;
  gammamsg[3] := GAMMALVL3;
  gammamsg[4] := GAMMALVL4;

////////////////////////////////////////////////////////////////////////////////
// MainMenu
  pmi := @MainMenu[0];
  pmi.status := 1;
  pmi.name := 'New Game';
  pmi.cmd := '';
  pmi.routine := @M_NewGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Options';
  pmi.cmd := '';
  pmi.routine := @M_Options;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Load Game';
  pmi.cmd := '';
  pmi.routine := @M_LoadGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Save Game';
  pmi.cmd := '';
  pmi.routine := @M_SaveGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  // Another hickup with Special edition.
  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Ordering Info';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Quit';
  pmi.cmd := '';
  pmi.routine := @M_QuitSpeed;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'q';

////////////////////////////////////////////////////////////////////////////////
//MainDef
  MainDef.numitems := Ord(main_end);
  MainDef.prevMenu := nil;
  MainDef.menuitems := Pmenuitem_tArray(@MainMenu);
  MainDef.drawproc := @M_DrawMainMenu;  // draw routine
  MainDef.x := DEF_MENU_ITEMS_START_X;
  MainDef.y := DEF_MENU_ITEMS_START_Y;
  MainDef.lastOn := 0;
  MainDef.itemheight := LINEHEIGHT;
  MainDef.texturebk := false;

////////////////////////////////////////////////////////////////////////////////
//EpisodeMenu
  pmi := @EpisodeMenu[0];
  pmi.status := 1;
  pmi.name := 'Course #1';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '1';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Course #2';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '2';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Course #3';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Course #4';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '4';

////////////////////////////////////////////////////////////////////////////////
//EpiDef
  EpiDef.numitems := Ord(ep_end); // # of menu items
  EpiDef.prevMenu := @MainDef; // previous menu
  EpiDef.menuitems := Pmenuitem_tArray(@EpisodeMenu);  // menu items
  EpiDef.drawproc := @M_DrawEpisode;  // draw routine
  EpiDef.x := DEF_MENU_ITEMS_START_X;
  EpiDef.y := DEF_MENU_ITEMS_START_Y;
  EpiDef.lastOn := Ord(mn_ep1); // last item user was on in menu
  EpiDef.itemheight := LINEHEIGHT;
  EpiDef.texturebk := false;

////////////////////////////////////////////////////////////////////////////////
//NewGameMenu
  pmi := @NewGameMenu[0];
  pmi.status := 1;
  pmi.name := 'Begginer';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Easy';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Medium';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Hard';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Very hard';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

////////////////////////////////////////////////////////////////////////////////
//NewDef
  NewDef.numitems := Ord(newg_end); // # of menu items
  NewDef.prevMenu := @EpiDef; // previous menu
  NewDef.menuitems := Pmenuitem_tArray(@NewGameMenu);  // menu items
  NewDef.drawproc := @M_DrawNewGame;  // draw routine
  NewDef.x := DEF_MENU_ITEMS_START_X;
  NewDef.y := DEF_MENU_ITEMS_START_Y;
  NewDef.lastOn := Ord(newg_hurtme); // last item user was on in menu
  NewDef.itemheight := LINEHEIGHT;
  NewDef.texturebk := false;

////////////////////////////////////////////////////////////////////////////////
//OptionsMenu
  pmi := @OptionsMenu[0];
  pmi.status := 1;
  pmi.name := 'General';
  pmi.cmd := '';
  pmi.routine := @M_OptionsGeneral;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Display';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Sound';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSound;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Compatibility';
  pmi.cmd := '';
  pmi.routine := @M_OptionsCompatibility;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Controls';
  pmi.cmd := '';
  pmi.routine := @M_OptionsConrols;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'System';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSystem;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDef
  OptionsDef.numitems := Ord(opt_end); // # of menu items
  OptionsDef.prevMenu := @MainDef; // previous menu
  OptionsDef.menuitems := Pmenuitem_tArray(@OptionsMenu);  // menu items
  OptionsDef.drawproc := @M_DrawOptions;  // draw routine
  OptionsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDef.lastOn := 0; // last item user was on in menu
  OptionsDef.itemheight := LINEHEIGHT;
  OptionsDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralMenu
  pmi := @OptionsGeneralMenu[0];
  pmi.status := 1;
  pmi.name := 'End Game';
  pmi.cmd := '';
  pmi.routine := @M_EndGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Messages';
  pmi.cmd := '';
  pmi.routine := @M_ChangeMessages;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralDef
  OptionsGeneralDef.numitems := Ord(optgen_end); // # of menu items
  OptionsGeneralDef.prevMenu := @OptionsDef; // previous menu
  OptionsGeneralDef.leftMenu := @SystemDef;
  OptionsGeneralDef.rightMenu := @OptionsDisplayDef;
  OptionsGeneralDef.menuitems := Pmenuitem_tArray(@OptionsGeneralMenu);  // menu items
  OptionsGeneralDef.drawproc := @M_DrawGeneralOptions;  // draw routine
  OptionsGeneralDef.x := DEF_MENU_ITEMS_START_X;
  OptionsGeneralDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsGeneralDef.lastOn := 0; // last item user was on in menu
  OptionsGeneralDef.itemheight := LINEHEIGHT;
  OptionsGeneralDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayMenu
  pmi := @OptionsDisplayMenu[0];
  pmi.status := 1;
  pmi.name := 'OpenGL';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGL;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Automap';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAutomap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Appearence';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAppearance;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Advanced';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAdvanced;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'True Color Options';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay32bit;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDef
  OptionsDisplayDef.numitems := Ord(optdisp_end); // # of menu items
  OptionsDisplayDef.prevMenu := @OptionsDef; // previous menu
  OptionsDisplayDef.leftMenu := @OptionsGeneralDef; // previous menu
  OptionsDisplayDef.rightMenu := @SoundDef; // previous menu
  OptionsDisplayDef.menuitems := Pmenuitem_tArray(@OptionsDisplayMenu);  // menu items
  OptionsDisplayDef.drawproc := @M_DrawDisplayOptions;  // draw routine
  OptionsDisplayDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDef.itemheight := LINEHEIGHT;
  OptionsDisplayDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailMenu
  pmi := @OptionsDisplayDetailMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow low details';
  pmi.cmd := 'allowlowdetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowlowdetails;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow high details';
  pmi.cmd := 'allowhidetails';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowhidetails;
  pmi.alphaKey := 'h';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailDef
  OptionsDisplayDetailDef.numitems := Ord(optdispdetail_end); // # of menu items
  OptionsDisplayDetailDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayDetailDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayDetailDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayDetailDef.menuitems := Pmenuitem_tArray(@OptionsDisplayDetailMenu);  // menu items
  OptionsDisplayDetailDef.drawproc := @M_DrawDisplayDetailOptions;  // draw routine
  OptionsDisplayDetailDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDetailDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDetailDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDetailDef.itemheight := LINEHEIGHT2;
  OptionsDisplayDetailDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeMenu
  pmi := @OptionsDisplayVideoModeMenu[0];
  pmi.status := 1;
  pmi.name := '!Fullscreen';
  pmi.cmd := '';
  pmi.routine := @M_ChangeFullScreen;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeScreenSize;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ApplyScreenSize;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeDef
  OptionsDisplayVideoModeDef.numitems := Ord(optdispvideomode_end); // # of menu items
  OptionsDisplayVideoModeDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayVideoModeDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayVideoModeDef.menuitems := Pmenuitem_tArray(@OptionsDisplayVideoModeMenu);  // menu items
  OptionsDisplayVideoModeDef.drawproc := @M_DrawDisplaySetVideoMode;  // draw routine
  OptionsDisplayVideoModeDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayVideoModeDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayVideoModeDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayVideoModeDef.itemheight := LINEHEIGHT2;
  OptionsDisplayVideoModeDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapMenu
  pmi := @OptionsDisplayAutomapMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow automap overlay';
  pmi.cmd := 'allowautomapoverlay';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomapoverlay;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow automap rotation';
  pmi.cmd := 'allowautomaprotate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomaprotate;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Textured Automap';
  pmi.cmd := 'texturedautomap';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @texturedautomap;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Automap grid';
  pmi.cmd := 'automapgrid';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @automapgrid;
  pmi.alphaKey := 'g';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapDef
  OptionsDisplayAutomapDef.numitems := Ord(optdispautomap_end); // # of menu items
  OptionsDisplayAutomapDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAutomapDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayAutomapDef.rightMenu := @OptionsDisplayAppearanceDef; // right menu
  OptionsDisplayAutomapDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAutomapMenu);  // menu items
  OptionsDisplayAutomapDef.drawproc := @M_DrawDisplayAutomapOptions;  // draw routine
  OptionsDisplayAutomapDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAutomapDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAutomapDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAutomapDef.itemheight := LINEHEIGHT2;
  OptionsDisplayAutomapDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceMenu
  pmi := @OptionsDisplayAppearanceMenu[0];
  pmi.status := 1;
  pmi.name := '!Display fps';
  pmi.cmd := 'drawfps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawfps;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Menu background';
  pmi.cmd := '';
  pmi.routine := @M_SwitchShadeMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display disk busy icon';
  pmi.cmd := 'displaydiskbusyicon';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displaydiskbusyicon;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display ENDOOM screen';
  pmi.cmd := 'displayendscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displayendscreen;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display demo playback progress';
  pmi.cmd := 'showdemoplaybackprogress';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @showdemoplaybackprogress;
  pmi.alphaKey := 'p';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceDef
  OptionsDisplayAppearanceDef.numitems := Ord(optdispappearance_end); // # of menu items
  OptionsDisplayAppearanceDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAppearanceDef.leftMenu := @OptionsDisplayAutomapDef; // left menu
  OptionsDisplayAppearanceDef.rightMenu := @OptionsDisplayAdvancedDef; // rightmenu
  OptionsDisplayAppearanceDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAppearanceMenu);  // menu items
  OptionsDisplayAppearanceDef.drawproc := @M_DrawDisplayAppearanceOptions;  // draw routine
  OptionsDisplayAppearanceDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAppearanceDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAppearanceDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAppearanceDef.itemheight := LINEHEIGHT2;
  OptionsDisplayAppearanceDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedMenu
  pmi := @OptionsDisplayAdvancedMenu[0];
  pmi.status := 1;
  pmi.name := '!Aspect Ratio...';
  pmi.cmd := '';
  pmi.routine := @M_OptionAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Camera...';
  pmi.cmd := '';
  pmi.routine := @M_OptionCameraShift;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Transparent sprites';
  pmi.cmd := 'usetransparentsprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usetransparentsprites;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Uncapped framerate';
  pmi.cmd := 'interpolate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolate;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Interpolate on capped';
  pmi.cmd := 'interpolateoncapped';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolateoncapped;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto fix memory stall';
  pmi.cmd := 'fixstallhack';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @fixstallhack;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto-adjust missing textures';
  pmi.cmd := 'autoadjustmissingtextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autoadjustmissingtextures;
  pmi.alphaKey := 'a';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedDef
  OptionsDisplayAdvancedDef.numitems := Ord(optdispadvanced_end); // # of menu items
  OptionsDisplayAdvancedDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAdvancedDef.leftMenu := @OptionsDisplayAppearanceDef; // left menu
  OptionsDisplayAdvancedDef.rightMenu := @OptionsDisplay32bitDef; // right menu
  OptionsDisplayAdvancedDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAdvancedMenu);  // menu items
  OptionsDisplayAdvancedDef.drawproc := @M_DrawOptionsDisplayAdvanced;  // draw routine
  OptionsDisplayAdvancedDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAdvancedDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAdvancedDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAdvancedDef.itemheight := LINEHEIGHT2;
  OptionsDisplayAdvancedDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioMenu
  pmi := @OptionsDisplayAspectRatioMenu[0];
  pmi.status := 1;
  pmi.name := '!Widescreen support';
  pmi.cmd := 'widescreensupport';
  pmi.routine := @M_BoolCmdSetSize;
  pmi.pBoolVal := @widescreensupport;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Player Sprites Stretch';
  pmi.cmd := 'excludewidescreenplayersprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @excludewidescreenplayersprites;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Force Aspect Ratio';
  pmi.cmd := '';
  pmi.routine := @M_SwitchForcedAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Intermission screens resize';
  pmi.cmd := 'intermissionstretch';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @intermissionstretch;
  pmi.alphaKey := 'i';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioDef
  OptionsDisplayAspectRatioDef.numitems := Ord(optdispaspect_end); // # of menu items
  OptionsDisplayAspectRatioDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayAspectRatioDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayAspectRatioDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAspectRatioMenu);  // menu items
  OptionsDisplayAspectRatioDef.drawproc := @M_DrawOptionsDisplayAspectRatio;  // draw routine
  OptionsDisplayAspectRatioDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAspectRatioDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAspectRatioDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAspectRatioDef.itemheight := LINEHEIGHT2;
  OptionsDisplayAspectRatioDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraMenu
  pmi := @OptionsDisplayCameraMenu[0];
  pmi.status := 1;
  pmi.name := '!Look Up/Down';
  pmi.cmd := 'zaxisshift';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @zaxisshift;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Chase camera';
  pmi.cmd := 'chasecamera';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @chasecamera;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera XY position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraXY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera Z position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraZ;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;


////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraDef
  OptionsDisplayCameraDef.numitems := Ord(optdispcamera_end); // # of menu items
  OptionsDisplayCameraDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayCameraDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayCameraDef.menuitems := Pmenuitem_tArray(@OptionsDisplayCameraMenu);  // menu items
  OptionsDisplayCameraDef.drawproc := @M_DrawOptionsDisplayCamera;  // draw routine
  OptionsDisplayCameraDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayCameraDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayCameraDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayCameraDef.itemheight := LINEHEIGHT2;
  OptionsDisplayCameraDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitMenu
  pmi := @OptionsDisplay32bitMenu[0];
  pmi.status := 1;
  pmi.name := '!Glow light effects';
  pmi.cmd := 'uselightboost';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @uselightboost;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use 32 bit colormaps';
  pmi.cmd := 'forcecolormaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @forcecolormaps;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!32 bit palette effect simulation';
  pmi.cmd := '32bittexturepaletteeffects';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @dc_32bittexturepaletteeffects;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use classic fuzz effect in 32 bit';
  pmi.cmd := 'use32bitfuzzeffect';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use32bitfuzzeffect;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external textures';
  pmi.cmd := 'useexternaltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternaltextures;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search texture paths in PK3';
  pmi.cmd := 'preferetexturesnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferetexturesnamesingamedirectory;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeFlatFiltering;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitDef
  OptionsDisplay32bitDef.numitems := Ord(optdisp32bit_end); // # of menu items
  OptionsDisplay32bitDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplay32bitDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplay32bitDef.rightMenu := @OptionsDisplayOpenGLDef; // right menu
  OptionsDisplay32bitDef.menuitems := Pmenuitem_tArray(@OptionsDisplay32bitMenu);  // menu items
  OptionsDisplay32bitDef.drawproc := @M_DrawOptionsDisplay32bit;  // draw routine
  OptionsDisplay32bitDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplay32bitDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplay32bitDef.lastOn := 0; // last item user was on in menu
  OptionsDisplay32bitDef.itemheight := LINEHEIGHT2;
  OptionsDisplay32bitDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLMenu
  pmi := @OptionsDisplayOpenGLMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Models...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLModels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxels...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLVoxels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Texture filtering...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLFilter;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use fog';
  pmi.cmd := 'use_fog';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use_fog;
  pmi.alphaKey := 'u';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw Sky';
  pmi.cmd := 'gl_drawsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawsky;
  pmi.alphaKey := 's';
  {$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use stencil buffer for sky';
  pmi.cmd := 'gl_stencilsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_stencilsky;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Render wireframe';
  pmi.cmd := 'gl_renderwireframe';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_renderwireframe;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use lightmaps';
  pmi.cmd := 'gl_uselightmaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_uselightmaps;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw shadows';
  pmi.cmd := 'gl_drawshadows';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawshadows;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw all linedefs';
  pmi.cmd := 'gl_add_all_lines';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_add_all_lines;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use GL_NODES if available';
  pmi.cmd := 'useglnodesifavailable';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useglnodesifavailable;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Limit framerate to screen sync';
  pmi.cmd := 'gl_screensync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_screensync;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLDef
  OptionsDisplayOpenGLDef.numitems := Ord(optdispopengl_end); // # of menu items
  OptionsDisplayOpenGLDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayOpenGLDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayOpenGLDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayOpenGLDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLMenu);  // menu items
  OptionsDisplayOpenGLDef.drawproc := @M_DrawOptionsDisplayOpenGL;  // draw routine
  OptionsDisplayOpenGLDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLDef.itemheight := LINEHEIGHT2;
  OptionsDisplayOpenGLDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsMenu
  pmi := @OptionsDisplayOpenGLModelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Smooth md2 model movement';
  pmi.cmd := 'gl_smoothmodelmovement';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_smoothmodelmovement;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precache model textures';
  pmi.cmd := 'gl_precachemodeltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_precachemodeltextures;
  pmi.alphaKey := 'p';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsDef
  OptionsDisplayOpenGLModelsDef.numitems := Ord(optglmodels_end); // # of menu items
  OptionsDisplayOpenGLModelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLModelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLModelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLModelsMenu);  // menu items
  OptionsDisplayOpenGLModelsDef.drawproc := @M_DrawOptionsDisplayOpenGLModels;  // draw routine
  OptionsDisplayOpenGLModelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLModelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLModelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLModelsDef.itemheight := LINEHEIGHT2;
  OptionsDisplayOpenGLModelsDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsMenu
  pmi := @OptionsDisplayOpenGLVoxelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Draw voxels instead of sprites';
  pmi.cmd := 'gl_drawvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawvoxels;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxel mesh optimization';
  pmi.cmd := '';
  pmi.routine := @M_ChangeVoxelOptimization;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Generate sprites from voxels';
  pmi.cmd := 'r_generatespritesfromvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_generatespritesfromvoxels;
  pmi.alphaKey := 'g';
  {$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsDef
  OptionsDisplayOpenGLVoxelsDef.numitems := Ord(optglvoxels_end); // # of menu items
  OptionsDisplayOpenGLVoxelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLVoxelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLVoxelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLVoxelsMenu);  // menu items
  OptionsDisplayOpenGLVoxelsDef.drawproc := @M_DrawOptionsDisplayOpenGLVoxels;  // draw routine
  OptionsDisplayOpenGLVoxelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLVoxelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLVoxelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLVoxelsDef.itemheight := LINEHEIGHT2;
  OptionsDisplayOpenGLVoxelsDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterMenu
  pmi := @OptionsDisplayOpenGLFilterMenu[0];
  pmi.status := 1;
  pmi.name := '!Filter';
  pmi.cmd := '';
  pmi.routine := @M_ChangeTextureFiltering;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Anisotropic texture filtering';
  pmi.cmd := 'gl_texture_filter_anisotropic';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_texture_filter_anisotropic;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Linear HUD filtering';
  pmi.cmd := 'gl_linear_hud';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_linear_hud;
  pmi.alphaKey := 'l';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterDef
  OptionsDisplayOpenGLFilterDef.numitems := Ord(optglfilter_end); // # of menu items
  OptionsDisplayOpenGLFilterDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLFilterDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLFilterDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLFilterMenu);  // menu items
  OptionsDisplayOpenGLFilterDef.drawproc := @M_DrawOptionsDisplayOpenGLFilter;  // draw routine
  OptionsDisplayOpenGLFilterDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLFilterDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLFilterDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLFilterDef.itemheight := LINEHEIGHT2;
  OptionsDisplayOpenGLFilterDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//ReadMenu1
  pmi := @ReadMenu1[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis2;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef1
  ReadDef1.numitems := Ord(read1_end); // # of menu items
  ReadDef1.prevMenu := @MainDef; // previous menu
  ReadDef1.menuitems := Pmenuitem_tArray(@ReadMenu1);  // menu items
  ReadDef1.drawproc := @M_DrawReadThis1;  // draw routine
  ReadDef1.x := 330;
  ReadDef1.y := 165; // x,y of menu
  ReadDef1.lastOn := 0; // last item user was on in menu
  ReadDef1.itemheight := LINEHEIGHT;
  ReadDef1.texturebk := false;

////////////////////////////////////////////////////////////////////////////////
//ReadMenu2
  pmi := @ReadMenu2[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef2
  ReadDef2.numitems := Ord(read2_end); // # of menu items
  ReadDef2.prevMenu := @ReadDef1; // previous menu
  ReadDef2.menuitems := Pmenuitem_tArray(@ReadMenu2);  // menu items
  ReadDef2.drawproc := @M_DrawReadThis2;  // draw routine
  ReadDef2.x := 330;
  ReadDef2.y := 165; // x,y of menu
  ReadDef2.lastOn := 0; // last item user was on in menu
  ReadDef2.itemheight := LINEHEIGHT;
  ReadDef2.texturebk := false;

// JVAL 20200122 - Extended help screens
////////////////////////////////////////////////////////////////////////////////
//ReadMenuExt
  pmi := @ReadMenuExt[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadExtThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDefExt
  ReadDefExt.numitems := Ord(readext_end); // # of menu items
  ReadDefExt.prevMenu := @ReadDef2; // previous menu
  ReadDefExt.menuitems := Pmenuitem_tArray(@ReadMenuExt);  // menu items
  ReadDefExt.drawproc := @M_DrawReadThisExt;  // draw routine
  ReadDefExt.x := 330;
  ReadDefExt.y := 165; // x,y of menu
  ReadDefExt.lastOn := 0; // last item user was on in menu
  ReadDefExt.itemheight := LINEHEIGHT;
  ReadDefExt.texturebk := false;

////////////////////////////////////////////////////////////////////////////////
//SoundMenu
  pmi := @SoundMenu[0];
  pmi.status := 1;
  pmi.name := '!Volume Control...';
  pmi.cmd := '';
  pmi.routine := @M_SoundVolume;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external MP3 files';
  pmi.cmd := 'usemp3';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemp3;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search MP3 paths in PK3';
  pmi.cmd := 'preferemp3namesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferemp3namesingamedirectory;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external WAV files';
  pmi.cmd := 'useexternalwav';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternalwav;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search WAV paths in PK3';
  pmi.cmd := 'preferewavnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferewavnamesingamedirectory;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SoundDef
  SoundDef.numitems := Ord(sound_end); // # of menu items
  SoundDef.prevMenu := @OptionsDef; // previous menu
  SoundDef.leftMenu := @OptionsDisplayDef; // left menu
  SoundDef.rightMenu := @CompatibilityDef; // left menu
  SoundDef.menuitems := Pmenuitem_tArray(@SoundMenu);  // menu items
  SoundDef.drawproc := @M_DrawSound;  // draw routine
  SoundDef.x := DEF_MENU_ITEMS_START_X;
  SoundDef.y := DEF_MENU_ITEMS_START_Y;
  SoundDef.lastOn := 0; // last item user was on in menu
  SoundDef.itemheight := LINEHEIGHT2;
  SoundDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//SoundVolMenu
  pmi := @SoundVolMenu[0];
  pmi.status := 2;
  pmi.name := '!Sound FX Volume';
  pmi.cmd := '';
  pmi.routine := @M_SfxVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Music Volume';
  pmi.cmd := '';
  pmi.routine := @M_MusicVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SoundVolDef
  SoundVolDef.numitems := Ord(soundvol_end); // # of menu items
  SoundVolDef.prevMenu := @SoundDef; // previous menu
  SoundVolDef.leftMenu := @SoundDef; // previous menu
  SoundVolDef.menuitems := Pmenuitem_tArray(@SoundVolMenu);  // menu items
  SoundVolDef.drawproc := @M_DrawSoundVol;  // draw routine
  SoundVolDef.x := DEF_MENU_ITEMS_START_X;
  SoundVolDef.y := DEF_MENU_ITEMS_START_Y;
  SoundVolDef.lastOn := 0; // last item user was on in menu
  SoundVolDef.itemheight := LINEHEIGHT2;
  SoundVolDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//CompatibilityMenu
  pmi := @CompatibilityMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow player jumps';
  pmi.cmd := 'allowplayerjumps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerjumps;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow player breath';
  pmi.cmd := 'allowplayerbreath';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerbreath;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Keep cheats when reborn';
  pmi.cmd := 'keepcheatsinplayerreborn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @keepcheatsinplayerreborn;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Boss death ends Doom1 level';
  pmi.cmd := 'majorbossdeathendsdoom1level';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @majorbossdeathendsdoom1level;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Spawn random monsters';
  pmi.cmd := 'spawnrandommonsters';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @spawnrandommonsters;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Splashes on special terrains';
  pmi.cmd := 'allowterrainsplashes';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowterrainsplashes;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Monsters fight after player death';
  pmi.cmd := 'continueafterplayerdeath';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @continueafterplayerdeath;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Dogs (Marine Best Friend)';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDogs;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';


////////////////////////////////////////////////////////////////////////////////
//CompatibilityDef
  CompatibilityDef.numitems := Ord(cmp_end); // # of menu items
  CompatibilityDef.prevMenu := @OptionsDef; // previous menu
  CompatibilityDef.leftMenu := @SoundDef; // left menu
  CompatibilityDef.rightMenu := @ControlsDef; // right menu
  CompatibilityDef.menuitems := Pmenuitem_tArray(@CompatibilityMenu);  // menu items
  CompatibilityDef.drawproc := @M_DrawCompatibility;  // draw routine
  CompatibilityDef.x := DEF_MENU_ITEMS_START_X;
  CompatibilityDef.y := DEF_MENU_ITEMS_START_Y;
  CompatibilityDef.lastOn := 0; // last item user was on in menu
  CompatibilityDef.itemheight := LINEHEIGHT2;
  CompatibilityDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//ControlsMenu
  pmi := @ControlsMenu[0];
  pmi.status := 1;
  pmi.name := '!Use mouse';
  pmi.cmd := 'use_mouse';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemouse;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse up/down look';
  pmi.cmd := 'invertmouselook';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouselook;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse turn left/right';
  pmi.cmd := 'invertmouseturn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouseturn;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Mouse sensitivity...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use joystic';
  pmi.cmd := 'use_joystick';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usejoystick;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Always run';
  pmi.cmd := 'autorunmode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autorunmode;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_SwitchKeyboardMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'k';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Key bindings...';
  pmi.cmd := '';
  pmi.routine := @M_KeyBindings;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

////////////////////////////////////////////////////////////////////////////////
//ControlsDef
  ControlsDef.numitems := Ord(ctrl_end); // # of menu items
  ControlsDef.prevMenu := @OptionsDef; // previous menu
  ControlsDef.leftMenu := @CompatibilityDef; // left menu
  ControlsDef.rightMenu := @SystemDef; // left menu
  ControlsDef.menuitems := Pmenuitem_tArray(@ControlsMenu);  // menu items
  ControlsDef.drawproc := @M_DrawControls;  // draw routine
  ControlsDef.x := DEF_MENU_ITEMS_START_X;
  ControlsDef.y := DEF_MENU_ITEMS_START_Y;
  ControlsDef.lastOn := 0; // last item user was on in menu
  ControlsDef.itemheight := LINEHEIGHT2;
  ControlsDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//SensitivityMenu
  pmi := @SensitivityMenu[0];
  pmi.status := 2;
  pmi.name := '!Global sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!X Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityX;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Y Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SensitivityDef
  SensitivityDef.numitems := Ord(sens_end); // # of menu items
  SensitivityDef.prevMenu := @ControlsDef; // previous menu
  SensitivityDef.menuitems := Pmenuitem_tArray(@SensitivityMenu);  // menu items
  SensitivityDef.drawproc := @M_DrawSensitivity;  // draw routine
  SensitivityDef.x := DEF_MENU_ITEMS_START_X;
  SensitivityDef.y := DEF_MENU_ITEMS_START_Y;
  SensitivityDef.lastOn := 0; // last item user was on in menu
  SensitivityDef.itemheight := LINEHEIGHT2;
  SensitivityDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//SystemMenu
  pmi := @SystemMenu[0];
  pmi.status := 1;
  pmi.name := '!Safe mode';
  pmi.cmd := 'safemode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @safemode;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use mmx/AMD 3D-Now';
  pmi.cmd := 'mmx';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemmx;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Time critical CPU priority';
  pmi.cmd := 'criticalcpupriority';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @criticalcpupriority;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Multithreading functions';
  pmi.cmd := 'usemultithread';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemultithread;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Screenshot format';
  pmi.cmd := '';
  pmi.routine := @M_ScreenShotCmd;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SystemDef
  SystemDef.numitems := Ord(sys_end); // # of menu items
  SystemDef.prevMenu := @OptionsDef; // previous menu
  SystemDef.leftMenu := @ControlsDef; // left menu
  SystemDef.rightMenu := @OptionsGeneralDef;  // right menu
  SystemDef.menuitems := Pmenuitem_tArray(@SystemMenu);  // menu items
  SystemDef.drawproc := @M_DrawSystem;  // draw routine
  SystemDef.x := DEF_MENU_ITEMS_START_X;
  SystemDef.y := DEF_MENU_ITEMS_START_Y;
  SystemDef.lastOn := 0; // last item user was on in menu
  SystemDef.itemheight := LINEHEIGHT2;
  SystemDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu1
  pmi := @KeyBindingsMenu1[0];
  for i := 0 to Ord(kb_weapon0) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect1;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef1
  KeyBindingsDef1.numitems := Ord(kb_weapon0); // # of menu items
  KeyBindingsDef1.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef1.leftMenu := @KeyBindingsDef2; // left menu
  KeyBindingsDef1.rightMenu := @KeyBindingsDef2; // right menu
  KeyBindingsDef1.menuitems := Pmenuitem_tArray(@KeyBindingsMenu1);  // menu items
  KeyBindingsDef1.drawproc := @M_DrawBindings1;  // draw routine
  KeyBindingsDef1.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef1.y := DEF_MENU_ITEMS_START_Y;
  KeyBindingsDef1.lastOn := 0; // last item user was on in menu
  KeyBindingsDef1.itemheight := LINEHEIGHT2;
  KeyBindingsDef1.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu2
  pmi := @KeyBindingsMenu2[0];
  for i := 0 to Ord(kb_end) - Ord(kb_weapon0) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect2;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef2
  KeyBindingsDef2.numitems := Ord(kb_end) - Ord(kb_weapon0); // # of menu items
  KeyBindingsDef2.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef2.leftMenu := @KeyBindingsDef1; // left menu
  KeyBindingsDef2.rightMenu := @KeyBindingsDef1; // right menu
  KeyBindingsDef2.menuitems := Pmenuitem_tArray(@KeyBindingsMenu2);  // menu items
  KeyBindingsDef2.drawproc := @M_DrawBindings2;  // draw routine
  KeyBindingsDef2.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef2.y := DEF_MENU_ITEMS_START_Y;
  KeyBindingsDef2.lastOn := 0; // last item user was on in menu
  KeyBindingsDef2.itemheight := LINEHEIGHT2;
  KeyBindingsDef2.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//LoadMenu
  pmi := @LoadMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_LoadSelect;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//LoadDef
  LoadDef.numitems := Ord(load_end); // # of menu items
  LoadDef.prevMenu := @MainDef; // previous menu
  LoadDef.menuitems := Pmenuitem_tArray(@LoadMenu);  // menu items
  LoadDef.drawproc := @M_DrawLoad;  // draw routine
  LoadDef.x := 40;
  LoadDef.y := 40;
  LoadDef.lastOn := 0; // last item user was on in menu
  LoadDef.itemheight := LINEHEIGHT;
  LoadDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
//SaveMenu
  pmi := @SaveMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_SaveSelect;
    pmi.alphaKey := Chr(Ord('1') + i);
    pmi.pBoolVal := nil;
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//SaveDef
  SaveDef.numitems := Ord(load_end); // # of menu items
  SaveDef.prevMenu := @MainDef; // previous menu
  SaveDef.menuitems := Pmenuitem_tArray(@SaveMenu);  // menu items
  SaveDef.drawproc := M_DrawSave;  // draw routine
  SaveDef.x := 40;
  SaveDef.y := 40;
  SaveDef.lastOn := 0; // last item user was on in menu
  SaveDef.itemheight := LINEHEIGHT;
  SaveDef.texturebk := true;

////////////////////////////////////////////////////////////////////////////////
  joywait := 0;
  mousewait := 0;
  mmousex := 0;
  mmousey := 0;
  mlastx := 0;
  mlasty := 0;

end;

end.

