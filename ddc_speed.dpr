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

{$IFDEF FPC}
{$Error: Use you must use Delphi to compile this project. Use Doom32f.dpr with FPC}
{$ENDIF}

{$IFNDEF DOOM}
{$Error: To compile this project you must define "DOOM"}
{$ENDIF}

{$IFNDEF DLL}
{$Error: To compile this project you must define "DLL"}
{$ENDIF}

{$IFNDEF ShareMM}
{$Error: To compile this project you must define "ShareMM"}
{$ENDIF}

{$I speed.inc}
{$D Speed}

library ddc_speed;

{$R *.RES}

uses
  FastMM4 in 'FASTMM4\FastMM4.pas',
  FastMM4Messages in 'FASTMM4\FastMM4Messages.pas',
  FastCode in 'FASTCODE\FastCode.pas',
  FastMove in 'FASTCODE\FastMove.pas',
  AnsiStringReplaceJOHIA32Unit12 in 'FASTCODE\AnsiStringReplaceJOHIA32Unit12.pas',
  AnsiStringReplaceJOHPASUnit12 in 'FASTCODE\AnsiStringReplaceJOHPASUnit12.pas',
  FastcodeAnsiStringReplaceUnit in 'FASTCODE\FastcodeAnsiStringReplaceUnit.pas',
  FastcodeCompareMemUnit in 'FASTCODE\FastcodeCompareMemUnit.pas',
  FastcodeCompareStrUnit in 'FASTCODE\FastcodeCompareStrUnit.pas',
  FastcodeCompareTextUnit in 'FASTCODE\FastcodeCompareTextUnit.pas',
  FastcodeCPUID in 'FASTCODE\FastcodeCPUID.pas',
  FastcodeFillCharUnit in 'FASTCODE\FastcodeFillCharUnit.pas',
  FastcodeLowerCaseUnit in 'FASTCODE\FastcodeLowerCaseUnit.pas',
  FastcodePatch in 'FASTCODE\FastcodePatch.pas',
  FastcodePosExUnit in 'FASTCODE\FastcodePosExUnit.pas',
  FastcodePosUnit in 'FASTCODE\FastcodePosUnit.pas',
  FastcodeStrCompUnit in 'FASTCODE\FastcodeStrCompUnit.pas',
  FastcodeStrCopyUnit in 'FASTCODE\FastcodeStrCopyUnit.pas',
  FastcodeStrICompUnit in 'FASTCODE\FastcodeStrICompUnit.pas',
  FastCodeStrLenUnit in 'FASTCODE\FastCodeStrLenUnit.pas',
  FastcodeStrToInt32Unit in 'FASTCODE\FastcodeStrToInt32Unit.pas',
  FastcodeUpperCaseUnit in 'FASTCODE\FastcodeUpperCaseUnit.pas',
  jpg_utils in 'JPEGLIB\jpg_utils.pas',
  jpg_comapi in 'JPEGLIB\jpg_comapi.pas',
  jpg_dapimin in 'JPEGLIB\jpg_dapimin.pas',
  jpg_dapistd in 'JPEGLIB\jpg_dapistd.pas',
  jpg_dcoefct in 'JPEGLIB\jpg_dcoefct.pas',
  jpg_dcolor in 'JPEGLIB\jpg_dcolor.pas',
  jpg_dct in 'JPEGLIB\jpg_dct.pas',
  jpg_ddctmgr in 'JPEGLIB\jpg_ddctmgr.pas',
  jpg_deferr in 'JPEGLIB\jpg_deferr.pas',
  jpg_dhuff in 'JPEGLIB\jpg_dhuff.pas',
  jpg_dinput in 'JPEGLIB\jpg_dinput.pas',
  jpg_dmainct in 'JPEGLIB\jpg_dmainct.pas',
  jpg_dmarker in 'JPEGLIB\jpg_dmarker.pas',
  jpg_dmaster in 'JPEGLIB\jpg_dmaster.pas',
  jpg_dmerge in 'JPEGLIB\jpg_dmerge.pas',
  jpg_dphuff in 'JPEGLIB\jpg_dphuff.pas',
  jpg_dpostct in 'JPEGLIB\jpg_dpostct.pas',
  jpg_dsample in 'JPEGLIB\jpg_dsample.pas',
  jpg_error in 'JPEGLIB\jpg_error.pas',
  jpg_idctasm in 'JPEGLIB\jpg_idctasm.pas',
  jpg_idctflt in 'JPEGLIB\jpg_idctflt.pas',
  jpg_idctfst in 'JPEGLIB\jpg_idctfst.pas',
  jpg_IDctRed in 'JPEGLIB\jpg_IDctRed.pas',
  jpg_lib in 'JPEGLIB\jpg_lib.pas',
  jpg_memmgr in 'JPEGLIB\jpg_memmgr.pas',
  jpg_memnobs in 'JPEGLIB\jpg_memnobs.pas',
  jpg_morecfg in 'JPEGLIB\jpg_morecfg.pas',
  jpg_quant1 in 'JPEGLIB\jpg_quant1.pas',
  jpg_quant2 in 'JPEGLIB\jpg_quant2.pas',
  mp3_SynthFilter in 'MP3LIB\mp3_SynthFilter.pas',
  mp3_Args in 'MP3LIB\mp3_Args.pas',
  mp3_BitReserve in 'MP3LIB\mp3_BitReserve.pas',
  mp3_BitStream in 'MP3LIB\mp3_BitStream.pas',
  mp3_CRC in 'MP3LIB\mp3_CRC.pas',
  mp3_Header in 'MP3LIB\mp3_Header.pas',
  mp3_Huffman in 'MP3LIB\mp3_Huffman.pas',
  mp3_InvMDT in 'MP3LIB\mp3_InvMDT.pas',
  mp3_L3Tables in 'MP3LIB\mp3_L3Tables.pas',
  mp3_L3Type in 'MP3LIB\mp3_L3Type.pas',
  mp3_Layer3 in 'MP3LIB\mp3_Layer3.pas',
  mp3_MPEGPlayer in 'MP3LIB\mp3_MPEGPlayer.pas',
  mp3_OBuffer in 'MP3LIB\mp3_OBuffer.pas',
  mp3_OBuffer_MCI in 'MP3LIB\mp3_OBuffer_MCI.pas',
  mp3_OBuffer_Wave in 'MP3LIB\mp3_OBuffer_Wave.pas',
  mp3_Player in 'MP3LIB\mp3_Player.pas',
  mp3_ScaleFac in 'MP3LIB\mp3_ScaleFac.pas',
  mp3_Shared in 'MP3LIB\mp3_Shared.pas',
  mp3_SubBand1 in 'MP3LIB\mp3_SubBand1.pas',
  mp3_SubBand2 in 'MP3LIB\mp3_SubBand2.pas',
  mp3_SubBand in 'MP3LIB\mp3_SubBand.pas',
  t_bmp in 'TEXLIB\t_bmp.pas',
  t_colors in 'TEXLIB\t_colors.pas',
  t_draw in 'TEXLIB\t_draw.pas',
  t_jpeg in 'TEXLIB\t_jpeg.pas',
  t_main in 'TEXLIB\t_main.pas',
  t_png in 'TEXLIB\t_png.pas',
  t_tga in 'TEXLIB\t_tga.pas',
  z_files in 'ZLIB\z_files.pas',
  DirectX in 'Common\DirectX.pas',
  am_map in 'Speed\am_map.pas',
  c_cmds in 'Base\c_cmds.pas',
  c_con in 'Base\c_con.pas',
  c_utils in 'Base\c_utils.pas',
  d_delphi in 'Common\d_delphi.pas',
  d_englsh in 'Speed\d_englsh.pas',
  d_event in 'Base\d_event.pas',
  d_fpc in 'Base\d_fpc.pas',
  d_items in 'Speed\d_items.pas',
  d_main in 'Speed\d_main.pas',
  d_net in 'Base\d_net.pas',
  d_net_h in 'Base\d_net_h.pas',
  d_player in 'Speed\d_player.pas',
  d_think in 'Base\d_think.pas',
  d_ticcmd in 'Base\d_ticcmd.pas',
  deh_main in 'Speed\deh_main.pas',
  doomdata in 'Speed\doomdata.pas',
  doomdef in 'Speed\doomdef.pas',
  doomstat in 'Speed\doomstat.pas',
  doomtype in 'Base\doomtype.pas',
  dstrings in 'Speed\dstrings.pas',
  f_finale in 'Speed\f_finale.pas',
  g_game in 'Speed\g_game.pas',
  hu_lib in 'Base\hu_lib.pas',
  hu_stuff in 'Speed\hu_stuff.pas',
  i_input in 'Base\i_input.pas',
  i_io in 'Base\i_io.pas',
  i_midi in 'Base\i_midi.pas',
  i_mp3 in 'Base\i_mp3.pas',
  i_music in 'Base\i_music.pas',
  i_net in 'Base\i_net.pas',
  i_sound in 'Base\i_sound.pas',
  i_system in 'Base\i_system.pas',
  i_displaymodes in 'Base\i_displaymodes.pas',
  info in 'Speed\info.pas',
  info_h in 'Speed\info_h.pas',
  info_rnd in 'Speed\info_rnd.pas',
  m_argv in 'Base\m_argv.pas',
  m_base in 'Base\m_base.pas',
  m_bbox in 'Base\m_bbox.pas',
  m_cheat in 'Base\m_cheat.pas',
  m_defs in 'Speed\m_defs.pas',
  m_fixed in 'Base\m_fixed.pas',
  m_menu in 'Speed\m_menu.pas',
  m_misc in 'Base\m_misc.pas',
  m_rnd in 'Base\m_rnd.pas',
  m_stack in 'Base\m_stack.pas',
  m_vectors in 'Base\m_vectors.pas',
  p_ceilng in 'Speed\p_ceilng.pas',
  p_doors in 'Speed\p_doors.pas',
  p_enemy in 'Speed\p_enemy.pas',
  p_extra in 'Speed\p_extra.pas',
  p_floor in 'Speed\p_floor.pas',
  p_genlin in 'Speed\p_genlin.pas',
  p_inter in 'Speed\p_inter.pas',
  p_lights in 'Speed\p_lights.pas',
  p_local in 'Speed\p_local.pas',
  p_map in 'Speed\p_map.pas',
  p_maputl in 'Speed\p_maputl.pas',
  p_mobj in 'Speed\p_mobj.pas',
  p_mobj_h in 'Speed\p_mobj_h.pas',
  p_plats in 'Speed\p_plats.pas',
  p_pspr in 'Speed\p_pspr.pas',
  p_pspr_h in 'Speed\p_pspr_h.pas',
  p_saveg in 'Speed\p_saveg.pas',
  p_scroll in 'Speed\p_scroll.pas',
  p_setup in 'Speed\p_setup.pas',
  p_sight in 'Speed\p_sight.pas',
  p_sounds in 'Speed\p_sounds.pas',
  p_spec in 'Speed\p_spec.pas',
  p_switch in 'Speed\p_switch.pas',
  p_telept in 'Speed\p_telept.pas',
  p_terrain in 'Speed\p_terrain.pas',
  p_tick in 'Speed\p_tick.pas',
  p_user in 'Speed\p_user.pas',
  r_bsp in 'Speed\r_bsp.pas',
  r_data in 'Speed\r_data.pas',
  r_defs in 'Speed\r_defs.pas',
  r_draw in 'Speed\r_draw.pas',
  r_hires in 'Base\r_hires.pas',
  r_intrpl in 'Base\r_intrpl.pas',
  r_lights in 'Base\r_lights.pas',
  r_dynlights in 'Base\r_dynlights.pas',
  r_main in 'Speed\r_main.pas',
  r_mmx in 'Base\r_mmx.pas',
  r_plane in 'Speed\r_plane.pas',
  r_sky in 'Speed\r_sky.pas',
  r_things in 'Base\r_things.pas',
  rtl_types in 'Base\rtl_types.pas',
  s_sound in 'Speed\s_sound.pas',
  sc_actordef in 'Base\sc_actordef.pas',
  sc_engine in 'Base\sc_engine.pas',
  sc_params in 'Base\sc_params.pas',
  sounds in 'Speed\sounds.pas',
  st_stuff in 'Speed\st_stuff.pas',
  tables in 'Base\tables.pas',
  v_data in 'Speed\v_data.pas',
  v_video in 'Base\v_video.pas',
  w_pak in 'Base\w_pak.pas',
  w_utils in 'Base\w_utils.pas',
  w_wad in 'Base\w_wad.pas',
  z_zone in 'Base\z_zone.pas',
  i_exec in 'Base\i_exec.pas',
  i_tmp in 'Base\i_tmp.pas',
  i_startup in 'Base\i_startup.pas' {StartUpConsoleForm},
  t_material in 'TEXLIB\t_material.pas',
  p_adjust in 'Base\p_adjust.pas',
  w_autoload in 'Base\w_autoload.pas',
  sc_tokens in 'Base\sc_tokens.pas',
  sc_states in 'Base\sc_states.pas',
  p_common in 'Base\p_common.pas',
  r_precalc in 'Base\r_precalc.pas',
  i_threads in 'Base\i_threads.pas',
  r_aspect in 'Base\r_aspect.pas',
  r_colormaps in 'Base\r_colormaps.pas',
  r_diher in 'Speed\r_diher.pas',
  z_memmgr in 'Base\z_memmgr.pas',
  vx_base in 'Base\vx_base.pas',
  info_fnd in 'Base\info_fnd.pas',
  m_crc32 in 'Base\m_crc32.pas',
  mt_utils in 'Base\mt_utils.pas',
  p_params in 'Base\p_params.pas',
  nd_main in 'Base\nd_main.pas',
  am_textured in 'Base\am_textured.pas',
  p_udmf in 'Base\p_udmf.pas',
  m_sshot_jpg in 'Base\m_sshot_jpg.pas',
  ps_main in 'SCRIPT\ps_main.pas',
  ps_import in 'SCRIPT\ps_import.pas',
  ps_compiler in 'SCRIPT\ps_compiler.pas',
  ps_runtime in 'SCRIPT\ps_runtime.pas',
  ps_utils in 'SCRIPT\ps_utils.pas',
  uPSC_dateutils in 'SCRIPT\uPSC_dateutils.pas',
  uPSC_dll in 'SCRIPT\uPSC_dll.pas',
  uPSR_dateutils in 'SCRIPT\uPSR_dateutils.pas',
  uPSR_dll in 'SCRIPT\uPSR_dll.pas',
  sc_thinker in 'Base\sc_thinker.pas',
  info_common in 'Base\info_common.pas',
  p_ladder in 'Base\p_ladder.pas',
  m_hash in 'Base\m_hash.pas',
  p_3dfloors in 'Base\p_3dfloors.pas',
  r_visplanes in 'Base\r_visplanes.pas',
  p_slopes in 'Base\p_slopes.pas',
  r_camera in 'Base\r_camera.pas',
  ps_proclist in 'SCRIPT\ps_proclist.pas',
  uPSPreProcessor in 'SCRIPT\uPSPreProcessor.pas',
  psi_system in 'SCRIPT\psi_system.pas',
  psi_globals in 'SCRIPT\psi_globals.pas',
  dd_compiler in 'SCRIPT\dd_compiler.pas',
  ddc_base in 'SCRIPT\ddc_base.pas',
  m_smartpointerlist in 'Base\m_smartpointerlist.pas',
  p_mobjlist in 'Base\p_mobjlist.pas',
  psi_game in 'SCRIPT\psi_game.pas',
  uPSDisassembly in 'SCRIPT\uPSDisassembly.pas',
  ps_events in 'SCRIPT\ps_events.pas',
  ps_serializer in 'SCRIPT\ps_serializer.pas',
  psi_overlay in 'SCRIPT\psi_overlay.pas',
  r_earthquake in 'Base\r_earthquake.pas',
  p_affectees in 'Base\p_affectees.pas',
  t_pcx in 'TEXLIB\t_pcx.pas',
  t_pcx4 in 'TEXLIB\t_pcx4.pas',
  ps_dll in 'SCRIPT\ps_dll.pas',
  ps_keywords in 'SCRIPT\ps_keywords.pas',
  ps_defs in 'SCRIPT\ps_defs.pas',
  p_gravity in 'Base\p_gravity.pas',
  t_patch in 'TEXLIB\t_patch.pas',
  p_bridge in 'Base\p_bridge.pas',
  w_sprite in 'Base\w_sprite.pas',
  i_steam in 'Base\i_steam.pas',
  d_notifications in 'Base\d_notifications.pas',
  sc_utils in 'Base\sc_utils.pas',
  w_folders in 'Base\w_folders.pas',
  r_subsectors in 'Base\r_subsectors.pas',
  r_renderstyle in 'Base\r_renderstyle.pas',
  vx_voxelsprite in 'Base\vx_voxelsprite.pas',
  w_wadwriter in 'Base\w_wadwriter.pas',
  m_sha1 in 'Base\m_sha1.pas',
  sc_evaluate_actor in 'Base\sc_evaluate_actor.pas',
  sc_evaluate in 'Base\sc_evaluate.pas',
  p_musinfo in 'Base\p_musinfo.pas',
  p_levelinfo in 'Base\p_levelinfo.pas',
  deh_base in 'Base\deh_base.pas',
  p_animdefs in 'Base\p_animdefs.pas',
  speed_alias in 'Speed\speed_alias.pas',
  speed_bitmap in 'Speed\speed_bitmap.pas',
  speed_defs in 'Speed\speed_defs.pas',
  speed_is2 in 'Speed\speed_is2.pas',
  speed_level in 'Speed\speed_level.pas',
  speed_palette in 'Speed\speed_palette.pas',
  speed_patch in 'Speed\speed_patch.pas',
  speed_sounds in 'Speed\speed_sounds.pas',
  speed_things in 'Speed\speed_things.pas',
  speed_xlat_wad in 'Speed\speed_xlat_wad.pas',
  speed_flatsize in 'Speed\speed_flatsize.pas',
  speed_cars in 'Speed\speed_cars.pas',
  speed_path in 'Speed\speed_path.pas',
  dglOpenGL in 'OPENGL\dglOpenGL.pas',
  gl_automap in 'OPENGL\gl_automap.pas',
  gl_clipper in 'OPENGL\gl_clipper.pas',
  gl_defs in 'OPENGL\gl_defs.pas',
  gl_frustum in 'OPENGL\gl_frustum.pas',
  gl_lightmaps in 'OPENGL\gl_lightmaps.pas',
  gl_lights in 'OPENGL\gl_lights.pas',
  gl_main in 'OPENGL\gl_main.pas',
  gl_misc in 'OPENGL\gl_misc.pas',
  gl_models in 'OPENGL\gl_models.pas',
  gl_render in 'OPENGL\gl_render.pas',
  gl_scrollingsky in 'OPENGL\gl_scrollingsky.pas',
  gl_shaders in 'OPENGL\gl_shaders.pas',
  gl_shadows in 'OPENGL\gl_shadows.pas',
  gl_slopes in 'OPENGL\gl_slopes.pas',
  gl_tex in 'OPENGL\gl_tex.pas',
  gl_types in 'OPENGL\gl_types.pas',
  gl_voxels in 'OPENGL\gl_voxels.pas',
  i3d_model in 'OPENGL\i3d_model.pas',
  i3d_palette in 'OPENGL\i3d_palette.pas',
  i3d_structs in 'OPENGL\i3d_structs.pas',
  i3d_textures in 'OPENGL\i3d_textures.pas',
  mdl_base in 'OPENGL\mdl_base.pas',
  mdl_ddmodel in 'OPENGL\mdl_ddmodel.pas',
  mdl_dllmodel in 'OPENGL\mdl_dllmodel.pas',
  mdl_i3d in 'OPENGL\mdl_i3d.pas',
  mdl_md2 in 'OPENGL\mdl_md2.pas',
  mdl_script in 'OPENGL\mdl_script.pas',
  mdl_script_functions in 'OPENGL\mdl_script_functions.pas',
  mdl_script_model in 'OPENGL\mdl_script_model.pas',
  mdl_script_proclist in 'OPENGL\mdl_script_proclist.pas',
  speed_actions in 'Speed\speed_actions.pas',
  speed_end_screen in 'Speed\speed_end_screen.pas',
  speed_font in 'Speed\speed_font.pas',
  speed_hud in 'Speed\speed_hud.pas',
  speed_intermission in 'Speed\speed_intermission.pas',
  speed_mapdata in 'Speed\speed_mapdata.pas',
  speed_particles in 'Speed\speed_particles.pas',
  speed_player in 'Speed\speed_player.pas',
  speed_race in 'Speed\speed_race.pas',
  speed_score in 'Speed\speed_score.pas',
  speed_score_draw in 'Speed\speed_score_draw.pas',
  speed_string_format in 'Speed\speed_string_format.pas',
  speed_wipe in 'Speed\speed_wipe.pas',
  i_itmusic in 'Base\i_itmusic.pas',
  i_mikplay in 'Base\i_mikplay.pas',
  i_modmusic in 'Base\i_modmusic.pas',
  i_s3mmusic in 'Base\i_s3mmusic.pas',
  i_xmmusic in 'Base\i_xmmusic.pas',
  libs3m in 'AUDIOLIB\libs3m.pas',
  c_lib in 'C_LIB\c_lib.pas',
  scanf in 'C_LIB\scanf.pas',
  scanf_c in 'C_LIB\scanf_c.pas',
  BTMemoryModule in 'Base\BTMemoryModule.pas',
  mikmod in 'Base\mikmod.pas',
  r_soft3d in 'Base\r_soft3d.pas',
  s_externalmusic in 'Base\s_externalmusic.pas',
  mn_drawmodel in 'Speed\mn_drawmodel.pas',
  mn_textwrite in 'Speed\mn_textwrite.pas',
  speed_maptexture in 'Speed\speed_maptexture.pas',
  speed_championship in 'Speed\speed_championship.pas',
  p_easyslope in 'Base\p_easyslope.pas',
  s_pk3sounds in 'Base\s_pk3sounds.pas';

exports
  dd_compile_speed,
  dd_getavailableunits_speed,
  dd_getunitfunctions_speed,
  dd_getconstants_speed,
  dd_getvariables_speed,
  dd_getclasses_speed,
  dd_getdisassembly_speed,
  dd_gettypes_speed,
  dd_getevents_speed,
  dd_getactordeffunctions_speed,
  dd_getmobjinfocsv_speed,
  dd_getstatescsv_speed,
  dd_getspritescsv_speed,
  dd_getactordef_speed;

begin

end.

