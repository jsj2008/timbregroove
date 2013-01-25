//
//  PoolWater.fsh
//
precision highp float;

uniform float u_time;

uniform float        u_rippleSize; // between 1 - 10 (ideal: 10)
uniform float        u_turbulence; // between 0.001 - 0.01 (ideal: 0.005)
uniform sampler2D    u_texture;
uniform vec2         u_center;     // -1 - 1
uniform float        u_radius;
uniform float        u_mix;

varying mediump vec2 v_st;

vec4 drawit(vec2 center, float radius)
{
    vec2  pos       = (v_st - 0.5) * 2.0; // transpose to object space
    vec2  position  = pos + center;
    float length    = length(position);   // sqroot( x-sqr + y-sqr + z+sqr )
    vec2  direction = position / length;
    
    float ripple     = (length * (u_rippleSize*2.0)) - (u_time * u_rippleSize);
    vec2  st         = v_st + direction * cos(ripple) * u_turbulence;
    
    vec3 color       = texture2D(u_texture, st).xyz;
    
    float alpha      = 1.0 - (length / radius);

    return vec4(color, alpha);
    
}
void main(void)
{
    vec4 c1 = drawit(u_center,  u_radius);
    
    gl_FragColor = c1;
    
}