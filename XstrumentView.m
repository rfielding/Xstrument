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
#import <math.h>
#include <mach/mach_time.h>
#include "PortableUI.h"

@implementation XstrumentView

- (int) loadHandle:(GLhandleARB*)phandle VertexShader: (NSString *) vertexString fragmentShader: (NSString *) fragmentString
{
	NSLog(@"Got shaders to compile");
	const GLcharARB *vertex_string, *fragment_string;
	GLint vertex_compiled, fragment_compiled;
	GLint linked;
	
	/* Delete any existing program object */
	if (*phandle) {
		NSLog(@"remove existing");
		glDeleteObjectARB(*phandle);
		*phandle = NULL;
	}
	
	/* Load and compile both shaders */
	if (vertexString) {
		NSLog(@"load vertex shader");
		vertex_shader   = glCreateShaderObjectARB(GL_VERTEX_SHADER_ARB);
		vertex_string   = (GLcharARB *) [vertexString UTF8String];
		NSLog(@"load vertex shader source");
		glShaderSourceARB(vertex_shader, 1, &vertex_string, NULL);
		NSLog(@"compile vertex shader source");
		glCompileShaderARB(vertex_shader);
		NSLog(@"parameterize vertex shader source");
		glGetObjectParameterivARB(vertex_shader, GL_OBJECT_COMPILE_STATUS_ARB, &vertex_compiled);
		/* TODO - Get info log */
	} else {
		vertex_shader   = NULL;
		vertex_compiled = 1;
	}
	
	if (fragmentString) {
		NSLog(@"load frag shader");
		fragment_shader   = glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
		fragment_string   = [fragmentString UTF8String];
		NSLog(@"load frag shader source");
		glShaderSourceARB(fragment_shader, 1, &fragment_string, NULL);
		NSLog(@"compile frag shader source");
		glCompileShaderARB(fragment_shader);
		NSLog(@"parameterize frag shader source");
		glGetObjectParameterivARB(fragment_shader, GL_OBJECT_COMPILE_STATUS_ARB, &fragment_compiled);
		/* TODO - Get info log */
	} else {
		fragment_shader   = NULL;
		fragment_compiled = 1;
	}
	
	/* Ensure both shaders compiled */
	if (!vertex_compiled || !fragment_compiled) {
		if (vertex_shader) {
			NSLog(@"clean up vertex shader");
			glDeleteObjectARB(vertex_shader);
			vertex_shader   = NULL;
		}
		if (fragment_shader) {
			NSLog(@"clean up frag shader");
			glDeleteObjectARB(fragment_shader);
			fragment_shader = NULL;
		}
		return 1;
	}
	
	/* Create a program object and link both shaders */
	*phandle = glCreateProgramObjectARB();
	if (vertex_shader != NULL)
	{
		NSLog(@"attach vertex shader");
		glAttachObjectARB(*phandle, vertex_shader);
		glDeleteObjectARB(vertex_shader);   /* Release */
	}
	if (fragment_shader != NULL)
	{
		NSLog(@"attach frag shader");
		glAttachObjectARB(*phandle, fragment_shader);
		glDeleteObjectARB(fragment_shader); /* Release */
	}
	NSLog(@"link shaders");
	glLinkProgramARB(*phandle);
	NSLog(@"parameterize shaders");
	glGetObjectParameterivARB(*phandle, GL_OBJECT_LINK_STATUS_ARB, &linked);
	/* TODO - Get info log */
	
	if (!linked) {
		NSLog(@"free unlinked shaders");
		glDeleteObjectARB(*phandle);
		*phandle = NULL;
		return 1;
	}
	
	return 0;
}


- (id)initWithFrame:(NSRect)theFrame {
	
	NSOpenGLPixelFormat *fmt;
	fmt = [super pixelFormat];
	self = [super initWithFrame: theFrame pixelFormat:fmt];
	[[super openGLContext] makeCurrentContext];
	
	//[fmt release];
	
	{
		const GLubyte* extensions = glGetString(GL_EXTENSIONS);
		if ((GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_shader_objects",       extensions)) ||
			(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_shading_language_100", extensions)) ||
			(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_vertex_shader",        extensions)) ||
			(GL_FALSE == gluCheckExtension((GLubyte *)"GL_ARB_fragment_shader",      extensions)))
		{
			NSLog(@"We don't have hardware shader support");
		}
		else
		{
			NSLog(@"WE HAZ HARDWAREZ SHADER");
		}
	}
	
	//Prevent tearing
	GLint VBL = 1;
	[[self openGLContext] setValues:&VBL forParameter:NSOpenGLCPSwapInterval];

	//Load shaders
	NSBundle* bundle = [NSBundle bundleForClass: [self class]];	
	NSString* vertex_string   = [bundle pathForResource: @"VertexNoise" ofType: @"vert"];
	vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
	NSString* fragment_string = [bundle pathForResource: @"VertexNoise" ofType: @"frag"];
	fragment_string = [NSString stringWithContentsOfFile: fragment_string];	
	[self loadHandle:&noise_shaders VertexShader:vertex_string fragmentShader:fragment_string];	
	glUseProgramObjectARB(noise_shaders);
	glUniform3fARB(glGetUniformLocationARB(noise_shaders, "SurfaceColor"), 0.5, 0.5, 0.4);
	glUniform3fARB(glGetUniformLocationARB(noise_shaders, "LightPosition"), 0.0, 0.0, 5.0);
	glUniform3fvARB(glGetUniformLocationARB(noise_shaders, "offset"), 1, portableui_offset_get());
	glUniform1fARB(glGetUniformLocationARB(noise_shaders, "scaleOut"), 0.2);	

	vertex_string   = [bundle pathForResource: @"ParticleFountain" ofType: @"vert"];
	vertex_string   = [NSString stringWithContentsOfFile: vertex_string];
	fragment_string = [bundle pathForResource: @"ParticleFountain" ofType: @"frag"];
	fragment_string = [NSString stringWithContentsOfFile: fragment_string];	
	[self loadHandle:&particle_shaders VertexShader:vertex_string fragmentShader:fragment_string];	
	glUseProgramObjectARB(particle_shaders);
	glUniform1fARB(glGetUniformLocationARB(particle_shaders, "time"), 0.0);
	glUniform3fARB(glGetUniformLocationARB(particle_shaders, "Color"), 0.0, 0.0, 5.0);
	
	portableui_init();
	
		
	//Only necessary when we are doing animation that is not in response to keys, such as timers
	[self invalidateLoop];
	return self;
}

- (id)initWithCoder:(NSCoder*)c
{
	self = [super initWithCoder:c];
	return [self initWithFrame:[self bounds]];
}

- (void)reshape
{
	NSLog(@"reshaping");
	NSRect baseRect = [self convertRectToBase:[self bounds]];
	portableui_reshape(baseRect.size.width, baseRect.size.height);
}


- (void)drawRect:(NSRect)rect
{	
	portableui_repaint();
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
	[self performSelector:@selector(invalidateLoop) withObject:self afterDelay:1/20.0];
}

- (void)intervalTick
{
	//uint64_t now = mach_absolute_time();
	portableui_offset_animate();
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
			portableui_offset_kick();
		}		
	}
	[self setNeedsDisplay:YES];
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
	[self setNeedsDisplay:YES];
}




@end
