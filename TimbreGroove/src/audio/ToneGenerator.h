//
//  ToneGenerator.h
//  TimbreGroove
//
//  Created by victor on 3/17/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class Scene;
@class ToneGeneratorProxy;
@class ConfigToneGenerator;

@protocol ToneGeneratorProtocol <NSObject>

-(void)renderProcForToneGenerator:(ToneGeneratorProxy *)generator;
-(void)getParameters:(NSMutableDictionary *)parameters;
-(void)triggersChanged:(Scene *)scene;
-(void)releaseRenderProc;
-(void)sendNote:(MIDINoteMessage *)noteMsg;

@end

@interface ToneGeneratorProxy : NSObject

-(id)initWithChannel:(int)channel andAU:(AudioUnit)au;
-(id<ToneGeneratorProtocol>)loadGenerator:(ConfigToneGenerator *)generatorConfig;

@property (nonatomic,strong) id<ToneGeneratorProtocol> generator;
@property (nonatomic) AudioUnit au;
@property (nonatomic) int channel;

@end

