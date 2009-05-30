//
//  XtrumentSynth.h
//  Xstrument
//
//  Created by Robert Fielding on 5/29/09.
//  Copyright 2009 Check Point Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>


@interface XstrumentSynth : NSObject {
	MIDIPortRef gOutputPort;
	Byte midiBuffer[1024];

}
-(void) sendMIDIPacketCmd:(int)cmd andNote:(int)note andVol:(int)vol;
-(void) stopSound;
-(id) init;

@end
