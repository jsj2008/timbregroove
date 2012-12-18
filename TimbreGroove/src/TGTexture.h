//
//  TGTexture.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"

@interface TGTexture : NSObject

@property (nonatomic) GLuint               glName;
@property (nonatomic) GLenum               glTarget;
@property (nonatomic) GLKTextureInfoOrigin origin;

-(TGTexture *)initWithFileName:(NSString *)fileName;
-(bool)loadFromFile:(NSString *)fileName;

@end
