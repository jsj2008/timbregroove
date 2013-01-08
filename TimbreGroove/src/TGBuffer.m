//
//  TGBuffer.m
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGBuffer.h"

@implementation TGBuffer

-(void)setData:(float *)data
         count:(unsigned int)count
{

    glGenBuffers(1, &_glindex);
    glBindBuffer(GL_ARRAY_BUFFER, _glindex);
    glBufferData(GL_ARRAY_BUFFER, count*sizeof(float), data, GL_STATIC_DRAW);

}
@end
