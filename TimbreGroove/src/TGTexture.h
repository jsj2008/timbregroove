//
//  TGTexture.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGTexture : NSObject

@property (nonatomic) GLuint glName;
@property (nonatomic) GLenum glTarget;

-(TGTexture *)initWithFileName:(NSString *)fileName;
-(bool)loadFromFile:(NSString *)fileName;

@end
