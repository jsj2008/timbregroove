//
//  texture
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

uniform sampler2D u_sampler;

varying lowp vec2 v_texCoordOut;

void main()
{
    lowp vec4 rgba = texture2D(u_sampler, v_texCoordOut);
    lowp float opacity = rgba.a;
    if( rgba.rgb == vec3(0) )
        opacity = 0.0;
    
    gl_FragColor = vec4( rgba.rgb, opacity );
}
