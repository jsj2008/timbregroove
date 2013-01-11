//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

precision highp float;

uniform vec2      u_pixelSize;
uniform float     u_timeDiff;
uniform int       u_refreshing;
uniform sampler2D u_sampSnap;
uniform sampler2D u_sampXPix;

varying vec2 v_texCoordOut;

void main()
{
    vec2 tc = v_texCoordOut;
    vec4 color;

    if( u_refreshing > 0 )
    {
#ifdef BLEED_UP
        float time = clamp(u_timeDiff,0.0,1.0);
        vec4 pic = texture2D(u_sampXPix,tc) * time;
        vec4 snap = texture2D(u_sampSnap,tc) * (1.0-time);
        color = (pic + snap) / 2.0;
        color.a = 1.0;
#else
        color = texture2D(u_sampXPix,tc);
        color.a = clamp(u_timeDiff,0.0,1.0);
#endif
    }
    else
    {
        vec2 neighbor;
        
        neighbor = vec2( tc.x, tc.y+u_pixelSize.y );
        vec4 colorN = texture2D(u_sampXPix,neighbor);
        
        neighbor = vec2( tc.x + u_pixelSize.x, tc.y );
        vec4 colorE = texture2D(u_sampXPix,neighbor);
        
        neighbor = vec2( tc.x, tc.y - u_pixelSize.y);
        vec4 colorS = texture2D(u_sampXPix,neighbor);
        
        neighbor = vec2( tc.x - u_pixelSize.x, tc.y );
        vec4 colorW = texture2D(u_sampXPix, neighbor);

#ifdef BLUR_DOWN
        color = ((colorN + colorE + colorS + colorW) / 4.0);
        color -= (color / 64.0);
#endif

#ifdef SOLARIZE
        color = ((colorN + colorE + colorS + colorW) / 2.0) - texture2D(u_sampSnap,tc);
        color -= (color / 64.0);
#endif

#ifdef BLEED_UP
         color = ((colorN + colorE + colorS + colorW) / 4.0);
         color *= 1.03;
         color.a = 1.0;
#endif
         
        color.a = 1.0;
    }
    
    gl_FragColor = color;
}
