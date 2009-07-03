/*
 *  EchoBuffer.h
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/21/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */
#import "MidiPlatform.h"

//Absolute time in milliseconds
#define absmillis long

void echoBuffer_init();
void echoBuffer_setIntervalStart(absmillis start);
void echoBuffer_setIntervalStop(absmillis stop);
void echoBuffer_write(absmillis at,int note,int vol);
int echoBuffer_drain(absmillis at);

