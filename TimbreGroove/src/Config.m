//
//  Config.m
//  TimbreGroove
//
//  Created by victor on 2/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define TimbreGroove_ConfigNames_h // prevent extern decls here
#import "Config.h"

NSString * const kConfigDefaultScene  = @"default_scene";

NSString * const kConfigScenes           = @"scenes";
NSString * const kConfigSceneIcon        = @"icon";
NSString * const kConfigSceneDisplayName = @"display";
NSString * const kConfigSceneAudio       = @"audio_element";
NSString * const kConfigScene3d          = @"3d_element";
NSString * const kConfigSceneConnections = @"connections";

NSString * const kConfigAudioProfiles      = @"audio_elements";
NSString * const kConfigAudioInstanceClass = @"instanceClass";
NSString * const kConfigAudioMidiFile      = @"midifile";
NSString * const kConfigAudioInstruments   = @"instruments";

NSString * const kConfigEQPanel = @"eqcube";

NSString * const kConfigInstruments           = @"instruments";
NSString * const kConfigInstrumentIsSoundFont = @"isSoundfont";
NSString * const kConfigInstrumentPatch       = @"patch";
NSString * const kConfigInstrumentPreset      = @"preset";
NSString * const kConfigInstrumentLowNote     = @"lo";
NSString * const kConfigInstrumentHighNote    = @"hi";


NSString * const kConfig3dElements      = @"3d_elements";
NSString * const kConfig3dInstanceClass = @"instanceClass";
NSString * const kConfig3dMenuOrder     = @"order";
NSString * const kConfig3dIcon          = @"icon";
NSString * const kConfig3dCustomProperties = @"userData";

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
+(Config *)sharedInstance
{
    @synchronized (self) {
        if( !__sharedConfig )
            __sharedConfig = [Config new];
    }
    return __sharedConfig;
}
-(ConfigScene *)defaultScene { return [self getScene:_plistConfig[kConfigDefaultScene]]; }
-(NSArray *)getSceneNames { return [_plistConfig[kConfigScenes] allKeys]; }
-(ConfigScene *)getScene:(NSString *)name {
    return [[ConfigScene alloc] initWithD:[_plistConfig[kConfigScenes] valueForKey:name]];
}
-(ConfigInstrument *)getInstrument:(NSString *)name {
    return [[ConfigInstrument alloc] initWithD:[_plistConfig[kConfigInstruments] valueForKey:name]];
}
-(ConfigAudioProfile *)getAudioProfile:(NSString *)name {
    return [[ConfigAudioProfile alloc] initWithD:[_plistConfig[kConfigAudioProfiles] valueForKey:name]];
}
-(ConfigGraphicElement *)getGraphicElement:(NSString *)name {
    return [[ConfigGraphicElement alloc] initWithD:[_plistConfig[kConfig3dElements] valueForKey:name]];
}
@end

@implementation ConfigBase

-(id)initWithD:(NSDictionary *)d
{
    self = [super init];
    if( self )
    {
        _me = d;
    }
    return self;
}

@end

@implementation ConfigGraphicElement
-(NSString *)icon { return [_me valueForKey:kConfig3dIcon]; }
-(int)menuOrder { return [[_me valueForKey:kConfig3dMenuOrder] intValue]; }
-(NSString *)instanceClass { return [_me valueForKey:kConfig3dInstanceClass]; }
-(NSDictionary *)customProperties { return [_me valueForKey:kConfig3dCustomProperties]; }
@end

@implementation ConfigInstrument
-(bool)isSoundFont { return [[_me valueForKey:kConfigInstrumentIsSoundFont] boolValue] == YES; }
-(int)patch { return [[_me valueForKey:kConfigInstrumentPatch] intValue]; }
-(NSString *)preset { return [_me valueForKey:kConfigInstrumentPreset]; }
-(int)low { return [[_me valueForKey:kConfigInstrumentLowNote] intValue]; }
-(int)high { return [[_me valueForKey:kConfigInstrumentHighNote] intValue]; }
@end

@implementation ConfigAudioProfile
-(NSString *)midiFile { return [_me valueForKey:kConfigAudioMidiFile]; }
-(NSString *)instanceClass { return [_me valueForKey:kConfigAudioInstanceClass]; }
-(NSDictionary *)customProperties { return [_me valueForKey:kConfig3dCustomProperties]; }
-(NSDictionary*)instruments
{
    NSMutableDictionary * dict = [NSMutableDictionary new];
    NSArray * names = [_me valueForKey:kConfigAudioInstruments];
    for( NSString * name in names )
        dict[name] = [__sharedConfig getInstrument:name];
    return dict;
}
@end

@implementation ConfigScene
-(NSString *)icon { return [_me valueForKey:kConfigSceneIcon]; }
-(NSString *)displayName { return [_me valueForKey:kConfigSceneDisplayName]; };
-(ConfigAudioProfile *)audioElement { return [__sharedConfig getAudioProfile:[_me valueForKey:kConfigSceneAudio]];}
-(ConfigGraphicElement *)graphicElement { return [__sharedConfig getGraphicElement:[_me valueForKey:kConfigScene3d]];}
-(NSArray *)connections { return [_me valueForKey:kConfigSceneConnections]; };
@end
