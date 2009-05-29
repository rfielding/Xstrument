//
//  XstrumentView.m
//  Xstrument
//
//  Created by Robert Fielding on 5/28/09.
//  Copyright 2009 Check Point Software. All rights reserved.
//

#import "XstrumentView.h"
#import <GLUT/glut.h>
#import <math.h>

@implementation XstrumentView

- (void)prepare
{
	NSLog(@"prepare");
	
	NSOpenGLContext* glcontext = [self openGLContext];
	[glcontext makeCurrentContext];
	
	glShadeModel(GL_SMOOTH);
	glEnable(GL_LIGHTING);
	glEnable(GL_DEPTH_TEST);
	
	GLfloat ambient[] = {0.2,0.2,0.2,1.0};
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,ambient);
	
	GLfloat diffuse[] = {1.0,1.0,1.0,1.0};
	glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuse);
	
	glEnable(GL_LIGHT0);
	
	GLfloat mat[] = {0.1, 0.1, 0.7, 1.0};
	glMaterialfv(GL_FRONT,GL_AMBIENT,mat);
	glMaterialfv(GL_FRONT,GL_DIFFUSE,mat);
	
	[self invalidateLoop];
	intervalCount = 0;
	intervalEstimate = 0;
	lastTime = mach_absolute_time();
	thisTime = mach_absolute_time();
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)c
{
	self = [super initWithCoder:c];
	[self prepare];
	return self;
}

- (void)reshape
{
	NSLog(@"reshaping");
	NSRect baseRect = [self convertRectToBase:[self bounds]];
	glViewport(0,0,baseRect.size.width, baseRect.size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60.0, baseRect.size.width/baseRect.size.height, 0.2, 7);
}


- (void)drawRect:(NSRect)rect
{
	float radius = 2.0f;
	float theta = 0.0f;
	float lightX = 1;
    glClearColor(0.2, 0.4, 0.1, 0.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	gluLookAt(
		radius*sin(theta), 0, radius*cos(theta), 
		0,0,0,
		0,1,0);
	GLfloat lightPosition[] = {lightX, 1, 3, 0.0};
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	if(!displayList)
	{
		displayList = glGenLists(1);
		glNewList(displayList,GL_COMPILE_AND_EXECUTE);
		glTranslatef(0,0,0);
		glutSolidTorus(0.3, 0.9, 35, 31);
		glTranslatef(0, 0, -1.2);
		glutSolidCone(1, 1, 17, 17);
		glEndList();
	}
	else
	{
		glCallList(displayList);
	}
	//Blink to estimated rhythm (distance between last keystrokes)
	if(intervalEstimate>0)
	{
		uint64_t now = mach_absolute_time();
		if((now/intervalEstimate) % 2)
		{
			glutSolidTorus(0.3, 1.8, 25, 31);
		}
	}
	glFinish();
}
 

- (void)awakeFromNib
{
	[self buildSynth];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)invalidateLoop
{
	[self setNeedsDisplay:YES];
	[self performSelector:@selector(invalidateLoop) withObject:self afterDelay:1/24.0];
}

- (void)intervalTick
{
	//Get a time diff;
	lastTime = thisTime;
	thisTime = mach_absolute_time();
	intervalCount++;
	if(intervalCount == 1)
	{
		intervalEstimate = thisTime - lastTime;
	}
	if(intervalCount > 1)
	{
		intervalEstimate = (intervalEstimate + (thisTime - lastTime))/2;
	}
}

- (void)keyDown:(NSEvent*)e
{
	int i=0;
	NSString* chars = [e characters];
	for(i=0; i < [chars length]; i++)
	{
		unichar k = [chars characterAtIndex:i];
		switch(k)
		{
			case '!': [self intervalTick];
				break;
			default:
				intervalCount = 0;
		}
	}
	[self sendMIDIPacketCmd:0x90 andNote:32 andVol:90];
}

- (void)keyUp:(NSEvent*)e
{
	[self sendMIDIPacketCmd:0x90 andNote:32 andVol:0];
}

/**
 Do synthesizer setup
 */
- (void)buildSynth
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
