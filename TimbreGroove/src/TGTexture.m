//
//  TGTexture.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTexture.h"

@implementation TGTexture

-(TGTexture *)initWithFileName:(NSString *)fileName
{
    if( (self = [super init]) )
    {
        if( ![self loadFromFile:fileName] )
            return nil;
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
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                               options: @{
                                GLKTextureLoaderApplyPremultiplication: nyes,
                                      GLKTextureLoaderOriginBottomLeft: nyes
                                   }
                                                                 error: nil];
    if( textureInfo )
    {
        _glName   = textureInfo.name;
        _glTarget = textureInfo.target;
        _origin   = textureInfo.textureOrigin;
    }
    else
    {
        ok = false;
    }
    return ok;
    
}


@end
