//
//  texture
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

uniform int u_useLighting;

#ifdef TEXTURE
uniform sampler2D u_sampler;
varying lowp vec2 v_texCoordOut;
#else
  #ifdef COLOR
varying lowp vec4 v_color;
  #endif
#endif

uniform lowp vec4 u_color;

uniform lowp float u_opacity;

void main()
{
    lowp vec4 color = u_color;

#ifdef TEXTURE
    color = texture2D(u_sampler, v_texCoordOut);
#else
  #ifdef COLOR
    color = v_color;
  #endif
#endif

    if( (color.a > 0.0) && (u_opacity < 1.0) )
       color.a = u_opacity;

    if( u_useLighting > 0 )
    {
    }
    else
    {
        gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 ); // color;
    }
}
