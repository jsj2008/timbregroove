//
//  TGVariables.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGTypes.h"


@class TGShader;

@interface TGVariables : NSObject

@property (nonatomic,weak,readonly) TGShader * shader;

-(TGVariables *)initWithShader:(TGShader *)shader;

-(void)write:(NSString *)name type:(TGUniformType)type data:(void*)data;
- (GLint) glNameForName:(NSString *)name program:(GLuint)program;

@end
