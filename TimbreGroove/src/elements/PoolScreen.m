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
#import "State.h"
#import "MathStuff.h"

NSString const * kParamPoolMoveItem = @"MoveItem";
NSString const * kParamPoolNewItem  = @"NewItem";
NSString const * kParamPoolItemRadius = @"ItemRadius";

extern float g_last_power, g_last_radius;

//--------------------------------------------------------------------------------
#pragma mark Pool Water Object

@interface PoolWater : NSObject {
    bool _shrinkingRadius;
    bool _resizingRadius;
    float _nativePitch;
}

@property (nonatomic) float radius;
@property (nonatomic) float meteredRadius;
@property (nonatomic) CGPoint center;

@end

@implementation PoolWater

-(bool)isOnCenter:(CGPoint)pt
{
    float distance = GLKVector2Distance(*(GLKVector2 *)&_center, *(GLKVector2 *)&pt);
    return distance <= _radius;
}

-(void)moveTo:(CGPoint)pt
{
    _center = pt;
}

@end

//--------------------------------------------------------------------------------

@interface PoolScreen : Generic {
    NSMutableArray * _waters;
    CGSize _viewSz;
    DepthTestState * _dts;
    int _movingItemIndex;
    float _maxF;
    float _minF;
}
@property (nonatomic,strong) Texture * texture;
-(void)getMovingPoint:(CGPoint *)ppt;
@end


//--------------------------------------------------------------------------------
#pragma mark Parameter

@interface PoolMoveItemParameter : Parameter {
    CGPoint _initialAnimationPt;
    __weak PoolScreen * _ps;
}

@end

@implementation PoolMoveItemParameter

+(id)withPoolScreen:(PoolScreen *)ps block:(id)block
{
    return [[PoolMoveItemParameter alloc] initWithPoolScreen:ps block:block];
}

-(id)initWithPoolScreen:(PoolScreen *)ps block:(id)block
{
    self = [super initWithBlock:block];
    if( self )
    {
        _ps = ps;
        self.additive = false;
    }
    return self;
}

-(void)getValue:(void *)p ofType:(char)type
{
    [_ps getMovingPoint:p];
}

@end

//--------------------------------------------------------------------------------

#pragma mark PoolScreen


@implementation PoolScreen {
    MeshBuffer * buffer;
}

-(id)wireUpWithViewSize:(CGSize)viewSize
{
    _viewSz = viewSize;
    self.camera = [IdentityCamera new];
    [super wireUpWithViewSize:viewSize];
    
    _dts = [DepthTestState new];
    
    for( int i =0; i < 4; i++ )
        [self addPoolChild];

    [self shuffle];
    
    _maxF = -20 + 120;
    _minF = -60 + 120;
    
    return self;
}


-(void)createBuffer
{
    buffer = [GridPlane gridWithIndicesIntoNames:@[@(pw_position),@(pw_uv)]
                                               andDoUVs:true
                                           andDoNormals:false];
    [self addBuffer:buffer];
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"pool.png"];
}

-(void)createShader
{
    PoolWaterShader * shader = [[PoolWaterShader alloc] init];
    CGSize sz = _viewSz;
    shader.scale = (GLKVector2){ 1/sz.width, 1/sz.height };
    [shader writeStatics];
    self.shader = shader;
    self.texture.uLocation = [_shader location:pw_sampler];
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
    MeshBuffer * b = buffer;
    [b bind];

    [_dts enable:false];
    
    for( PoolWater * water in _waters )
    {
        CGPoint pt = water.center;
        shader.center = *(GLKVector2 *)&pt;
        shader.radius = water.radius;
        [b draw];
    }

    [b unbind];
    [self.texture unbind:shader];

    [_dts restore];
}


-(PoolWater *)waterFromPt:(CGPoint)pt
{
    for( PoolWater * water in _waters )
    {
        if( [water isOnCenter:pt] )
            return water;
    }
    return nil;
}

-(void)getMovingPoint:(CGPoint *)ppt
{
    int count = [_waters count];
    if( !count )
        return;
    _movingItemIndex = count == 1 ? 0 : R0_n(count);
    CGPoint pt = ((PoolWater *)_waters[_movingItemIndex]).center;
    *ppt = (CGPoint){-pt.x, -pt.y};
}

-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    parameters[kParamPoolMoveItem] = [PoolMoveItemParameter withPoolScreen:self block:^(CGPoint pt) {
        [_waters[_movingItemIndex] moveTo:(CGPoint){-pt.x,-pt.y}];
    }];
    
    parameters[kParamPoolNewItem] = [Parameter withBlock:^(CGPoint pt) {
        PoolWater * pw = [self addPoolChild];
        pw.center = (CGPoint){-pt.x,-pt.y};
    }];
    
    parameters[kParamPoolItemRadius] = [Parameter withBlock:^(float fp) {
        int count = [_waters count];
        int index = count == 1 ? 0 : R0_n(count);
        PoolWater * pw = (PoolWater *)_waters[index];
        
        float f = _explodeFromCenter(fp, 0.4, 0.7, 1);
        if( f < 0.0 )
            f = 0.01;
        f *= 0.1;
        if( f <= 1.0 )
            pw.radius = f;
    }];
}

-(void)shuffle
{
    [_waters each:^(PoolWater * pw) {
        pw.center = (CGPoint){ (R0_1() * 2.0) - 1.0, (R0_1() * 2.0) - 1.0 };
    }];
}

-(PoolWater *)addPoolChild
{
    PoolWater * child = [PoolWater new];
    child.radius = 0.0001;
    
    if( !_waters )
        _waters = [NSMutableArray new];
    [_waters addObject:child];
    return child;
}
@end
