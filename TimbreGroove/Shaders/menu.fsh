//
//  menu
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
precision highp float;

uniform sampler2D u_sampler;
varying lowp vec2 v_texCoordOut;

uniform vec3 u_lightDir;
uniform int u_shadowDraw;
uniform float u_shadowStrength;

varying float v_xpos;

void main()
{
    vec4 color = texture2D(u_sampler, v_texCoordOut);

    if( u_shadowDraw > 0 )
    {
        if( color.a > 0.0 )
            color = vec4( vec3(0.2), u_shadowStrength );
    }
    else
    {
        float xnormal = clamp(v_xpos-1.0,-1.0,-0.2);
        float dProd = max(0.0, dot(vec3(xnormal,0,-1), normalize(u_lightDir)));
        color = vec4( color.xyz* (vec3(0.8,0.8,0.8) * dProd), color.a );
    }
    
    gl_FragColor = color;
}
