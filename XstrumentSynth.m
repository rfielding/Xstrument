//
//  XtrumentSynth.m
//  Xstrument
//
//  Created by Robert Fielding on 5/29/09.
//  Copyright 2009 Check Point Software. All rights reserved.
/*
 Code originates from the MIDI echo example app for XCode Cocoa examples
 */
//

#import "XstrumentSynth.h"

@implementation XstrumentSynth
/**
 Do synthesizer setup
 */
- (id)init
{
	int i=0;
	int n=0;
	for(i=0;i<1024;i++)
	{
		midiBuffer[i] = 0x00;
	}
	gOutputPort = (MIDIPortRef)0;
	
	MIDIClientRef client = NULL;
	MIDIClientCreate(CFSTR("Midi Echo"),NULL,NULL,&client);
	if(client != NULL)
	{
		MIDIOutputPortCreate(client,CFSTR("Output Port"),&(gOutputPort));
		if(gOutputPort)
		{
			CFStringRef pname, pmanuf, pmodel;
			char name[64], manuf[64], model[64];
			n = MIDIGetNumberOfDevices();
			for (i = 0; i < n; ++i) {
				MIDIDeviceRef dev = MIDIGetDevice(i);
				MIDIObjectGetStringProperty(dev, kMIDIPropertyName, &pname);
				MIDIObjectGetStringProperty(dev, kMIDIPropertyManufacturer, &pmanuf);
				MIDIObjectGetStringProperty(dev, kMIDIPropertyModel, &pmodel);
				CFStringGetCString(pname, name, sizeof(name), 0);
				CFStringGetCString(pmanuf, manuf, sizeof(manuf), 0);
				CFStringGetCString(pmodel, model, sizeof(model), 0);
				CFRelease(pname);
				CFRelease(pmanuf);
				CFRelease(pmodel);
				printf("name=%s, manuf=%s, model=%s\n", name, manuf, model);
			}
		}
		else
		{
			printf("no output port created!\n");
		}
	}
	else
	{
		printf("no midi client created!\n");
	}
	return self;
}

/**
 Send 3 byte midi messages.  Usually interpreted as cmd/note/vol
 */
-(void) sendMIDIPacketCmd:(int)cmd andNote:(int)note andVol:(int)vol
{
	int i=0;
	MIDIPacketList* pktList = (MIDIPacketList*)midiBuffer;
	MIDIPacket* curPacket = MIDIPacketListInit(pktList);
	Byte noteOn[] = { cmd, note, vol};
	curPacket = MIDIPacketListAdd(
								  pktList, sizeof(midiBuffer), curPacket, 0, 3, noteOn
								  );
	ItemCount nDests = MIDIGetNumberOfDestinations();
	for(i=0;i<nDests;i++)
	{
		//printf("midiSend %d %d %d %d\n", i,cmd, note, vol);
		MIDIEndpointRef dest = MIDIGetDestination(i);
		MIDISend(gOutputPort, dest, pktList);
	}
}

/**
 Stop all sounds.  This is plenty fast.
 */
-(void)stopSound
{
	int i=0;
	for(i=0; i<128; i++)
	{
		[self sendMIDIPacketCmd:0x90 andNote:i andVol:0];
	}
}

@end