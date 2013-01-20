//
//  ParticleSimple.vsh
//  created with Shaderific
//
//
//  Vertex shader for a particle fountain
//
//  Author: Philip Rideout
//
//  Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
//  See the file menu for license information
//


attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform float time;
uniform vec2 touchCoordinates[10];

const float RepeatFactor = 0.75;
const float Radius = 1.25;
const float Acceleration = 1.0;

varying vec4 Color;


void main(void)
{
    
	vec4 vertex = vec4(0,0,0,1);
    
	float t = max(time - normal.x + 0.5, 0.0);
    
	// modulo(a, b) = a - b * floor(a * (1 / b)).
	t = t - RepeatFactor * floor(t * (1.0 / RepeatFactor));
    
	vec3 velocity = Radius * (position.xyz);
    
	vertex += vec4(velocity * t, 0.0);
	vertex.y -= Acceleration * t * t;
        
	Color = vec4(position.rgb + vec3(0.5), 1.0 - t);
	gl_Position = modelViewProjectionMatrix * vertex;
    gl_PointSize = 1.0;

}