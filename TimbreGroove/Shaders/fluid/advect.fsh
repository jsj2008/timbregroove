precision highp float;
uniform sampler2D source;
uniform sampler2D velocity;
uniform float dt;
uniform float scale;
uniform vec2 px1;
varying vec2 uv;

void main(){
/*
    vec2 velPixel = texture2D(velocity,uv).xy;
    vec2 pos = velPixel * dt * px1;
    vec4 pixel = texture2D(source,uv-pos);
    gl_FragColor = pixel * scale;
*/
  gl_FragColor = texture2D(source, uv-texture2D(velocity, uv).xy*dt*px1)*scale;
    
}
