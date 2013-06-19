//
//  ChannelProtocol.h
//  TimbreGroove
//
//  Created by victor on 3/20/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SoundSystem;

@protocol ChannelProtocol <NSObject>

-(int)channel;
-(void)setChannel:(int)channel;
-(NSString *)name;
-(void)setName:(NSString *)name;
-(void)didAttachToGraph:(SoundSystem *)ss;
-(void)didDetachFromGraph:(SoundSystem *)ss;
@end
