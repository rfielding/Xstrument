/*
 *  PortableUI.h
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/11/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 *
 */

#import <GLUT/glut.h>
#import <math.h>
#import "MusicTheory.h"
#import <stdio.h>

struct
{
	float lightX, theta, radius;
	char midiBuffer[1024];	
	char charBuffer[1024];
	int font;
	int bitmapHeight;
	int sustain;
	float width;
	float height;
} rchill;

void rchill_init();
void rchill_repaint();
void rchill_glSetup();
void rchill_reshape();
