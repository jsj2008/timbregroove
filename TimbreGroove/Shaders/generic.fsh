//
//  generic frag shader
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
        varying vec4 v_vertex_color;
    #endif
#endif

#ifdef NORMAL
varying vec4 v_color;
varying vec4 v_specular;
#endif

#ifdef TIME
varying float v_time;
#endif

#ifdef TEXTURE_DISTORT
uniform float u_rippleSize;
uniform vec2  u_ripplePt;

vec4 texture_dist()
{
    vec2  center     = u_ripplePt;
    float rippleSize = u_rippleSize;
    
    if( rippleSize < 0.1 )
        rippleSize = 0.2;
    
    vec2  pos       = (v_texCoordOut - 0.5) * 2.0; // transpose to object space
    vec2  position  = (pos - center);
    float length    = length(position);   // sqroot( x-sqr + y-sqr + z+sqr )
    vec2  direction = position / length;
    
    float t = v_time * 0.1;
    float ripple     = (length * (rippleSize*2.0)) - (t * rippleSize);
    vec2 diff = ((direction * cos(ripple))/100.0);
    /*
    float max = 0.15;
    float alpha = ((max - length(diff)) / max);
    */
    vec3 coord = texture2D(u_sampler, v_texCoordOut + diff).rgb;
    float alpha = clamp( sin(coord.x) * cos(coord.y) * 1.2, 0.0, 1.0 );
    return vec4( coord, alpha );
}
#endif

void main()
{
    vec4 color = vec4(0);
    
#ifdef TEXTURE
    #ifdef TEXTURE_DISTORT
        color = texture_dist();
    #else
        color = texture2D(u_sampler, v_texCoordOut);
    #endif
#else
    #ifdef COLOR
        color = v_vertex_color;
    #endif
#endif
    
#ifdef NORMAL
    color += v_color;
    color = vec4(color.rgb + v_specular.rgb, color.a);
#endif
    
    gl_FragColor = color;
}
