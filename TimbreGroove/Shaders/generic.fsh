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

#ifdef TIME
varying float v_time;
#endif

#ifdef NORMAL
varying vec3 v_lightFilter;
#endif

#ifdef SPOT_FILTER
uniform vec2 u_spotLocation;
uniform float u_spotIntensity;
float spotFilter()
{
    if( u_spotIntensity < 0.001 )
        return 0.0;
    vec2  pos       = (v_texCoordOut - 0.5) * 2.0; // transpose to object space
    float dist = distance(pos,u_spotLocation);
    if( dist > 0.3 )
        return 0.0;
    return clamp( cos(dist), 0.0, 1.0 );
}
#endif

uniform vec4 u_color;

#ifdef TEXTURE_DISTORT
uniform float u_rippleSize;
uniform vec2  u_ripplePt;

vec4 texture_dist(vec2 center)
{
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
    float max = 0.15;
    float alpha = ((max - length(diff)) / max);
    return vec4( texture2D(u_sampler, v_texCoordOut + diff).rgb, alpha );
}
#endif

void main()
{
    vec4 color;
    
#ifdef TEXTURE
    float alpha;
    #ifdef SPOT_FILTER
        alpha = spotFilter();
    #else
        alpha = 1.0;
    #endif
    if( alpha > 0.0 )
    {
    #ifdef TEXTURE_DISTORT
        color = texture_dist( u_ripplePt );
        color.a = min( color.a, alpha );
    #else
        vec2 st = v_texCoordOut;
        #ifdef PSYCHEDELIC
            vec2  pos = (st - 0.5) * 2.0; // transpose to object space
            float len = length(pos);
            st = st + (pos / len) * cos(len - v_time);
        #endif
        color = vec4( texture2D(u_sampler, st).rgb, alpha );
    #endif
    }
  #ifdef U_COLOR
    color += u_color;
  #endif
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
