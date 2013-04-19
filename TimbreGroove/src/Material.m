//
//  TGTexture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Material.h"
#import "Shader.h"
#import "Generic.h"
#import "GenericShader.h"

@implementation ColorMaterial
+(id)withColor:(GLKVector4)color
{
    ColorMaterial * cm = [ColorMaterial new];
    cm->_color = color;
    return cm;
}
-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureUColor];
}
-(void)bind:(Shader *)shader object:(Generic *)object
{
    [shader writeToLocation:gv_ucolor type:TG_VECTOR4 data:_color.v];
}
-(void)unbind:(Shader *)shader {}
-(void)setShader:(Shader *)shader{}
@end

@implementation AmbientLighting
-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeatureAmbientLighting];
}
-(void)bind:(Shader *)shader object:(Generic *)object
{
    [shader writeToLocation:gv_ambient  type:TG_VECTOR3 data:_ambientColor.v];
    [shader writeToLocation:gv_dirColor type:TG_VECTOR3 data:_dirColor.v];
}
-(void)unbind:(Shader *)shader {}
-(void)setShader:(Shader *)shader{}
@end

@implementation PhongLighting {
    GLKVector4 _colors[ PhongColor_NUM_COLORS ];
    float      _values[ PhongValue_NUM_FLOATS ];
}

-(void)getShaderFeatureNames:(NSMutableArray *)putHere
{
    [putHere addObject:kShaderFeaturePhongLighting];
}

-(void)setMaterials:(GLKVector4 *)colors values:(float *)values
{
    memcpy(_colors,colors,sizeof(_colors));
    memcpy(_values,values,sizeof(_values));
}

-(void)getMaterials:(GLKVector4 **)colors values:(float **)values
{
    *colors = _colors;
    *values = _values;
}

-(void)bind:(Shader *)shader object:(Generic *)object
{
    glUniform4fv( [shader location:gv_phongColors], PhongColor_NUM_COLORS, (const GLfloat *)_colors);
    glUniform1fv( [shader location:gv_phoneValues], PhongValue_NUM_FLOATS, (const GLfloat *)_values);
}
-(void)unbind:(Shader *)shader {}
-(void)setShader:(Shader *)shader{}
@end

#pragma mark -

@implementation Texture {
    GLuint               _glTexture;
    GLenum               _target;
    GLKTextureInfoOrigin _origin;
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


-(void)bind:(Shader *)shader object:(Generic *)object
{
    [self bind:_target];
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
    glActiveTexture(GL_TEXTURE0 + target);
    glBindTexture(GL_TEXTURE_2D, _glTexture);
    glUniform1i(_uLocation, target);
    _target = target;
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
