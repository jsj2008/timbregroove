//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
attribute vec2 a_uv;

uniform mat4  u_pvm;

varying  vec2 v_texCoordOut;


void main()
{
    v_texCoordOut = a_uv;
	gl_Position   = u_pvm * a_position;
}

