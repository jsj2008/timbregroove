//
//  ToonShader.vsh
//  created with Shaderific
//
//  Vertex shader for cartoon-style shading
//
//  Author: Philip Rideout
//
//  Copyright (c) 2005-2006 3Dlabs Inc. Ltd.
//
//  See the file menu for license information
//

attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform highp mat4 modelViewMatrix;
uniform mat3 normalMatrix;

varying vec3 eyespaceNormal; 
varying vec4 eyespacePosition;

void main(void)
{

    eyespaceNormal = normalMatrix * normal;
    eyespacePosition = modelViewMatrix * position;
    gl_Position = modelViewProjectionMatrix * position;

}