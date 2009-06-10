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
#import "MusicTheory.h"
#import <math.h>
#include <mach/mach_time.h>

struct
{
	float lightX, theta, radius;
	char midiBuffer[1024];	
	char charBuffer[1024];
	int font;
	int bitmapHeight;
	int sustain;
	int width;
	int height;
	int accBend;
	int tremBend;
} rchill;

void rchill_renderBitmapString(char* string, float xarg, float yarg)
{
	char* c;
	glRasterPos2f(xarg,yarg);
	for(c=string; *c != '\0'; c++)
	{
		glutBitmapCharacter((void*)rchill.font, *c);
	}
}

void rchill_drawNote(int noteNumber)
{
	float x=0;
	float y=0;
	//This is the radius
	float startRadius = 0.15* noteNumber / 12.0f;
	float stopRadius = 0.15* (noteNumber + 12) / 12.0f;
	
	//This is the angle
	float startAngle = (((M_PI*2)/12) * (noteNumber % 12));
	float stopAngle = (((M_PI*2)/12) * ((noteNumber + 1) % 12));
	
	x = stopRadius*cos(startAngle);
	y = -stopRadius*sin(startAngle);
	glVertex3f(x,y, 0);
	x = stopRadius*cos(stopAngle);
	y = -stopRadius*sin(stopAngle);
	glVertex3f(x,y, 0);
	x = startRadius*cos(stopAngle);
	y = -startRadius*sin(stopAngle);
	glVertex3f(x,y, 0);
	x = startRadius*cos(startAngle);
	y = -startRadius*sin(startAngle);
	glVertex3f(x,y, 0);
}


void rchill_repaint()
{
	int i=0;
	float x=0;
	float y=0;
	int xParm=0;
	int yParm=0;
	char stringBuffer[16];
	
	GLfloat lightPosition[] = {rchill.lightX, 1, 3, 0.0};
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT); //Not using 3D yet anyway | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	rchill.radius = 3.0f * (1.0f + (0x2000-musicTheory_wheel())/(0x2000 * 15.0));
	gluLookAt(
			  rchill.radius * sin(rchill.theta) , 0, rchill.radius * cos(rchill.theta), 
			  0, 0, 0, 
			  0, 1, 0
			  );
	
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	glTranslatef(0,0,0);
	
	if(musicTheory_dirtyScale())
	{
		glNewList(1000,GL_COMPILE);
		
		glBegin(GL_TRIANGLES);
		for(i=0;i<7;i++)
		{
			int note = musicTheory_pickNote(i) % 12; 
			float stopRadius = 5.0f;
			float startAngle = (((M_PI*2)/12) * (note % 12));
			float stopAngle = (((M_PI*2)/12) * ((note+1) % 12));
			int mode = ((i%7 + (3*musicTheory_sharpCount())%7)) %7; 
			if( 2 == mode)
			{
				glColor3f(0.0,0.1,0.1f);
			}
			else
				if( 0 == mode )
				{
					glColor3f(0.1,0,0.1f);
				}
				else
				{
					glColor3f(0,0,0);
				}
			
			glVertex3f(0,0,0);
			x = stopRadius*cos(startAngle);
			y = -stopRadius*sin(startAngle);
			glColor3f(0,0,0.5f);
			glVertex3f(x,y,0);
			x = stopRadius*cos(stopAngle);
			y = -stopRadius*sin(stopAngle);
			glVertex3f(x,y,0);
		}
		glEnd();
		
		
		glBegin(GL_LINE_STRIP);
		glNormal3f(0.0f,0.0f,1.f);
		
		for(i=0;i<256;i++)
		{
			glColor3f(0.0,i/512.0f,0.0);
			//This is the radius
			float startRadius = 0.15* i / 12.0f;
			float stopRadius = 0.15* (i + 12) / 12.0f;
			
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
		glEndList();
		
		glNewList(1001,GL_COMPILE);
		//Draw a star representing what happens with the circle of fifths
		glBegin(GL_LINE_STRIP);
		glNormal3f(0.0f,0.0f,1.f);
		for(i=0;i<13;i++)
		{
			int fifth = ((musicTheory_sharpCount()+i)*7)%12; 
			glColor3f((12-i)/(10.0f + 1*(12-i)*i) ,0.0, i/(10.0f + 1*(12-i)*i));
			//This is the radius
			float startRadius = 0.4f;
			
			float startAngle = (((M_PI*2)/12) * (fifth % 12)) + M_PI/12;
			
			x = startRadius*cos(startAngle);
			y = -startRadius*sin(startAngle);
			glVertex3f(x,y, 1.5);
		}
		glEnd();
		
		glColor3d(0.2,0.9,0.2);
		for(i=0;i<=12;i++)
		{
			float stopRadius = 1.5f;
			float startAngle = (((M_PI*2)/12) * (i % 12));
			
			x = (stopRadius)*cos(startAngle + (M_PI/12));
			y = -(stopRadius)*sin(startAngle + (M_PI/12));
			//This buffer is managed by musicTheory
			char* noteName = (char*)musicTheory_findNoteName(i);
			rchill_renderBitmapString(noteName,x,y);	
		}
		
		glColor3d(0.2,0.5,0.2);
		for(i=0;i<=7;i++)
		{
			int note = musicTheory_pickNote(i) % 12; 
			
			float stopRadius = 1.0f;
			float startAngle = (((M_PI*2)/12) * (note % 12));
			int mode = ((i%7 + (3*musicTheory_sharpCount())%7)) %7; 
			
			x = (stopRadius)*cos(startAngle + (M_PI/12));
			y = -(stopRadius)*sin(startAngle + (M_PI/12));
			
			sprintf(stringBuffer,"%d", mode+1);
			rchill_renderBitmapString(stringBuffer,x,y);	
		}
		
		glEndList();
		musicTheory_scaleUpdated();
	}
	glCallList(1000);
	
	
	int* downNotes = (int*)musicTheory_notes();
	int* downCounts = (int*)musicTheory_downCounts();
	
	glBegin(GL_QUADS);
	int lastNote = musicTheory_note();
	
	//Render the last note, regardless of whether it's pressed
	if(lastNote>=0)
	{
		if(!rchill.sustain)
		{
			glColor3f(0.4,0.2,0.2);
		}
		else
		{
			glColor3f(0.2,0.4,0.2);
		}
		rchill_drawNote(lastNote);
	}
	
	//Draw stuck notes... we can do this on purpose by holding shift before a key is released
	for(i=0;i<255;i++)
	{
		int downCount = downCounts[i];	
		if(downCount>0)
		{
			glColor3f(0.1,0.3,0.5);
			rchill_drawNote(i);					
		}
	}
	
	//Draw down notes 
	for(i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(
		   noteNumber>=0 || 
		   lastNote == noteNumber
		   )
		{
			if(noteNumber == lastNote)
			{
				glColor3f(0.8,0.8,1.0);
			}
			else
				if(noteNumber>=0)
				{
					glColor3f(0.1,0.3,0.5);
				}
			
			rchill_drawNote(noteNumber);					
		}		
	}
	glEnd();
	
	glColor3f(0.7,1.0,0.7);
	xParm = musicTheory_getX();
	yParm = musicTheory_getY();
	//	loud = musicTheory_loud();
	//	sprintf(stringBuffer,"vol %d", loud);
	//	rchill_renderBitmapString(stringBuffer,0,0);	
	
	sprintf(stringBuffer,"fx=%d, vol=%d", xParm, yParm);
	rchill_renderBitmapString(stringBuffer,(xParm-64)/25.0,(yParm-64)/35.0);	
	
	glCallList(1001);
	glFinish();
}

void rchill_init()
{
	musicTheory_init();
	rchill.font = (int)GLUT_BITMAP_9_BY_15;
	rchill.bitmapHeight = 15;
	rchill.charBuffer[0] = 0x00;
	rchill.sustain=0;
	rchill.accBend = 127;
}

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
	
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
	
	rchill_init();
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
	rchill_repaint();
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
}




@end
