/*
 *  EchoBuffer.c
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/21/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */

#include "EchoBuffer.h"
#include "MidiPlatform.h"
#include <stdio.h>

struct echoBufferFrame
{
	int midiNote;
	int midiVolume;
	int nextInterval;
	int decay;
};

#define EBFRAMEMAX 1024
#define EBTRACKMAX 16
struct
{
	absmillis intervalStart;
	absmillis intervalStop;
	absmillis interval;
	int frame;
	struct echoBufferFrame frames[EBTRACKMAX][EBFRAMEMAX];
} echoBuffer;

void echoBuffer_init()
{
	int i=0;
	int j=0;
	echoBuffer.intervalStart = 0;
	echoBuffer.intervalStop = 0;
	echoBuffer.interval = 0;
	echoBuffer.frame = 0;
	for(i=0; i<EBTRACKMAX; i++)
	{
		for(j=0; j<EBFRAMEMAX; j++)
		{
			echoBuffer.frames[i][j].midiNote = -1;
			echoBuffer.frames[i][j].midiVolume = 0;
			echoBuffer.frames[i][j].nextInterval = 0;
			echoBuffer.frames[i][j].decay = 15;
		}
	}
}

void echoBuffer_setIntervalStart(absmillis start)
{
	echoBuffer.intervalStart = start;
	echoBuffer.interval = 0;
}

void echoBuffer_setIntervalStop(absmillis stop)
{
	echoBuffer.intervalStop = stop;
	echoBuffer.interval = echoBuffer.intervalStop = echoBuffer.intervalStart;
}


int frameFromAbsMillis(absmillis at)
{
	return (at/100000) % EBFRAMEMAX;
}

void echoBuffer_write(absmillis at,int note,int vol)
{
	//int frame = frameFromAbsMillis(at);
}

int echoBuffer_drain(absmillis at)
{
	echoBuffer.frame=1;
	//unsigned long frameIdxStop = frameFromAbsMillis(at);
	unsigned long frameIdxStop = 0;
	do
	{
		//printf("%uld %uld %uld\n",at,echoBuffer.frame,frameIdxStop);					

		echoBuffer.frame++;
		int nextFrame = echoBuffer.frame %= EBFRAMEMAX;
		if(nextFrame < echoBuffer.frame)
		{
			//midiPlatform_sendMidiPacket(0x90,24,0);
			midiPlatform_sendMidiPacket(0x90,24,90);
		}
		echoBuffer.frame = nextFrame;
	}while(echoBuffer.frame != frameIdxStop);

	return 0;
}
