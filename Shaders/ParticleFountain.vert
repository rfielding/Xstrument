
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
varying vec4 Color;
varying vec4 Center;

const float maxy = 1.85;
const float rad = 0.95;

void main(void)
{
	//float t = time;
	//t = clamp(t - gl_Color.a, 0.0, 10000.0);
	//t = mod(t, 5.0);
	//vec4 vertex = gl_Vertex;
	//vertex = gl_Vertex + Center*0.0001;
	//vertex.x = rad * gl_Color.y * t * sin(gl_Color.x * 6.28);
	//vertex.z = rad * gl_Color.y * t * cos(gl_Color.x * 6.28);
	//float miny = 
	//	(			
	//		((gl_Color.y * t) >  1.0)
	//	) ? -5000.0 : -1.0;
	//float h = gl_Color.z * maxy;
	//vertex.y = - (t - h) * (t - h) + h * h - 1.0;
	//vertex.y = clamp(vertex.y, miny, 100.0);
	//vertex = 0.1*Center + glPosition;
	//vertex.x = gl_Vertex.x*0.1+0.1; //(9.0 * gl_Color.x + Center.x) * 0.1;
	//vertex.y = gl_Vertex.y*0.1; //(9.0 * gl_Color.y + Center.y) * 0.1;
	//vertex.z = gl_Vertex.z*0.1;
	//vertex.w = 1.0; //(9.0 * gl_Color.z + Center.z) * 0.1;
	//gl_Position = gl_ModelViewProjectionMatrix * vertex;

	//Color.r = 0.5;
	//Color.g = 1.0;
	//Color.b = 0.5;
	//Color.a = 0.5;
	//Color.a = 1.0 - t / 1.75;
	
	//vec3 normal = gl_Normal;
	//vec3 vertex = gl_Vertex.xyz; // + noise3(offset + gl_Vertex.xyz * scaleIn) * scaleOut;

	//normal = normalize(gl_NormalMatrix * normal);
	//vec3 position = vec3(gl_ModelViewMatrix * vec4(vertex,1.0));
    //vec3 lightVec   = normalize(LightPosition - position);
    //float diffuse   = max(dot(lightVec, normal), 0.0);

    //Color = vec4(gl_Color * diffuse); 
	
	vec4 vertex = gl_Vertex;
    gl_Position = gl_ModelViewProjectionMatrix * vertex;	
	//Color.g = 1.0;
}
