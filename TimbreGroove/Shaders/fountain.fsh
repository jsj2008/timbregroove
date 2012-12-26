//
//  Shader.fsh
//  TestOvals
//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

varying lowp vec4 v_colorVarying;

void main()
{
    gl_FragColor = v_colorVarying;
}
