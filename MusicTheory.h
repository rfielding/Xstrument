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

void musicTheory_init();
void musicTheory_keyUp(int k);
void musicTheory_keyDown(int k);

int musicTheory_dirtyScale();
void musicTheory_scaleUpdated();
void musicTheory_setXY(int xArg, int yArg);
int* musicTheory_notes();
int musicTheory_wheel();
int musicTheory_pickNote(int n);
int musicTheory_sharpCount();
char* musicTheory_findNoteName(int n);
int musicTheory_downCount(int n);
int* musicTheory_downCounts();
int musicTheory_note();
int musicTheory_getX();
int musicTheory_getY();
int musicTheory_getSustain();






