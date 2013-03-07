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
#import "SoundSystem.h"
#import "PoolWater.h"


NSString const * kParamPoolMoveItem = @"MoveItem";

@interface PoolScreen : Generic {
    NSMutableArray * _waters;
    CGSize _viewSz;
}
@property (nonatomic) CGPoint moveItem;
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
@property (nonatomic) GLKVector2 center;

@end

@implementation PoolWater

-(bool)isOnCenter:(GLKVector2)pt
{
    float distance = GLKVector2Distance(_center, pt);
    return distance <= _radius;
}

-(void)setCenterX:(float)centerX
{
    _centerX = centerX;
    _center = (GLKVector2){ _centerX, _centerY };
}

-(void)setCenterY:(float)centerY
{
    _centerY = centerY;
    _center = (GLKVector2){ _centerX, _centerY };
}

-(void)moveTo:(CGPoint)pt
{
    _center = *(GLKVector2 *)&pt;
}

@end

#pragma mark PoolScreen implementation

@implementation PoolScreen

-(id)wireUpWithViewSize:(CGSize)viewSize
{
    _viewSz = viewSize;
    self.camera = [IdentityCamera new];
    [super wireUpWithViewSize:viewSize];
    
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
    PoolWaterShader * shader = [[PoolWaterShader alloc] init];
    CGSize sz = _viewSz;
    shader.scale = (GLKVector2){ 1/sz.width, 1/sz.height };
    [shader writeStatics];
    self.shader = shader;
}

-(void)update:(NSTimeInterval)dt
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


-(PoolWater *)waterFromPt:(GLKVector2)pt
{
    for( PoolWater * water in _waters )
    {
        if( [water isOnCenter:pt] )
            return water;
    }
    return nil;
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"moveItem"] = ^(CGPoint pt) {
        [_waters[0] moveTo:pt];
    };
}


-(PoolWater *)addPoolChild
{
    PoolWater * child = [PoolWater new];
    child.radius = 0.2;
    
    if( !_waters )
        _waters = [NSMutableArray new];
    [_waters addObject:child];
    return child;
}
@end
