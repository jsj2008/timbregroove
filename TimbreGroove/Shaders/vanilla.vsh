//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//

attribute vec4 a_position;

uniform mat4  u_mvpMatrix;
uniform vec4 u_color;

varying lowp vec4 v_color;


void main() {
    v_color = u_color;
	gl_Position = /* u_mvpMatrix */ a_position;
}

