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
 MIDI code started from Midi echo in the XCode examples.
 */
//

#import "XstrumentView.h"
#import "XstrumentModel.h"
#import <GLUT/glut.h>
#import <math.h>
#include <mach/mach_time.h>

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
	
	xmodel = [[XstrumentModel alloc] init];	
	[self invalidateLoop];
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
	glViewport(0,0,baseRect.size.width, baseRect.size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60.0, baseRect.size.width/baseRect.size.height, 0.2, 7);
}


- (void)drawRect:(NSRect)rect
{
	//Just show some junk on the screen now so that we can tell that timing
	//and MIDI and keyboard are all working
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
	/*
	if(timeA < timeB)
	{
		uint64_t now = mach_absolute_time();
		if((now/(timeB-timeA)) % 2)
		{
			glutSolidTorus(0.3, 1.8, 25, 31);
		}
	}
	 */
	glFinish();
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
	[xmodel tickAt:mach_absolute_time()];
	[self setNeedsDisplay:YES];
}

- (void)keyDown:(NSEvent*)e
{
	[xmodel keyDownAt:mach_absolute_time() withKeys:[e characters]];
}

- (void)keyUp:(NSEvent*)e
{
	[xmodel keyUpAt:mach_absolute_time() withKeys:[e characters]];
}




@end
