//
//  PoolBoard.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "GridPlane.h"
#import "Camera.h"
#import "FBO.h"
#import "Tweener.h"
#import "UIViewController+TGExtension.h"
#import "Mixer.h"
#import "PoolWater.h"

@interface PoolScreen : Generic {
    NSMutableArray * _waters;
}
+(GLKVector2)screenToPool:(CGPoint)pt;

@end

//--------------------------------------------------------------------------------
#pragma mark Pool Water Object

@interface PoolWater : NSObject {
    bool _shrinkingRadius;
    bool _resizingRadius;
    float _nativePitch;
}

@property (nonatomic) float centerX;
@property (nonatomic) float centerY;
@property (nonatomic) float radius;
@property (nonatomic) float meteredRadius;
@property (nonatomic) Sound * sound;
@property (nonatomic) GLKVector2 center;

@end

@implementation PoolWater

-(bool)isOnCenter:(GLKVector2)pt
{
    float distance = GLKVector2Distance(_center, pt);
    return distance <= _radius;
}

-(void)doneResizingRadius
{
    _resizingRadius = false;
}

-(void)animateRadius
{
    if( !_resizingRadius )
    {
        float radius = _radius;
        if( _shrinkingRadius )
            radius -= 0.2;
        else
            radius += 0.2;
        
        if( radius >= 1.0 )
        {
            _shrinkingRadius = true;
            radius = 1.0;
        }
        else if( radius <= 0.2 )
        {
            _shrinkingRadius = false;
            radius = 0.2;
        }
        
        [self setAnimatedRadius:radius];
        
    }
}

-(void)setAnimatedRadius:(float)radius
{
    _resizingRadius = true;
    
    NSDictionary * params = @{    TWEEN_DURATION: @0.2f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEINSINE,
                                    @"radius": @(radius),
                                TWEEN_ON_COMPLETE_SELECTOR: @"doneResizingRadius",
                                TWEEN_ON_COMPLETE_TARGET: self
    };
    
    [Tweener addTween:self withParameters:params];
    
}

-(void)moveTo:(GLKVector2)pt
{
    NSDictionary * params = @{    TWEEN_DURATION: @0.5f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                    @"centerX": @(pt.x)
                                    };
    
    [Tweener addTween:self withParameters:params];

    NSDictionary * params2 = @{    TWEEN_DURATION: @0.5f,
                                TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                    @"centerY": @(pt.y)
                                    };
    
    [Tweener addTween:self withParameters:params2];    
}

@end

#pragma mark PoolScreen implementation

@implementation PoolScreen

-(id)wireUp
{
    self.camera = [IdentityCamera new];
    [super wireUp];    
    
    [self addPoolChild].center = (GLKVector2){0.4,0.4};
    return self;
}

-(void)setView:(GLKView *)view
{
    /*
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onTap:)];
    
    UITapGestureRecognizer * menuInvoker =  [[self getVC] getMenuInvokerGesture];
    if( menuInvoker )
    {
        [tgr requireGestureRecognizerToFail:menuInvoker];
    }
    
    [view addGestureRecognizer:tgr];
    
    UILongPressGestureRecognizer *lpgr =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(onLongTap:)];
    [view addGestureRecognizer:lpgr];
    */
    [super setView:view];
}

-(UIViewController *)getVC
{
    // .keyWindow is nil (wtf?)
    UIWindow * window = [[UIApplication sharedApplication] delegate].window;
    return window.rootViewController;
}

-(void)createBuffer
{
    MeshBuffer * buffer = [GridPlane gridWithIndicesIntoNames:@[@(pw_position),@(pw_uv)]
                                               andDoUVs:true
                                           andDoNormals:false];
    [self addBuffer:buffer];
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"pool.png"];
}

-(void)getTextureLocations
{
    self.texture.uLocation = [_shader location:pw_sampler];
}

-(void)createShader
{
    PoolWaterShader * shader = [PoolWaterShader new];
    [shader writeStatics];
    self.shader = shader;
}

-(void)update:(NSTimeInterval)dt mixerUpdate:(MixerUpdate *)mixerUpdate
{
    if( _timer > 1.0/8.0 )
    {
        for( PoolWater * water in _waters )
        {
            /*
            [water.sound updateMeters];
            float peak = [water.sound averagePowerForChannel:0];
            if( peak > 0 )
                peak = 0;
            float targetRadius = (peak + 160.0) / 640.0;
            water.radius = targetRadius;
             */
        }
        _timer = 0.0;
    }
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    PoolWaterShader * shader = (PoolWaterShader *)_shader;
    
    [shader use];
    
    shader.time = (float)self.totalTime;
    
    [self.texture bind:0];
    MeshBuffer * b = _buffers[0];
    [b bind];

    glDisable(GL_DEPTH_TEST);
    
    for( PoolWater * water in _waters )
    {
        shader.center = water.center;
        shader.radius = water.radius;
        [b draw];
    }

    [b unbind];
    [self.texture unbind];

    glEnable(GL_DEPTH_TEST);
}


+(GLKVector2)screenToPool:(CGPoint)pt
{
    CGSize sz = [UIScreen mainScreen].bounds.size;
    float xsize = sz.width / 2.0; // (float)self.view.drawableWidth / 2.0;
    float ysize = sz.height / 2.0; // (float)self.view.drawableHeight / 2.0;
    float x = -(pt.x - xsize) / xsize;
    float y = (pt.y - ysize) / ysize;
    return (GLKVector2){x,y};
}

-(PoolWater *)waterFromPt:(GLKVector2)pt
{
    for( PoolWater * water in _waters )
    {
        if( [water isOnCenter:pt] )
            return water;
    }
    return nil;
}

-(void)onLongTap:(UILongPressGestureRecognizer *)lpgr
{
    GLKVector2 pt = [PoolScreen screenToPool:[lpgr locationInView:self.view]];
    PoolWater * water = [self waterFromPt:pt];
    if( water )
    {
        [water animateRadius];
    }
}

-(void)onTap:(UITapGestureRecognizer *)tgr
{
    if( [[self getVC] clearMenus] ) // yea, this should be somewhere else
        return;
    
    GLKVector2 pt = [PoolScreen screenToPool:[tgr locationInView:self.view]];
    PoolWater * water = [self waterFromPt:pt];
    if( water )
    {
        //[water onTap:tgr];
    }
    else
    {
        PoolWater * water = [self addPoolChild];
        water.center = pt;
    }
    
}

-(PoolWater *)addPoolChild
{
    PoolWater * child = [PoolWater new];
    [child setAnimatedRadius:0.2];
    
    if( !_waters )
        _waters = [NSMutableArray new];
    [_waters addObject:child];
    return child;
}
@end
