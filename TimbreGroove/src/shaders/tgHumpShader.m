//
//  tgHumpShader.m
//  TG1
//
//  Created by victor on 11/10/12.
//
//

#import "tgHumpShader.h"
#import "Isgl3dGLTexture.h"
#import "Isgl3dGLTextureFactory.h"
#import "Isgl3dGLVBOData.h"

/*
 
 attribute vec3 a_position;    // vertex array maps here
 attribute vec2 a_texCoord0;  // uv array maps here
 
 varying lowp vec2 v_TexCoordOut;
 
 uniform mat4  u_viewprojMatrix;
 uniform float u_humpDimension;
 uniform vec3  u_apex;

 uniform sampler2D u_texture;

*/
@interface tgHumpShader () {
    Isgl3dGLTexture * m_xmaterial;
    unsigned int m_textureUnit;
    float __apex[3];
}
@end

@implementation tgHumpShader

+ (id) shaderWithKey:(NSString *)key {
	return [[self alloc] initWithKey:key];
}

- (id) initWithKey:(NSString *)key {
	if ((self = [super initWithVertexShaderFile:@"tgHump.vsh"
                             fragmentShaderFile:@"tgHump.fsh"
                                            key:key ])) {

        m_textureUnit =[Isgl3dCustomShader allocTextureUnit];

        _apex = __apex;
        float ax[3] = { 0.0f, 0.0f, 4.0f };
        self.apex = ax;
		[self setUniform1fWithName:@"u_humpDimension" value:4.0f];
        
	}
	return self;
}

- (void)setApex:(float *)apex
{
    __apex[0] = apex[0];
    __apex[1] = apex[1];
    __apex[2] = apex[2];
}

- (void)moveApexBy:(float)x y:(float)y z:(float)z
{
    __apex[0] += x;
    __apex[1] += y;
    __apex[2] += z;
//    NSLog(@"moving apex:%f, %f, %f",_apex[0],_apex[1],_apex[2]);
}


- (Isgl3dGLTexture *)setTextureFile:(NSString *)fileName {
    // Create textures
    m_xmaterial = [[Isgl3dGLTextureFactory sharedInstance] createTextureFromFile:fileName];
    
    // Set the texture units to use
    [self setUniformSamplerWithName:@"u_texture" forTextureUnit:m_textureUnit];
    
    return m_xmaterial;
}
/*
- (void) onRenderPhaseBeginsWithDeltaTime:(float)deltaTime {
	// Update the animation factor with a new render phase
}
*/

- (void) onModelRenderReady {
    
    [self bindTexture: m_xmaterial
          textureUnit: m_textureUnit ];
    
	[self setVertexAttribute: GL_FLOAT
               attributeName: @"a_position"
                        size: VBO_POSITION_SIZE
                 strideBytes: self.vboData.stride
                      offset: self.vboData.positionOffset ];

    [self setVertexAttribute: GL_FLOAT
               attributeName: @"a_texCoord0"
                        size: VBO_UV_SIZE
                 strideBytes: self.vboData.stride
                      offset: self.vboData.uvOffset ];

    [self setUniform3fvWithName: @"u_apex"
                         values: _apex];
    
	[self setUniformMatrix4WithName: @"u_viewprojMatrix"
                             matrix: self.modelViewProjectionMatrix];
}

@end
