//
//  Fluid.m
//  TimbreGroove
//
//  Created by victor on 1/2/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Fluid.h"
#import "Generic.h"
#import "Shader.h"
#import "FBO.h"
#import "MeshBuffer.h"
#import "Camera.h"
#import "View.h"
#import "Texture.h"
#import "VaryingColor.h"

//#define TEST_OUTPUT


#ifdef TEST_OUTPUT

@interface VaryColorFBO : FBO
@end
@implementation VaryColorFBO

-(id)initWithWidth:(GLuint)width height:(GLuint)height type:(GLenum)type format:(GLenum)format
{
    if( (self = [super initWithWidth:width height:height type:type format:format]))
    {
        VaryingColor * vc = [[VaryingColor alloc] init];
        [vc wireUp];
        vc.fbo = self;
        [vc renderToFBO];
        vc.fbo = nil;
        vc = nil;
    }
    return self;
}
@end

#pragma mark -
#pragma mark Test object to peeking into FBOs
#pragma mark -

@interface TestFBO : Generic
@end
@implementation TestFBO

-(void)createBuffer
{
    [self createBufferDataByType:@[@(st_float3),@(st_float2)]
                     numVertices:6
                      numIndices:0
                indicesIntoNames:@[@(gv_pos),@(gv_uv)]];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*(3+2)] = {
    //   x   y  z    u    v
        -1, -1, 0,   0,   0,
        -1,  1, 0,   0,   1,
         1, -1, 0,   1,   0,
        
        -1,  1, 0,   0,   1,
         1,  1, 0,   1,   1,
         1, -1, 0,   1,   0
    };
    
    memcpy(vertextData, v, sizeof(v));
}

@end
#else
#define VaryColorFBO FBO
#endif


#pragma mark -
#pragma mark Options settings

typedef struct Fluid_options {
    int iterations;
    int mouse_force;
    float resolution;
    int cursor_size;
    float step;
} Fluid_options;

static Fluid_options options = { 32, 1, 1.0f, 100, 1.0f/60.0f };

#pragma mark Shader doodads

typedef enum FluidVariableName {
    fl_position,
    fl_offset,
    
    FL_LAST_ATTR = fl_offset,
    
    fl_px,
    fl_px1,
    fl_scale_f,
    fl_dt,
    fl_force,
    fl_center,
    fl_scale_v2,
    fl_alpha,
    fl_beta,
    
    fl_LAST_SCALAR_UNIFORM = fl_beta,
    
    fl_velocity,
    fl_source,
    fl_pressure,
    fl_divergence,
    
    NUM_fl_VARIABLES
    
} FluidVariableName;

typedef struct FluidVariable {
    TGUniformType utype;
    union {
        GLKVector2 v2;
        float f;
    } data;
} FluidVariable;

static const char * __fluidShaderNames[NUM_fl_VARIABLES] = {
    "position",
    "offset",
    
    "px",
    "px1",
    "scale",
    "dt",
    "force",
    "center",
    "scalev",
    "alpha",
    "beta",

    "velocity",
    "source",
    "pressure",
    "divergence"
};

FluidVariable __kVariables[ NUM_fl_VARIABLES ] = {
    { -1 },
    { -1 },
    
    { TG_VECTOR2},
    { TG_VECTOR2},
    { TG_FLOAT},
    { TG_FLOAT},
    { TG_VECTOR2 },
    { TG_VECTOR2 },
    { TG_VECTOR2 },
    { TG_FLOAT },
    { TG_FLOAT },
    
    { TG_TEXTURE },
    { TG_TEXTURE },
    { TG_TEXTURE },
    { TG_TEXTURE }
};

#pragma mark -
#pragma mark Shader
#pragma mark -

@interface FluidShader : Shader {
    FluidVariable _vars[ NUM_fl_VARIABLES ];
}

@end
@implementation FluidShader

-(FluidVariable *)var:(FluidVariableName)name
{
    return _vars + name;
}

-(id)initWithVertex:(const char *)vert andFragment:(const char * )frag
{
    self.acceptMissingVars = true;
    
    self = [super initWithVertex: vert
                      andFragment: frag
                      andVarNames: __fluidShaderNames
                      andNumNames: NUM_fl_VARIABLES
                      andLastAttr: FL_LAST_ATTR
                       andHeaders: nil];
    
    if( self )
    {
        NSLog(@"Creating shader for %s/%s",vert,frag);
        memcpy(&_vars, &__kVariables, sizeof(__kVariables));
    }
    
    return self;
}

-(void)setUValue:(FluidVariableName)fname value:(void *)value
{
    FluidVariable * fv = _vars + fname;
    if( fv->utype == TG_FLOAT )
        fv->data.f = *(float *)value;
    else
        fv->data.v2 = *(GLKVector2 *)value;
}

-(void)writeUValues
{
    [self use];
    for( FluidVariableName i = FL_LAST_ATTR+1; i < fl_LAST_SCALAR_UNIFORM; i++ )
    {
        FluidVariable * fv = _vars + i;
        [self writeToLocation:i type:fv->utype data:&fv->data];
    }
}
@end

#pragma mark -
#pragma mark Base class for Fluid kernels
#pragma mark -

@interface FluidMesh : Generic {
    const char * _vShader;
    const char * _fShader;
    NSMutableDictionary * _keyedTextures; // key=uSamplerName value=FBO*
@protected
    float _x;
    float _y;
}
@property (nonatomic) bool blend;
@end


@implementation FluidMesh

-(void)setV:(const char *)vShader
        f:(const char *)fShader
 textures:(NSDictionary *) textures
{
    _fShader = fShader;
    _vShader = vShader;
    _keyedTextures = [textures mutableCopy];
}

-(void)setX:(float)x
        Y:(float)y
  vShader:(const char *)vShader
  fShader:(const char *)fShader
 textures:(NSDictionary *)textures
{
    _x = x;
    _y = y;
    _fShader = fShader;
    _vShader = vShader;
    _keyedTextures = [textures mutableCopy];
}

-(void)createShader
{
    FluidShader * shader = [[FluidShader alloc] initWithVertex:_vShader andFragment:_fShader];
    self.shader = shader;
}

-(void)setTextures:(NSDictionary *)dict
{
    _keyedTextures = [dict mutableCopy];
}

-(void)setTexture:(Texture *)texture withKey:(FluidVariableName)key
{
    _keyedTextures[@(key)] = texture;
}

-(void)setFloat:(FluidVariableName)fname value:(float)value
{
    [((FluidShader *)self.shader) setUValue:fname value:&value];
}

-(void)setVector2:(FluidVariableName)fname value:(GLKVector2 *)value
{
    [((FluidShader *)self.shader) setUValue:fname value:value];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    FluidShader * shader = (FluidShader *)self.shader;
    
    [shader use];
    
    int target = 0;
    for( id key in _keyedTextures )
    {
        Texture * t = _keyedTextures[key];
        t.uLocation = [self.shader location:[key intValue]];
        [t bindTarget:target];
        ++target;
    }
    
    [shader writeUValues];
    
    if( _blend )
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        glEnable(GL_BLEND);
    }
    else
    {
        glDisable(GL_BLEND);
    }
    
    for( MeshBuffer * b in _buffers )
    {
        [b bind];
        [b draw];
        [b unbind];
    }
    
    for( id key in _keyedTextures )
    {
        Texture * t = _keyedTextures[key];
        [t unbind];
    }
}

@end

#pragma mark -
#pragma mark Kernel based on Mesh
#pragma mark -

@interface QuadMesh : FluidMesh 
@end

@implementation QuadMesh

-(void)createBuffer
{
    [self createBufferDataByType:@[@(st_float3)]
                     numVertices:6 
                      numIndices:0
                indicesIntoNames:@[@(fl_position)]];
}

-(void)getBufferData:(void *)vertextData indexData:(unsigned int *)indexData
{
    float xscale = _x > 0 ? _x : 1;
    float yscale = _y > 0 ? _y : xscale;
    float data[18] = {
             -xscale, yscale, 0,
             -xscale, -yscale, 0,
             xscale, -yscale, 0,
             
             -xscale, yscale, 0,
             xscale, -yscale, 0,
        xscale, yscale, 0 };

    memcpy(vertextData, data, sizeof(data));
}

@end

#pragma mark -
#pragma mark Kernel based on Boundary
#pragma mark -

@interface BoundaryMesh : FluidMesh
@end

@implementation BoundaryMesh

-(void)createBuffer
{
    MeshBuffer * buffer =
    [self createBufferDataByType:@[@(st_float2),@(st_float2)]
                     numVertices:8
                      numIndices:0
                indicesIntoNames:@[@(fl_position),@(fl_offset)]];
    
    buffer.drawType = GL_LINES;
}

-(void)getBufferData:(void *)vertextData indexData:(unsigned int *)indexData
{
    float twoPixelsX = _x * 2.0;
    float twoPixelsY = _y * 2.0;
    
#define OFS(x) ((x)*0.5+0.5)
    
    float data[] = {
    // bottom
        -1, -1,
        OFS(-1), OFS(-1+twoPixelsY),

         1, -1,
         OFS(1), OFS(-1+twoPixelsY),

        // top
        -1,  1,
        OFS(-1),  OFS(1-twoPixelsY),

        1,  1,
        OFS(1),  OFS(1-twoPixelsY),

        // left
        -1, 1,
        OFS(-1+twoPixelsX),  OFS(1),

        -1, -1,
        OFS(-1+twoPixelsX), OFS(-1),

        // right
        1, 1,
        OFS(1-twoPixelsX),  OFS(1),

        1, -1,
        OFS(1-twoPixelsX), OFS(-1)
    };
    
    memcpy(vertextData, data, sizeof(data));
}
@end

#pragma mark -
#pragma mark Main Fluid object
#pragma mark -

@interface Fluid() {
    
    FBO * _velocity0;
    FBO * _velocity1;
    FBO * _divergence;
    FBO * _pressure0;
    FBO * _pressure1;
    
    float _input_x;
    float _input_y;
    float _delta_x;
    float _delta_y;
    
    FluidMesh * _advectVelocity;
    FluidMesh * _addForceKernel;
    FluidMesh * _velocityBoundaryKernel;
    FluidMesh * _divergenceKernel;
    FluidMesh * _jacobiKernel;
    FluidMesh * _pressureBoundaryKernel;
    FluidMesh * _subtractPressureGradientKernel;
    FluidMesh * _subtractPressureGradientBoundaryKernel;
    FluidMesh * _drawKernel;
    
    bool _gestureRegistered;

#ifdef TEST_OUTPUT
    TestFBO * _test;
#endif
}
@end

@implementation Fluid

-(id)wireUp
{
    GLKView * view = self.view;
    
    if( !_gestureRegistered )
    {
        // For now just do a two fingered drag to move the center
        // in the simulator you hold down SHIFT-ALT key, then mouse click,
        // then drag around
        // be careful not to pinch or rotate
        // TODO: manually handle UITouch events for more control over this stuff
        UIPanGestureRecognizer * pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
        pgr.minimumNumberOfTouches = 2;
        [view addGestureRecognizer:pgr];
        _gestureRegistered = true;
    }
    
    // yea, yea reusing variable. Sue me later.
    view = (GLKView *)view.superview;
    _viewSize = CGSizeMake(view.drawableWidth,view.drawableHeight);
    CGFloat width = _viewSize.width;
    CGFloat height = _viewSize.height;
    _px = 1.0/width;
    _py = 1.0/height;
  
    GLKVector2 px = { _px, _py };
    GLKVector2 px1 = { 1.0, width/height };
    
    _velocity0 = [[VaryColorFBO alloc] initWithWidth:width height:height];
    _velocity1 = [[VaryColorFBO alloc] initWithWidth:width height:height];
    
    float twoPixelsX = _px * 2.0;
    float twoPixelsY = _py * 2.0;
    
    // =================================    
    _advectVelocity = [[QuadMesh alloc] init];
    [_advectVelocity setX:1.0 - twoPixelsX
                        Y:1.0 - twoPixelsY
                  vShader:"kernel"
                  fShader:"advect"
                 textures:@{@(fl_velocity):_velocity0,@(fl_source):_velocity0}];
    [_advectVelocity wireUp];
    [_advectVelocity setVector2:fl_px value:&px];
    [_advectVelocity setVector2:fl_px1 value:&px1];
    [_advectVelocity setFloat:fl_scale_f value:1.0];
    [_advectVelocity setFloat:fl_dt value:options.step];
    
    _advectVelocity.fbo = _velocity1;
    // =================================
    _addForceKernel = [[QuadMesh alloc] init];
    [_addForceKernel setX: twoPixelsX * options.cursor_size
                        Y: twoPixelsY * options.cursor_size
                  vShader:"cursor"
                  fShader:"addForce"
                 textures:nil];
    [_addForceKernel wireUp];
    _addForceKernel.blend = true;
    
    GLKVector2 scalev = { options.cursor_size*_px, options.cursor_size*_py };
    
    [_addForceKernel setVector2:fl_px value:&px];
    [_addForceKernel setVector2:fl_scale_v2 value:&scalev];
    _addForceKernel.fbo = _velocity1;
    //=====================================
    _velocityBoundaryKernel = [[BoundaryMesh alloc] init];
    [_velocityBoundaryKernel setX:_px
                                Y:_py
                          vShader:"boundary"
                          fShader:"advect"
                         textures:@{@(fl_velocity):_velocity0,@(fl_source):_velocity0}];
    [_velocityBoundaryKernel wireUp];
    [_velocityBoundaryKernel setVector2:fl_px value:&px];
    [_velocityBoundaryKernel setFloat:fl_scale_f value:-1.0];
    [_velocityBoundaryKernel setFloat:fl_dt value:1.0f/60.0f];
    _velocityBoundaryKernel.fbo = _velocity1;
    //=========================================
    _divergence = [[VaryColorFBO alloc] initWithWidth:width height:height];
    
    _divergenceKernel = [[QuadMesh alloc] init];
    [_divergenceKernel setX:1
                          Y:1
                    vShader:"kernel"
                    fShader:"divergence"
                   textures:@{@(fl_velocity):_velocity1}];
    [_divergenceKernel wireUp];
    [_divergenceKernel setVector2:fl_px  value:&px];
    [_divergenceKernel setVector2:fl_px1 value:&px]; // sic - send px value to px1
    _divergenceKernel.fbo = _divergence;
    //=========================================
    _pressure0 = [[VaryColorFBO alloc] initWithWidth:width height:height];
    _pressure1 = [[VaryColorFBO alloc] initWithWidth:width height:height];
    
    _jacobiKernel = [[QuadMesh alloc] init];
    [_jacobiKernel setX:1
                      Y:1
                vShader:"kernel"
                fShader:"jacobi"
               textures: @{@(fl_pressure):_pressure0,@(fl_divergence):_velocity1}];//  _divergence}];
    [_jacobiKernel wireUp];

    [_jacobiKernel setFloat:fl_alpha value:-1.0];
    [_jacobiKernel setFloat:fl_beta value:0.25];
    [_jacobiKernel setVector2:fl_px value:&px];
    _jacobiKernel.fbo = _pressure1;

    //=========================================
    _pressureBoundaryKernel = [[BoundaryMesh alloc]init];
    [_pressureBoundaryKernel setX:_px
                                Y:_py
                          vShader:"boundary"
                          fShader:"jacobi"
                         textures: @{@(fl_pressure):_pressure0,@(fl_divergence):_velocity1}];//  _divergence}];
    [_pressureBoundaryKernel wireUp];
    
    [_pressureBoundaryKernel setFloat:fl_alpha value:-1.0];
    [_pressureBoundaryKernel setFloat:fl_beta value:0.25];
    [_pressureBoundaryKernel setVector2:fl_px value:&px];
    _pressureBoundaryKernel.fbo = _pressure1;
    //=========================================
    _subtractPressureGradientKernel = [[QuadMesh alloc]init];
    [_subtractPressureGradientKernel setX:1
                                        Y:1
                                  vShader:"kernel"
                                  fShader:"subtractPressureGradient"
                                 textures: @{@(fl_pressure):_pressure0,@(fl_velocity):_velocity1}];
    [_subtractPressureGradientKernel wireUp];
    
    [_subtractPressureGradientKernel setFloat:fl_scale_f value:1];
    [_subtractPressureGradientKernel setVector2:fl_px value:&px];
    _subtractPressureGradientKernel.fbo = _velocity0;
    //=========================================
    _subtractPressureGradientBoundaryKernel = [[BoundaryMesh alloc]init];
    [_subtractPressureGradientBoundaryKernel setX:_px
                                                Y:_py
                                          vShader:"boundary"
                                          fShader:"subtractPressureGradient"
                                         textures: @{@(fl_pressure):_pressure0,@(fl_velocity):_velocity1}];
    [_subtractPressureGradientBoundaryKernel wireUp];
    [_subtractPressureGradientBoundaryKernel setFloat:fl_scale_f value:-1];
    [_subtractPressureGradientBoundaryKernel setVector2:fl_px value:&px];
    _subtractPressureGradientBoundaryKernel.fbo = _velocity0;
    //=========================================
    _drawKernel = [[QuadMesh alloc]init];
    [_drawKernel setX:1
                    Y:1
              vShader:"kernel"
              fShader:"visualize"
             textures: @{@(fl_pressure):_pressure0,@(fl_velocity):_velocity0}];
    [_drawKernel wireUp];
    [_drawKernel setVector2:fl_px value:&px];
    
#ifdef TEST_OUTPUT
    [self testFBO:_pressure0];
#endif
    return self;
}

-(void)update:(NSTimeInterval)dt
{
    bool doClear = true;
    
    //=====================================================
    [_advectVelocity renderToFBOWithClear:doClear];
    //=====================================================
    GLKVector2 force = GLKVector2Make( _delta_x * _px * options.cursor_size * options.mouse_force,
                                      -_delta_y * _py * options.cursor_size * options.mouse_force);
    
    GLKVector2 center = GLKVector2Make(  _input_x * _px * 2 - 1.0f,
                                       -(_input_y * _py * 2 - 1.0f) );
    
    [_addForceKernel setVector2:fl_force value:&force];
    [_addForceKernel setVector2:fl_center value:&center];
    [_addForceKernel renderToFBOWithClear:false];
    
    //=====================================================
    [_velocityBoundaryKernel renderToFBOWithClear:doClear];
    //=====================================================
    [_divergenceKernel renderToFBOWithClear:doClear];
    
    //=====================================================
    FBO * p0 = _pressure0;
    FBO * p1 = _pressure1;
    FBO * swap;
    for(int i = 0; i < 2; i++) // options.iterations; i++)
    {
        [_jacobiKernel           setTexture:p0 withKey:fl_pressure];
        [_pressureBoundaryKernel setTexture:p0 withKey:fl_pressure];
        _jacobiKernel.fbo = p1;
        _pressureBoundaryKernel.fbo = p1;
        [_jacobiKernel           renderToFBOWithClear:doClear andBindFlags:FBOBF_SkipUnbind];
        [_pressureBoundaryKernel renderToFBOWithClear:doClear andBindFlags:FBOBF_SkipBind|FBOBF_SkipUnbind];

        swap = p0;
        p0 = p1;
        p1 = swap;
    }
#ifndef TEST_OUTPUT
    
    //=====================================================
    [_subtractPressureGradientKernel renderToFBOWithClear:doClear];
    [_subtractPressureGradientBoundaryKernel renderToFBOWithClear:doClear];
#endif
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
#ifndef TEST_OUTPUT
    [_drawKernel render:w h:h];
#endif
    
}

#ifdef TEST_OUTPUT
-(void)testFBO:(FBO *)fbo
{
    _test = [[TestFBO alloc] init];
    _test.texture = fbo;
    _test.camera = [IdentityCamera new];
    [self cleanChildren];
    [self appendChild:_test];
    [_test wireUp];
}
#endif

-(void)onDrag:(UIPanGestureRecognizer *)pgr
{
    if( pgr.state != UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [pgr locationOfTouch:0 inView:self.view];
        float newX = pt.x * options.resolution;
        float newY = pt.y * options.resolution;
        if( _input_x && _input_y )
        {
            _delta_x = newX - _input_x;
            _delta_y = newY - _input_y;
        }
        _input_x = newX;
        _input_y = newY;
        
        // NSLog(@"drag at: %f, %f", _input_x, _input_y);
    }
}


@end
