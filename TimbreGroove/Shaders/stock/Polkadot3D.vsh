//
//  Polkadot3D.vsh
//  created with Shaderific
//
//  This is the Vertex Shader for three dimensional polka dots.
//
//  Author:  Joshua Doss
//
//  Copyright (c) 2005-2006 3Dlabs Inc. Ltd.
//
//  See the file menu for license information
//

attribute vec4 position;
attribute vec3 normal;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;
uniform vec4 lightPosition;
uniform float materialSpecularExponent;

varying vec3 MCPosition;
varying float LightIntensity;

const float SpecularContribution = 0.3;
const float diffusecontribution  = 1.0 - SpecularContribution;

void main(void)
{

    vec3 LightPosition = lightPosition.xyz;
    
    // compute the vertex position in eye coordinates
    vec3  ecPosition           = vec3(modelViewMatrix * position);
    
    // compute the transformed normal
    vec3  tnorm                = normalize(normalMatrix * normal);
    
    // compute a vector from the model to the light position
    vec3  lightVec             = normalize(LightPosition - ecPosition);
    
    // compute the reflection vector
    vec3  reflectVec           = reflect(-lightVec, tnorm);
    
    // compute a unit vector in direction of viewing position
    vec3  viewVec              = normalize(-ecPosition);
    
    // calculate amount of diffuse light based on normal and light angle
    float diffuse              = max(dot(lightVec, tnorm), 0.0);
    float spec                 = 0.0;
    
    // if there is diffuse lighting, calculate specular
    if(diffuse > 0.0)
       {
          spec = max(dot(reflectVec, viewVec), 0.0);
          spec = pow(spec, materialSpecularExponent);
       }
    
    // add up the light sources, since this is a varying (global) it will pass to frag shader     
    LightIntensity  = diffusecontribution * diffuse * 1.5 +
                          SpecularContribution * spec;
    
    // the varying variable MCPosition will be used by the fragment shader to determine where
    //    in model space the current pixel is                      
    MCPosition      = vec3 (position);
    
    // send vertex information
    gl_Position     = modelViewProjectionMatrix * position;

}

