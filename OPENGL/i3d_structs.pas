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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    I3D File Structs
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/speed-game/
//------------------------------------------------------------------------------

{$I speed.inc}

unit i3d_structs;

interface

uses
  d_delphi;

const
  ID3_MAGIC = $443342; // "B3D"

// ----------------------------- OBJECT3D.H ---------------------------
// For use with Watcom C.
// (C) Copyright 1995 by Jare & JCAB of Iguana.

// Definitive 3D object routines.

// ----------------------------- OBJECT3D.H ---------------------------
(*

    An object should be composed of:

        Detail? Or differently detailed objects shall be different objects?

        Vertices
        Normals
        Faces
            Normal
            Color
            Texture
            Vertices
                Normal
                Mapping

    Proposed structure: O3DF_ means disk data, O3DM_ means memory data.

    Skeleton file: were a value seems redundant, it will be used for
          consistency check, and won't appear in the binary version.
          This is especially true of the order numbers.

    Object "name"
    Vertices # Normals # Faces # FaceVertices # Materials #
    Flags 0x0000
    EndHeader
    Material # Color # Flags # Ambient # Diffuse # Reflected # Texture "tname"
     ...
    EndMaterials
    Vertex # X # Y # Z #
     ...
    EndVertices
    Normal # X # Y # Z #
     ...
    EndNormals
    Face # Vertices # Material # Flags # Array
        Vertex # Normal # TextureX # TextureY #
         ...
     ...
    EndFaces
*)

// -----------------------------------------
// Disk image of the object.

type
  vec3i_t = packed record
    x, y, z: integer;
  end;
  vec3i_p = ^vec3i_t;
  vec3i_tArray = packed array[0..$FFF] of vec3i_t;
  Pvec3i_tArray = ^vec3i_tArray;

  O3DF_TVertex = vec3i_t; // Pretty obvious.
  O3DF_TVertex_p = ^O3DF_TVertex;
  O3DF_TVertexArray = packed array[0..$FFF] of O3DF_TVertex;
  PO3DF_TVertexArray = ^O3DF_TVertexArray;
  O3DF_TNormal = vec3i_t;
  O3DF_TNormal_p = ^O3DF_TNormal;
  O3DF_TNormalArray = packed array[0..$FFF] of O3DF_TNormal;
  PO3DF_TNormalArray = ^O3DF_TNormalArray;

  O3DF_TFaceVertex = packed record
    nvert: smallint;  // 3D vertex index.
    nnorm: smallint;  // Normal vector at this vertex.
    tx, ty: integer;  // Texture values.
  end;
  O3DF_TFaceVertex_p = ^O3DF_TFaceVertex;
  O3DF_TFaceVertexArray = packed array[0..$FFF] of O3DF_TFaceVertex;
  PO3DF_TFaceVertexArray = ^O3DF_TFaceVertexArray;

  O3DF_TFaceHeader = packed record
    nVerts: word;
    material: smallint; // -1 => not visible.
    flags: LongWord;   // May indicate, for example, that it's a split.
    tox, toy, tsx, tsy, ta: integer;  // Texture data.
  end;
  O3DF_TFaceHeader_p = ^O3DF_TFaceHeader;
  O3DF_TFaceHeaderArray = packed array[0..$FFF] of O3DF_TFaceHeader;
  PO3DF_TFaceHeaderArray = ^O3DF_TFaceHeaderArray;

  O3DF_TFace = packed record
    h: O3DF_TFaceHeader;
  end;
  O3DF_TFace_p = ^O3DF_TFace;
  O3DF_TFaceArray = packed array[0..$FFF] of O3DF_TFace;
  PO3DF_TFaceArray = ^O3DF_TFaceArray;

  O3DF_TMaterial = packed record
    color: byte;
    flags: word;      // Semi-transparent? Translucid? etc.
    ambient: integer; // Lighting parameters.
    diffuse: integer;
    reflected: integer;
    texname: packed array[0..7] of char;  // Filename of the texture, or "" for flat.
  end;
  O3DF_TMaterial_p = ^O3DF_TMaterial;
  O3DF_TMaterialArray = packed array[0..$FFF] of O3DF_TMaterial;
  PO3DF_TMaterialArray = ^O3DF_TMaterialArray;

  O3DF_TObject = packed record
    nVerts: word;        // Are rotated and translated.
    nNormals: word;      // Are rotated, but not translated.
    nFaces: word;
    nFaceVerts: word;
    nMaterials: word;
    // Object loader can determine the amount of mem to alloc in a
    // single block, from the nXXX values above -> Less heap overhead.
    flags: word;
    scx, scy, scz: integer;     // Scale factors for the application to handle.
                                // Recommended format is 16.16.
                                // But note that they default to 0.
    dcx, dcy, dcz: integer;     // Center for the application to handle.
                                // Recommended format is: same as vertices
                                // *before* scaling.
  end;
  O3DF_TObject_p = ^O3DF_TObject;
  O3DF_TObjectArray = packed array[0..$FFF] of O3DF_TObject;
  PO3DF_TObjectArray = ^O3DF_TObjectArray;

// -----------------------------------------
// Memory image of the object.

type
  O3DM_TMaterial = packed record
    color: byte;
    texid: shortint; // JVAL: Hack :) - Take advantage of 2 byte ALIGN
    flags: word;          // Semi-transparent? Translucid? etc.
    ambient: integer;     // Lighting parameters.
    diffuse: integer; // was
    reflected: integer;
    texname: packed array[0..7] of char;  // Filename of the texture, or "" for flat.
    texture: PByteArray;  // Pointer to loaded texture mem.
  end;
  O3DM_TMaterial_p = ^O3DM_TMaterial;
  O3DM_TMaterialArray = packed array[0..$FFF] of O3DM_TMaterial;
  PO3DM_TMaterialArray = ^O3DM_TMaterialArray;

  O3DM_TVertex = packed record
    x, y, z: integer; // Pretty obvious.
    rx, ry, rz: integer;
    px, py: integer;
    l: integer;      // Calculated.
  end;
  O3DM_TVertex_p = ^O3DM_TVertex;
  O3DM_TVertexArray = packed array[0..$FFF] of O3DM_TVertex;
  PO3DM_TVertexArray = ^O3DM_TVertexArray;

  O3DM_TNormal = packed record
    x, y, z: integer; // Pretty obvious.
    rx, ry, rz: integer;
    l: integer;       // Calculated
  end;
  O3DM_TNormal_p = ^O3DM_TNormal;
  O3DM_TNormalArray = packed array[0..$FFF] of O3DM_TNormal;
  PO3DM_TNormalArray = ^O3DM_TNormalArray;

  O3DM_TFaceVertex = packed record
    vert: O3DM_TVertex_p;   // 3D vertex index.
    normal: O3DM_TNormal_p; // Normal vector at this vertex.
    l: integer;             // Calculated
    tx, ty: integer;        // Texture values.
  end;
  O3DM_TFaceVertex_p = ^O3DM_TFaceVertex;
  O3DM_TFaceVertexArray = packed array[0..$FFF] of O3DM_TFaceVertex;
  PO3DM_TFaceVertexArray = ^O3DM_TFaceVertexArray;
  O3DM_PFaceVertexArray = packed array[0..$FFF] of O3DM_TFaceVertex_p;
  PO3DM_PFaceVertexArray = ^O3DM_PFaceVertexArray;

  O3DM_TFace_p = ^O3DM_TFace;

  O3DM_TFaceHeader = packed record
    visible: wordbool;  // Calculated.
    nVerts: word;
    flags: LongWord;    // May indicate, for example, that it's a split.
    material: O3DM_TMaterial_p; // NULL => not to be drawn.
    tox, toy, tsx, tsy, ta: integer; // Texture data.
    back, front: O3DM_TFace_p;  // BSP links, or doubly linked list
                                // of regular faces in the BSP leaf.
    depth: integer;             // Calculated.
    next: O3DM_TFace_p;
  end;
  O3DM_TFaceHeader_p = ^O3DM_TFaceHeader;
  O3DM_TFaceHeaderArray = packed array[0..$FFF] of O3DM_TFaceHeader;
  PO3DM_TFaceHeaderArray = ^O3DM_TFaceHeaderArray;

  O3DM_TFace = packed record
    h: O3DM_TFaceHeader_p;
    verts: PO3DM_TFaceVertexArray;
  end;
  O3DM_TFaceArray = packed array[0..$FFF] of O3DM_TFace;
  PO3DM_TFaceArray = ^O3DM_TFaceArray;
  O3DM_PFaceArray = packed array[0..$FFF] of O3DM_TFace_p;
  PO3DM_PFaceArray = ^O3DM_PFaceArray;


  O3DM_TObject = packed record
    nVerts: word;        // Are rotated and translated.
    nNormals: word;      // Are rotated, but not translated.
    nFaces: word;
    nFaceVerts: word;
    nMaterials: word;
    // Object loader can determine the amount of mem to alloc in a
    // single block, from the nXXX values above -> Less heap overhead.
    flags: word;
    verts: PO3DM_TVertexArray;
    normals: PO3DM_TNormalArray;
    facecache: PByteArray;
    materials: PO3DM_TMaterialArray;
  end;
  O3DM_TObject_p = ^O3DM_TObject;
  O3DM_TObjectArray = packed array[0..$FFF] of O3DM_TObject;
  PO3DM_TObjectArray = ^O3DM_TObjectArray;

const
  // Material flags.
  O3DMF_NOSHADE = $0001;     // Don't apply any lightning.
  O3DMF_TRANS   = $0002;     // Translucent.
  O3DMF_HOLES   = $0004;     // Color 0 in the texture is transparent.
  O3DMF_256     = $0008;     // 256 wide bitmap

  // Face flags.
  O3DFF_FLAT    = $0001;     // Face is flat shaded (1st vertex' normal).
  O3DFF_NORDER  = $0002;     // Face should be rendered prior to the rest.
  O3DFF_VISIBLE = $0004;     // Should be though of as visible always.


const
  O3DD_FLAT = 0;
  O3DD_GOURAUD = 1;
  O3DD_TEXTURED = 2;
  O3DD_TEXLIGHT = 3;
  O3DD_TEXGOURAUD = 4;
  O3DD_MAXDETAIL = 5;

// ----------------------------- OBJECT3D.H ---------------------------

implementation

end.
