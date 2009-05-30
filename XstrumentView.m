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
	gluPerspective(60.0, baseRect.size.width/baseRect.size.height, 0.2, 32);
}


- (void)drawRect:(NSRect)rect
{
	int i=0;
	float radius = 2.0f;
	float theta = 0.0f;
	float lightX = 1;
	float xa=0.0f;
	float ya=0.0f;
	float xb=0.0f;
	float yb=0.0f;
	float xavg=0;
	float yavg=0;
    glClearColor(0.0f , 0.0f, 0.0f, 0.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	gluLookAt(
		radius*sin(theta), 0, radius*cos(theta), 
		0,0,0,
		0,1,0);
	GLfloat lightPosition[] = {lightX, 1, 3, 0.0};
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	//Render 3 dimensionally, so we can bump the UI when the user touches something
	//as feedback.
	glBegin(GL_LINE_STRIP);
	for(i=0; i<128; i++)
	{
		glColor3f(0.0f, 1, 0.0f);
		//This is the radius
		float startDistance = -(i)/16.0f;
		float stopDistance = -(i+1)/16.0f;
		
		float startAngle = (((M_PI*2)/12) * (i % 12));
		float stopAngle = (((M_PI*2)/12) * ((i + 1) % 12));

		
		xa = cos(startAngle);
		ya = -sin(startAngle);
		xb = cos(stopAngle);
		yb = -sin(stopAngle);
		xavg = (xa+xb)/2;
		yavg = (ya+yb)/2;
		glNormal3f(cos(xavg),-sin(yavg),0.0f);	
		glVertex3f(xa,ya, startDistance);
		glVertex3f(xb,yb, stopDistance);
	}
	glEnd();
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
	if([e isARepeat])
	{
		//Ignore repeats
	}
	else
	{
		[xmodel keyDownAt:mach_absolute_time() withKeys:[e characters]];
	}
}

- (void)keyUp:(NSEvent*)e
{
	[xmodel keyUpAt:mach_absolute_time() withKeys:[e characters]];
}




@end
