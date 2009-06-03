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
-(id)initNow:(uint64_t)now
{
	int i=0;
	timeA=0;
	timeB=0;
	tickA=0;
	tickB=0;
	timeCycled=now;
	timePlayed=now;

    mach_timebase_info(&timebaseInfo);
		
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
	//LAAARGE
	for(i=0;i<BEATBUFFER;i++)
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
	//play all echoed notes until we are caught up
	
	uint64_t stop = ((now * timebaseInfo.numer / (timebaseInfo.denom*10000000L)))%BEATBUFFER;
	uint64_t idx = ((timePlayed * timebaseInfo.numer / (timebaseInfo.denom*10000000L)))%BEATBUFFER;	
	while(idx != stop)
	{
		int vol = echoVol[idx];
		if(vol>0)
		{
			int note = echoNote[idx];
			[self playEchoedPacketNow:now andCmd:0x90 andNote:note andVol:vol];
		}
		echoVol[idx]=0;
		idx++;
		idx %= BEATBUFFER;
	}
	timePlayed = now;
}

//Use this to render hints to GUI to show when next cycle begins
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

//Set interval start
-(void)tickStartAt:(uint64_t)now
{
	timeA = now;
}

//Set interval stop
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
				
			case 'b':
				[self tickStartAt:now];
				break;
			case 'n':
				[self tickStopAt:now];
				break;
				
		}
		//Just make sure we are alive
		chromaticLocation = scaleShape[(diatonicLocation%7)]+12*(diatonicLocation/7) + note;
		downKeyPlays[c] = chromaticLocation;
		[self playEchoedPacketNow:now andCmd:0x90 andNote:chromaticLocation andVol:100];
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
		[self playEchoedPacketNow:now andCmd:0x90 andNote:playedNote andVol:0];
		downKeyPlays[c] = 0;
	}
}

-(int*)downKeys
{
	return downKeyPlays;
}

-(void) playEchoedPacketNow:(uint64_t)now andCmd:(int)cmd andNote:(int)note andVol:(int)vol;
{
	//Play the given note
	[xsynth sendMIDIPacketCmd:cmd andNote:note andVol:vol];
	uint64_t nowTime = ((now * timebaseInfo.numer / (timebaseInfo.denom*10000000L)))%BEATBUFFER;
	echoVol[nowTime] = 0;
	timePlayed = now;
	//Write a note one interval length out if applicable
	if(timeA < timeB && vol > 0)
	{
		uint64_t absolutePlayTime = now + timeB-timeA;
		uint64_t playTime = ((absolutePlayTime * timebaseInfo.numer / (timebaseInfo.denom*10000000L)))%BEATBUFFER;
		echoVol[playTime] = 2*vol/3;
		echoNote[playTime] = note;
	}
}
@end
