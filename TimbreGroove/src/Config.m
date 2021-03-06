//
//  Config.m
//  TimbreGroove
//
//  Created by victor on 2/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//
#define TimbreGroove_ConfigNames_h // prevent extern decls here
#import "Config.h"

// d'oh the const in the wrong place - ah well, the "right" way
// is way too many warning messages at this point

NSString * const kConfigDefaultScene  = @"default_scene";
NSString * const kConfigEQPanelScene  = @"EQPanel";

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
NSString * const kConfigAudioGenerators    = @"generators";
NSString * const kConfigAudioCustomProperties  = @"properties";

NSString * const kConfigAudioEQ        =   @"EQ";
NSString * const kConfigEQBandLowPass  =   @"LowPass";
NSString * const kConfigEQBandParametric = @"Parametric";
NSString * const kConfigEQBandHighPass =   @"HightPass";

NSString * const kConfigEQPanel = @"eqcube";

NSString * const kConfigInstruments           = @"instruments";
NSString * const kConfigInstrumentIsSoundFont = @"isSoundfont";
NSString * const kConfigInstrumentPatch       = @"patch";
NSString * const kConfigInstrumentPreset      = @"preset";
NSString * const kConfigInstrumentLowNote     = @"lo";
NSString * const kConfigInstrumentHighNote    = @"hi";

NSString * const kConfigToneGenerators        = @"generators";
NSString * const kConfigToneInstanceClass     = @"instanceClass";
NSString * const kConfigToneCustomProperties  = @"properties";

NSString * const kConfig3dElements      = @"3d_elements";
NSString * const kConfig3dInstanceClass = @"instanceClass";
NSString * const kConfig3dMenuOrder     = @"order";
NSString * const kConfig3dIcon          = @"icon";
NSString * const kConfig3dCustomProperties = @"properties";

NSString * const kConfigModels = @"models";

NSString * const kConfigLogging = @"logging";

extern NSString const * textNameForkName( NSString const * kName );

NSDictionary * __mapParamNames(NSDictionary * dict)
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
    
	[dict each:^(NSString * kNameKey, NSString * kNameValue)
     {
         result[textNameForkName(kNameKey)] = textNameForkName(kNameValue);
     }];
	
	return result;
}

NSArray * mapParamNames(NSArray * inArr)
{
    return [inArr map:^id(id obj) { return  __mapParamNames(obj); }];
}

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
+(ConfigScene *)defaultScene
{ return [__sharedConfig getScene:__sharedConfig->_plistConfig[kConfigDefaultScene]]; }

-(NSDictionary *)getScenes {
    NSDictionary * scenConfigs = _plistConfig[kConfigScenes];
   return [scenConfigs map:^id(id name, id sceneDict) {
        return [[ConfigScene alloc] initWithD:sceneDict];
    }];
}
-(ConfigScene *)getScene:(NSString *)name {
    NSDictionary * scenes = _plistConfig[kConfigScenes];
    return [[ConfigScene alloc] initWithD:[scenes valueForKey:name]];
}
-(ConfigInstrument *)getInstrument:(NSString *)name {
    ConfigInstrument * config = [[ConfigInstrument alloc] initWithD:[_plistConfig[kConfigInstruments] valueForKey:name]];
    config.name = name;
    return config;
}
-(ConfigToneGenerator *)getToneGenerator:(NSString *)name {
    ConfigToneGenerator * config = [[ConfigToneGenerator alloc] initWithD:[_plistConfig[kConfigToneGenerators] valueForKey:name]];
    config.name = name;
    return config;
}
-(ConfigAudioProfile *)getAudioProfile:(NSString *)name {
    return [[ConfigAudioProfile alloc] initWithD:[_plistConfig[kConfigAudioProfiles] valueForKey:name]];
}
-(ConfigGraphicElement *)getGraphicElement:(NSString *)name {
    return [[ConfigGraphicElement alloc] initWithD:[_plistConfig[kConfig3dElements] valueForKey:name]];
}

-(NSDictionary *)getModel:(NSString *)name
{
    NSDictionary * models = _plistConfig[kConfigModels];
    return models[name];
}

+(NSDictionary *)getLoggingOpts
{
    if( !__sharedConfig )
        [Config sharedInstance];
    return  __sharedConfig->_plistConfig[kConfigLogging];
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

@implementation ConfigToneGenerator
-(NSString *)instanceClass { return [_me valueForKey:kConfigToneInstanceClass]; }
-(NSDictionary *)customProperties { return [_me valueForKey:kConfigToneCustomProperties]; }
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
-(NSString *)EQ { return [_me valueForKey:kConfigAudioEQ]; }
-(NSString *)instanceClass { return [_me valueForKey:kConfigAudioInstanceClass]; }
-(NSDictionary *)customProperties { return [_me valueForKey:kConfigAudioCustomProperties]; }
-(NSArray *)connections { return mapParamNames([_me valueForKey:kConfigSceneConnections]); };
-(NSArray*)instruments {
    NSArray * names = [_me valueForKey:kConfigAudioInstruments];
    return [names map:^id(id name) {
        return [__sharedConfig getInstrument:name];
    }];
}
-(NSArray *)generators {
    NSArray * names = [_me valueForKey:kConfigAudioGenerators];
    return [names map:^id(id name) {
        return [__sharedConfig getToneGenerator:name];
    }];
}
@end

@implementation ConfigScene
-(NSString *)icon { return [_me valueForKey:kConfigSceneIcon]; }
-(NSString *)displayName { return [_me valueForKey:kConfigSceneDisplayName]; };
-(ConfigAudioProfile *)audioElement { return [__sharedConfig getAudioProfile:[_me valueForKey:kConfigSceneAudio]];}
-(ConfigGraphicElement *)graphicElement { return [__sharedConfig getGraphicElement:[_me valueForKey:kConfigScene3d]];}
-(NSArray *)connections { return mapParamNames([_me valueForKey:kConfigSceneConnections]); };
@end
