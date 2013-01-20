//
//  TileShader.fsh
//  created with Shaderific
//


varying mediump vec3 normalVarying;
varying mediump vec2 textureCoordinate;

uniform mediump vec4 materialSpecularColor;
uniform mediump float materialSpecularExponent;
uniform mediump vec4 lightPosition;
uniform mediump mat3 normalMatrix;

uniform sampler2D texture0;
uniform sampler2D texture1;


void main(void)
{
    
    mediump vec2 repetitions = vec2(10.0, 5.0);

    mediump vec3 materialDiffuseColor = texture2D(texture0, textureCoordinate * repetitions).xyz;
    mediump vec3 materialSpecularColor = materialSpecularColor.xyz;
        
    highp float theta = acos(normalVarying.y); 
    highp float phi = atan(normalVarying.z, normalVarying.x);

    highp vec2 deltaNormal = (texture2D(texture1, textureCoordinate * repetitions).xy - 0.5) * 2.0;
    theta = theta + deltaNormal.y;
    phi = phi - deltaNormal.x;
  
    mediump vec3 normal = vec3(cos(phi) * sin(theta), cos(theta), sin(phi) * sin(theta));
    normal = normalMatrix * normal;


    mediump vec3 lightDirection = normalize(vec3(lightPosition));    
    mediump vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    mediump vec3 halfPlane = normalize(lightDirection + viewDirection);
    
    mediump float diffuseFactor = max(0.0, dot(normal, lightDirection)); 
    mediump float specularFactor = max(0.0, dot(normal, halfPlane)); 
    
    specularFactor = pow(specularFactor, materialSpecularExponent);
    mediump vec3 color = diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;

    
    gl_FragColor = vec4(color, 1); 
    
}