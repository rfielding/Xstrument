/*
 *  PortableGL.h
 *  Xstrument
 *
 *  Created by Robert Fielding on 6/11/09.
 *  Copyright 2009 Check Point Software. All rights reserved.
 * 
 * This indirection is here because Windows OpenGL is retarded and forced you to include <windows.h>,
 * breaking lots of otherwise pure and portable OpenGL code.  So, put that junk here if you must!
 */

#import <GLUT/glut.h>
