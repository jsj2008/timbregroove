//
//  PoolWater.vsh
//


attribute vec4 a_position;
attribute vec2 a_uvs;

uniform mat4 u_pvm;
varying vec2 v_st;

void main(void)
{
    v_st = a_uvs;
    gl_Position = a_position;
}