//
//  Shader.vsh
//  TestOvals
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

attribute vec4 a_position;
attribute vec2 a_arcDefs;

varying lowp vec4 v_colorVarying;

uniform mat4  u_modelViewProjectionMatrix;
uniform float u_segment;
uniform bool  u_doArc;
uniform vec3  u_center;

const float PI = 3.1415926;

void main()
{
    
    vec3 pos = a_position.xyz;
    v_colorVarying = vec4( clamp(pos.x+0.5,0.0,1.0), clamp(pos.y+0.5,0.0,1.0), 0.0, 1.0 );

    if( u_doArc )
    {
        float signX = sign(pos.x);
        float posX  = pos.x + (signX * a_arcDefs.x);
        float seg   = u_segment;

        if( signX < 0.0 )
            seg += PI;
        
        pos.x = posX  + (        sin(seg) * a_arcDefs.x);
        pos.y = pos.y + (signX * cos(seg) * a_arcDefs.y);

    }
    
    pos += u_center;
    gl_PointSize = 2.0;
    gl_Position = u_modelViewProjectionMatrix * vec4( pos, a_position.w );
}
