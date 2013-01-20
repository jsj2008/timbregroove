//
//  BrickShader.fsh
//  created with Shaderific
//
//  Fragment shader for procedural bricks
//
//  Authors: Dave Baldwin, Steve Koren, Randi Rost
//          based on a shader by Darwyn Peachey
//
//  Copyright (c) 2002-2006 3Dlabs Inc. Ltd. 
//
//  See the file menu for license information
//

precision highp float;

uniform highp vec4 materialDiffuseColor2;
uniform highp vec4 materialDiffuseColor3;

// varying highp vec2  MCposition;
varying highp vec3 objectspacePosition;
varying float LightIntensity;

void main() {

	vec2 BrickSize = vec2(0.1, 0.05);
	vec2 BrickPct = vec2(0.9, 0.9);
	vec3 BrickColor =  materialDiffuseColor2.xyz;
	vec3 MortarColor = materialDiffuseColor3.xyz;
    
    float theta = asin(objectspacePosition.y / length(objectspacePosition.xyz));
    float phi = atan(objectspacePosition.z , objectspacePosition.x);
    
	highp vec2 MCposition  = vec2(phi, theta);  

	
    vec3 color;
	vec2 position, useBrick;

	position = MCposition / BrickSize;
	
	if (fract(position.y * 0.5) > 0.5)
		position.x += 0.5;

	position = fract(position);

	useBrick = step(position, BrickPct);

	color    = mix(MortarColor, BrickColor, useBrick.x * useBrick.y);
	color   *= LightIntensity * 1.5;
	gl_FragColor = vec4(color, 1.0);

}