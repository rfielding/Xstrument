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
	char charBuffer[1024];
	int font;
	int bitmapHeight;
	float width;
	float height;
} portableui;

void portableui_init();
void portableui_repaint();
void portableui_glSetup();
void portableui_reshape();
