//
//  Vanilla.m
//  TimbreGroove
//
//  Created by victor on 12/14/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Vanilla.h"
#import "TGVertexBuffer.h"
#import "TGVariables.h"

@implementation Vanilla

-(Vanilla *)initWithColor:(float*)color andData:(float *)data numVectors:(unsigned int)nv
{
    if( (self = [super initWithName:@"vanilla"]) )
    {
        _buffer = [[TGVertexBuffer alloc] init];
        
        TGVertexStride s;
        StrideInit3fv(&s, "a_position");
        [_buffer setData:data strides:&s countStrides:1 numElem:nv shader:self];
        
        [self.uniforms write:@"u_color" type:TG_VECTOR4 data:color];
    }
    
    return self;
}

-(void)preRender:(unsigned int)phase
{
    [self writePVM:@"u_mvpMatrix"];
}
@end
