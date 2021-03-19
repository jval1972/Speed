/*	MikMod sound library
	(c) 1998, 1999 Miodrag Vallat and others - see file AUTHORS for
	complete list.

	This library is free software; you can redistribute it and/or modify
	it under the terms of the GNU Library General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.
 
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Library General Public License for more details.
 
	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
	02111-1307, USA.
*/

/*==============================================================================

  $Id: mikmod_internals.h,v 1.12 1999/02/08 07:24:21 miod Exp $

  MikMod sound library internal definitions

  Edited by J�rg Mensmann ("|| defined(WIN32)" added)

==============================================================================*/

#ifndef _MIKMOD_INTERNALS_H
#define _MIKMOD_INTERNALS_H

#include <mikmod.h>

/*========== More type definitions */

#if defined(__alpha)
typedef long		SLONGLONG;	/* 8 bytes, signed */
#else
#if defined(__WATCOMC__) || defined(WIN32) /* jm */
typedef __int64		SLONGLONG;  /* 8 bytes, signed */
#else
typedef long long	SLONGLONG;  /* 8 bytes, signed */
#endif
#endif

/*========== Error handling */

#define _mm_errno MikMod_errno
#define _mm_critical MikMod_critical
extern MikMod_handler_t _mm_errorhandler;

/*========== Memory allocation */

extern void* _mm_malloc(size_t);
extern void* _mm_calloc(size_t,size_t);

/*========== Portable file I/O */

extern MREADER* _mm_new_file_reader(FILE* fp);
extern void _mm_delete_file_reader(MREADER*);

extern MWRITER* _mm_new_file_writer(FILE *fp);
extern void _mm_delete_file_writer(MWRITER*);

extern BOOL _mm_FileExists(CHAR *fname);

#define _mm_write_SBYTE(x,y) y->Put(y,(int)x)
#define _mm_write_UBYTE(x,y) y->Put(y,(int)x)

#define _mm_read_SBYTE(x) (SBYTE)x->Get(x)
#define _mm_read_UBYTE(x) (UBYTE)x->Get(x)

#define _mm_write_SBYTES(x,y,z) z->Write(z,(void *)x,y)
#define _mm_write_UBYTES(x,y,z) z->Write(z,(void *)x,y)
#define _mm_read_SBYTES(x,y,z)  z->Read(z,(void *)x,y)
#define _mm_read_UBYTES(x,y,z)  z->Read(z,(void *)x,y)

#define _mm_fseek(x,y,z) x->Seek(x,y,z)
#define _mm_ftell(x) x->Tell(x)
#define _mm_rewind(x) _mm_fseek(x,0,SEEK_SET)

#define _mm_eof(x) x->Eof(x)

extern void _mm_iobase_setcur(MREADER*);
extern void _mm_iobase_revert(void);
extern FILE *_mm_fopen(CHAR*,CHAR*);
extern void _mm_write_string(CHAR*,MWRITER*);
extern int  _mm_read_string (CHAR*,int,MREADER*);

extern SWORD _mm_read_M_SWORD(MREADER*);
extern SWORD _mm_read_I_SWORD(MREADER*);
extern UWORD _mm_read_M_UWORD(MREADER*);
extern UWORD _mm_read_I_UWORD(MREADER*);

extern SLONG _mm_read_M_SLONG(MREADER*);
extern SLONG _mm_read_I_SLONG(MREADER*);
extern ULONG _mm_read_M_ULONG(MREADER*);
extern ULONG _mm_read_I_ULONG(MREADER*);

extern int _mm_read_M_SWORDS(SWORD*,int,MREADER*);
extern int _mm_read_I_SWORDS(SWORD*,int,MREADER*);
extern int _mm_read_M_UWORDS(UWORD*,int,MREADER*);
extern int _mm_read_I_UWORDS(UWORD*,int,MREADER*);

extern int _mm_read_M_SLONGS(SLONG*,int,MREADER*);
extern int _mm_read_I_SLONGS(SLONG*,int,MREADER*);
extern int _mm_read_M_ULONGS(ULONG*,int,MREADER*);
extern int _mm_read_I_ULONGS(ULONG*,int,MREADER*);

extern void _mm_write_M_SWORD(SWORD,MWRITER*);
extern void _mm_write_I_SWORD(SWORD,MWRITER*);
extern void _mm_write_M_UWORD(UWORD,MWRITER*);
extern void _mm_write_I_UWORD(UWORD,MWRITER*);

extern void _mm_write_M_SLONG(SLONG,MWRITER*);
extern void _mm_write_I_SLONG(SLONG,MWRITER*);
extern void _mm_write_M_ULONG(ULONG,MWRITER*);
extern void _mm_write_I_ULONG(ULONG,MWRITER*);

extern void _mm_write_M_SWORDS(SWORD*,int,MWRITER*);
extern void _mm_write_I_SWORDS(SWORD*,int,MWRITER*);
extern void _mm_write_M_UWORDS(UWORD*,int,MWRITER*);
extern void _mm_write_I_UWORDS(UWORD*,int,MWRITER*);

extern void _mm_write_M_SLONGS(SLONG*,int,MWRITER*);
extern void _mm_write_I_SLONGS(SLONG*,int,MWRITER*);
extern void _mm_write_M_ULONGS(ULONG*,int,MWRITER*);
extern void _mm_write_I_ULONGS(ULONG*,int,MWRITER*);

/*========== Samples */

/* This is a handle of sorts attached to any sample registered with
   SL_RegisterSample.  Generally, this only need be used or changed by the
   loaders and drivers of mikmod. */
typedef struct SAMPLOAD {
	struct SAMPLOAD *next;

	ULONG    length;       /* length of sample (in samples!) */
	ULONG    loopstart;    /* repeat position (relative to start, in samples) */
	ULONG    loopend;      /* repeat end */
	UWORD    infmt,outfmt;
	int      scalefactor;
	SAMPLE*  sample;
	MREADER* reader;
} SAMPLOAD;

/*========== Sample and waves loading interface */

extern void      SL_HalveSample(SAMPLOAD*,int);
extern void      SL_Sample8to16(SAMPLOAD*);
extern void      SL_Sample16to8(SAMPLOAD*);
extern void      SL_SampleSigned(SAMPLOAD*);
extern void      SL_SampleUnsigned(SAMPLOAD*);
extern BOOL      SL_LoadSamples(void);
extern SAMPLOAD* SL_RegisterSample(SAMPLE*,int,MREADER*);
extern BOOL      SL_Load(void*,SAMPLOAD*,ULONG);
extern BOOL      SL_Init(SAMPLOAD*);
extern void      SL_Exit(SAMPLOAD*);

/*========== Internal module representation (UniMod) interface */

/* number of notes in an octave */
#define OCTAVE 12

/* The UniTrack stuff is generally for internal use only, but would be required
   in making a tracker or a module player that scrolls pattern data. */

extern void   UniSetRow(UBYTE*);
extern UBYTE  UniGetByte(void);
extern UBYTE* UniFindRow(UBYTE*,UWORD);
extern void   UniSkipOpcode(UBYTE);
extern void   UniReset(void);
extern void   UniWrite(UBYTE);
extern void   UniNewline(void);
extern UBYTE* UniDup(void);
extern BOOL   UniInit(void);
extern void   UniCleanup(void);
extern void   UniEffect(UWORD,UWORD);
#define UniInstrument(x) UniEffect(UNI_INSTRUMENT,x)
#define UniNote(x)       UniEffect(UNI_NOTE,x)
extern void   UniPTEffect(UBYTE,UBYTE);
extern void   UniVolEffect(UWORD,UBYTE);

/*========== Module Commands */

enum {
	/* Simple note */
	UNI_NOTE = 1,
	/* Instrument change */
	UNI_INSTRUMENT,
	/* Protracker effects */
	UNI_PTEFFECT0,
	UNI_PTEFFECT1,
	UNI_PTEFFECT2,
	UNI_PTEFFECT3,
	UNI_PTEFFECT4,
	UNI_PTEFFECT5,
	UNI_PTEFFECT6,
	UNI_PTEFFECT7,
	UNI_PTEFFECT8,
	UNI_PTEFFECT9,
	UNI_PTEFFECTA,
	UNI_PTEFFECTB,
	UNI_PTEFFECTC,
	UNI_PTEFFECTD,
	UNI_PTEFFECTE,
	UNI_PTEFFECTF,
	/* Scream Tracker effects */
	UNI_S3MEFFECTA,
	UNI_S3MEFFECTD,
	UNI_S3MEFFECTE,
	UNI_S3MEFFECTF,
	UNI_S3MEFFECTI,
	UNI_S3MEFFECTQ,
	UNI_S3MEFFECTR,
	UNI_S3MEFFECTT,
	UNI_S3MEFFECTU, 
	UNI_KEYOFF,
	UNI_KEYFADE,
	UNI_VOLEFFECTS,
	/* Fast Tracker effects */
	UNI_XMEFFECT4,
	UNI_XMEFFECTA,
	UNI_XMEFFECTE1,
	UNI_XMEFFECTE2,
	UNI_XMEFFECTEA,
	UNI_XMEFFECTEB,
	UNI_XMEFFECTG,
	UNI_XMEFFECTH,
	UNI_XMEFFECTL,
	UNI_XMEFFECTP,
	UNI_XMEFFECTX1,
	UNI_XMEFFECTX2,
	/* Impulse Tracker effects */
	UNI_ITEFFECTG,     /* Porta to Note .. no kick=0; */
	UNI_ITEFFECTH,     /* IT specific Vibrato */
	UNI_ITEFFECTI,     /* IT tremor (xy not incremented) */
	UNI_ITEFFECTM,     /* Set Channel Volume */
	UNI_ITEFFECTN,     /* Slide / Fineslide Channel Volume */
	UNI_ITEFFECTP,     /* Slide / Fineslide Channel Panning */
	UNI_ITEFFECTU,     /* IT fine vibrato */
	UNI_ITEFFECTW,     /* Slide / Fineslide Global volume */
	UNI_ITEFFECTY,     /* The Satanic Panbrello */
	UNI_ITEFFECTZ,     /* Resonant filters */
	UNI_ITEFFECTS0,
	/* UltraTracker effects */
	UNI_ULTEFFECT9,    /* Sample fine offset */
	/* OctaMED effects */
	UNI_MEDSPEED,
	UNI_MEDEFFECTF1,   /* play note twice */
	UNI_MEDEFFECTF2,   /* delay note */
	UNI_MEDEFFECTF3,   /* play note three times */

	UNI_LAST
};

extern UWORD unioperands[UNI_LAST];

/* IT / S3M Extended SS effects: */
enum {
	SS_GLISSANDO = 1,
	SS_FINETUNE,
	SS_VIBWAVE,
	SS_TREMWAVE,
	SS_PANWAVE,
	SS_FRAMEDELAY,
	SS_S7EFFECTS,
	SS_PANNING,
	SS_SURROUND,
	SS_HIOFFSET,
	SS_PATLOOP,
	SS_NOTECUT,
	SS_NOTEDELAY,
	SS_PATDELAY
};

/* IT Volume column effects */
enum {
	VOL_VOLUME = 1,
	VOL_PANNING,
	VOL_VOLSLIDE,
	VOL_PITCHSLIDEDN,
	VOL_PITCHSLIDEUP,
	VOL_PORTAMENTO,
	VOL_VIBRATO
};

/* IT resonant filter information */

#define FILT_CUT      0x80
#define FILT_RESONANT 0x81

typedef struct FILTER {
    UBYTE filter,inf;
} FILTER;

/*========== Instruments */

/* Instrument format flags */
#define IF_OWNPAN       1
#define IF_PITCHPAN     2

/* Envelope flags: */
#define EF_ON           1
#define EF_SUSTAIN      2
#define EF_LOOP         4
#define EF_VOLENV       8

/* New Note Action Flags */
#define NNA_CUT         0
#define NNA_CONTINUE    1
#define NNA_OFF         2
#define NNA_FADE        3

#define NNA_MASK        3

#define DCT_OFF         0
#define DCT_NOTE        1                         
#define DCT_SAMPLE      2                         
#define DCT_INST        3           

#define DCA_CUT         0
#define DCA_OFF         1
#define DCA_FADE        2

#define KEY_KICK        0
#define KEY_OFF         1
#define KEY_FADE        2
#define KEY_KILL        (KEY_OFF|KEY_FADE)

#define AV_IT           1   /* IT vs. XM vibrato info */

/*========== Playing */

#define POS_NONE        (-2) /* no loop position defined */

typedef struct ENVPR {
	UBYTE  flg;          /* envelope flag */
	UBYTE  pts;          /* number of envelope points */
	UBYTE  susbeg;       /* envelope sustain index begin */
	UBYTE  susend;       /* envelope sustain index end */
	UBYTE  beg;          /* envelope loop begin */
	UBYTE  end;          /* envelope loop end */
	SWORD  p;            /* current envelope counter */
	UWORD  a;            /* envelope index a */
	UWORD  b;            /* envelope index b */
	ENVPT* env;          /* envelope points */
} ENVPR;

typedef struct MP_CONTROL {
	INSTRUMENT* i;
	SAMPLE*     s;
	UBYTE       sample;       /* which sample number */
	UBYTE       note;         /* the audible note as heard, direct rep of period */
	SWORD       outvolume;    /* output volume (vol + sampcol + instvol) */
	SBYTE       chanvol;      /* channel's "global" volume */
	UWORD       fadevol;      /* fading volume rate */
	SWORD       panning;      /* panning position */
	UBYTE       kick;         /* if true = sample has to be restarted */
	UBYTE       muted;        /* if set, channel not played */
	UWORD       period;       /* period to play the sample at */
	UBYTE       nna;          /* New note action type + master/slave flags */
	UBYTE       prevnna;

	UBYTE       volflg;       /* volume envelope settings */
	UBYTE       panflg;       /* panning envelope settings */
	UBYTE       pitflg;       /* pitch envelope settings */

	UBYTE       keyoff;       /* if true = fade out and stuff */
	SWORD       handle;       /* which sample-handle */
	UBYTE       notedelay;    /* (used for note delay) */
	SLONG       start;        /* The starting byte index in the sample */

	UWORD		ultoffset;    /* fine sample offset memory */

struct MP_VOICE*slave;        /* Audio Slave of current effects control channel */
	UBYTE       slavechn;     /* Audio Slave of current effects control channel */
	UBYTE       anote;        /* the note that indexes the audible */
	UBYTE		oldnote;
	SWORD       ownper;
	SWORD       ownvol;
	UBYTE       dca;          /* duplicate check action */
	UBYTE       dct;          /* duplicate check type */
	UBYTE*      row;          /* row currently playing on this channel */
	SBYTE       retrig;       /* retrig value (0 means don't retrig) */
	ULONG       speed;        /* what finetune to use */
	SWORD       volume;       /* amiga volume (0 t/m 64) to play the sample at */

	SBYTE       tmpvolume;    /* tmp volume */
	UWORD       tmpperiod;    /* tmp period */
	UWORD       wantedperiod; /* period to slide to (with effect 3 or 5) */
	UBYTE       pansspd;      /* panslide speed */
	UWORD       slidespeed;   /* */
	UWORD       portspeed;    /* noteslide speed (toneportamento) */

	UBYTE       s3mtremor;    /* s3m tremor (effect I) counter */
	UBYTE       s3mtronof;    /* s3m tremor ontime/offtime */
	UBYTE       s3mvolslide;  /* last used volslide */
	SBYTE       sliding;
	UBYTE       s3mrtgspeed;  /* last used retrig speed */
	UBYTE       s3mrtgslide;  /* last used retrig slide */

	UBYTE       glissando;    /* glissando (0 means off) */
	UBYTE       wavecontrol;

	SBYTE       vibpos;       /* current vibrato position */
	UBYTE       vibspd;       /* "" speed */
	UBYTE       vibdepth;     /* "" depth */

	SBYTE       trmpos;       /* current tremolo position */
	UBYTE       trmspd;       /* "" speed */
	UBYTE       trmdepth;     /* "" depth */

	UBYTE       fslideupspd;
	UBYTE       fslidednspd;
	UBYTE       fportupspd;   /* fx E1 (extra fine portamento up) data */
	UBYTE       fportdnspd;   /* fx E2 (extra fine portamento dn) data */
	UBYTE       ffportupspd;  /* fx X1 (extra fine portamento up) data */
	UBYTE       ffportdnspd;  /* fx X2 (extra fine portamento dn) data */

	ULONG       hioffset;     /* last used high order of sample offset */
	UWORD       soffset;      /* last used low order of sample-offset (effect 9) */

	UBYTE       sseffect;     /* last used Sxx effect */
	UBYTE       ssdata;       /* last used Sxx data info */
	UBYTE       chanvolslide; /* last used channel volume slide */

	UBYTE       panbwave;     /* current panbrello waveform */
	UBYTE       panbpos;      /* current panbrello position */
	SBYTE       panbspd;      /* "" speed */
	UBYTE       panbdepth;    /* "" depth */

	UWORD       newsamp;      /* set to 1 upon a sample / inst change */
	UBYTE       voleffect;    /* Volume Column Effect Memory as used by IT */
	UBYTE       voldata;      /* Volume Column Data Memory */

	SWORD       pat_reppos;   /* patternloop position */
	UWORD       pat_repcnt;   /* times to loop */
} MP_CONTROL;

/* Used by NNA only player (audio control.  AUDTMP is used for full effects
   control). */
typedef struct MP_VOICE {
	INSTRUMENT* i;
	SAMPLE*     s;
	UBYTE       sample;       /* which instrument number */

	SWORD       volume;       /* output volume (vol + sampcol + instvol) */
	SWORD       panning;      /* panning position */
	SBYTE       chanvol;      /* channel's "global" volume */
	UWORD       fadevol;      /* fading volume rate */
	UWORD       period;       /* period to play the sample at */

	UBYTE       volflg;       /* volume envelope settings */
	UBYTE       panflg;       /* panning envelope settings */
	UBYTE       pitflg;       /* pitch envelope settings */

	UBYTE       keyoff;       /* if true = fade out and stuff */
	UBYTE       kick;         /* if true = sample has to be restarted */
	UBYTE       note;         /* the audible note (as heard, direct rep of period) */
	UBYTE       nna;          /* New note action type + master/slave flags */
	UBYTE       prevnna;
	SWORD       handle;       /* which sample-handle */
	SLONG       start;        /* The start byte index in the sample */

/* Below here is info NOT in MP_CONTROL!! */
	ENVPR       venv;
	ENVPR       penv;
	ENVPR       cenv;

	UWORD       avibpos;      /* autovibrato pos */
	UWORD       aswppos;      /* autovibrato sweep pos */

	ULONG       totalvol;     /* total volume of channel (before global mixings) */

	BOOL        mflag;
	SWORD       masterchn;
	UWORD       masterperiod;

	MP_CONTROL* master;       /* index of "master" effects channel */
} MP_VOICE;

/*========== Loaders */

typedef struct MLOADER {
struct MLOADER* next;
	CHAR*       type;
	CHAR*       version;
	BOOL        (*Init)(void);
	BOOL        (*Test)(void);
	BOOL        (*Load)(BOOL);
	void        (*Cleanup)(void);
	CHAR*       (*LoadTitle)(void);
} MLOADER;

/* internal loader variables: */
extern MREADER* modreader;
extern UWORD   finetune[16];
extern MODULE  of;                  /* static unimod loading space */
extern UWORD   npertab[7*OCTAVE];   /* used by the original MOD loaders */

extern SBYTE   remap[64];           /* for removing empty channels */
extern UBYTE*  poslookup;           /* lookup table for pattern jumps after
                                      blank pattern removal */
extern UBYTE   poslookupcnt;

extern BOOL    filters;             /* resonant filters in use */
extern UBYTE   activemacro;         /* active midi macro number for Sxx */
extern UBYTE   filtermacros[16];    /* midi macros settings */
extern FILTER  filtersettings[256]; /* computed filter settings */

extern int*    noteindex;

/*========== Internal loader interface */

extern BOOL   ReadComment(UWORD);
extern BOOL   ReadLinedComment(UWORD,UWORD);
extern BOOL   AllocPositions(int);
extern BOOL   AllocPatterns(void);
extern BOOL   AllocTracks(void);
extern BOOL   AllocInstruments(void);
extern BOOL   AllocSamples(void);
extern CHAR*  DupStr(CHAR*,UWORD,BOOL);

/* loader utility functions */
extern int*   AllocLinear(void);
extern void   FreeLinear(void);
extern int    speed_to_finetune(ULONG,int);
extern void   S3MIT_ProcessCmd(UBYTE,UBYTE,BOOL);

/* used to convert c4spd to linear XM periods (IT and IMF loaders). */
extern UWORD  getlinearperiod(UBYTE,ULONG);
extern ULONG  getfrequency(UBYTE,ULONG);

/*========== Player interface */

extern BOOL   Player_Init(MODULE*);
extern void   Player_Exit(MODULE*);
extern void   Player_HandleTick(void);

/*========== Drivers */

/* max. number of handles a driver has to provide. (not strict) */
#define MAXSAMPLEHANDLES 384

/* These variables can be changed at ANY time and results will be immediate */
extern UWORD md_bpm;         /* current song / hardware BPM rate */

/* Variables below can be changed via MD_SetNumVoices at any time. However, a
   call to MD_SetNumVoicess while the driver is active will cause the sound to
   skip slightly. */
extern UBYTE md_numchn;      /* number of song + sound effects voices */
extern UBYTE md_sngchn;      /* number of song voices */
extern UBYTE md_sfxchn;      /* number of sound effects voices */
extern UBYTE md_hardchn;     /* number of hardware mixed voices */
extern UBYTE md_softchn;     /* number of software mixed voices */

/* This is for use by the hardware drivers only.  It points to the registered
   tickhandler function. */
extern void (*md_player)(void);

extern SWORD  MD_SampleLoad(SAMPLOAD*,int);
extern void   MD_SampleUnload(SWORD);
extern ULONG  MD_SampleSpace(int);
extern ULONG  MD_SampleLength(int,SAMPLE*);

/*========== Virtual channel mixer interface */

extern BOOL  VC_Init(void);
extern void  VC_Exit(void);
extern BOOL  VC_SetNumVoices(void);
extern ULONG VC_SampleSpace(int);
extern ULONG VC_SampleLength(int,SAMPLE*);

extern BOOL  VC_PlayStart(void);
extern void  VC_PlayStop(void);

extern SWORD VC_SampleLoad(SAMPLOAD*,int);
extern void  VC_SampleUnload(SWORD);

extern ULONG VC_WriteBytes(SBYTE*,ULONG);
extern ULONG VC_SilenceBytes(SBYTE*,ULONG);

extern void  VC_VoiceSetVolume(UBYTE,UWORD);
extern void  VC_VoiceSetFrequency(UBYTE,ULONG);
extern void  VC_VoiceSetPanning(UBYTE,ULONG);
extern void  VC_VoicePlay(UBYTE,SWORD,ULONG,ULONG,ULONG,ULONG,UWORD);

extern void  VC_VoiceStop(UBYTE);
extern BOOL  VC_VoiceStopped(UBYTE);
extern SLONG VC_VoiceGetPosition(UBYTE);
extern ULONG VC_VoiceRealVolume(UBYTE);

#endif
