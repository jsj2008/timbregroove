precision highp float;
uniform sampler2D velocity;
uniform float dt;
uniform vec2 px1;
varying vec2 uv;

void main(){
    float x0 = texture2D(velocity, uv-vec2(px1.x, 0)).x;
    float x1 = texture2D(velocity, uv+vec2(px1.x, 0)).x;
    float y0 = texture2D(velocity, uv-vec2(0, px1.y)).y;
    float y1 = texture2D(velocity, uv+vec2(0, px1.y)).y;
    float divergence = (x1-x0 + y1-y0)*0.5;
    gl_FragColor = vec4(divergence);
}
