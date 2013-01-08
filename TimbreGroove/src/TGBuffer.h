//
//  TGBuffer.h
//  TimbreGroove
//
//  Created by victor on 12/12/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGBuffer : NSObject
@property (nonatomic) GLuint glindex;
-(void)setData:(float *)data count:(unsigned int)count;
@end
