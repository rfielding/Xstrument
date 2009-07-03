//
//  MusicTheory.m
//  RChill
//
//  Created by Robert Fielding on 1/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

//
//
//  Leon Gruenbaum has a patent on the Samchillian.  
//  This implementation was done with his permission.
//  Any derived works must have Leon's permission.
//
//  Samchillian instrument code goes here.  I stopped treating OpenGL as portable, as I can't run
//  it on Win32 under VMWare Fusion anyhow.
/*
  You may not sell and redistribute copies of this software, or sell derivatives of this software.
  Leon Gruenbaum holds copyrights on the Samchillian instrument, this implementation was made with his permission.
*/

#import <stdio.h>

#import "MusicTheory.h"
#import "MidiPlatform.h"

struct
{
	int lastNote;
	int previousNote;
	int scalePosition;
	int scale[15];
	int scaleBend[12];
	int sharps;
	int twist;
	int lastDistance;
	int downNotes[256];
	int downCounts[256];
	char* noteNames[15];
	int pitchWheel;
	int lastKey;
	int dirtyScale;
	int microTonal;
	int x;
	int y;
	int pentatonic;
	int sustain;
	int tremBend;
	int accBend;
} musicTheory;

void musicTheory_setXY(int xArg, int yArg)
{
	musicTheory.x = xArg;
	musicTheory.y = yArg;
}

int musicTheory_getX()
{
	return musicTheory.x;
}

int musicTheory_getY()
{
	return musicTheory.y;
}

void musicTheory_init()
{
	int i=0;
	musicTheory.lastNote=12*5;
	musicTheory.scalePosition=7*3;
	musicTheory.scale[0] = 0;
	musicTheory.scale[1] = 2;
	musicTheory.scale[2] = 3;
	musicTheory.scale[3] = 5;
	musicTheory.scale[4] = 7;
	musicTheory.scale[5] = 8;
	musicTheory.scale[6] = 10;
	musicTheory.scale[7] = 12;
	for(i=0;i<8;i++)
	{
		musicTheory.scale[i + 7] = 12 + musicTheory.scale[i];
	}
	for(i=0;i<12;i++)
	{
		musicTheory.scaleBend[i] = 0x2000;
	}
	musicTheory.scaleBend[3] += (0x2000>>2);
	musicTheory.scaleBend[8] += (0x2000>>2);
	
	musicTheory.microTonal=1;
	for(i=0;i<15;i++)
	{
		printf("%d ",musicTheory_scaleBend(i));
	}
	printf("\n");
	musicTheory.microTonal=0;
	
	musicTheory.sharps=3;
	musicTheory.lastDistance=0;
	musicTheory.twist=0;
	for(i=0;i<256;i++)
	{
		musicTheory.downNotes[i]=-1;
	}
	musicTheory.noteNames[0] = "C";
	musicTheory.noteNames[1] = "C#";
	musicTheory.noteNames[2] = "D";
	musicTheory.noteNames[3] = "D#";
	musicTheory.noteNames[4] = "E";
	musicTheory.noteNames[5]  = "F";
	musicTheory.noteNames[6] = "F#";
	musicTheory.noteNames[7] = "G";
	musicTheory.noteNames[8] = "G#";
	musicTheory.noteNames[9] = "A";
	musicTheory.noteNames[10] = "A#";
	musicTheory.noteNames[11] = "B";
	musicTheory.noteNames[12] = "C";
	musicTheory.pitchWheel = 0x0000;
	musicTheory.lastKey = 'a';
	musicTheory.dirtyScale = 1;
	musicTheory.microTonal = 0;
	musicTheory.x = 64;
	musicTheory.y = 127;
	musicTheory.pentatonic=0;
	musicTheory.sustain=0;
	musicTheory.tremBend=0;
	musicTheory.accBend=0;
	midiPlatform_init();
}

int musicTheory_dirtyScale()
{
	return musicTheory.dirtyScale;
}

void musicTheory_scaleUpdated()
{
	musicTheory.dirtyScale = 0;
}

void musicTheory_limitRange()
{
	while(musicTheory.lastNote >= 127)
	{
		musicTheory.lastNote -= 12;
		musicTheory.scalePosition -= 7;
	}
	while(musicTheory.lastNote < 0)
	{
		musicTheory.lastNote += 12;
		musicTheory.scalePosition += 7;
	}
}


int musicTheory_scaleBend(int n)
{
	int basis = (n+(5*musicTheory.sharps))%12;
	if(musicTheory.microTonal==1 && (basis==3 || basis==8))
	{
		return 0x2000 + (0x2000>>2);
	}
	if(musicTheory.microTonal==2 && (basis==7 || basis==2))
	{
		return 0x2000 - (0x2000>>2);
	}
	return 0x2000;
}

int musicTheory_pickNote(int n)
{
	int note=0;
	if(musicTheory.sharps<0)musicTheory.sharps+=7;
	if(n<0)
	{
		n+=7;
	}
	if(n>=127)
	{
		n-=7;
	}
	int octaveBase = 12*(n/7);
	int answer = octaveBase + musicTheory.scale[ (n%7 + (3*musicTheory.sharps)%7)] - (5*musicTheory.sharps)%12;
	if(musicTheory.pentatonic>0)
	{
		note = (n+3*musicTheory.sharps)%7;
		switch(musicTheory.twist)
		{
			case 0:
			switch(note)
			{
				case 1: answer++; break;
				case 2: answer+=2; break;
				case 3: answer++; break;
				case 5: answer+=2; break;
				case 6: answer+=2; break;
			}
			break;
			case 1:
			switch(note)
			{
				case 1: answer--; break;
				case 2: answer++; break;
				case 3: answer+=0; break;
				case 4: answer+=0; break;
				case 5: answer+=0; break;
				case 6: answer++; break;
			}
			break;
			case 2:
			switch(note)
			{
				case 1: answer--; break;
				case 2: answer++; break;
				case 3: answer+=1; break;
				case 4: answer+=0; break;
				case 5: answer+=0; break;
				case 6: answer++; break;
			}
			break;
		}
	}
	else
	{
		if(musicTheory.twist>0)
		{
			if(((n+3*musicTheory.sharps)%7) == 6)
			{
				answer++;
			}
			if(musicTheory.twist==2 && ((n+3*musicTheory.sharps)%7)==5)
			{
				answer++;
			}
		}
	}
	return answer;
}

void musicTheory_move(int distance)
{
	musicTheory.lastDistance = distance;
	musicTheory.scalePosition += distance;
	musicTheory.previousNote = musicTheory.lastNote;
	musicTheory.lastNote = musicTheory_pickNote(musicTheory.scalePosition);
	musicTheory_limitRange();
}

int musicTheory_findNearest(int n, int baseNote)
{
	if(n<0)
	{
		n+=7;
	}
	int diff = - ((n + 7 - baseNote + (3*musicTheory.sharps))%7);
	if(diff < -3)
	{
		diff +=7;
	}	
	return diff;
}

int musicTheory_scaleNote(int n)
{	
	return musicTheory.lastNote = musicTheory_pickNote(n);
}

int musicTheory_last()
{
	return musicTheory.lastDistance;
}

int musicTheory_prevNote()
{
	return musicTheory.previousNote;
}


int* musicTheory_notes()
{
	return (int*)musicTheory.downNotes;
}

int* musicTheory_downCounts()
{
	return (int*)musicTheory.downCounts;
}

int* musicTheory_scalePattern()
{
	return musicTheory.scale;
}

int musicTheory_wheelUp()
{
	musicTheory.pitchWheel +=0x0fff;
	return musicTheory.pitchWheel;
}

int musicTheory_wheelDown()
{
	musicTheory.pitchWheel -=0x0fff;
	return musicTheory.pitchWheel;
}

int musicTheory_down(int key)
{
	switch(key)
	{
		case 'z':
		case '/':
			musicTheory_wheelUp();
			return -1;
		case '\r':
			musicTheory_wheelDown();
			return -1;	
	}
	int realKey = key;
	int virtualJump = 0;
	if(key == ' ' || key == 'j')
	{
		key = musicTheory.lastKey;
	}
	else
	{
		musicTheory.lastKey = key;
	}
	int tryPosition=0;
	int distance=0;
	switch(key)
	{
		case 'd': 
		case 'n': 
			distance=1; break;
		case 'f':
		case 'h':
			distance=-1; break;
		case 'a':
		case '\'':
			distance=0; break;
		case 'o':  //Sorry... arpeggiation is important!
		case 's': distance=2; break;
		case 'r': distance=-3; break;
		case 'i': distance=3; break;
		case 'k': distance=-2; break;
		case 'c': distance=-7; break;
		case 'x': distance=-14; break;
		case ',': distance=7; break;
		case '.': distance=14; break;
		case 'p': distance=-4; break;
		case 'e': distance=4; break;
		case 'w': distance=5; break;
		case 'v': distance=-6; break;
		case 'm': distance=6; break;
//		case '|': 
//			musicTheory.microTonal = !musicTheory.microTonal; 
//			return -1;
			/*
		case 'g':
			musicTheory.y=0x60;
			return -1;
		case 't': 
			musicTheory.y-=0x10;
			if(musicTheory.y<0x10)
			{
				musicTheory.y=0x10;
			} 
			return -1;
			 
		case 'y': 
			musicTheory.y+=0x10;
			if(musicTheory.y>0x7F)
			{
				musicTheory.y=0x7F;
			} 
			return -1;
			 */
		case ';':
			distance = -5; break;
		case 't':
		case '[':
			musicTheory.sharps++; musicTheory.sharps%=12; 
			musicTheory.dirtyScale = 1;
			return -1;
		case 'y':
		case ']':
			musicTheory.sharps--; musicTheory.sharps+=12; musicTheory.sharps%=12; 
			musicTheory.dirtyScale = 1;
			return -1;
		case '\\':
			musicTheory.microTonal++;
			musicTheory.microTonal%=3;
			musicTheory.dirtyScale = 1;
			return -1;
		case 'g':
			musicTheory.dirtyScale = 1;
			musicTheory.twist++; musicTheory.twist%=2; return -1;
		case '|':
			musicTheory.dirtyScale = 1;
			musicTheory.pentatonic=!musicTheory.pentatonic; return -1;
		case 'u':
			tryPosition = musicTheory_pickNote(musicTheory.scalePosition+1);
			if(musicTheory.lastNote+1 < tryPosition)
			{
				musicTheory.lastNote++;
				musicTheory.downNotes[((unsigned int)realKey)%256] = musicTheory.lastNote;
				musicTheory_limitRange();
				musicTheory.downCounts[musicTheory.lastNote]++;
				return musicTheory.lastNote;
			}
			else
			{
				distance=1;
			}
			break;
		case 'l':
			tryPosition = musicTheory_pickNote(musicTheory.scalePosition - 1);
			if(musicTheory.lastNote-1 > tryPosition)
			{
				musicTheory.lastNote--;
				musicTheory.downNotes[((unsigned int)realKey)%256] = musicTheory.lastNote;
				musicTheory_limitRange();
				musicTheory.downCounts[musicTheory.lastNote]++;
				return musicTheory.lastNote;
			}
			else
			{
				distance=-1;
			}
			break;
		case 0x1B: //ESC
		case '`':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		case '0':
		case '-':
		case '=':
			if(0x1B == key)
			{
				virtualJump = 5;
			}
			else
			if('`' == key)
			{
				virtualJump = 6;
			}
			else
			if('1' <= key && key <= '9')
			{
				virtualJump = (key - '1');			
				if(virtualJump > 7)
				{
					virtualJump -= 7;
				}	
			}
			else
			if('0' == key)
			{
				virtualJump = 2;
			}
			else
			if('-' == key)
			{
				virtualJump = 3;
			}
			else
			if('=' == key)
			{
				virtualJump = 4;
			}
			distance = musicTheory_findNearest(musicTheory.scalePosition, virtualJump);
			break;
		default: printf("%d\n", key); return -1;
	}
	musicTheory_move(distance);
	musicTheory.downNotes[((unsigned int)realKey)%256] = musicTheory.lastNote;
	musicTheory.downCounts[musicTheory.lastNote]++;
	return musicTheory.lastNote;
}

int musicTheory_up(int key)
{
	switch(key)
	{	
		case '/':
		case 'z':
			musicTheory_wheelDown();
			return -1;
		case '\r':
			musicTheory_wheelUp();
			return -1;
	}
	int location = ((unsigned int)key)%256;
	int note = musicTheory.downNotes[location];
	musicTheory.downNotes[location] = -1;
	musicTheory.downCounts[note]--;
	if(musicTheory.downCounts[note]<0)
	{
		musicTheory.downCounts[note]=0;
	}
	return note;
}

int musicTheory_note()
{
	return musicTheory.lastNote;
}

int musicTheory_wheel()
{
	return musicTheory.pitchWheel;
}

int musicTheory_downCountOf(int n)
{
	return musicTheory.downCounts[n];
}

void musicTheory_clearAllDown()
{
	int i=0;
	for(i=0; i< 256; i++)
	{
		musicTheory.downCounts[i] = 0;
		musicTheory.downNotes[i] = -1;
	}
	musicTheory.pitchWheel = 0x0000;
}

char* musicTheory_findNoteName(int n)
{
	return musicTheory.noteNames[n];
}

int musicTheory_sharpCount()
{
	return musicTheory.sharps;
}

int musicTheory_downCount(int n)
{
	return musicTheory.downCounts[n];
}

void musicTheory_keyDown(int k)
{
	int note = musicTheory_down(k);
	
	if(k == '~')
	{
		musicTheory.sustain = !musicTheory.sustain;
	}
	
	if(k == 'q' || k=='Q')
	{
		if(k=='Q')
		{
			midiPlatform_stopSound();
		}
		else
		if(k== 'q')
		{
			musicTheory_clearAllDown();
		}
	}
	else
	{
		int vbend = musicTheory_wheel();
		int bend = musicTheory_scaleBend(note) + vbend + musicTheory.tremBend;
		midiPlatform_sendMidiPacket(0xE0, (bend)&0x7f, (bend>>7)&0x7f);
		if(note>=0)
		{
			int loud = musicTheory_getY();
			midiPlatform_sendMidiPacket(0x90,note,loud);
		}
	}
}

void musicTheory_keyUp(int k)
{
	int note = musicTheory_up(k);
	int vbend = musicTheory_wheel();
	int bend = 0x2000 + vbend + musicTheory.tremBend;
	midiPlatform_sendMidiPacket(0xE0, bend&0x7f, (bend>>7)&0x7f);
	if(note>=0)
	{
		if(!musicTheory.sustain && musicTheory_downCount(note)<=0)
		{
			midiPlatform_sendMidiPacket(0x90, note, 0x00);
		}
	}
}

void musicTheory_setTremBend(int tremBend)
{
	musicTheory.tremBend = tremBend;
}

void musicTheory_setAccBend(int accBend)
{
	musicTheory.accBend = accBend;
}

int musicTheory_getSustain()
{
	return musicTheory.sustain;
}
