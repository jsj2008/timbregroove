//
//  Config.m
//  TimbreGroove
//
//  Created by victor on 2/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Config.h"

static Config * __sharedConfig;

@interface Config () {
    NSDictionary * _plistConfig;
}

@end
@implementation Config

-(id)init
{
    self = [super init];
    
    if( self )
    {
        NSString * configPath = [[NSBundle mainBundle] pathForResource:@"config"
                                                                ofType:@"plist" ];
        _plistConfig = [NSDictionary dictionaryWithContentsOfFile:configPath];
    }
    
    return self;
}

-(id)valueForUndefinedKey:(NSString *)key
{
    return _plistConfig[key];
}

+(Config *)sharedInstance
{
    @synchronized(self) {
        if( !__sharedConfig )
            __sharedConfig = [Config new];
    }
    
    return __sharedConfig;
}
@end
