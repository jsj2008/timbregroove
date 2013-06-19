//
//  Config.h
//  TimbreGroove
//
//  Created by victor on 2/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigNames.h"

@interface ConfigBase : NSObject {
    @protected
    NSDictionary * _me;
}
-(id)initWithD:(NSDictionary *)d;
@end

@interface ConfigToneGenerator : ConfigBase
@property (nonatomic,readonly) NSString * instanceClass;
@property (nonatomic,readonly) NSDictionary * customProperties;
@property (nonatomic) NSString * name;
@end

@interface ConfigGraphicElement : ConfigBase
@property (nonatomic,readonly) NSString * icon;
@property (nonatomic,readonly) int menuOrder;
@property (nonatomic,readonly) NSString * instanceClass;
@property (nonatomic,readonly) NSDictionary * customProperties;
@end

@interface ConfigInstrument : ConfigBase
@property (nonatomic,readonly) bool isSoundFont;
@property (nonatomic,readonly) int patch;
@property (nonatomic,readonly) NSString * preset;
@property (nonatomic,readonly) int low;
@property (nonatomic,readonly) int high;
@property (nonatomic) NSString * name;
@end

@interface ConfigAudioProfile : ConfigBase
@property (nonatomic,readonly) NSString * midiFile;
@property (nonatomic,readonly) NSArray * instruments;
@property (nonatomic,readonly) NSArray * generators;
@property (nonatomic,readonly) NSString * instanceClass;
@property (nonatomic,readonly) NSDictionary * customProperties;
@property (nonatomic,readonly) NSArray * connections;
@end

@interface ConfigScene : ConfigBase
@property (nonatomic,readonly) NSString * icon;
@property (nonatomic,readonly) NSString * displayName;
@property (nonatomic,readonly) ConfigAudioProfile * audioElement;
@property (nonatomic,readonly) ConfigGraphicElement * graphicElement;
@property (nonatomic,readonly) NSArray * connections;
@end

@interface Config : NSObject
+(Config*)sharedInstance;
+(ConfigScene *)defaultScene;

-(NSDictionary *)getScenes;
-(ConfigScene *)getScene:(NSString *)name;
-(ConfigGraphicElement *)getGraphicElement:(NSString *)name;
-(NSDictionary *)getModel:(NSString *)name;

+(NSDictionary *)getLoggingOpts;
@end
