//
//  ToneGenerator.m
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "ToneGenerator.h"
#import "Config.h"

@implementation ToneGeneratorProxy

-(id)initWithChannel:(int)channel andAU:(AudioUnit)au
{
    self = [super init];
    if( self )
    {
        _au = au;
        _channel = channel;
    }
    return self;
}

-(id<ToneGeneratorProtocol>)loadGenerator:(ConfigToneGenerator *)config
{
    Class klass = NSClassFromString(config.instanceClass);
    _generator = [[klass alloc] init];
    NSDictionary * userData = config.customProperties;
    if( userData )
        [(NSObject *)_generator setValuesForKeysWithDictionary:userData];
    [_generator renderProcForToneGenerator:self];
    return _generator;
}
@end
