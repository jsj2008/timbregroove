//
//  PoolBoard.m
//  TimbreGroove
//
//  Created by victor on 1/21/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "Texture.h"
#import "GridPlane.h"
#import "Camera.h"
#import "MeshBuffer.h"
#import "Text.h"
#import "FBO.h"
#import "Shader.h"
#import "Tweener.h"
#import "TG3dObject+Sound.h"
#import "TrackView+Sound.h"
#import "Sound.h"
#import "MeshBuffer.h"
#import "UIViewController+TGExtension.h"

@interface PoolScreen : Generic {
    NSMutableArray * _waters;
}
+(GLKVector2)screenToPool:(CGPoint)pt;

@end

//--------------------------------------------------------------------------------
#pragma mark Pool Water Shader

typedef enum PoolWaterVariables {
    pw_position,
    pw_uv,
    PW_LAST_ATTR = pw_uv,
//    pw_pvm,
    pw_sampler,
    pw_time,
    pw_ripple,
    pw_turbulence,
    pw_center,
    pw_radius,
    pw_scale,
    PW_NUM_NAMES
} PoolWaterVariables;

const char * _pw_names[] = {
    "a_position",
    "a_uvs",
    "u_texture",
    "u_time",
    "u_rippleSize",
    "u_turbulence",
    "u_center",
    "u_radius",
    "u_scale"
};

const char * _pw_shader_name = "PoolScreen";

@interface PoolWaterShader : Shader

@property (nonatomic) float rippleSize;
@property (nonatomic) float turbulence;
@property (nonatomic) GLKVector2 center;
@property (nonatomic) float radius;
@property (nonatomic) GLKVector2 scale;
@end

@implementation PoolWaterShader

-(id)init
{
    self = [super initWithVertex:_pw_shader_name
                     andFragment:_pw_shader_name
                     andVarNames:_pw_names
                     andNumNames:PW_NUM_NAMES
                     andLastAttr:PW_LAST_ATTR
                      andHeaders:nil];
    if( self )
    {
        _rippleSize = 7.0;
        _turbulence = 0.005f;
        _radius = 0.01;
        CGSize sz = [UIScreen mainScreen].bounds.size;
        _scale = (GLKVector2){ 1/sz.width, 1/sz.height };
    }
    return self;
}

-(void)writeStatics
{
    [self writeToLocation:pw_ripple     type:TG_FLOAT   data:&_rippleSize];
    [self writeToLocation:pw_turbulence type:TG_FLOAT   data:&_turbulence];
    [self writeToLocation:pw_scale      type:TG_VECTOR2 data:&_scale];
}

-(void)setCenter:(GLKVector2)center
{
    _center = center;
    [self writeToLocation:pw_center type:TG_VECTOR2 data:&_center];
}

-(void)setRadius:(float)radius
{
    _radius = radius;
    [self writeToLocation:pw_radius type:TG_FLOAT data:&_radius];
}

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
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onTap:)];

    // .keyWindow is nil (wtf?)
    UIWindow * window = [[UIApplication sharedApplication] delegate].window;
    UITapGestureRecognizer * menuInvoker =  [window.rootViewController getMenuInvokerGesture];
    if( menuInvoker )
    {
        [tgr requireGestureRecognizerToFail:menuInvoker];
    }

    [self.view addGestureRecognizer:tgr];
    
    UILongPressGestureRecognizer *lpgr =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(onLongTap:)];
    [self.view addGestureRecognizer:lpgr];
    
    [self addPoolChild].center = (GLKVector2){0.4,0.4};
    return self;
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

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    PoolWaterShader * shader = (PoolWaterShader *)_shader;
    
    [shader use];
    float f = (float)self.totalTime;
    [shader writeToLocation:pw_time type:TG_FLOAT data:&f];

    [self.texture bind:0];
    MeshBuffer * b = _buffers[0];
    [b bind];

    glDisable(GL_DEPTH_TEST);
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
    
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
