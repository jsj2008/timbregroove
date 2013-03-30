uniform sampler2D sTexture;

varying lowp    float LightIntensity;
varying mediump vec2  TexCoord;

void main()
{
    gl_FragColor = vec4(1) + (texture2D(sTexture, TexCoord) * LightIntensity);
}
