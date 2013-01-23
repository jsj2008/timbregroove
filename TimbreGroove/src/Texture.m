//
//  TGTexture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Texture.h"
#import "Shader.h"

@interface Material () {
}

@end

@implementation Material
@end

#pragma mark -

@interface Texture() {
    GLuint               _glTexture;
    GLenum               _target;
    GLKTextureInfoOrigin _origin;
}
@end

@implementation Texture

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
        NSLog(@"assigned texture for (%d)",_glTexture);        
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
            NSLog(@"created texture for %@ (%d)",text,_glTexture);
        }
        else
        {
            NSLog(@"FAILURE: %@\nDESCRIPTION: %@", [err localizedFailureReason],
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
    NSLog(@"created texture for %@ (%d)",fileName,_glTexture);
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
        NSLog(@"FAILURE: %@\nDESCRIPTION: %@", [err localizedFailureReason], [err localizedDescription]);
        ok = false;
    }
    
    return ok;
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

-(void)unbind
{
    glActiveTexture(GL_TEXTURE0 + _target);
    glBindTexture(GL_TEXTURE_2D, 0); // 0 is reserved for unbind
}

-(void)dealloc
{
    glDeleteTextures(1, &_glTexture);
    NSLog(@"Deleted texture: %d",_glTexture);
    _glTexture = 0;
}

@end
