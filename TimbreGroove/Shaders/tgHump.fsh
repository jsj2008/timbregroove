//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//


precision mediump float;

varying lowp vec2 v_TexCoordOut;

uniform sampler2D u_texture;

void main() {
    gl_FragColor = texture2D(u_texture, v_TexCoordOut);
}
