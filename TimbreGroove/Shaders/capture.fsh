//
//  generic frag shader
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
precision highp float;
varying vec4 v_color;

void main()
{
    gl_FragColor = v_color;
}
