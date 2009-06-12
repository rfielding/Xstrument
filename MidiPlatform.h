/*
 *  MidiPlatform.h
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/9/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */

/*
   MIDI messages are three bytes, typically designated cmd,note,vol
   But the actual interpretation is determined by the MIDI spec.
   Google that.
 */
void midiPlatform_sendMidiPacket(int cmd, int note, int vol);

/*
   Send zero volume to EVERY note.  This is a shutup function.
 */
void midiPlatform_stopSound();

/*
   Initialize MIDI output for our platform
 */
void midiPlatform_init();
