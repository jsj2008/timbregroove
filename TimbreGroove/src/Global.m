//
//  Global.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#define NO_GLOBAL_DECLS
#import "Global.h"

NSString const * kGlobalScene        = @"scene";
NSString const * kGlobalRecording    = @"recording";
NSString const * kGlobalDisplayGraph = @"displayGraph";

static Global * __sharedGlobal;

@implementation Global

-(id)init
{
    self = [super init];
    if( self )
    {
    }
    return self;
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
