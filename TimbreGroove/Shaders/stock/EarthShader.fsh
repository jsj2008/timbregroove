//
//  EarthShader.fsh
//  created with Shaderific
//

varying mediump vec3 eyespaceNormal;
varying highp vec4 eyespacePosition;
varying mediump vec2 textureCoordinate;
 
uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;
uniform highp vec4 lightPosition;

uniform highp float time;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;


void main(void)
{
    
    // Surface texture and lighting
    
    highp vec3 materialDiffuseColor = texture2D(texture0, textureCoordinate).xyz;
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
    

    // Specular map    
    
    specularFactor *= texture2D(texture1, textureCoordinate).x;
    
    
    // Cloud map
    
    highp vec2 newTextureCoordinate = vec2(textureCoordinate.x + time / 300.0, textureCoordinate.y);
    
    highp vec2 position = (newTextureCoordinate - 0.5) * 2.0;
    highp float length = length(position);
    highp vec2 direction = position / length;
    
    highp vec2 st = newTextureCoordinate.xy + direction * cos(length * 20.0 - time * 0.5) * 0.01;
    highp vec3 clouds = texture2D(texture2, st).xyz;
    highp float density = clouds.x * 0.8;
    
    materialDiffuseColor = clouds * density + materialDiffuseColor * (1.0 - density);
    specularFactor = specularFactor * (1.0 - density);
    
    
    // Night lights map
    
    if (diffuseFactor < 0.3) {
    
        // Smooth the day / night transition
        diffuseFactor = diffuseFactor + (0.3 - diffuseFactor) * 20.0 * length(texture2D(texture3, textureCoordinate).xyz);
        
        // Declorize the night lights
        mediump float brightness = (materialDiffuseColor.x + materialDiffuseColor.y + materialDiffuseColor.z) / 3.0;
        materialDiffuseColor = vec3((materialDiffuseColor.x + 2.0 * brightness) / 3.0, 
                                    (materialDiffuseColor.y + 2.0 * brightness) / 3.0, 
                                    (materialDiffuseColor.z + 2.0 * brightness) / 3.0);
            
    }
    
    // Resulting color
    
    highp vec3 color = diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;
    
    gl_FragColor = vec4(color, 1);
    
}