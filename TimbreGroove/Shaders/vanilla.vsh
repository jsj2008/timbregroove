//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//

attribute vec4 a_position;

uniform mat4  u_pvm;

void main() {
	gl_Position = u_pvm * a_position;
}

