//
//  DepthShader.vsh
//  created with Shaderific
//

attribute vec4 position;

uniform mat4 modelViewProjectionMatrix;
uniform vec4 materialDiffuseColor0;

varying lowp vec4 colorVarying;

void main()
{

    float z = (position.z + 0.5) * 1.2;
    
    colorVarying = vec4(materialDiffuseColor0.x * z, materialDiffuseColor0.y * z, materialDiffuseColor0.z * z, 1.0);
    gl_Position = modelViewProjectionMatrix * position;

}