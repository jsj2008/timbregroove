//
//  TGShader.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TGVariables;

@interface TGShader : NSObject

- (TGShader *)initWithName:(NSString *)name;
- (TGShader *)initWithVertex:(NSString *)vname andFragment:(NSString *)fname;


@property (nonatomic, strong) TGVariables * uniforms;
@property (nonatomic)         GLuint        program;
@property (nonatomic)         GLKMatrix4    pvm;

- (void)use;
- (void)preRender:(unsigned int)phase;
- (void)writePVM:(NSString *)name;

@end
