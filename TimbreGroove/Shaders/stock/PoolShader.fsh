//
//  PoolShader.fsh
//  created with Shaderific
//


varying mediump vec3 eyespaceNormal;
varying highp vec4 eyespacePosition;
varying highp vec3 objectspacePosition;

uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;
uniform sampler2D texture0;
uniform highp vec4 lightPosition;

uniform highp float time;

const highp float M_PI = 3.14159;
const highp float M_2PI = 6.28318;


varying mediump vec2 textureCoordinate;

void main(void)
{
    
    highp float theta = asin(objectspacePosition.y / length(objectspacePosition.xyz));
    highp float phi = atan(objectspacePosition.z , objectspacePosition.x);
  //  mediump vec2 textureCoordinate = vec2(theta / M_PI, phi / M_2PI);
    
    highp vec2 position = (textureCoordinate - 0.5) * 2.0;
    highp float length = length(position);
    highp vec2 direction = position / length;
        
    highp vec2 st = textureCoordinate.xy + direction * cos(length * 20.0 - time * 10.0) * 0.005;
    highp vec3 materialDiffuseColor = texture2D(texture0, st).xyz;
    
    highp vec3 materialSpecularColor = materialSpecularColor.xyz;
    
    highp vec3 lightDirection;; 
    
    if (lightPosition.w == 0.0)
    lightDirection = normalize(vec3(lightPosition));
    else
    lightDirection = normalize(vec3(lightPosition - eyespacePosition)); 
    
    highp vec3 normal = normalize(eyespaceNormal);
    highp vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    highp vec3 halfPlane = normalize(lightDirection + viewDirection);
    
    highp float diffuseFactor = max(0.1, 1.5 * dot(normal, lightDirection)); 
    highp float specularFactor = max(0.0, dot(normal, halfPlane)); 
    
    specularFactor = pow(specularFactor, materialSpecularExponent);
        
    highp vec3 color = diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;
    
    gl_FragColor = vec4(color, 1);
    
}