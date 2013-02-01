//
//  menu
//  Created by victor on 01/30/13.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
attribute vec2 a_uv;

uniform mat4 u_pvm; // for scaling

varying lowp vec2 v_texCoordOut;
varying float v_xpos;

void main()
{
    v_texCoordOut = a_uv;
    v_xpos        = a_position.x;
	gl_Position   = u_pvm * a_position;
}

