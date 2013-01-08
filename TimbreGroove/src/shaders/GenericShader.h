//
//  TGGenericShader.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "Shader.h"

@interface GenericShader : Shader

-(id)initWithName:(NSString *)name andHeader:(NSString *)header;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) GLKMatrix4 pvm;
@property (nonatomic) GLKMatrix3 normalMat;
@property (nonatomic) GLKVector3 lightDir;
@property (nonatomic) GLKVector3 dirColor;
@property (nonatomic) GLKVector3 ambient;

@end
