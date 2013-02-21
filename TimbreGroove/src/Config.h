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
@end

@interface ConfigAudioProfile : ConfigBase
@property (nonatomic,readonly) NSString * midiFile;
@property (nonatomic,readonly) ConfigInstrument * instrument;
@end

@interface ConfigScene : ConfigBase
@property (nonatomic,readonly) NSString * icon;
@property (nonatomic,readonly) NSString * displayName;
@property (nonatomic,readonly) ConfigAudioProfile * audioElement;
@property (nonatomic,readonly) ConfigGraphicElement * graphicElement;
@property (nonatomic,readonly) NSDictionary * connections;
@end

@interface Config : NSObject
+(Config*)sharedInstance;
-(ConfigScene *)defaultScene;
-(NSArray *)getSceneNames;
-(ConfigScene *)getScene:(NSString *)name;
-(ConfigGraphicElement *)getGraphicElement:(NSString *)name;
@end
