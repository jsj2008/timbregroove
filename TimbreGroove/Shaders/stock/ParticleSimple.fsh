//
//  ParticleSimple.fsh
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


varying mediump vec4 Color;


void main (void)
{

    gl_FragColor = Color;

}