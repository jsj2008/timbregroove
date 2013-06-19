//
//  SoundSource.h
//  TimbreGroove
//
//  Created by victor on 6/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChannelProtocol.h"
#import "Midi.h"

@protocol SoundSource <NSObject,ChannelProtocol,MidiCapableProtocol>

@end
