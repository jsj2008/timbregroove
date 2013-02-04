//
//  Fluid.m
//  TimbreGroove
//
//  Created by victor on 1/2/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Generic.h"
#import "Shader.h"
#import "FBO.h"
#import "MeshBuffer.h"
#import "Camera.h"
#import "GraphView.h"
#import "Texture.h"
#import "Geometry.h"
#import "BlendState.h"

#pragma mark -
#pragma mark Options settings

typedef struct Fluid_options {
    int iterations;
    int mouse_force;
    float resolution;
    int cursor_size;
    float step;
} Fluid_options;

static Fluid_options options = { 16, 1, 1.0f, 50, 1.0f/30.0f };

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
    FluidVariable _fvars[ NUM_fl_VARIABLES ];
}

@end
@implementation FluidShader

-(FluidVariable *)var:(FluidVariableName)name
{
    return _fvars + name;
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
        memcpy(&_fvars, &__kVariables, sizeof(__kVariables));
    }
    
    return self;
}

-(void)setUValue:(FluidVariableName)fname value:(void *)value
{
    FluidVariable * fv = _fvars + fname;
    if( fv->utype == TG_FLOAT )
        fv->data.f = *(float *)value;
    else
        fv->data.v2 = *(GLKVector2 *)value;
}

-(void)writeUValues
{
    for( FluidVariableName i = FL_LAST_ATTR+1; i < fl_LAST_SCALAR_UNIFORM; i++ )
    {
        if( _vars[i] != -1 )
        {
            FluidVariable * fv = _fvars + i;
            [self writeToLocation:i type:fv->utype data:&fv->data];
        }
    }
}
@end

#pragma mark -
#pragma mark Quad Mesh
#pragma mark -


@interface QuadMesh : Geometry {
    float _x;
    float _y;
}
@end

@implementation QuadMesh

-(id)initWithX:(float)x andY:(float)y
{
    _x = x;
    _y = y;
    
    if( (self = [super init]) )
    {
        [self createBufferDataByType:@[@(st_float3)]
                    indicesIntoNames:@[@(fl_position)]];        
    }
    
    return self;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = 6;
    stats->numIndices  = 0;
}


-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
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
#pragma mark Boundary Mesh
#pragma mark -

@interface BoundaryMesh : Geometry {
    float _x;
    float _y;
}
@end

@implementation BoundaryMesh


-(id)initWithX:(float)x andY:(float)y
{
    _x = x;
    _y = y;
    
    if( (self = [super init]) )
    {
        [self createBufferDataByType:@[@(st_float2),@(st_float2)]
                    indicesIntoNames:@[@(fl_position),@(fl_offset)]];
    }
    return self;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = 8;
    stats->numIndices  = 0;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    float twoPixelsX = _x * 2.0;
    float twoPixelsY = _y * 2.0;
    
    float data[] = {
        // bottom
        -1, -1,
        -1, -1+twoPixelsY,
        
        1, -1,
        1, -1+twoPixelsY,
        
        // top
        -1,  1,
        -1,  1-twoPixelsY,
        
        1,  1,
        1,  1-twoPixelsY,
        
        // left
        -1, 1,
        -1+twoPixelsX, 1,
        
        -1, -1,
        -1+twoPixelsX, -1,
        
        // right
        1, 1,
        1-twoPixelsX, 1,
        
        1, -1,
        1-twoPixelsX, -1
    };
    
    memcpy(vertextData, data, sizeof(data));
}
@end

#pragma mark -
#pragma mark Kernel
#pragma mark -

@interface FluidKernel : NSObject {
    MeshBuffer * _buffer;
    FluidShader * _shader;
    NSMutableDictionary * _keyedTextures; // key=uSamplerName value=FBO*
}
@property (nonatomic) bool blend;
@property (nonatomic) bool bindFBO;
@property (nonatomic) bool unbindFBO;
@property (nonatomic,strong) FBO * fbo;
@end


@implementation FluidKernel

-(void)setVShader:(const char *)vShader
          FShader:(const char *)fShader
         textures:(NSDictionary *) textures
           buffer:(MeshBuffer *)buffer;
{
    _buffer = buffer;
    _shader = [[FluidShader alloc] initWithVertex:vShader andFragment:fShader];
    _keyedTextures = [textures mutableCopy];
    _bindFBO = true;
    _unbindFBO = true;
}

-(void)setFloat:(FluidVariableName)fname value:(float)value
{
    [_shader setUValue:fname value:&value];
}

-(void)setVector2:(FluidVariableName)fname value:(GLKVector2 *)value
{
    [_shader setUValue:fname value:value];
}

-(void)setTexture:(Texture *)texture forKey:(int)key
{
    _keyedTextures[@(key)] = texture;
}

-(void)render
{
    [_shader use];
    
    int target = 0;
    for( id key in _keyedTextures )
    {
        Texture * t = _keyedTextures[key];
        t.uLocation = [_shader location:[key intValue]];
        [t bind:target];
        ++target;
    }
    
    [_shader writeUValues];
    
    BlendState * bs;

    if( _blend )
    {
        bs = [BlendState enable:true srcFactor:GL_SRC_ALPHA dstFactor:GL_ONE];
    }
    else
    {
        bs = [BlendState enable:false];
    }
    
    if( _fbo && _bindFBO )
       [_fbo bindToRender];
    
    [_buffer getLocations:_shader];    
    [_buffer bind];
    [_buffer draw];
    [_buffer unbind];
    
    if( _fbo && _unbindFBO )
        [_fbo unbindFromRender];
    
    for( id key in _keyedTextures )
    {
        Texture * t = _keyedTextures[key];
        [t unbind];
    }

    [bs restore];
}

@end

#pragma mark -
#pragma mark Main Fluid object
#pragma mark -

@interface Fluid : TG3dObject {
    float _px;
    float _py;
}
@end

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
    
    FluidKernel * _advectVelocity;
    FluidKernel * _addForceKernel;
    FluidKernel * _velocityBoundaryKernel;
    FluidKernel * _divergenceKernel;
    FluidKernel * _jacobiKernel;
    FluidKernel * _pressureBoundaryKernel;
    FluidKernel * _subtractPressureGradientKernel;
    FluidKernel * _subtractPressureGradientBoundaryKernel;
    FluidKernel * _drawKernel;
    
    bool _gestureRegistered;
}
@end

@implementation Fluid

-(id)wireUpWithViewSize:(CGSize)viewSize
{
    CGSize sz = viewSize;
    _px = 1.0/sz.width;
    _py = 1.0/sz.height;
  
    GLKVector2 px = { _px, _py };
    GLKVector2 px1 = { 1.0, sz.width/sz.height };
    
    _velocity0 = [[FBO alloc] initWithWidth:sz.width height:sz.height type:GL_HALF_FLOAT_OES format:0];
    _velocity1 = [[FBO alloc] initWithWidth:sz.width height:sz.height type:GL_HALF_FLOAT_OES format:0];
    _pressure0 = [[FBO alloc] initWithWidth:sz.width height:sz.height type:GL_HALF_FLOAT_OES format:GL_LUMINANCE];
    _pressure1 = [[FBO alloc] initWithWidth:sz.width height:sz.height type:GL_HALF_FLOAT_OES format:GL_LUMINANCE];
    _divergence = [[FBO alloc] initWithWidth:sz.width height:sz.height type:GL_HALF_FLOAT_OES format:GL_LUMINANCE];
    
    float twoPixelsX = _px * 2.0;
    float twoPixelsY = _py * 2.0;
    
    QuadMesh * inside = [[QuadMesh alloc]initWithX:1.0 - twoPixelsX andY:1.0 - twoPixelsY];
    QuadMesh * all    = [[QuadMesh alloc]initWithX:1 andY:1];
    QuadMesh * cursor = [[QuadMesh alloc]initWithX:_px*options.cursor_size*2 andY:_py*options.cursor_size*2];
    BoundaryMesh * boundary = [[BoundaryMesh alloc] initWithX:_px andY:_px];
    
    NSDictionary * vv0sv0 = @{@(fl_velocity):_velocity0,@(fl_source):_velocity0};
    NSDictionary * pp0dd  = @{@(fl_pressure):_pressure0,@(fl_divergence):_divergence};
    NSDictionary * pp0vv1 = @{@(fl_pressure):_pressure0,@(fl_velocity):_velocity1};
    NSDictionary * pp0vv0 = @{@(fl_pressure):_pressure0,@(fl_velocity):_velocity0};
    
    // =================================
    _advectVelocity = [FluidKernel new];
    [_advectVelocity setVShader:"kernel"
                        FShader:"advect"
                 textures: vv0sv0
                   buffer: inside];
    
    [_advectVelocity setVector2:fl_px value:&px];
    [_advectVelocity setVector2:fl_px1 value:&px1];
    [_advectVelocity setFloat:fl_scale_f value:1.0];
    [_advectVelocity setFloat:fl_dt value:options.step];
    
    _advectVelocity.fbo = _velocity1;
    //=====================================
    _velocityBoundaryKernel = [FluidKernel new];
    [_velocityBoundaryKernel setVShader:"boundary"
                                FShader:"advect"
                         textures:vv0sv0
                           buffer:boundary];
    
    [_velocityBoundaryKernel setVector2:fl_px value:&px];
    [_velocityBoundaryKernel setFloat:fl_scale_f value:-1.0];
    [_velocityBoundaryKernel setFloat:fl_dt value:options.step];
    _velocityBoundaryKernel.fbo = _velocity1;
    // =================================
    _addForceKernel = [FluidKernel new];
    [_addForceKernel setVShader:"cursor"
                        FShader:"addForce"
                 textures:nil
                   buffer:cursor];

    _addForceKernel.blend = true;
    
    GLKVector2 scalev = { options.cursor_size*_px, options.cursor_size*_py };
    
    [_addForceKernel setVector2:fl_px value:&px];
    [_addForceKernel setVector2:fl_scale_v2 value:&scalev];
    _addForceKernel.fbo = _velocity1;
    //=========================================
    _divergenceKernel = [FluidKernel new];
    [_divergenceKernel setVShader:"kernel"
                    FShader:"divergence"
                   textures:@{@(fl_velocity):_velocity1}
                     buffer:all];
    
    [_divergenceKernel setVector2:fl_px  value:&px];
    [_divergenceKernel setVector2:fl_px1 value:&px]; // sic - send px value to px1
    _divergenceKernel.fbo = _divergence;
    //=========================================
    _jacobiKernel = [FluidKernel new];
    [_jacobiKernel setVShader:"kernel"
                      FShader:"jacobi"
               textures: pp0dd
                 buffer:all];

    [_jacobiKernel setFloat:fl_alpha value:-1.0];
    [_jacobiKernel setFloat:fl_beta value:0.25];
    [_jacobiKernel setVector2:fl_px value:&px];
    _jacobiKernel.fbo = _pressure1;
    _jacobiKernel.unbindFBO = false;
    //=========================================
    _pressureBoundaryKernel = [FluidKernel new];
    [_pressureBoundaryKernel setVShader:"boundary"
                                FShader:"jacobi"
                         textures: pp0dd
                           buffer:boundary];

    [_pressureBoundaryKernel setFloat:fl_alpha value:-1.0];
    [_pressureBoundaryKernel setFloat:fl_beta value:0.25];
    [_pressureBoundaryKernel setVector2:fl_px value:&px];
    _pressureBoundaryKernel.fbo = _pressure1;
    _pressureBoundaryKernel.unbindFBO = false;
    _pressureBoundaryKernel.bindFBO = false;
    //=========================================
    _subtractPressureGradientKernel = [FluidKernel new];
    [_subtractPressureGradientKernel setVShader:"kernel"
                                        FShader:"subtractPressureGradient"
                                 textures: pp0vv1
                                   buffer:all];

    [_subtractPressureGradientKernel setFloat:fl_scale_f value:1];
    [_subtractPressureGradientKernel setVector2:fl_px value:&px];
    _subtractPressureGradientKernel.fbo = _velocity0;
    //=========================================
    _subtractPressureGradientBoundaryKernel = [FluidKernel new];
    [_subtractPressureGradientBoundaryKernel setVShader:"boundary"
                                                FShader:"subtractPressureGradient"
                                         textures: pp0vv1
                                           buffer:boundary];
    
    [_subtractPressureGradientBoundaryKernel setFloat:fl_scale_f value:-1];
    [_subtractPressureGradientBoundaryKernel setVector2:fl_px value:&px];
    _subtractPressureGradientBoundaryKernel.fbo = _velocity0;
    //=========================================
    _drawKernel = [FluidKernel new];
    [_drawKernel setVShader:"kernel"
                    FShader:"visualize"
             textures: pp0vv0
               buffer:all];

    [_drawKernel setVector2:fl_px value:&px];
    
    return self;
}

-(void)setView:(GLKView *)view
{
    if( !_gestureRegistered )
    {
        // TODO: manually handle UITouch events for more control over this stuff
        UIPanGestureRecognizer * pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
        // pgr.minimumNumberOfTouches = 2;
        [view addGestureRecognizer:pgr];
        _gestureRegistered = true;
    }
}

-(void)update:(NSTimeInterval)dt
{
    GLboolean prevDT = glIsEnabled(GL_DEPTH_TEST);
    glDisable(GL_DEPTH_TEST);
    
    //=====================================================
    [_advectVelocity render];
    //=====================================================
    GLKVector2 force = GLKVector2Make( _delta_x * _px * options.cursor_size * options.mouse_force,
                                      -_delta_y * _py * options.cursor_size * options.mouse_force);
    
    GLKVector2 center = GLKVector2Make(  _input_x * _px * 2 - 1.0f,
                                       -(_input_y * _py * 2 - 1.0f) );
    
    [_addForceKernel setVector2:fl_force value:&force];
    [_addForceKernel setVector2:fl_center value:&center];
    [_addForceKernel render];
    
    //=====================================================
    [_velocityBoundaryKernel render];
    //=====================================================
    [_divergenceKernel render];
    
    //=====================================================
    FBO * p0 = _pressure0;
    FBO * p1 = _pressure1;
    FBO * swap;
    for(int i = 0; i < options.iterations; i++)
    {
        [_jacobiKernel           setTexture:p0 forKey:fl_pressure];
        [_pressureBoundaryKernel setTexture:p0 forKey:fl_pressure];
        _jacobiKernel.fbo = p1;
        _pressureBoundaryKernel.fbo = p1;
        [_jacobiKernel           render];
        [_pressureBoundaryKernel render];

        swap = p0;
        p0 = p1;
        p1 = swap;
    }
    
    //=====================================================
    [_subtractPressureGradientKernel render];
    [_subtractPressureGradientBoundaryKernel render];

    if( prevDT )
        glEnable(GL_DEPTH_TEST);
    
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    GLboolean prevDT = glIsEnabled(GL_DEPTH_TEST);
    glDisable(GL_DEPTH_TEST);
    [_drawKernel render];
    if( prevDT )
        glEnable(GL_DEPTH_TEST);
}

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
        
         NSLog(@"drag at: %f, %f", _input_x, _input_y);
    }
}


@end
