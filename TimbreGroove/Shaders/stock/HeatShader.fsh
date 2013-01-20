//
//  HeatShader.fsh
//  created with Shaderific
//


precision highp float;
precision highp int;

varying vec3 colorVarying;

void main(void)
{

    gl_FragColor = vec4(colorVarying, 1); 
    
}
