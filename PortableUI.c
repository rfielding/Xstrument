/*
 *  PortableUI.c
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/11/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */

#import <math.h>
#import <stdio.h>
#import "PortableGL.h"

#include "PortableUI.h"

#define PORTABLEUI_DIRTYLIST 1000
#define PORTABLEUI_STARLIST 1001

/* Parameter */
struct Parameter {
	float current [4];
	float min     [4];
	float max     [4];
	float delta   [4];	
	float downCenter[4];
};

struct
{
	char charBuffer[1024];
	int font;
	int bitmapHeight;
	float width;
	float height;
	struct Parameter offset;
} portableui;

void portableui_animate()
{
	int i; 
	for (i = 0; i < 4; i ++) 
	{
		portableui.offset.current[i] += portableui.offset.delta[i];
		if ((portableui.offset.current[i] < portableui.offset.min[i]) || (portableui.offset.current[i] > portableui.offset.max[i])) 
		{
			portableui.offset.delta[i] = -portableui.offset.delta[i];
		}
		portableui.offset.delta[i] *= 0.75;
	}
}

void portableui_kick()
{
	int* downNotes = (int*)musicTheory_notes();
	for(int i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(noteNumber>=0)
		{
			for(int j=0; j<4; j++)
			{
				if(portableui.offset.delta[j] < 0.2f)
				{
					portableui.offset.delta[j] = 0.2f;
				}
				if(portableui.offset.delta[j] < 1.0f)
				{
					portableui.offset.delta[j] *= 1.5;
				}
			}
		}
	}
}
float* portableui_getoffset()
{
	return portableui.offset.current;
}

void portableui_init()
{
	glShadeModel(GL_SMOOTH);
	glEnable(GL_LIGHTING);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_AUTO_NORMAL);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint(GL_LINE_SMOOTH_HINT,GL_NICEST);
	
	GLfloat ambient[] = {0.1,0.5,0.2,1.0};
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,ambient);
	
	GLfloat diffuse[] = {0.9,0.7,0.8,1.0};
	glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuse);	
	glEnable(GL_LIGHT0);
	
	GLfloat mat[] = {0.9, 0.8, 0.7, 0.5};
	glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,mat);
	glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,mat);
	
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
	
	portableui.font = (int)GLUT_BITMAP_9_BY_15;
	portableui.bitmapHeight = 15;
	portableui.charBuffer[0] = 0x00;

	portableui.offset.current[0] = 1;
	portableui.offset.min[0] = 0;
	portableui.offset.max[0] = 100;
	portableui.offset.delta[0] = 0.1;
	
	portableui.offset.current[1] = 15;
	portableui.offset.min[1] = 0;
	portableui.offset.max[1] = 100;
	portableui.offset.delta[1] = 0.1;
	
	portableui.offset.current[2] = 5;
	portableui.offset.min[2] = 0;
	portableui.offset.max[2] = 100;
	portableui.offset.delta[2] = 0.1;	
	
	portableui.offset.downCenter[0] = 0;
	portableui.offset.downCenter[1] = 0;
	portableui.offset.downCenter[2] = 0;
	portableui.offset.downCenter[3] = 1;
	
	musicTheory_init();
}

void portableui_reshape(float width, float height)
{
	portableui.width = width;
	portableui.height = height;
	glViewport(0,0,portableui.width, portableui.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60.0, portableui.width/portableui.height, 0.2, 256);
}

void rchill_renderBitmapString(char* string, float xarg, float yarg)
{
	glDisable(GL_LIGHTING);
	char* c;
	glRasterPos2f(xarg,yarg);
	for(c=string; *c != '\0'; c++)
	{
		glutBitmapCharacter((void*)portableui.font, *c);
	}
	glEnable(GL_LIGHTING);
}

//Abstract away the points to notes transform so that we can move to 3d with no changes
void rchill_noteToPoint(int note,float* pX,float* pY,float* pZ)
{
	int offset = 0;
	
	if(musicTheory_scaleBend(note) < CENTERTONE)offset=-1;
	if(musicTheory_scaleBend(note) > CENTERTONE)offset=+1;
	
	float startAngle = (((M_PI*2)/(12*HALFTONE)) * ((HALFTONE*(note-2)+musicTheory_scaleBend(note)) % (12*HALFTONE)));
	float startRadius = 1;
	(*pX) = startRadius * cos(startAngle);
	(*pY) = -startRadius * sin(startAngle);
	(*pZ) = note/8.0 - 14; //0;
}

void rchill_drawQuadShaded(int noteNumber,float xC,float yC,float zC)
{
	float x=0;
	float y=0;
	float z=0;
	
	float x2=0;
	float y2=0;
	float z2=0;
	
	float x3=0;
	float y3=0;
	float z3=0;
	
	float x4=0;
	float y4=0;
	float z4=0;
	
	rchill_noteToPoint(noteNumber+12,&x,&y,&z);
	rchill_noteToPoint(noteNumber+1+12,&x2,&y2,&z2);
	rchill_noteToPoint(noteNumber+1,&x3,&y3,&z3);
	rchill_noteToPoint(noteNumber+0,&x4,&y4,&z4);
	
	glColor3f(xC*0.5,yC*0.5,zC*0.5);
	glVertex3f(x,y,z);
	glVertex3f(x2,y2,z2);
	glColor3f(xC,yC,zC);
	glVertex3f(x3,y3,z3);
	glVertex3f(x4,y4,z4);
}

void rchill_quadCenter(int noteNumber,float* xC,float* yC,float* zC)
{
	float x=0;
	float y=0;
	float z=0;
	
	float x2=0;
	float y2=0;
	float z2=0;
	
	float x3=0;
	float y3=0;
	float z3=0;
	
	float x4=0;
	float y4=0;
	float z4=0;
	
	rchill_noteToPoint(noteNumber+12,&x,&y,&z);
	rchill_noteToPoint(noteNumber+1+12,&x2,&y2,&z2);
	rchill_noteToPoint(noteNumber+1,&x3,&y3,&z3);
	rchill_noteToPoint(noteNumber+0,&x4,&y4,&z4);
	
	*xC = (x+x2+x3+x4)/4;
	*yC = (y+y2+y3+y4)/4;
	*zC = (z+z2+z3+z4)/4;
}



void rchill_repaintDirtyScale()
{
	int i=0;
	float x=0;
	float y=0;
	float z=0;
	
	float x2=0;
	float y2=0;
	float z2=0;
	
	float x3=0;
	float y3=0;
	float z3=0;
	
	float x4=0;
	float y4=0;
	float z4=0;
	
	char stringBuffer[16];
	
	glNewList(PORTABLEUI_DIRTYLIST,GL_COMPILE);
	int minor = (7*musicTheory_sharpCount())%12;
	int major = (7*musicTheory_sharpCount() + 3)%12;
	int inScale=0;
	for(i=0;i<7;i++)
	{
		int n = ((musicTheory_pickNote(i+7)%12));
		inScale |= 1<< n;
	}
	glBegin(GL_QUADS);
	for(i=0;i<128;i++)
	{
		float r=0.0;
		float g=0.0;
		float b=0.0;
		int note = (i % 12);
		int isInScale = inScale & (1<<note);
		if( minor == note)
		{
			r=0.8; b=0.8f;
		}
		else
		if( major == note )
		{
			g=0.8f; b=0.8f;
		}
		else
		if( isInScale )
		{
			b=1.0f;
		}
		
		if(1) //r>0.0 || g>0.0 || b>0.0)
		{
			glColor3f(r,g,b);
			rchill_noteToPoint(i+12,&x,&y,&z);
			rchill_noteToPoint(i+1+12,&x2,&y2,&z2);
			rchill_noteToPoint(i+1,&x3,&y3,&z3);
			rchill_noteToPoint(i+0,&x4,&y4,&z4);
			
			glVertex3f(x,y,z);
			glVertex3f(x2,y2,z2);
			glVertex3f(x3,y3,z3);
			glVertex3f(x4,y4,z4);
		}
	}
	/*
	for(i=0;i<7;i++)
	{
		int note = musicTheory_pickNote(i) % 12; 
		int mode = ((i%7 + (3*musicTheory_sharpCount())%7)) %7; 
		if( 2 == mode)
		{
			glColor3f(0.0,0.8,0.8f);
		}
		else
			if( 0 == mode )
			{
				glColor3f(0.8,0,0.8f);
			}
			else
			{
				glColor3f(0,0,0);
			}
		
		rchill_noteToPoint(note+1, &x, &y,&z);
		glVertex3f(x,y,z);
		rchill_noteToPoint(note, &x, &y,&z);
		glVertex3f(x,y,z);
		rchill_noteToPoint(note+12*12, &x, &y,&z);
		
		glColor3f(0,0,0.25f);
		glVertex3f(x,y,z);
		rchill_noteToPoint(note+12*12+1, &x, &y,&z);
		glVertex3f(x,y,z);
	}		
	 */
	glEnd();		
	
	glBegin(GL_LINE_STRIP);
	
	for(i=0;i<128;i++)
	{
		glColor3f(0.0,/*(i/64.0-1.0)* */ 0.8,0.0);
		
		rchill_noteToPoint(i+12,&x,&y,&z);
		rchill_noteToPoint(i+1+12,&x2,&y2,&z2);
		rchill_noteToPoint(i+1,&x3,&y3,&z3);
		rchill_noteToPoint(i+0,&x4,&y4,&z4);
		
		glVertex3f(x,y,z);
		glVertex3f(x2,y2,z2);
		glVertex3f(x3,y3,z3);
		glVertex3f(x2,y2,z2);
	}
	glEnd();
	glEndList();
	
	glNewList(PORTABLEUI_STARLIST,GL_COMPILE);
	//Draw a star representing what happens with the circle of fifths
	glBegin(GL_LINE_STRIP);
	for(i=0;i<13;i++)
	{
		int fifth = ((musicTheory_sharpCount()+i)*7)%12; 
		glColor3f((12-i)/(10.0f + 1*(12-i)*i) ,0.0, i/(10.0f + 1*(12-i)*i));
		rchill_noteToPoint(fifth+12*8,&x2,&y2,&z2);
		rchill_noteToPoint(fifth+1+12*8,&x3,&y3,&z3);
		x = (x2+x3)/8;
		y = (y2+y3)/8;
		z = (z2+z3)/64;
		
		glVertex3f(x,y,z+2);
	}
	glEnd();
	
	for(i=0;i<=12;i++)
	{
		rchill_noteToPoint(i+12*5,&x2,&y2,&z2);
		rchill_noteToPoint(i+12*5+1,&x3,&y3,&z3);
		x = (x2+x3)/2;
		y = (y2+y3)/2;
		z = (z2+z3)/2;
		char* noteName = (char*)musicTheory_findNoteName(i);
		if(noteName[1]=='\0')
		{
			glColor3f(0.8,1,0.8);
		}
		else
		{
			glColor3f(0.0,0.2,0.0);
		}
		rchill_renderBitmapString(noteName,x,y);	
	}
	
	glColor3d(0.4,1,0.4);
	for(i=0;i<=7;i++)
	{
		int note = musicTheory_pickNote(i) % 12; 
		int mode = ((i%7 + (3*musicTheory_sharpCount())%7)) %7; 
		rchill_noteToPoint(note+12*5,&x2,&y2,&z2);
		rchill_noteToPoint(note+12*5+1,&x3,&y3,&z3);
		x = 0.8*(x2+x3);
		y = 0.8*(y2+y3);
		z = 0.8*(z2+z3);
		sprintf(stringBuffer,"%d", mode+1);
		rchill_renderBitmapString(stringBuffer,x,y);	
	}
	
	glEndList();
	musicTheory_scaleUpdated();
}

void portableui_repaintCleanScale()
{
	int i=0;
	
	float x=0;
	float y=0;
	float z=0;
			
	int* downNotes = (int*)musicTheory_notes();
	int* downCounts = (int*)musicTheory_downCounts();
	int lastNote = musicTheory_note();
	
	glBegin(GL_QUADS);
	
	//Render the last note, regardless of whether it's pressed
	if(lastNote>=0)
	{
		if(!musicTheory_getSustain())
		{
			x=0.4;
			y=0.2;
			z=0.2;
		}
		else
		{
			x=0.2;
			y=0.4;
			z=0.2;
		}
		rchill_drawQuadShaded(lastNote,x,y,z);
	}
	
	//Draw stuck notes... we can do this on purpose by holding shift before a key is released
	for(i=0;i<255;i++)
	{
		int downCount = downCounts[i];	
		if(downCount>0)
		{
			x=0.1;
			y=0.3;
			z=0.5;
			rchill_drawQuadShaded(i,x,y,z);					
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
				x=0.8;
				y=0.8;
				z=1.0;
				rchill_quadCenter(
								  noteNumber,
								  &portableui.offset.downCenter[0],
								  &portableui.offset.downCenter[1],
								  &portableui.offset.downCenter[2]
				);					
			}
			else
			if(noteNumber>=0)
			{
				x=1.0;
				y=0.3;
				z=0.5;
			}
			
			rchill_drawQuadShaded(noteNumber,x,y,z);					
		}		
	}
	glEnd();
}



void portableui_repaint()
{
	int i=0;
	
	float x=0;
	float y=0;
	float z=0;
	
	float bumpX=0;
	float bumpY=0;
	float bumpZ=0;
		
	int* downNotes = (int*)musicTheory_notes();
	int lastNote = musicTheory_note();
	
	GLfloat lightPosition[] = {3, 3, 5, 0.0};
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT); // | GL_DEPTH_BUFFER_BIT);
	
	glUniform1fARB(glGetUniformLocationARB(program_object, "scaleIn"), portableui.offset.delta[0]);
	glUniform3fvARB(glGetUniformLocationARB(program_object, "color"), 1, portableui_getoffset());
	glUniform3fvARB(glGetUniformLocationARB(program_object, "center"), 1, portableui.offset.downCenter);
	for(i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(noteNumber >= 0)
		{
			rchill_noteToPoint(lastNote, &x,&y,&z);
			bumpX += x;
			bumpY += y;
			bumpZ += z;
		}
	}
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	z = 3.0f * (1.0f + (0x2000-musicTheory_wheel())/(0x2000 * 12.0));
	gluLookAt(
			  bumpX*0.02,bumpY*0.02,z,
			  //rchill.radius * sin(rchill.theta) , 0, rchill.radius * cos(rchill.theta), 
			  -bumpX*0.01, -bumpY*0.01, -bumpZ*0.01, 
			  0, 1, 0
			  );
	
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	glTranslatef(0,0,0);
	
	glUniform3fvARB(glGetUniformLocationARB(program_object, "offset"), 1, portableui_getoffset());
	
	if(musicTheory_dirtyScale())
	{
		rchill_repaintDirtyScale();
	}
	glCallList(PORTABLEUI_DIRTYLIST);
	
	portableui_repaintCleanScale();
	
	glCallList(PORTABLEUI_STARLIST);
	
	glColor4f(1.0,0.7,1.0,0.9);
	rchill_renderBitmapString(musicTheory_keyBuffer(),-2,-1.5);	
	
	glFinish();
}

