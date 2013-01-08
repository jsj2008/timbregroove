//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec3 a_position;

void main(void)
{
    gl_Position = vec4(a_position, 1.0);
}
