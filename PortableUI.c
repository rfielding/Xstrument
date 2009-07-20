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
#import <stdlib.h>
#import "PortableGL.h"

#include "PortableUI.h"

#define PORTABLEUI_DIRTYLIST 1000
#define PORTABLEUI_STARLIST 1001

/* Particle set*/
#define PARTICLECOUNT 2000//00

#define RAND_EXPECT_ZERO() (((float)rand()/(float)RAND_MAX)-0.5)
#define RAND_EXPECT_HALF() (((float)rand()/(float)RAND_MAX))

// {x,y,z,alpha} -- location with alpha as the x,y plane angle
GLfloat particles[PARTICLECOUNT * sizeof(GLfloat) * 8];
#define NTH(i,j) (i*8+j)

/* Parameter */
struct Parameter {
	float current [4];
	float min     [4];
	float max     [4];
	float delta   [4];	
};

struct Parameter offset;
float downCenter[4];
float prevCenter[4];
float colors[16][3];
float vect[16][3];

struct
{
	char charBuffer[1024];
	int font;
	int bitmapHeight;
	float width;
	float height;
	int lastDifferentNote;
	int frameTick;
	int previouslyNoNotes;
} portableui;

void portableui_particleinit()
{
	int i;
	for (i = 0; i < PARTICLECOUNT; i++)
	{
		float r = RAND_EXPECT_HALF()*5;
		float a = 2 * RAND_EXPECT_HALF() * M_PI;
		float b = 10 * RAND_EXPECT_HALF();
		float x = cos(a) - sin(a);
		float y = sin(a) + cos(a);
		particles[NTH(i,0)] = r * x;
		particles[NTH(i,1)] = r * y;
		particles[NTH(i,2)] = b;
		particles[NTH(i,3)] = 1.0;
		particles[NTH(i,4)] = RAND_EXPECT_HALF() * 2 * M_PI;
		particles[NTH(i,5)] = RAND_EXPECT_HALF() * 2 * M_PI;
		particles[NTH(i,6)] = RAND_EXPECT_HALF() * 2 * M_PI;
	}	
}

void portableui_offset_animate()
{
	int i; 
	for (i = 0; i < 4; i ++) 
	{
		//make delta drop down gradually
		offset.current[i] += offset.delta[i];
		if ((offset.current[i] < offset.min[i]) || (offset.current[i] > offset.max[i])) 
		{
			offset.delta[i] = -offset.delta[i];
		}
		offset.delta[i] *= 0.8;
	}
}

void portableui_averageAndScale(GLfloat* v,GLfloat* v1,GLfloat* v2,float scale)
{
	for(int i=0; i<3; i++)
	{
		v[i] = scale*(v1[i]+v2[i])/2;
	}
}

void portableui_offset_init()
{
	offset.current[0] = 1;
	offset.min[0] = 0;
	offset.max[0] = 100;
	offset.delta[0] = 0.05;
	
	offset.current[1] = 15;
	offset.min[1] = 0;
	offset.max[1] = 100;
	offset.delta[1] = 0.05;
	
	offset.current[2] = 5;
	offset.min[2] = 0;
	offset.max[2] = 100;
	offset.delta[2] = 0.05;	
}

void portableui_offset_kick()
{
	int* downNotes = (int*)musicTheory_notes();
	for(int i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(noteNumber>=0)
		{
			//Bump all these numbers up, in bound of [0.2 .. 7.5]
			for(int j=0; j<4; j++)
			{
				if(offset.delta[j] < 0.05f)
				{
					offset.delta[j] = 0.05f;
				}
				if(offset.delta[j] < 5.0f)
				{
					offset.delta[j] *= 1.5;
				}
			}
		}
	}
}

float* portableui_offset_get()
{
	return offset.current;
}


//Abstract away the points to notes transform so that we can move to 3d with no changes
void rchill_noteToPointWithMicrotones(int note,float* v)
{
	int offset = 0;
	
	if(musicTheory_scaleBend(note) < CENTERTONE)offset=-1;
	if(musicTheory_scaleBend(note) > CENTERTONE)offset=+1;
	
	float startAngle = (((M_PI*2)/(12*HALFTONE)) * ((HALFTONE*(note-2)+musicTheory_scaleBend(note)) % (12*HALFTONE)));
	float startRadius = 1;
	(*(v)) = startRadius * cos(startAngle);
	(*(v+1)) = -startRadius * sin(startAngle);
	(*(v+2)) = note/8.0 - 14; //0;
}


void rchill_noteToPointNoMicrotones(int note,float* v)
{
	int offset = 0;
	
	if(musicTheory_scaleBend(note) < CENTERTONE)offset=-1;
	if(musicTheory_scaleBend(note) > CENTERTONE)offset=+1;
	
	float startAngle = (((M_PI*2)/(12*HALFTONE)) * ((HALFTONE*(note-2)+0x2000) % (12*HALFTONE)));
	float startRadius = 1;
	(*(v)) = startRadius * cos(startAngle);
	(*(v+1)) = -startRadius * sin(startAngle);
	(*(v+2)) = note/8.0 - 14; //0;
}

void rchill_quadCenter(int noteNumber)
{
	rchill_noteToPointNoMicrotones(noteNumber+12,vect[0]);
	rchill_noteToPointNoMicrotones(noteNumber+0,vect[3]);	
	portableui_averageAndScale(downCenter,vect[0],vect[3],1.0);
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

	portableui_offset_init();
	
	downCenter[0] = 0;
	downCenter[1] = 0;
	downCenter[2] = 0;
	downCenter[3] = 1;
	
	prevCenter[0] = 0;
	prevCenter[1] = 0;
	prevCenter[2] = 0;
	prevCenter[3] = 1;
	
	portableui.frameTick=0;
	portableui.previouslyNoNotes=1;
	
	rchill_quadCenter(0);					
	
	portableui_particleinit();
	
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



void rchill_drawQuadShaded(int noteNumber,float* c1,float* c2)
{
	rchill_noteToPointWithMicrotones(noteNumber+0,vect[0]);
	rchill_noteToPointWithMicrotones(noteNumber+12,vect[1]);
	
	rchill_noteToPointWithMicrotones(noteNumber-1+12,vect[2]);
	portableui_averageAndScale(vect[2], vect[2], vect[1], 1.0);
	
	rchill_noteToPointWithMicrotones(noteNumber-1,vect[3]);	
	portableui_averageAndScale(vect[3], vect[3], vect[0], 1.0);
	
	rchill_noteToPointWithMicrotones(noteNumber+1,vect[4]);
	portableui_averageAndScale(vect[4], vect[4], vect[0], 1.0);
	
	rchill_noteToPointWithMicrotones(noteNumber+1+12,vect[5]);
	portableui_averageAndScale(vect[5], vect[5], vect[1], 1.0);

	glColor3fv(c1);
	glVertex3fv(vect[0]);
	glVertex3fv(vect[1]);
	glColor3fv(c2);
	glVertex3fv(vect[2]);
	glVertex3fv(vect[3]);
	 
	glColor3fv(c2);
	glVertex3fv(vect[4]);
	glVertex3fv(vect[5]);
	glColor3fv(c1);
	glVertex3fv(vect[1]);
	glVertex3fv(vect[0]);
}


void portableui_particleDrawPoints(int* downNotes,int notesDown,GLfloat pointSize,GLfloat a)
{
	glPointSize(pointSize);
	glBegin(GL_POINTS);
	int mode = musicTheory_microtonalMode(); 
	for (int i = 0; i < PARTICLECOUNT; i++)
	{
		float alpha = particles[NTH(i,4)]/(M_PI);
		if(mode==2)
		{
			glColor4f(alpha, 1.0, 0.2, a);
		}
		else
		if(mode==1)
		{
			glColor4f(alpha*alpha,1/(alpha*alpha*alpha),alpha*alpha, a);
		}
		else
		{
			glColor4f(1.0, alpha*alpha,0.0, a);
		}
		glVertex3fv(&particles[NTH(i,0)]);
	}	
	glEnd();
}

int portableui_fifthsDistance(int a,int b)
{
	switch((a-b+12)%12)
	{
		case 0: 
			return 0;
		case 5: 
		case 7:
			return 1;
		case 10:
		case 2:
			return 2;
		case 3:
		case 9:
			return 3;
		case 8:
		case 4:
			return 4;
		case 1:
		case 11:
			return 5;
		case 6:
			return 6;
	}
	return 0;
}

/*
 The worst function in the house.  Empirically tweaking this crap until it looks "cool".
 It changes frequently because I really don't know what the hell I'm doing.  Summary?
 
 When you press a key, some number of the particles (picked roughly according to current note)
 start flying off from the current note.  Dividing v by d gives a part of a normal, but instead of
 (v/d)/d2 --- which is normal part div by dist squared, I added in other factors to try to warp the shapes
 out of circular shapes.
 
 The factors around x,y,z are such that at a minimum it randomly walks around a plane (producing flat circles),
 but walking around the other two perpendicular planes I don't get something that looks exactly circular.
 (Do I need more of a quaternion struct where I twist around direction radius then bend a few degrees for that?)
 
 So, I add in random factors that try to add visual variety and tradeoff on performance.
 */
void portableui_particleDraw()
{
	int notesDown = 0;
	int* downNotes = (int*)musicTheory_notes();
	for(int i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(noteNumber>=0)notesDown++;
	}
	int burst=portableui.previouslyNoNotes && notesDown;
	float xc = downCenter[0];
	float yc = downCenter[1];
	float zc = downCenter[2];
	for (int i = 0; i < PARTICLECOUNT; i++)
	{
		/*
		     ca  sa  0     cb   0   -sb
			-sa  ca  0     0    1     0
			  0   0  1     sb   0    cb
		 
             ca*cb    sa   -ca*sb
			-sa*cb    ca    sa*sb
		        sb     0     cb
		 */
		float xa = particles[NTH(i,0)];
		float ya = particles[NTH(i,1)];
		float za = particles[NTH(i,3)];
		float d2 = (xa-xc)*(xa-xc) + (ya-yc)*(ya-yc) + (za-zc)*(za-zc);
		//float d = sqrt(d2);
		int chromatic = musicTheory_note()%12; 
		int fd = portableui_fifthsDistance(i%12,chromatic);
		float factor = (1+notesDown+fd)/90.0;			

		float alpha = particles[NTH(i,4)];
		float beta = particles[NTH(i,5)];
		float gamma = particles[NTH(i,6)];
		float ca = cos(alpha);
		float sa = sin(alpha);
		float cb = cos(beta);
		float sb = sin(beta);
		float cg = cos(gamma);
		float sg = sin(gamma);
		float x = 1;
		float y = 1;
		float z = 1;
		
		//if(notesDown==0 || fd>0)
		{
			x *= (ca+sa); y*= (ca-sa);
		}
		if(notesDown==0 || fd>2)
		{
			x *= (cb-sb); z *= (cb+sb);
		}
		if(notesDown==0 || fd>3)
		{
			y *= (cg+sg); z *= (cg-sg);
		}
		particles[NTH(i,4)] += RAND_EXPECT_ZERO()*M_PI/8;
		particles[NTH(i,5)] += RAND_EXPECT_ZERO()*M_PI/8;
		particles[NTH(i,6)] += RAND_EXPECT_ZERO()*M_PI/8;
		particles[NTH(i,0)] += factor* x;
		particles[NTH(i,1)] += factor* y;
		particles[NTH(i,2)] += factor* z;
		for(int k=0;k<3;k++)
		{
			int j = NTH(i,k);
			float v = (downCenter[k]-particles[j]);
			if(burst && fd<4)particles[j] = downCenter[k];
			if(notesDown)
			{
				if(fd<4)
				{
					particles[j] += 100*v/(d2*d2);
				}
			}
			if(fd<5)
				particles[j] += 10*fd*v/(d2*d2);
		}
	}
	
	/////Fireworks!
	glPushAttrib(GL_POINT_BIT);
	//portableui_particleDrawPoints(downNotes,notesDown,9.0,0.05);
	portableui_particleDrawPoints(downNotes,notesDown,7.0,0.05);
	//portableui_particleDrawPoints(downNotes,notesDown,5.0,0.05);
	portableui_particleDrawPoints(downNotes,notesDown,3.0,0.05);
	portableui_particleDrawPoints(downNotes,notesDown,1.0,1.0);	
	glPopAttrib();
	
	//Make sure that if no notes down on first frame we notice.
	if(burst)
	{
		portableui.previouslyNoNotes=0;
	}
	else
	{
		if(notesDown==0)
		{
		   portableui.previouslyNoNotes=1;
		}
	}
}

void rchill_repaintDirtyScale()
{
	int i=0;
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
	for(i=1;i<128;i++)
	{
		colors[0][0]=0.0;
		colors[0][1]=0.0;
		colors[0][2]=0.0;
		int note = (i % 12);
		int isInScale = inScale & (1<<note);
		float octaveBottomFactor = (i/12.0)/64;
		float octaveTopFactor = ((i+12)/12.0)/8;
		if( minor == note)
		{
			colors[0][0]=0.8; colors[0][2]=0.8f;
		}
		else
		if( major == note )
		{
			colors[0][1]=0.8f; colors[0][2]=0.8f;
		}
		else
		if( isInScale )
		{
			colors[0][2]=1.0f;
		}
		
		{
			portableui_averageAndScale(colors[1], colors[0], colors[0], octaveTopFactor);
			portableui_averageAndScale(colors[2], colors[0], colors[0], octaveBottomFactor);
			rchill_drawQuadShaded(i, colors[1], colors[2]);
		}
	}
	glEnd();		
	
	glBegin(GL_LINE_STRIP);
	
	for(i=1;i<128;i++)
	{
		float a = (i)/128.0;
		glColor4f(0.0,0.8,0.0,a);
		
		rchill_noteToPointNoMicrotones(i+12,vect[0]);
		rchill_noteToPointNoMicrotones(i+1+12,vect[1]);
		rchill_noteToPointNoMicrotones(i+1,vect[2]);
		rchill_noteToPointNoMicrotones(i+0,vect[3]);
		
		glVertex3fv(vect[0]);
		glVertex3fv(vect[1]);
		glVertex3fv(vect[2]);
		glVertex3fv(vect[3]);
		glVertex3fv(vect[0]);
	}
	glEnd();
	
	for(i=0;i<=12;i++)
	{
		int isInScale = inScale & (1<<i);
		rchill_noteToPointNoMicrotones(i+12*5,vect[1]);
		portableui_averageAndScale(vect[0],vect[1],vect[1],1.0);
		portableui_averageAndScale(vect[2],vect[0],vect[0],1.5);
		char* noteName = (char*)musicTheory_findNoteName(i);
		if(noteName[1]=='\0')
		{
			glColor3f(1.0,1,1.0);
		}
		else
		{
			glColor3f(0.0,1.0,0.0);
		}
		if(isInScale)
		{
			rchill_renderBitmapString(noteName,vect[0][0],vect[0][1]);	
		}
	}
	 
	
	glColor3d(1.0,1,1.0);
	for(i=0;i<=7;i++)
	{
		int note = musicTheory_pickNote(i) % 12; 
		int mode = ((i%7 + (3*musicTheory_sharpCount())%7)) %7; 
		rchill_noteToPointNoMicrotones(note+12*2,vect[1]);
		portableui_averageAndScale(vect[0],vect[1],vect[1],1.25);
		sprintf(stringBuffer,"%d",mode+1);
		rchill_renderBitmapString(stringBuffer,vect[0][0],vect[0][1]);	
	}
	
	glEndList();
	
	glNewList(PORTABLEUI_STARLIST,GL_COMPILE);
	glBegin(GL_LINE_STRIP);
	for(i=0;i<13;i++)
	{
		int fifth = ((musicTheory_sharpCount()+i)*7)%12; 
		double a = (12-i)/(10.0f + (12-i)*i);
		double b = i/(10.0f + 1*(12-i)*i);
		glColor4f(a ,0.0, b, 0.5);
		rchill_noteToPointNoMicrotones(fifth+12*8,vect[1]);
		//rchill_noteToPointNoMicrotones(fifth+1+12*8,vect[2]);
		vect[1][2]+=4;
		//vect[2][2]+=4;
		portableui_averageAndScale(vect[0],vect[1],vect[1],0.25);
		
		glVertex3fv(vect[0]);
	}
	glEnd();
	glEndList();
	musicTheory_scaleUpdated();
}

void portableui_repaintCleanScale()
{
	int i=0;
	
	colors[0][0]=0;
	colors[0][1]=0;
	colors[0][2]=0;
			
	int* downNotes = (int*)musicTheory_notes();
	int* downCounts = (int*)musicTheory_downCounts();
	int lastNote = musicTheory_note();
	
	glBegin(GL_QUADS);
	
	//Render the last note, regardless of whether it's pressed
	if(lastNote>=0)
	{
		if(!musicTheory_getSustain())
		{
			colors[0][0]=0.4;
			colors[0][1]=0.2;
			colors[0][2]=0.2;
		}
		else
		{
			colors[0][0]=0.2;
			colors[0][1]=0.4;
			colors[0][2]=0.2;
		}
		rchill_drawQuadShaded(lastNote,colors[0],colors[0]);
	}
	
	//Draw stuck notes... we can do this on purpose by holding shift before a key is released
	for(i=0;i<255;i++)
	{
		int downCount = downCounts[i];	
		if(downCount>0)
		{
			colors[0][0]=0.1;
			colors[0][1]=0.3;
			colors[0][2]=0.5;
			rchill_drawQuadShaded(i,colors[0],colors[1]);					
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
				colors[0][0]=0.8;
				colors[0][1]=0.8;
				colors[0][2]=1.0;
				rchill_quadCenter(noteNumber);					
				glUniform3fvARB(glGetUniformLocationARB(particle_shaders, "Center"), 1, downCenter);
			}
			else
			if(noteNumber>=0)
			{
				colors[0][0]=1.0;
				colors[0][1]=0.3;
				colors[0][2]=0.5;
			}
			
			rchill_drawQuadShaded(noteNumber,colors[0],colors[0]);					
		}		
	}
	glEnd();
}



void portableui_repaint()
{
	int i=0;
	
	float bumpX=0;
	float bumpY=0;
	float bumpZ=0;
		
	int* downNotes = (int*)musicTheory_notes();
	int lastNote = musicTheory_note();
	GLfloat fogFactor = 0.7;
	GLfloat brightFactor = 3.0;
	
	GLfloat lightPosition[] = {3, 3, 5, 0.0};
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);// | GL_DEPTH_BUFFER_BIT);

	
	glUseProgramObjectARB(noise_shaders);
	glUniform1fARB(glGetUniformLocationARB(noise_shaders, "scaleIn"), offset.delta[0]);
	glUniform3fvARB(glGetUniformLocationARB(noise_shaders, "center"), 1, downCenter);
	glUniform1fvARB(glGetUniformLocationARB(noise_shaders, "factor"), 1, &fogFactor);
	for(i=0;i<255;i++)
	{
		int noteNumber = downNotes[i];
		if(noteNumber >= 0)
		{
			rchill_noteToPointNoMicrotones(lastNote, vect[0]);
			bumpX += vect[0][0];
			bumpY += vect[0][1];
			bumpZ += vect[0][2];
		}
	}
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	vect[0][2] = 3.0f * (1.0f + (0x2000-musicTheory_wheel())/(0x2000 * 12.0));
	gluLookAt(
			  bumpX*0.04,bumpY*0.03,vect[0][2],
			  -bumpX*0.01, -bumpY*0.01, -bumpZ*0.01, 
			  0, 1, 0
			  );
	
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
	
	glTranslatef(0,0,0);
	
	glUniform3fvARB(glGetUniformLocationARB(noise_shaders, "offset"), 1, portableui_offset_get());
	
	if(musicTheory_dirtyScale())
	{
		rchill_repaintDirtyScale();
	}
	glCallList(PORTABLEUI_DIRTYLIST);
	
	glUniform1fvARB(glGetUniformLocationARB(noise_shaders, "factor"), 1, &brightFactor);
	portableui_repaintCleanScale();
	
	portableui_particleDraw();
	glCallList(PORTABLEUI_STARLIST);
	glUseProgramObjectARB(NULL);
	
	glColor4f(1.0,0.5,1.0,0.5);	
	rchill_renderBitmapString(musicTheory_keyBuffer(),-2,-1.5);	
	
	glFinish();
	portableui.frameTick++;
}

