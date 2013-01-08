//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//

attribute vec4 a_position;
attribute vec4 a_color;

uniform mat4  u_pvm;

varying lowp vec4 v_color;

void main() {
    v_color = a_color;
	gl_Position = u_pvm * a_position;
}

