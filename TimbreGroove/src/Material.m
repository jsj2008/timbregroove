//
//  TGTexture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Material.h"
#import "Shader.h"
#import "Painter.h"
#import "GenericShader.h"

/*
@property (nonatomic) MaterialColors colors;
@property (nonatomic) float shininess;
@property (nonatomic) bool  doLighting;
@property (nonatomic) bool  doSpecular;
+(id)withColor:(GLKVector4)color;
+(id)withColors:(MaterialColors)matcolors shininess:(float)shininess;
*/
@implementation Material
+(id)withColor:(GLKVector4)color
{
    Material * m = [Material new];
    m->_colors.diffuse = color;
    m->_colors.ambient = (GLKVector4){ 1, 1, 1, 1 };
    m->_colors.specular = (GLKVector4){ 1, 1, 1, 1 };
    return m;
}
+(id)withColors:(MaterialColors)matcolors shininess:(float)shininess doSpecular:(bool)doSpecular
{
    Material * m = [Material new];
    m->_colors = matcolors;
    m->_shininess = shininess;
    m->_doSpecular = doSpecular;
    return m;
}

-(void)bind:(Shader *)shader object:(Painter *)object
{
    [shader writeToLocation:gv_material   type:TG_VECTOR4 data:&_colors count:4];
    [shader writeToLocation:gv_shininess  type:TG_FLOAT data:&_shininess];
    [shader writeToLocation:gv_doSpecular type:TG_BOOL data:&_doSpecular];
}

-(GLKVector4)ambient
{
    return _colors.ambient;
}

-(void)setAmbient:(GLKVector4)ambient
{
    _colors.ambient = ambient;
}

-(GLKVector4)diffuse
{
    return _colors.diffuse;
}

-(void)setDiffuse:(GLKVector4)diffuse
{
    _colors.diffuse = diffuse;
}

-(GLKVector4)specular
{
    return _colors.specular;
}

-(void)setSpecular:(GLKVector4)specular
{
    _colors.specular = specular;
}

-(void)unbind:(Shader *)shader {}
@end

#pragma mark -

@implementation Texture {
    GLuint               _glTexture;
    GLenum               _target;
    GLKTextureInfoOrigin _origin;
    NSString * _fileName;
}

-(NSString *)fileName
{
    return _fileName;
}

-(id)initWithFileName:(NSString *)fileName
{
    if( (self = [super init]) )
    {
        if( ![self loadFromFile:fileName] )
            return nil;
        _uLocation = -1;
    }
    
    return self;
}

-(id)initWithGlTextureId:(GLuint)glTextureId
{
    if( (self = [super init]) )
    {
        _glTexture = glTextureId;
        TGLog(LLGLResource, @"assigned texture for (%d)",_glTexture);
        _uLocation = -1;
    }
    
    return self;
}

-(id)initWithImage:(UIImage *)image
{
    if( (self = [super init]) )
    {
        if( ![self loadFromImage:image] )
            return nil;
        _uLocation = -1;
    }
    return self;
}

-(id)initWithString:(NSString *)text
{
    if( (self = [super init]) )
    {
        NSNumber * nyes = [NSNumber numberWithBool:YES];
        UIFont *font = [UIFont fontWithName:@"Arial" size:50];
        CGSize size  = [text sizeWithFont:font];
        
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);

        CGContextRef cf = UIGraphicsGetCurrentContext ();
        CGContextSetFillColorWithColor(cf, [UIColor whiteColor].CGColor);
        [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
        // TODO: Am I supposed to Release() something here?
        CGImageRef imageRef = [UIGraphicsGetImageFromCurrentImageContext() CGImage];

        // see http://stackoverflow.com/questions/8611063/glktextureloader-fails-when-loading-a-certain-texture-the-first-time-but-succee
        glGetError();
       
        NSError * err = nil;
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                                   options: @{
                   //                 GLKTextureLoaderApplyPremultiplication: nyes,
                                          GLKTextureLoaderOriginBottomLeft: nyes }
                                                                     error: &err];
        
        if( textureInfo )
        {
             _glTexture  = textureInfo.name;
             _target     = textureInfo.target;
             _origin     = textureInfo.textureOrigin;
            TGLog(LLGLResource, @"created texture for %@ (%d)",text,_glTexture);
        }
        else
        {
            TGLog(LLShitsOnFire, @"FAILURE: %@\nDESCRIPTION: %@", [err localizedFailureReason],
                                                   [err localizedDescription]);
        }
        
        UIGraphicsEndImageContext();
        _uLocation = -1;
    }

    return self;
}

-(bool)loadFromFile:(NSString *)fileName
{
    _fileName = fileName;
    NSString * path = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
    UIImage * image = [UIImage imageWithContentsOfFile:path];
    bool ok = [self loadFromImage:image];
    TGLog(LLGLResource, @"created texture for %@ (%d)",fileName,_glTexture);
    return ok;
}

-(bool)loadFromImage:(UIImage *)image
{
    bool ok = true;
    NSNumber * nyes = [NSNumber numberWithBool:YES];
    CGImageRef imageRef = [image CGImage];
    
    _orgSize = [image size];
    
    // see http://stackoverflow.com/questions/8611063/glktextureloader-fails-when-loading-a-certain-texture-the-first-time-but-succee
    glGetError();
    
    NSError * err = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                               options: @{
                            //   GLKTextureLoaderApplyPremultiplication: nyes,
                                      GLKTextureLoaderOriginBottomLeft: nyes }
                                                                 error: &err];
    
    if( textureInfo )
    {
        _glTexture  = textureInfo.name;
        _target     = textureInfo.target;
        _origin     = textureInfo.textureOrigin;
    }
    else
    {
        TGLog(LLShitsOnFire, @"FAILURE: %@\nDESCRIPTION: %@", [err localizedFailureReason], [err localizedDescription]);
        ok = false;
    }
    
    return ok;
}

/*
 
 // load from asset
 
 AssetLoader * _ati;

 
 -(void)setTextureFileName:(id)textureFileName
 {
 _textureFileName = textureFileName;
 if( [textureFileName isKindOfClass:[NSURL class]] )
 {
 _ati = [[AssetToImage alloc] initWithURL:textureFileName andTarget:self andKey:@"textureImage"];
 }
 else
 {
 self.texture = [[Texture alloc] initWithFileName:_textureFileName];
 }
 }
 
 // be careful not to call this setter while
 // another part of the code triggers the AssetToImage
 // call above
 -(void)setTextureImage:(UIImage *)image
 {
 self.texture = [[Texture alloc] initWithImage:image];
 _ati = nil;
 }
 
 */

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureTexture];
}


-(void)bind:(Shader *)shader object:(Painter *)object
{
    [self bind:0]; // er, always zero for single texture blits? 
}

-(void)unbind:(Shader *)shader
{
    glActiveTexture(GL_TEXTURE0 + _target);
    glBindTexture(GL_TEXTURE_2D, 0); // 0 is reserved for unbind
}

-(void)setShader:(Shader *)shader
{
    _uLocation = [shader location:gv_sampler];
}

-(void)bind:(int)target
{
    _target = target;
    glActiveTexture(GL_TEXTURE0 + target);
    glBindTexture(GL_TEXTURE_2D, _glTexture);
    glUniform1i(_uLocation, target);
    if( _repeat )
    {
        glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
        glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    }
}


-(void)dealloc
{
    glDeleteTextures(1, &_glTexture);
    TGLog(LLGLResource | LLObjLifetime, @"Deleted texture: %d",_glTexture);
    _glTexture = 0;
}

@end
