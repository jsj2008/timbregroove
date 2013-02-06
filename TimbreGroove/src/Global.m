//
//  Global.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Global.h"

static Global * __sharedGlobal;

@implementation Global

-(id)init
{
    self = [super init];
    if( self )
    {
        _BPM = FACTORY_BPM;
    }
    return self;
}

-(NSTimeInterval)lengthOfQuarterNote
{
    return (NSTimeInterval)(60.0) / _BPM;
}

-(NSTimeInterval)lengthOf8thNote
{
    return (NSTimeInterval)(60.0) / (_BPM*2.0);
}

-(NSTimeInterval)lengthOf16thNote
{
    return (NSTimeInterval)(60.0) / (_BPM*4.0);
}

+(Global *)sharedInstance
{
    @synchronized(self) {
        if( !__sharedGlobal )
            __sharedGlobal = [Global new];
    }
    
    return __sharedGlobal;
}
@end
