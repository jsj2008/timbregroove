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

//#define TEST_OUTPUT

#pragma mark -
#pragma mark Test object to peeking into FBOs
#pragma mark -

#ifdef TEST_OUTPUT
@interface TestFBO : Generic
@end
@implementation TestFBO

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_uv)] numVertices:6 numIndices:0];
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
    fl_NONE  = -2,
    fl_ERROR = -1,
    
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
    FluidVariableName kname;
    const char *  name;
    TGUniformType utype;
    GLint location;
    union {
        GLKVector2 v2;
        float f;
    } data;
} FluidVariable;

FluidVariable __kVariables[ NUM_fl_VARIABLES ] = {
    
    { fl_px,         "px",         TG_VECTOR2},
    { fl_px1,        "px1",        TG_VECTOR2},
    { fl_scale_f,    "scale",      TG_FLOAT},
    { fl_dt,         "dt",         TG_FLOAT},
    { fl_force,      "force",      TG_VECTOR2 },
    { fl_center,     "center",     TG_VECTOR2 },
    { fl_scale_v2,   "scalev",     TG_VECTOR2 },
    { fl_alpha,      "alpha",      TG_FLOAT },
    { fl_beta,       "beta",       TG_FLOAT },
    
    { fl_velocity,   "velocity",   TG_TEXTURE },
    { fl_source,     "source",     TG_TEXTURE },
    { fl_pressure,   "pressure",   TG_TEXTURE },
    { fl_divergence, "divergence", TG_TEXTURE }
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

-(id)initWithVertex:(const char *)vname andFragment:(const char * )fname
{
    if( (self = [super init] ) )
    {
        NSLog(@"Creating shader for %s/%s",vname,fname);
        [self load:@(vname) withFragment:@(fname)];
        memcpy(_vars,__kVariables,sizeof(_vars));
        GLuint program = self.program;
        for( int i = 0; i < NUM_fl_VARIABLES; i++ )
        {
            FluidVariable * fv = _vars + i;
            // missing uniforms will silently fail with -1
            fv->location = glGetUniformLocation(program, fv->name);
        }        
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
    for( FluidVariableName i = 0; i < fl_LAST_SCALAR_UNIFORM; i++ )
    {
        FluidVariable * fv = _vars + i;
        if( fv->location != -1 )
        {
            if( fv->utype == TG_FLOAT )
                glUniform1f(fv->location, fv->data.f);
            else
                glUniform2fv(fv->location, 1, fv->data.v2.v);
        }
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
    _keyedTextures = [textures mutableCopy];;
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
        FluidVariable * var = [shader var:[key intValue]];
        t.uLocation = var->location;
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
    [self createBufferDataByType:@[@(sv_pos)]
                     numVertices:18
                      numIndices:0
                        uniforms:@{@(sv_pos) : @"position"}];
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
    [self createBufferDataByType:@[@(sv_pos2f),@(sv_customAttr2f)]
                     numVertices:8
                      numIndices:0
                        uniforms:@{@(sv_pos2f) : @"position",@(sv_customAttr2f) : @"offset"}];
    
    buffer.drawType = GL_LINES;
}

-(void)getBufferData:(void *)vertextData indexData:(unsigned int *)indexData
{
    float twoPixelsX = _x * 2.0;
    float twoPixelsY = _y * 2.0;
    
#define OFS(x) x // ((x)*0.5+0.5)
    
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
    
    _velocity0 = [[FBO alloc] initWithWidth:width height:height];
    _velocity1 = [[FBO alloc] initWithWidth:width height:height];
    
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
    _divergence = [[FBO alloc] initWithWidth:width height:height];
    
    _divergenceKernel = [[QuadMesh alloc] init];
    [_divergenceKernel setX:1
                          Y:1
                    vShader:"kernel"
                    fShader:"divergence"
                   textures:@{@(fl_velocity):_velocity1}];
    [_divergenceKernel wireUp];
    [_divergenceKernel setVector2:fl_px value:&px];
    _divergenceKernel.fbo = _divergence;    
    //=========================================
#ifdef TEST_OUTPUT
    [self testFBO:_divergence];
#endif
    //=========================================
    _pressure0 = [[FBO alloc] initWithWidth:width height:height];
    _pressure1 = [[FBO alloc] initWithWidth:width height:height];
    
    _jacobiKernel = [[QuadMesh alloc] init];
    [_jacobiKernel setX:1
                      Y:1
                vShader:"kernel"
                fShader:"jacobi"
               textures: @{@(fl_pressure):_pressure0,@(fl_divergence):_divergence}];
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
                         textures: @{@(fl_pressure):_pressure0,@(fl_divergence):_divergence}];
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
    [_addForceKernel renderToFBOWithClear:doClear];
    
    //=====================================================
    [_velocityBoundaryKernel renderToFBOWithClear:false];
        
    //=====================================================
    [_divergenceKernel renderToFBOWithClear:doClear];
    
    //=====================================================
    FBO * p0 = _pressure0;
    FBO * p1 = _pressure1;
    FBO * swap;
    for(int i = 0; i < options.iterations; i++)
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
    
    //=====================================================
    [_subtractPressureGradientKernel renderToFBOWithClear:doClear];
    [_subtractPressureGradientBoundaryKernel renderToFBOWithClear:doClear];
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [_drawKernel render:w h:h];
}

#ifdef TEST_OUTPUT
-(void)testFBO:(FBO *)fbo
{
    TestFBO * test = [[TestFBO alloc] init];
    test.fbo = fbo;
    test.camera = [IdentityCamera new];
    [self appendChild:test];
    [test wireUp];
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
