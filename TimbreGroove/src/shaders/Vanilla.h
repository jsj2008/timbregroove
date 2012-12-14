//
//  Vanilla.h
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGShader.h"

@class TGVertexBuffer;

@interface Vanilla : TGShader

@property (nonatomic,strong) TGVertexBuffer * buffer;
-(Vanilla *)initWithColor: (float*)color andData:(float *)data numVectors:(unsigned int)nv;

@end
