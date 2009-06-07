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
	
	GLfloat ambient[] = {0.8,0.7,0.8,1.0};
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,ambient);
	
	GLfloat diffuse[] = {0.9,0.99,0.999,1.0};
	glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuse);	
	glEnable(GL_LIGHT0);
	
	GLfloat mat[] = {0.2, 0.2, 0.2, 0.5};
	glMaterialfv(GL_FRONT,GL_AMBIENT,mat);
	glMaterialfv(GL_FRONT,GL_DIFFUSE,mat);
	
	xmodel = [[XstrumentModel alloc] initNow:mach_absolute_time()];	
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
	int downNote=0;
	//float radius = 2.0f;
	//float theta = 0.0f;
	float lightX = 1;
	float xa=0.0f;
	float ya=0.0f;
	float xb=0.0f;
	float yb=0.0f;
	float xavg=0;
	float yavg=0;
	float triX=0;
	float triY=0;
	float bumpX=0;
	float bumpY=0;
	float bumpZ=0;
	GLfloat matG[] = {0.2, 0.7, 0.2, 0.5};
	GLfloat matB[] = {0.2, 0.2, 0.7, 0.5};
	GLfloat matR[] = {1.0, 0.2, 0.2, 0.5};
	
	//float epsilon=0.00005;
	uint64_t now = mach_absolute_time();
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	for(i=0; i<128; i++)
	{
		downNote = [xmodel downKeys][i];
		if(downNote > 0)
		{
			bumpX+=0.01;
			bumpY+=0.01;
		}
	}
	if([xmodel nextCycleAt:now])
	{
		bumpZ+=0.05;
	}
	
	gluLookAt(
		bumpX, bumpY, 1+bumpZ, 
		0,0,0,
		0,1,0);
	
	GLfloat lightPosition[] = {lightX, 1, 1, -1.0};
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	glTranslatef(0,0,0);
    glClearColor(0.0f , 0.0f, 0.0f, 0.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	//Render 3 dimensionally, so we can bump the UI when the user touches something
	//as feedback.
	glMaterialfv(GL_FRONT,GL_AMBIENT,matG);
	glMaterialfv(GL_FRONT,GL_DIFFUSE,matG);
	glBegin(GL_LINE_STRIP);
	for(i=0; i<128; i++)
	{
		glColor3f(0.0f, 1.0f, 0.0f);
		//This is the radius
		float startDistance = (i)/8.0f -16;
		float stopDistance = (i+1)/8.0f -16;
		
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
	
	glMaterialfv(GL_FRONT,GL_AMBIENT,matB);
	glMaterialfv(GL_FRONT,GL_DIFFUSE,matB);
	glBegin(GL_LINES);
	for(i=0; i<12; i++)
	{
		if(i==0 || i==2 || i==3 || i==5 || i==7 || i==9 || i==10)
		{
			float startAngle = (((M_PI*2)/12) * (i % 12));
			float stopAngle = (((M_PI*2)/12) * ((i + 1) % 12));
			xb = cos(startAngle);
			yb = -sin(startAngle);
			glNormal3f(0,0,-1.0f);	
			glVertex3f(xb,yb, -16);
			glVertex3f(xb,yb, 0);
		}
	}
	glEnd();

	glMaterialfv(GL_FRONT,GL_AMBIENT,matR);
	glMaterialfv(GL_FRONT,GL_DIFFUSE,matR);
	//Render down notes (iterate over note range)
	glBegin(GL_TRIANGLES);
	for(i=0; i<128; i++)
	{
		downNote = [xmodel downKeys][i];
		if(downNote > 0)
		{
			//This is the radius
			float startDistance = (downNote)/8.0f -16;		
			float startAngle = (((M_PI*2)/12) * (downNote % 12));
			xa = cos(startAngle);
			ya = -sin(startAngle);
			//xa,ya,startDistance is a point in space
			glNormal3f(0, 0, 1.0f);	
			glColor3f(1.0f, 0.0f, 0.0f);
			//now is a bunch of goo bits... basically randomness
			triX = cos(now)/(8 + now%8);  
			triY = -sin(now)/(8 + now%8);
			glVertex3f(xa + triX, ya + triY, startDistance);
			triX = cos(now + M_PI/3)/(8 + now%8);  
			triY = -sin(now + M_PI/3)/(8 + now%8);
			glVertex3f(xa + triX, ya + triY, startDistance);
			triX = cos(now + 2*M_PI/3)/(8 + now%8);  
			triY = -sin(now + 2*M_PI/3)/(8 + now%8);
			glVertex3f(xa + triX, ya + triY, startDistance);
		}
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
	uint64_t now = mach_absolute_time();
	[xmodel tickAt:now];
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
