//
//  Created by victor on 10/25/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
//
precision highp float;

attribute vec4 a_position;
uniform mat4 u_pvm;


#ifdef TEXTURE
attribute vec2 a_uv;
varying lowp vec2 v_texCoordOut;
#endif

#ifdef COLOR
attribute vec4 a_color;
varying vec4 v_color;
#endif

#ifdef BONES
attribute int a_boneIndex;
attribute float int a_boneWeights;
#endif

#ifdef NORMAL
attribute vec3 a_normal;

uniform mat3 u_normalMat;
uniform vec3 u_lightDir;
uniform vec3 u_lightPosition;

#ifdef AMBIENT_LIGHTING
uniform vec3 u_dirColor;
uniform vec3 u_ambient;

varying vec3 v_lightFilter;

void sendAmbientLight()
{
    vec3 transformedNormal = u_normalMat * a_normal;
    float directionalLightWeighting = max(dot(transformedNormal, u_lightDir), 0.0);
    v_lightFilter = u_ambient + u_dirColor * directionalLightWeighting;
}
#endif

#ifdef PHONG_LIGHTING


varying vec4  v_phongLitColor;

uniform vec4  u_phongColors[6];
uniform float u_phongValues[3];

const int PhongColor_Emission = 0;
const int PhongColor_Ambient = 1;
const int PhongColor_Diffuse = 2;
const int PhongColor_Specular = 3;
const int PhongColor_Reflective = 4;
const int PhongColor_Transparent = 5;

const int PhongValue_Shininess = 0;
const int PhongValue_Reflectivity = 1;
const int PhongValue_Transparency = 2;

void phongLighting(vec3 position)
{
    vec3 materialAmbientColor  = u_phongColors[PhongColor_Ambient].xyz;
    vec3 materialDiffuseColor  = u_phongColors[PhongColor_Diffuse].xyz;
    vec3 materialSpecularColor = u_phongColors[PhongColor_Specular].xyz;

    vec3 lightDirection;
    
    if (u_lightPos.w == 0.0)
        lightDirection = normalize(vec3(u_lightPosition));
    else
        lightDirection = normalize(vec3(u_lightPosition - u_pvm * position)); 

    vec3 eyespaceNormal  = u_normalMat * a_normal;
    vec3 viewDirection   = vec3(0.0, 0.0, 1.0);
    vec3 halfPlane       = normalize(lightDirection + viewDirection);

    float diffuseFactor  = max(0.0, dot(eyespaceNormal, lightDirection)); 
    float specularFactor = max(0.0, dot(eyespaceNormal, halfPlane)); 

    specularFactor = pow(specularFactor, u_phongValues[PhongValue_Shininess]);
    vec3 color = materialAmbientColor + (diffuseFactor * materialDiffuseColor) + (specularFactor * materialSpecularColor);

    v_phongLitColor = vec4(color, 1.0);
#endif

#endif

#ifdef TIME
uniform float u_time;
varying float v_time;
#endif

void main()
{
    vec3 pos = a_position.xyz;

#ifdef TEXTURE
    v_texCoordOut = a_uv;
#endif
    
#ifdef COLOR
    v_color = a_color;
#endif
    
#ifdef AMBIENT_LIGHTING
    sendAmbientLight();
#endif
    
#ifdef PHONG_LIGHTING
    phongLighting(a_position);
#endif

#ifdef TIME
    v_time = u_time;
#endif

	gl_Position   = u_pvm * vec4(pos,a_position.w);


}

