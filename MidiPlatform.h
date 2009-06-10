/*
 *  MidiPlatform.h
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/9/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */

void midiPlatform_sendMidiPacket(int cmd, int note, int vol);
void midiPlatform_stopSound();
void midiPlatform_init();
