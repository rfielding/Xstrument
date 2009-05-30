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
	gluPerspective(60.0, baseRect.size.width/baseRect.size.height, 0.2, 7);
}


- (void)drawRect:(NSRect)rect
{
	//Just show some junk on the screen now so that we can tell that timing
	//and MIDI and keyboard are all working
	int i=0;
	float radius = 2.0f;
	float theta = 0.0f;
	float lightX = 1;
	float x=0.0f;
	float y=0.0f;
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
	
	glBegin(GL_LINE_STRIP);
	glNormal3f(0.0f,0.0f,1.0f);
	
	for(i=0; i<128; i++)
	{
		glColor3f(0.0f, i/512.0f, 0.0f);
		//This is the radius
		float startRadius = 0.10* i / 12.0f;
		float stopRadius = 0.10* (i + 12) / 12.0f;
		
		float startAngle = (((M_PI*2)/12) * (i % 12));
		float stopAngle = (((M_PI*2)/12) * ((i + 1) % 12));
		
		x = stopRadius*cos(startAngle);
		y = -stopRadius*sin(startAngle);
		glVertex3f(x,y, 0);
		x = stopRadius*cos(stopAngle);
		y = -stopRadius*sin(stopAngle);
		glVertex3f(x,y, 0);
		x = startRadius*cos(stopAngle);
		y = -startRadius*sin(stopAngle);
		glVertex3f(x,y, 0);
		x = stopRadius*cos(stopAngle);
		y = -stopRadius*sin(stopAngle);
		glVertex3f(x,y, 0);		
	}
	glEnd();
	/*
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
	 */
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
