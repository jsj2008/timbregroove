//
//  Fluid.m
//  TimbreGroove
//
//  Created by victor on 12/28/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Fluid.h"
#import "MeshBuffer.h"
#import "FBO.h"
#import "Shader.h"
#import "Texture.h"
#import "View.h"

typedef struct FL_options {
    int iterations;
    int mouse_force;
    float resolution;
    int cursor_size;
    float step;
} FL_options;

static FL_options options = { 32, 1, 0.5f, 100, 1.0f/60.0f };

typedef enum FBOName
{
    FBO_velocity0 = 100,
    FBO_velocity1,
    FBO_divergence,
    FBO_pressure0,
    FBO_pressure1
} FBOName;

typedef enum MeshBufferName
{
    MB_inside = 200,
    MB_all,
    MB_cursor,
    MB_boundary
} MeshBufferName;

typedef enum KVariableName {
    KV_NONE  = -2,
    KV_ERROR = -1,
    
    kv_px,
    kv_px1,
    kv_scale_f,
    kv_dt,
    kv_force,
    kv_center,
    kv_scale_v2,
    kv_alpha,
    kv_beta,
    
    KV_LAST_SCALAR_UNIFORM = kv_beta,
    
    kv_velocity,
    kv_source,
    kv_pressure,
    kv_divergence,
    
    NUM_KV_VARIABLES
    
} KVariableName;

typedef union KData {
        GLKVector2 v;
        float      f;
        FBOName   n;
} KData;

typedef struct KVariable {
    KVariableName kname;
    const char *  name;
    TGUniformType utype;
    GLint location;
    KData value;
} KVariable;

typedef struct KValue {
    KVariableName kname;
    KData value;
} KValue;

#define DONT_NEED_LOCATION -3
#define NEED_LOCATION      -2
#define LOCATION_ERROR     -1
#define VALID_LOCATION     0

KVariable __kVariables[ NUM_KV_VARIABLES ] = {
    
    { kv_px,         "px",         TG_VECTOR2, DONT_NEED_LOCATION },
    { kv_px1,        "px1",        TG_VECTOR2, DONT_NEED_LOCATION },
    { kv_scale_f,    "scale",      TG_FLOAT,   DONT_NEED_LOCATION },
    { kv_dt,         "dt",         TG_FLOAT,   DONT_NEED_LOCATION },
    { kv_force,      "force",      TG_VECTOR2, DONT_NEED_LOCATION },
    { kv_center,     "center",     TG_VECTOR2, DONT_NEED_LOCATION },
    { kv_scale_v2,   "scale",      TG_VECTOR2, DONT_NEED_LOCATION },
    { kv_alpha,      "alpha",      TG_FLOAT,   DONT_NEED_LOCATION },
    { kv_beta,       "beta",       TG_FLOAT,   DONT_NEED_LOCATION },
    
    { kv_velocity,   "velocity",   TG_TEXTURE, DONT_NEED_LOCATION },
    { kv_source,     "source",     TG_TEXTURE, DONT_NEED_LOCATION },
    { kv_pressure,   "pressure",   TG_TEXTURE, DONT_NEED_LOCATION },
    { kv_divergence, "divergence", TG_TEXTURE, DONT_NEED_LOCATION }
};

#pragma mark -
#pragma mark Kernel Shader
#pragma mark -

@interface KernelShader : Shader
{
    KVariable             _kvars[NUM_KV_VARIABLES];
    NSMutableDictionary * _textures;
}
@end

@implementation KernelShader
-(id)initWithV:(const char *)vertexShader
             F:(const char * )fragmentShader
      uniforms:(KValue *)uniforms
   numUniforms:(int)numUniforms
{
    if( (self = [super init]) )
    {
        [self load:@(vertexShader) withFragment:@(fragmentShader)];
        
        memcpy(_kvars,__kVariables,sizeof(__kVariables));
        
        for( int i = 0; i < numUniforms; i++ )
        {
            KValue * src     = uniforms + i;
            KVariable * dest = _kvars + src->kname;
            dest->value = src->value;
            dest->location = NEED_LOCATION;
        }
    }
    return self;
}

-(void)setFloat:(KVariableName)name value:(float)value
{
    _kvars[name].value.f = value;
}

-(void)setVector2:(KVariableName)name value:(GLKVector2)value
{
    _kvars[name].value.v = value;
}

-(void)setTexture:(KVariableName)name value:(FBO *)fbo
{
    _textures[@(name)] = fbo;
}

-(void)getLocations:(NSDictionary *)fbos
{
    [self use];
    
    _textures = [NSMutableDictionary new];
    for( int i = 0; i < NUM_KV_VARIABLES; i++ )
    {
        KVariable * kv = _kvars + i;
        if( kv->location == NEED_LOCATION )
        {
            // N.B. some locations have been optimized out by iOS shader compiler
            GLint location = glGetUniformLocation(_program, kv->name);
            if( kv->kname > KV_LAST_SCALAR_UNIFORM )
            {
                FBO * fbo = fbos[@(kv->value.n)];
                fbo.uLocation = location;
                _textures[@(kv->kname)] = fbo;
                kv->location = DONT_NEED_LOCATION;
            }
            else
            {
                kv->location = location;
            }
        }
    }
}

-(void)bind
{
    int target = 0;
    for( id key in _textures )
    {
        FBO * texture = _textures[key];
        [texture bindTarget:target];
        target++;
    }
    
    ShaderLocations * locs = self.locations;
    for( int i = 0; i < NUM_KV_VARIABLES; i++ )
    {
        KVariable * kv = _kvars + i;
        if( kv->location >= VALID_LOCATION )
            [locs writeToLocation:kv->location type:kv->utype data:&kv->value];
    }
}

-(void)unbind
{
    for( id key in _textures )
    {
        FBO * texture = _textures[key];
        [texture unbind];
    }
}
@end

#pragma mark -
#pragma mark Computer Kernel
#pragma mark -

typedef enum K_flags {
    KF_NONE = 0,
    KF_Blend = 1,
    KF_NoBind = 2,
    KF_NoUnbind = 4
} K_flags;

#define K_FLAG(b) ((_flags & b) != 0)

@interface ComputeKernel : NSObject {
    MeshBuffer * _mesh;
    K_flags _flags;
}
@property (nonatomic,strong) KernelShader * shader;
@property (nonatomic,strong) FBO * fbo;
@end

@implementation ComputeKernel
-(id) initWithShader:(KernelShader *)shader
                mesh:(MeshBuffer *)mesh
                 fbo:(FBO*)fbo
               flags:(K_flags)flags
{
    if( (self = [super init]) )
    {
        _shader = shader;
        _mesh = mesh;
        _fbo = fbo;
        _flags = flags;
    }
    return self;
}

-(id) initWithShader:(KernelShader *)shader
                mesh:(MeshBuffer *)mesh
                 fbo:(FBO*)fbo
{
    return [self initWithShader:shader mesh:mesh fbo:fbo flags:KF_NONE];
}

-(void)run
{
    if( _fbo && !K_FLAG(KF_NoBind) )
        [_fbo bindToRender];
    
    [_shader use];
    [_shader bind];

    if( K_FLAG(KF_Blend) )
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        glEnable(GL_BLEND);
    }
    else
    {
        glDisable(GL_BLEND);
    }
    
    [_mesh getLocations:_shader]; // can be elsewhere ???
    [_mesh bind:_shader];
    
    [_mesh draw];
    
    [_shader unbind];
    if( _fbo && !K_FLAG(KF_NoUnbind) )
       [_fbo unbindFromRender];
    
}
@end

#pragma mark -
#pragma mark Fluid Helpers
#pragma mark -

static void ScreenQuadData(float xscale, float yscale, float * EighteenFloats )
{
    if( !xscale )
        xscale = 1;
    if( !yscale )
        yscale = xscale;

    float data[18] = {
        -xscale, yscale, 0,
        -xscale, -yscale, 0,
        xscale, -yscale, 0,
        
        -xscale, yscale, 0,
        xscale, -yscale, 0,
        xscale, yscale, 0
    };
    
    memcpy(EighteenFloats, data, sizeof(data));
}

static void BoundaryData( float px_x, float px_y, float * ThirtyTwoFloats )
{
     float data[32] = {
        // bottom
        -1+px_x*0.0, -1+px_y*0.0,
        -1+px_x*0.0, -1+px_y*2.0,
        
        1-px_x*0.0, -1+px_y*0.0,
        1-px_x*0.0, -1+px_y*2.0,
        
        // top
        -1+px_x*0.0,  1-px_y*0.0,
        -1+px_x*0.0,  1-px_y*2.0,
        
        1-px_x*0.0,  1-px_y*0.0,
        1-px_x*0.0,  1-px_y*2.0,
        
        // left
        -1+px_x*0.0,  1-px_y*0.0,
        -1+px_x*2.0,  1-px_y*0.0,
        
        -1+px_x*0.0, -1+px_y*0.0,
        -1+px_x*2.0, -1+px_y*0.0,
        
        // right
        1-px_x*0.0,  1-px_y*0.0,
        1-px_x*2.0,  1-px_y*0.0,
        
        1-px_x*0.0, -1+px_y*0.0,
        1-px_x*2.0, -1+px_y*0.0        
    };
    
    memcpy(ThirtyTwoFloats, data, sizeof(data));
}

#pragma mark -
#pragma mark Fluids
#pragma mark -

@interface Fluid() {
    NSMutableDictionary * _buffers;
    NSMutableDictionary * _fbos;

    ComputeKernel * _k_advectVelocity;
    ComputeKernel * _k_velocityBoundary;
    ComputeKernel * _k_addForce;
    ComputeKernel * _k_divergence;
    ComputeKernel * _k_jacobi;
    ComputeKernel * _k_pressureBoundary;
    ComputeKernel * _k_subtractPressureGradient;
    ComputeKernel * _k_subtractPressureBoundaryGradient;
    ComputeKernel * _k_draw;
    
    float _input_x;
    float _input_y;
    float _input_x0;
    float _input_y0;
    float _px_x;
    float _px_y;
}
@end

@implementation Fluid

-(void)createScreenData:(float)x y:(float)y name:(MeshBufferName)name
{
    float * screenData = malloc(sizeof(float)*18);
    ScreenQuadData(x,y, screenData);
    TGVertexStride s;
    StrideInit3f(&s, SV_NONE);
    s.shaderAttrName = "position";
    MeshBuffer * buffer = [[MeshBuffer alloc] init];
    [buffer setData:screenData strides:&s countStrides:1 numVertices:18];
    free(screenData);
    _buffers[@(name)] = buffer;
}

-(void)createBoundaryData:(float)x y:(float)y
{
    float * meshData = malloc(sizeof(float)*32);
    BoundaryData(x, y, meshData);
    TGVertexStride s[2];
    StrideInit2f(s+0, SV_NONE);
    s[0].shaderAttrName = "position";
    StrideInit2f(s+1, SV_NONE);
    s[1].shaderAttrName = "offset";
    MeshBuffer * buffer = [[MeshBuffer alloc] init];
    buffer.drawType = GL_LINES;
    [buffer setData:meshData strides:s countStrides:2 numVertices:32];
    free(meshData);
    _buffers[@(MB_boundary)] = buffer;
}

-(id)initWithObject:(id)dictObj
{
    self = [super init];
    if( !self )
        return nil;
    
    NSDictionary * params = dictObj;
    int width = [params[@"drawableWidth"] intValue];
    int height = [params[@"drawableHeight"] intValue];
    
    glDisable(GL_DEPTH_TEST);
    
    float px_x = _px_x = 1.0/width;
    float px_y = _px_y = 1.0/height;
    GLKVector2 px  = { px_x, px_y };
    GLKVector2 px1 = { 1, width/height };

    _buffers = [NSMutableDictionary new];
    
    [self createScreenData:1.0-px_x*2.0 y:1.0-px_y*2.0 name:MB_inside];
    [self createScreenData:1 y:1 name:MB_all];
    [self createBoundaryData:px_x y:px_y];
    [self createScreenData:px_x*options.cursor_size*2 y:px_y*options.cursor_size*2 name:MB_cursor];
    
    _fbos = [NSMutableDictionary new];
    _fbos[@(FBO_velocity0)]  = [[FBO alloc] initWithWidth:width height:height];
    _fbos[@(FBO_velocity1)]  = [[FBO alloc] initWithWidth:width height:height];
    _fbos[@(FBO_divergence)] = [[FBO alloc] initWithWidth:width height:height];
    _fbos[@(FBO_pressure0)]  = [[FBO alloc] initWithWidth:width height:height];
    _fbos[@(FBO_pressure1)]  = [[FBO alloc] initWithWidth:width height:height];

    KernelShader *ks;
    
    {
        KValue vs[6] = {
            { kv_px,        px },
            { kv_px1,       px1 },
            { kv_scale_f,   1.0f },
            { kv_velocity, {.n = FBO_velocity0} },
            { kv_source,   {.n = FBO_velocity0} },
            { kv_dt,        options.step }
        };
        
        ks = [[KernelShader alloc] initWithV:"kernel" F:"advect" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_advectVelocity = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_inside)] fbo:_fbos[@(FBO_velocity1)]];
    }
    
    {
        KValue vs[5] = {
            { kv_px,        px },
            { kv_scale_f,   1.0f },
            { kv_velocity, {.n = FBO_velocity0} },
            { kv_source,   {.n = FBO_velocity0} },
            { kv_dt,        options.step }
        };
        
        ks = [[KernelShader alloc] initWithV:"boundary" F:"advect" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_velocityBoundary = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_boundary)] fbo:_fbos[@(FBO_velocity1)]];
    }
    
    {
        KValue vs[4] = {
            { kv_px, px },
            { kv_force, GLKVector2Make(0.5, 0.2) },
            { kv_center, GLKVector2Make(0.1, 0.4) },
            { kv_scale_v2, GLKVector2Make(options.cursor_size*px_x, options.cursor_size*px_y) }
        };

        ks = [[KernelShader alloc] initWithV:"cursor" F:"addForce" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_addForce = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_cursor)] fbo:_fbos[@(FBO_velocity1)] flags:KF_Blend];
    }

    {
        KValue vs[2] = {
            { kv_px, px },
            { kv_velocity, {.n = FBO_velocity1} }
        };
        
        ks = [[KernelShader alloc] initWithV:"kernel" F:"divergence" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_divergence = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_all)] fbo:_fbos[@(FBO_divergence)]];
    }

    {
        KValue vs[5] = {
            { kv_px, px },
            { kv_pressure, {.n = FBO_pressure1} },
            { kv_divergence, {.n = FBO_divergence} },
            { kv_alpha, -1.0 },
            { kv_beta, 0.25 }
        };
        
        ks = [[KernelShader alloc] initWithV:"kernel" F:"jacobi" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_jacobi = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@"all"] fbo:_fbos[@(FBO_pressure1)] flags:KF_NoUnbind];

        ks = [[KernelShader alloc] initWithV:"boundary" F:"jacobi" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_pressureBoundary = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_boundary)] fbo:_fbos[@(FBO_pressure1)] flags:KF_NoBind|KF_NoUnbind];

    }

    {
        KValue vs[4] = {
            { kv_px, px },
            { kv_scale_f, 1.0f },
            { kv_pressure, {.n = FBO_pressure1} },
            { kv_velocity, {.n = FBO_velocity1} }
        };
        
        ks = [[KernelShader alloc] initWithV:"kernel" F:"subtractPressureGradient" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_subtractPressureGradient = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_all)] fbo:_fbos[@(FBO_velocity0)]];

        ks = [[KernelShader alloc] initWithV:"boundary" F:"subtractPressureGradient" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_subtractPressureBoundaryGradient = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_boundary)] fbo:_fbos[@(FBO_velocity0)]];
    }

    {
        KValue vs[4] = {
            { kv_px, px },
            { kv_pressure, {.n = FBO_pressure0} },
            { kv_velocity, {.n = FBO_velocity0} }
        };
        
        ks = [[KernelShader alloc] initWithV:"kernel" F:"visualize" uniforms:vs numUniforms:sizeof(vs)/sizeof(vs[0])];
        [ks getLocations:_fbos];
        _k_draw = [[ComputeKernel alloc] initWithShader:ks mesh:_buffers[@(MB_all)] fbo:nil];
        
    }
    
    View * view = (View *)params[@"view"];
    UITapGestureRecognizer * tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    tgr.numberOfTapsRequired = 2;
    [view addGestureRecognizer:tgr];
    
    
    return self;
}

-(void)onDoubleTap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [tgr locationInView:self.view];
        _input_x = pt.x;
        _input_y = -pt.y;
        NSLog(@"double tap at: %f, %f", _input_x, _input_y);
    }
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    float x1 = _input_x * options.resolution;
    float y1 = _input_y * options.resolution;
    float xd = x1 - _input_x0;
    float yd = y1 - _input_y0;
    
    _input_x0 = x1;
    _input_y0 = y1;
    if(_input_x0 == 0 && _input_y0 == 0)
        xd = yd = 0;
    
    ComputeKernel * ck;
    
    ck = _k_advectVelocity;
    [ck.shader setFloat:kv_dt value:options.step];
    [ck run];

    ck = _k_addForce;
    GLKVector2 force = { xd*_px_x*options.cursor_size*options.mouse_force,
                        -yd*_px_y*options.cursor_size*options.mouse_force };
    [ck.shader setVector2:kv_force value:force];
    GLKVector2 center = { _input_x0*_px_x*2-1.0, (_input_y0*_px_y*2-1.0)*-1 };
    [ck.shader setVector2:kv_center value:center];
    [ck run];
    
    [_k_velocityBoundary run];
    [_k_divergence run];

    FBO * p0 = _fbos[@(FBO_pressure0)];
    FBO * p1 = _fbos[@(FBO_pressure1)];
    FBO * pX = p0;
    
    KernelShader * jacobiShader = _k_jacobi.shader;
    KernelShader * pressShader  = _k_pressureBoundary.shader;
    
    for( int i = 0; i < options.iterations; i++ )
    {
        [jacobiShader setTexture:kv_pressure value:p0];
        [pressShader  setTexture:kv_pressure value:p0];
        _k_jacobi.fbo = p1;
        _k_pressureBoundary.fbo = p1;
        
        [_k_jacobi run];
        [_k_pressureBoundary run];
        
        pX = p0;
        p0 = p1;
        p1 = pX;
    }

    [_k_subtractPressureGradient run];
    [_k_subtractPressureBoundaryGradient run];
    [_k_draw run];

}
@end
