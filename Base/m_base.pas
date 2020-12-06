//------------------------------------------------------------------------------
//
//  DelphiDoom: A modified and improved DOOM engine for Windows
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2020 by Jim Valavanis
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
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_base;

interface

const
{$IFDEF DOOM}
  _GAME = 'Doom';
{$ENDIF}
{$IFDEF HERETIC}
  _GAME = 'Heretic';
{$ENDIF}
{$IFDEF HEXEN}
  _GAME = 'Hexen';
{$ENDIF}
{$IFDEF STRIFE}
  _GAME = 'Strife';
{$ENDIF}

  APPNAME = 'Delphi' + _GAME;
  DEFARGVFILENAME = _GAME + '32.cmd';
  WINCLASSNAME = _GAME + '32';


implementation

end.
