//
//  TGTexture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Texture.h"
#import "__Shader.h"

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
    }
    
    return self;
}

-(id)initWithGlTextureId:(GLuint)glTextureId
{
    if( (self = [super init]) )
    {
        _glTexture = glTextureId;
    }
    
    return self;
}

-(id)initWithString:(NSString *)text
{
    if( (self = [super init]) )
    {
        UIFont *font = [UIFont fontWithName:@"Arial" size:50];
        CGSize size  = [text sizeWithFont:font];
        
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);

        CGContextRef cf = UIGraphicsGetCurrentContext ();
        CGContextSetFillColorWithColor(cf, [UIColor whiteColor].CGColor);
        [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
        // TODO: Am I supposed to Release() something here?
        CGImageRef imageRef = [UIGraphicsGetImageFromCurrentImageContext() CGImage];
        
        NSNumber * nyes = [NSNumber numberWithBool:YES];
        
        NSError * err;
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
    }

    return self;
}

-(bool)loadFromFile:(NSString *)fileName
{
    /*
     
     NSString *const GLKTextureLoaderApplyPremultiplication;
     NSString *const GLKTextureLoaderGenerateMipmaps;
     NSString *const GLKTextureLoaderOriginBottomLeft;
     NSString *const GLKTextureLoaderGrayscaleAsAlpha;
*/     
    bool ok = true;
    NSNumber * nyes = [NSNumber numberWithBool:YES];
    CGImageRef imageRef = [[UIImage imageNamed:fileName] CGImage];
    
    // see http://stackoverflow.com/questions/8611063/glktextureloader-fails-when-loading-a-certain-texture-the-first-time-but-succee
    glGetError();
    
    NSError * err;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                               options: @{
                                GLKTextureLoaderApplyPremultiplication: nyes,
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

-(void)bind:(__Shader *)shader target:(int)i
{
    glActiveTexture(GL_TEXTURE0 + i);
    glBindTexture(GL_TEXTURE_2D, _glTexture);
    glUniform1i(_uLocation, i);
}

@end
