//
//  TGGenericShader.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Shader.h"

@interface __GenericShader : Shader

-(id)initWithName:(NSString *)name andHeader:(NSString *)header;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) float      opacity;
@property (nonatomic) GLKMatrix4 pvm;
@property (nonatomic) bool       useLighting;

@end
