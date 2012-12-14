//
//  TGVariables.h
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    TG_FLOAT,
    TG_VECTOR2,
    TG_VECTOR3,
    TG_VECTOR4,
    TG_MATRIX4,
    TG_BOOL
} TGUniformType;

@class TGShader;

@interface TGVariables : NSObject

@property (nonatomic,weak,readonly) TGShader * shader;

-(TGVariables *)initWithShader:(TGShader *)shader;

-(void)write:(NSString *)name type:(TGUniformType)type data:(void*)data;
- (GLint) glNameForName:(NSString *)name program:(GLuint)program;

@end
