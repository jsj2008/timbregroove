//
//  TGGenericShader.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGTypes.h"
#import "TGShader.h"

@interface TGGenericShader : TGShader

-(TGGenericShader *)initWithParams:(TGGenericElementParams *)params;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) float opacity;

-(void)writeUniforms:(float *)matrix;

@end
