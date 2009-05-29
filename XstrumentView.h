//
//  XstrumentView.h
//  Xstrument
//
//  Created by Robert Fielding on 5/28/09.
//  Copyright 2009 Check Point Software. All rights reserved.
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
	int counter;
}
-(void) sendMIDIPacketCmd:(int)cmd andNote:(int)note andVol:(int)vol;
-(void) stopSound;
-(void) buildSynth;
-(void) invalidateLoop;
@end
