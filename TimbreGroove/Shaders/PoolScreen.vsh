//
//  PoolWater.vsh
//


attribute vec4 a_position;
attribute vec2 a_uvs;

uniform mat4 u_pvm;
uniform vec2 u_scale;
varying vec2 v_st;

void main(void)
{
    v_st = a_uvs * (1.0+u_scale);
    gl_Position = a_position;
}