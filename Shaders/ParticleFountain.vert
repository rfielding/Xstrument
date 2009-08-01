
//
// particle.vert: Vertex shader for a particle fountain.
//
// author: Philip Rideout
//
// Copyright (c) 2005-2006: 3Dlabs, Inc.
//
//
// See 3Dlabs-License.txt for license information
//

uniform float time;
univorm vec4 Color;
uniform vec4 Center;

const float maxy = 1.85;
const float rad = 0.95;

void main(void)
{	
	vec4 vertex = gl_Vertex;
    gl_Position = gl_ModelViewProjectionMatrix * vertex;	
}