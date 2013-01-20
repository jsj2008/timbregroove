//
//  ToonShader.fsh
//  created with Shaderific
//
//  Fragment shader for cartoon-style shading
//
//  Author: Philip Rideout
//
//  Copyright (c) 2005-2006 3Dlabs Inc. Ltd.
//
//  See the file menu for license information
//

varying mediump vec3 eyespaceNormal;
varying highp vec4 eyespacePosition;

uniform highp vec4 materialAmbientColor; 
uniform highp vec4 materialDiffuseColor0;
uniform highp vec4 materialSpecularColor;
uniform highp float materialSpecularExponent;

uniform highp vec4 lightPosition;

void main(void)
{

    highp vec3 materialAmbientColor = materialAmbientColor.xyz;
    highp vec3 materialDiffuseColor = materialDiffuseColor0.xyz;
    highp vec3 materialSpecularColor = materialSpecularColor.xyz;
    
    highp vec3 lightDirection;; 
    
    if (lightPosition.w == 0.0)
        lightDirection = normalize(vec3(lightPosition));
    else
        lightDirection = normalize(vec3(lightPosition - eyespacePosition)); 
    
    highp vec3 normal = normalize(eyespaceNormal);
    highp vec3 viewDirection = vec3(0.0, 0.0, 1.0);
    highp vec3 halfPlane = normalize(lightDirection + viewDirection);
    
    highp float diffuseFactor = max(0.0, dot(normal, lightDirection)); 
    highp float specularFactor = max(0.0, dot(normal, halfPlane)); 
    
    specularFactor = pow(specularFactor, materialSpecularExponent);


    if (diffuseFactor < 0.1) 
        diffuseFactor = 0.0;
    else if (diffuseFactor < 0.3) 
        diffuseFactor = 0.3; 
    else if (diffuseFactor < 0.6) 
        diffuseFactor = 0.6; 
    else 
        diffuseFactor = 1.0;

    specularFactor = step(0.5, specularFactor);
    

    highp vec3 color = materialAmbientColor + diffuseFactor * materialDiffuseColor + specularFactor * materialSpecularColor;
        
    
    gl_FragColor = vec4(color, 1); 
    
}