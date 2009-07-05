//
//  MusicTheory.h
//  RChill
//
//  Created by Robert Fielding on 1/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
/*
  You may not sell and redistribute copies of this software, or sell derivatives of this software.
  Leon Gruenbaum holds copyrights on the Samchillian instrument, this implementation was made with his permission.
*/

#import "MidiPlatform.h"

#define QUARTERTONE 0x0800
#define HALFTONE    (QUARTERTONE*2)
#define FULLTONE    (HALFTONE*2)
#define CENTERTONE  FULLTONE
#define BENDRANGE   (2*FULLTONE)

/*
   The first thing that must be called
 */
void musicTheory_init();

/*
   These are invoked by the OS when keys are pressed and released.
   It is expeced that total up and down counts equal out to zero.
   We only support ASCII range at the moment.  A function in 
   MidiPlatform would have to define non-portable keycodes for us.
 */
void musicTheory_keyUp(int k);
void musicTheory_keyDown(int k);


/*
   The GUI queries this when it needs to know if the scale has changed.
   This way, most of the drawing can be put into a display list to minimize
   the amount of drawing that needs to be done.
   
   A boolean 0 or 1 value
 */
int musicTheory_dirtyScale();

/*
   We notify if we updated the scale, so that dirtyScale returns zero again
 */
void musicTheory_scaleUpdated();


/*
   Not used at the moment.  Was previously used for mouse hooks
 */
void musicTheory_setXY(int xArg, int yArg);


/*
        asciiIndex ->  [midiNote | -1]
 
   Index ascii code to note that is down for that key.
 
      asciiIndex in [0..255]
      midiNote in [0..127 | -1]  where -1 signifies no note for the key
 */
int* musicTheory_notes();

/*
   Within the current scale (usually diatonic...definitely 7 notes per scale), 
   pick the corresponding midiNote in [0..127]
 */
int musicTheory_pickNote(int n);

/*
   Get the current pitch wheel value, in which 0x2000 is the center value
 */
int musicTheory_wheel();

/*
   The current diatonic scale, how many sharps you have to add going down the circle of fifths
   to get this scale.  (ex: Am -> 0, Em -> 1, etc)
 */
int musicTheory_sharpCount();

/*
   Get a name for diatonic note n, in terms of sharps
 */
char* musicTheory_findNoteName(int n);

/*
   How many times is this note down?  We have multiple keys for the same note.  We want to track so
   that releasing one of multiple keys doesn't stop the note until they all come back up
 */
int musicTheory_downCount(int n);
int* musicTheory_downCounts();

/*
   Where are we currently located?  We need to draw this in the UI
 */
int musicTheory_note();

/*
   Not used now, but previously used for rendering mouse position
 */
int musicTheory_getX();
int musicTheory_getY();

/*
   Are we in sustain mode (where we don't turn notes off)?  boolean 0 or 1
 */
int musicTheory_getSustain();

int musicTheory_scaleBend(int note);


char* musicTheory_keyBuffer();

