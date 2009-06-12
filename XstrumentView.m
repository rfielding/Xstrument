//
//  XstrumentView.m
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
 
 OpenGL code started from The Hillengrass Cocoa book.
 */
//

#import "XstrumentView.h"
#import <math.h>
#include <mach/mach_time.h>
#include "PortableUI.h"


@implementation XstrumentView

- (void)prepare
{
	NSLog(@"prepare");
	
	NSOpenGLContext* glcontext = [self openGLContext];
	[glcontext makeCurrentContext];	
	portableui_init();
	
	//Only necessary when we are doing animation that is not in response to keys, such as timers
	//[self invalidateLoop];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {		
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
	portableui_reshape(baseRect.size.width, baseRect.size.height);
}


- (void)drawRect:(NSRect)rect
{
	portableui_repaint();
}
 

- (void)awakeFromNib
{
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)invalidateLoop
{
	[self intervalTick];
	[self performSelector:@selector(invalidateLoop) withObject:self afterDelay:1/24.0];
}

- (void)intervalTick
{
	//uint64_t now = mach_absolute_time();
	[self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent*)e
{
	if([e isARepeat])
	{
		//Ignore repeats
	}
	else
	{
		int i=0;
		NSString* chars = [e characters];
		for(i=0; i<[chars length]; i++)
		{
			unichar c = [chars characterAtIndex:i];
			musicTheory_keyDown(c);
		}		
	}
	[self setNeedsDisplay:YES];
}

- (void)keyUp:(NSEvent*)e
{
	int i=0;
	NSString* chars = [e characters];
	for(i=0; i<[chars length]; i++)
	{
		unichar c = [chars characterAtIndex:i];
		musicTheory_keyUp(c);
	}		
	[self setNeedsDisplay:YES];
}




@end
