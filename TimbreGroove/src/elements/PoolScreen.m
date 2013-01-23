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
    pw_center2,
    pw_radius,
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
    "u_center2",
    "u_radius"
};

const char * _pw_shader_name = "PoolWater";

@interface PoolWaterShader : Shader
@property (nonatomic) float rippleSize;
@property (nonatomic) float turbulence;
@property (nonatomic) GLKVector2 center;
@property (nonatomic) GLKVector2 center2;
@property (nonatomic) float radius;
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
        _radius = 0.2;
    }
    return self;
}

-(void)writeStatics
{
    [self writeToLocation:pw_ripple type:TG_FLOAT data:&_rippleSize];
    [self writeToLocation:pw_turbulence type:TG_FLOAT data:&_turbulence];
    [self writeToLocation:pw_center type:TG_VECTOR2 data:&_center];
    [self writeToLocation:pw_center2 type:TG_VECTOR2 data:&_center2];
    [self writeToLocation:pw_radius type:TG_FLOAT data:&_radius];
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

-(void)prepareRender:(TG3dObject *)object
{
    float f = (float)object.totalTime;
    [self writeToLocation:pw_time type:TG_FLOAT data:&f];
}

@end

//--------------------------------------------------------------------------------
#pragma mark Pool Water Object

@interface PoolScreen : Generic {
    bool _shrinkingRadius;
    bool _resizingRadius;
    float _nativePitch;
}

@property (nonatomic) float centerX;
@property (nonatomic) float centerY;

@end

@implementation PoolScreen

-(id)wireUp
{
    self.sound.volume = 0.2f;
    _nativePitch = self.sound.pitch;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onTap:)];
    [self.view addGestureRecognizer:tgr];
    
    UILongPressGestureRecognizer *lpgr =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(onLongTap:)];
    [self.view addGestureRecognizer:lpgr];
    
    return [super wireUp];
}

-(GLKVector2)screenToPool:(CGPoint)pt
{
    CGSize sz = [UIScreen mainScreen].bounds.size;
    float xsize = sz.width / 2.0; // (float)self.view.drawableWidth / 2.0;
    float ysize = sz.height / 2.0; // (float)self.view.drawableHeight / 2.0;
    float x = -(pt.x - xsize) / xsize;
    float y = (pt.y - ysize) / ysize;
    return (GLKVector2){x,y};
}

-(bool)isOnCenter:(GLKVector2)pt
{
    PoolWaterShader * shader = (PoolWaterShader *)_shader;
    GLKVector2 center = shader.center;
    float distance = GLKVector2Distance(center, pt);
    return distance <= shader.radius;
}

-(void)doneResizingRadius
{
    _resizingRadius = false;
}

-(void)onLongTap:(UILongPressGestureRecognizer *)lpgr
{
    GLKVector2 pt = [self screenToPool:[lpgr locationInView:self.view]];
    if( !_resizingRadius && [self isOnCenter:pt] )
    {
        _resizingRadius = true;
        
        PoolWaterShader * shader = (PoolWaterShader *)_shader;
        float radius = shader.radius;
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
        
        NSDictionary * params = @{    TWEEN_DURATION: @0.2f,
                                    TWEEN_TRANSITION: TWEEN_FUNC_EASEINSINE,
                                           @"radius": @(radius),
                          TWEEN_ON_COMPLETE_SELECTOR: @"doneResizingRadius",
                            TWEEN_ON_COMPLETE_TARGET: self
                        };
        
        [Tweener addTween:shader withParameters:params];
        
        params = @{    TWEEN_DURATION: @0.1f,
                                    TWEEN_TRANSITION: TWEEN_FUNC_EASEINSINE,
                                        @"volume": @(radius),
                                        };
        
        [Tweener addTween:self.sound withParameters:params];
    }
}

-(void)onTap:(UITapGestureRecognizer *)tgr
{
    GLKVector2 pt = [self screenToPool:[tgr locationInView:self.view]];
    
    if( [self isOnCenter:pt] )
        return;
    
    PoolWaterShader * shader = (PoolWaterShader *)_shader;

    GLKVector2 cXY = shader.center;
    _centerX = cXY.x;
    _centerY = cXY.y;
    

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
    
    float base = _nativePitch;
    if( pt.y > 0 )
        base = -base;
    
    self.sound.pitch = base + (pt.y * -44000.0f);
    
    NSLog(@"Pitch: %f", self.sound.pitch);

}

-(void)setCenterX:(float)centerX
{
    _centerX = centerX;
    PoolWaterShader * shader = (PoolWaterShader *)_shader;
    shader.center = (GLKVector2){ _centerX, _centerY };
}

-(void)setCenterY:(float)centerY
{
    _centerY = centerY;
    PoolWaterShader * shader = (PoolWaterShader *)_shader;
    shader.center = (GLKVector2){ _centerX, _centerY };
}

-(void)createBuffer
{
    MeshBuffer * buffer = [GridPlane gridWithIndicesIntoNames:@[@(pw_position),@(pw_uv)]
                                                     andDoUVs:true
                                                 andDoNormals:false];
    
    [self addBuffer:buffer];
}

-(void)createShader
{
    self.camera = [IdentityCamera new];
    
    PoolWaterShader * shader = [PoolWaterShader new];
    shader.center = (GLKVector2){0,0};
    shader.center2 = (GLKVector2){0.7,0.7};

    [shader writeStatics];
    
    self.shader = shader;
}

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"pool.png"];
}

-(void)getTextureLocations
{
    self.texture.uLocation = [_shader location:pw_sampler];
}

@end

