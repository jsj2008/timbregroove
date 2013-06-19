//
//  VibesPlayer
//  TimbreGroove
//
//  Created by victor on 2/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Scene.h"
#import "Names.h"
#import "Audio.h"
#import "Sampler.h"
#import "TriggerMap.h"
#import "NSString+Tweening.h"
#import "NoteGenerator.h"

#define VIBES_VIRTUAL_CHANNEL   0

@interface VibesPlayer : Audio

@end

@interface VibesPlayer() {
    NoteGenerator * _vibesScale;

    UInt32            _vibesChannel;
    PointerParamBlock _midiNote;
}

@end
@implementation VibesPlayer

-(void)start
{
    [super start];
    
    _vibesChannel = [self channelFromName:@"vibes"];
    _vibesScale = [[NoteGenerator alloc] initWithScale:kScaleBluesPen isRandom:true andRange:(NoteRange){34,80}];
}

-(void)triggersChanged:(Scene *)scene
{
    [super triggersChanged:scene];
    
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        _midiNote = [tm getPointerTrigger:kParamMIDINote];
    }
    else
    {
        _midiNote = nil;
    }
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"RandomVibesNote"] = [Parameter withBlock:
                              ^(CGPoint pt)
                              {
                                  MIDINoteMessage mnm;
                                  mnm.note = [_vibesScale next];
                                  mnm.duration = 1.1;
                                  mnm.velocity = 127;
                                  mnm.channel = _vibesChannel;
                                  _midiNote(&mnm);
                              }];
}
@end
