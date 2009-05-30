//
//  XstrumentModel.m
//  Xstrument
//
/*
 The Samchillian is patented by Leon Gruenbaum. 
 I have gotten permission to make this application available for general consumption. 
 Refer to the original Samchillian 
 http://www.samchillian.com 
 if you have any questions about whether you need to be concerned about copyright
 or patent issues (such as if you have implemented something similar yourself). 
 Like the official Samchillian software, this is only for non commercial use, 
 which means that you have no right to sell this or modified copies of this 
 software without explicit permission.  
 */
/*
 The timeA/timeB pair specify a time interval that can be used for echo
 
 The tickA/tickB pair specify the last time MIDI messages were sent versus the current time.
 When determining what MIDI messages need to be sent, we iterate echoNote echoVol buffers from
 
     tickA < i <= tickB
 
 We play those notes as we iterate.  Then we zero out the notes that we have played while writing
 forward (at decreased volume and 1 interval away) any echoes we need to write.  We presume that
 the echo decreases at such a rate that a single note will never propagate all the way around the buffer.
 
 Presume for the moment that we only handle note down events.  
 */
//

#import "XstrumentModel.h"


@implementation XstrumentModel
-(id)init
{
	int i=0;
	
	timeA=0;
	timeB=0;
	tickA=0;
	tickB=0;
	timeCycled=0;
	timePlayed=0;
	
	chromaticLocation = CHROMATICNOTES*4;
	diatonicLocation = DIATONICNOTES*2;
	chromaticBase = DIATONICNOTES*2;
	//Make diatonic scale shape (minor based... not major based)
	for(i=0; i<2;i++)
	{
		scaleShape[0] = i*12 + 0;
		scaleShape[1] = i*12 + 2;
		scaleShape[2] = i*12 + 3;
		scaleShape[3] = i*12 + 5;
		scaleShape[4] = i*12 + 7;
		scaleShape[5] = i*12 + 9;
		scaleShape[6] = i*12 + 10;
	}
	scaleShape[DIATONICNOTES*2]=24;
	for(i=0;i<BEATBUFFER*TICKSPERBEAT;i++)
	{
		echoVol[i] = 0;
		echoNote[i] = 0;
	}
	for(i=0;i<1024;i++)
	{
		keyDownCount[i]=0;
		downKeyPlays[i]=0;
	}
	xsynth = [[XstrumentSynth alloc] init];
	return self;
}

-(void)tickAt:(uint64_t)now
{
}

-(BOOL)nextCycleAt:(uint64_t)now
{
	if(timeA < timeB)
	{
		if( (now-timeCycled)/(timeB-timeA) > 1)
		{
			timeCycled = now;
			return YES;
		}
	}
	return NO;
}

-(void)tickStartAt:(uint64_t)now
{
	timeA = now;
}

-(void)tickStopAt:(uint64_t)now
{
	timeB = now;
}

-(void)keyDownAt:(uint64_t)now withKeys:(NSString*)chars
{
	int i=0;
	int note=0;
	for(i=0; i<[chars length]; i++)
	{
		unichar c = [chars characterAtIndex:i];
		keyDownCount[c]++;
		switch(c)
		{
				
			//Chromatic relative rows
			case 'a':
			case ';':
				diatonicLocation+=4;
				break;
			case 's':
			case 'l':
				diatonicLocation+=3;
				break;
			case 'd':
			case 'k':
				diatonicLocation+=2;
				break;
			case 'f':
			case 'j':
				diatonicLocation+=1;
				break;
			case 'v':
			case 'm':
				diatonicLocation-=1;
				break;
			case 'c':
			case ',':
				diatonicLocation-=2;
				break;
			case 'x':
			case '.':
				diatonicLocation-=3;
				break;
			case 'z':
			case '/':
				diatonicLocation-=4;
				break;
				
		}
		//Just make sure we are alive
		chromaticLocation = scaleShape[(diatonicLocation%7)]+12*(diatonicLocation/7) + note;
		downKeyPlays[c] = chromaticLocation;
		[xsynth sendMIDIPacketCmd:0x90 andNote:chromaticLocation andVol:90];
	}
}

-(void)keyUpAt:(uint64_t)now withKeys:(NSString*)chars
{
	int i=0;
	int playedNote=0;
	for(i=0; i<[chars length]; i++)
	{
		unichar c = [chars characterAtIndex:i];
		keyDownCount[c]--;
		playedNote = downKeyPlays[c];
		[xsynth sendMIDIPacketCmd:0x90 andNote:playedNote andVol:0];
	}
}
@end
