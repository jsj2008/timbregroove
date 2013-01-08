//
//  texture
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
precision highp float;

#ifdef TEXTURE
uniform sampler2D u_sampler;
varying lowp vec2 v_texCoordOut;
#else
#ifdef COLOR
varying vec4 v_color;
#endif
#endif

#ifdef NORMAL
varying vec3 v_lightFilter;
#endif

uniform vec4 u_color;

void main()
{
    vec4 color;
    
#ifdef TEXTURE
    color = texture2D(u_sampler, v_texCoordOut);
#else
#ifdef COLOR
    color = v_color;
#else
    color = u_color;
#endif
#endif

#ifdef NORMAL
    color = vec4(color.rgb * v_lightFilter, color.a);
#endif
    
    gl_FragColor = color;
}
