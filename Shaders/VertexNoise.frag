
//
// vertexnoise.frag: Fragment shader for warping the geometry with noise.
//
// author: Philip Rideout
//
// Copyright (c) 2005-2006: 3Dlabs, Inc.
//
//
// See 3Dlabs-License.txt for license information
//

varying vec4 Color;
varying vec4 Center;

void main (void)
{
	float z = gl_FragCoord.z / gl_FragCoord.w;
	float sz = log(z+0.9);
    gl_FragColor = 0.7*Color / sz;
}