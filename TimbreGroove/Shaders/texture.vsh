//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//

attribute vec4 a_position;
attribute vec2 a_textureUV;  // uv array maps here

varying lowp vec2 v_texCoordOut;

uniform mat4 u_pvmMatrix;

void main() 
{
    v_texCoordOut = a_textureUV;
	gl_Position   = u_pvmMatrix * a_position;
}

