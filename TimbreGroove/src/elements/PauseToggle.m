//
//  PauseToggle.m
//  TimbreGroove
//
//  Created by victor on 1/30/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MenuItem.h"
#import "Texture.h"
@interface PauseToggle : MenuItem {
    NSArray * _swaps;
    int _toggle;
    bool _inRotation;
    float _degrees;
}

@end

@implementation PauseToggle

-(id)wireUp
{
    [super wireUp];
    
    Texture *play = [[Texture alloc] initWithFileName:@"play.png"];
    play.uLocation = self.texture.uLocation;
    _swaps = @[ self.texture, play ];
    _degrees = 180;
    _toggle = [self.delegate Menu:(Menu*)self.parent playMode:self];
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    if( _inRotation )
    {
        self.shadow = _degrees > 335;
        _degrees += 10;
        if( _degrees == 90 )
        {
            _degrees = 270;
            _toggle ^= 1;
            self.texture = _swaps[_toggle];
        }
        else if( _degrees >= 360 )
        {
            _inRotation = false;
            _degrees = 0;
        }
        self.rotation = (GLKVector3){ 0, GLKMathDegreesToRadians(_degrees), 0 };
    }
}

-(void)onTap:(UITapGestureRecognizer *)tgr
{
    _inRotation = true;
    _degrees = 0;
    [super onTap:tgr];
}

@end
