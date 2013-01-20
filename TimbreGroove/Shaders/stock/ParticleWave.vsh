//
//  ParticleWave.vsh
//  created with Shaderific
//
//
//  Vertex shader for a particle wave
//
//  Author: Philip Rideout
//
//  Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
//  See the file menu for license information
//


attribute vec4 position;

uniform mat4 modelViewProjectionMatrix;
uniform float time;

varying vec4 Color;

const float radius = 0.5;


void main(void)
{

	vec4 vertex = position + vec4(0.5);
    vec3 modulation = position.xyz + vec3(0.5);
    
	float t1 = mod(time, 10.0);
    
    if (t1 > 5.0) {
        
        t1 = 10.0 - t1;
        
    }
    
	vertex.x = radius * modulation.y * t1 * sin(modulation.x * 6.28);
	vertex.z = radius * modulation.y * t1 * cos(modulation.x * 6.28);
    
	float h = modulation.y * 1.25;
	float t2 = mod(t1, h*2.0);
	vertex.y = -(t2-h)*(t2-h)+h*h;
//	vertex.y -= 1.0;
	gl_Position = modelViewProjectionMatrix * vertex;
    
	Color.r = 1.0;
	Color.g = 1.0 - modulation.y;
	Color.b = 0.0;
	Color.a = 1.0 - t1 / 5.0;
    
    gl_PointSize = 1.0;

}