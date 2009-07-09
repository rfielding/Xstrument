
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

void main (void)
{
	float z = gl_FragCoord.z / gl_FragCoord.w;
	float sz = log(z+0.5);
    gl_FragColor = Color / sz;
}