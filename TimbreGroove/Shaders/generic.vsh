//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//

attribute vec4 a_position;

#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying lowp vec4 v_color;
#endif

#ifdef NORMAL
attribute vec3 a_normal;
#endif

uniform mat4 u_pvm;

void main()
{
#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_color = a_color;
#endif
    
	gl_Position   = u_pvm * a_position;
}

