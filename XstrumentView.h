//
//  XstrumentView.h
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
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>
#include <mach/mach_time.h>


@interface XstrumentView : NSOpenGLView {
	int displayList;
	MIDIPortRef gOutputPort;
	Byte midiBuffer[1024];
	
	uint64_t lastTime;
	uint64_t thisTime;
	uint64_t intervalEstimate;
	int intervalCount;
}
-(void) sendMIDIPacketCmd:(int)cmd andNote:(int)note andVol:(int)vol;
-(void) stopSound;
-(void) buildSynth;
-(void) invalidateLoop;
-(void) intervalTick;
@end
