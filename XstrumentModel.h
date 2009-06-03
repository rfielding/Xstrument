//
//  XstrumentModel.h
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
//

#import <Cocoa/Cocoa.h>
#import "XstrumentSynth.h"
#import <mach/mach_time.h>

#define CHROMATICNOTES 12
#define DIATONICNOTES 7
///30 seconds stored in one hundredths 
#define BEATBUFFER 100*60*5
#define TICKSPERBEAT 24
@interface XstrumentModel : NSObject {
	uint64_t timeA;
	uint64_t timeB;
	uint64_t timeCycled;
	uint64_t timePlayed;
	uint64_t tickA;
	uint64_t tickB;
    mach_timebase_info_data_t    timebaseInfo;
	
	int chromaticBase;
	int chromaticLocation;
	int diatonicLocation;
	
	//Large real-time (not ticks) buffer
	int echoVol[BEATBUFFER];
	int echoNote[BEATBUFFER];
	
	int keyDownCount[1024];
	int downKeyPlays[1024];
	int scaleShape[2*CHROMATICNOTES+1];	

	XstrumentSynth* xsynth;
}
-(id)initNow:(uint64_t)now;

/*
 Events such as nextCycleAt, keyDownAt, etc will signal tickAt to edit the MIDI buffer
 */
-(void)tickAt:(uint64_t)now;

/* Keep calling until it returns YES.  
   When it returns YES it won't do so until the next cycle. 
 */
-(BOOL)nextCycleAt:(uint64_t)now;

/*
   Note that the following keys went down at this time
 */
-(void)keyDownAt:(uint64_t)now withKeys:(NSString*)chars;

/*
 Note that the following keys went up at this time
 */
-(void)keyUpAt:(uint64_t)now withKeys:(NSString*)chars;

/* 
 The tickStart/tickStop pair determines a time interval over which nextCycle returns YES once 
 */
-(void)tickStartAt:(uint64_t)now;
-(void)tickStopAt:(uint64_t)now;

-(int*)downKeys;

-(void) playEchoedPacketNow:(uint64_t)now andCmd:(int)cmd andNote:(int)note andVol:(int)vol;

@end
