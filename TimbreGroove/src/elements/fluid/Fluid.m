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

#pragma mark -
#pragma mark Test object to peeking into FBOs
#pragma mark -

@interface TestFBO : Generic
@end
@implementation TestFBO

-(id)initWithTexture:(Texture *)FBO
{
    if( (self = [super init]) )
    {
        self.texture = FBO;
        [self getTextureLocations];
        self.camera = [IdentityCamera new];
    }
    return self;
}

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
    NSDictionary * _textures; // key=uSamplerName value=FBO*
}
@property (nonatomic) bool blend;
@end
@implementation FluidMesh

-(id)initWithV:(const char *)vShader f:(const char *)fShader textures:(NSDictionary *) textures
{
    _fShader = fShader;
    _vShader = vShader;
    _textures = textures;
    //_blend = true;
    return [super init];
}

-(void)createShader
{
    FluidShader * shader = [[FluidShader alloc] initWithVertex:_vShader andFragment:_fShader];
    self.shader = shader;
}

-(void)setTextures:(NSDictionary *)dict
{
    _textures = dict;
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
    for( id key in _textures )
    {
        Texture * t = _textures[key];
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
        [b bind:shader];
        [b draw];
    }
    
    for( id key in _textures )
    {
        Texture * t = _textures[key];
        [t unbind];
    }
}

@end

#pragma mark -
#pragma mark Kernel based on Mesh
#pragma mark -

@interface QuadMesh : FluidMesh {
    float _x;
    float _y;
}
@end

@implementation QuadMesh

-(id)initWithX:(float)x
             Y:(float)y
       vShader:(const char *)vShader
       fShader:(const char *)fShader
      textures:(NSDictionary *)texutures
{
    _x = x;
    _y = y;
    return [super initWithV:vShader f:fShader textures:texutures];
}

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos)] numVertices:18 numIndices:0 uniforms:@{@(sv_pos) : @"position"}];
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

@interface BoundaryMesh : FluidMesh {
    float _x;
    float _y;
}
@end

@implementation BoundaryMesh

-(id)initWithX:(float)x
             Y:(float)y
       vShader:(const char *)vShader
       fShader:(const char *)fShader
      textures:(NSDictionary *)texutures
{
    _x = x;
    _y = y;
    return [super initWithV:vShader f:fShader textures:texutures];
}

-(void)createBuffer
{
    TGGenericElementParams params;
    
    memset(&params, 0, sizeof(params));
    
    params.numStrides = 2;
    
    params.strides = malloc(sizeof(TGVertexStride)*params.numStrides);
    
    TGVertexStride strides[2];
    StrideInit2f(&strides[0], sv_pos);
    strides[0].shaderAttrName = "position";
    StrideInit2f(&strides[1], sv_custom);
    strides[1].shaderAttrName = "offset";
    
    GLsizei sz = [MeshBuffer calcDataSize:strides countStrides:2 numVertices:8];
    void * vertexData = malloc(sz);
    [self getBufferData:vertexData indexData:NULL];
    
    MeshBuffer * buffer = [[MeshBuffer alloc] init];
    
    [buffer setData:vertexData
            strides:strides
       countStrides:2
        numVertices:8];
    
    buffer.drawType = GL_LINES;
    
    if( !_buffers )
        _buffers = [NSMutableArray new];
    [_buffers addObject:buffer];
    
    free(params.vertexData);
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
    
    float _input_x;
    float _input_y;
    float _delta_x;
    float _delta_y;
    
    FluidMesh * _advectVelocity;
    FluidMesh * _addForceKernel;
    FluidMesh * _velocityBoundaryKernel;
    FluidMesh * _divergenceKernel;
}
@end

@implementation Fluid

-(id)initWithObject:(id)view
{
    self = [super init];
    if( !self )
        return nil;

    GLKView * glview = (GLKView *)(((GLKView *)view).superview);
    GLint width = glview.drawableWidth;
    GLint height = glview.drawableHeight;
    
    [self setupWorldWithWidth:width andHeight:height];

    UIPanGestureRecognizer * pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
    pgr.minimumNumberOfTouches = 2;
    [glview addGestureRecognizer:pgr];
    
    return self;
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
        
       // NSLog(@"drag at: %f, %f", _input_x, _input_y);
    }
}

-(void)setupWorldWithWidth:(unsigned int)width andHeight:(unsigned int)height;
{
    _px = 1.0/width;
    _py = 1.0/height;
    CGSize sz = { width, height };
    _viewSize = sz;
  
    GLKVector2 px = { _px, _py };
    GLKVector2 px1 = { 1.0, width/(float)height };
    
    _velocity0 = [[FBO alloc] initWithWidth:width height:height];
    _velocity1 = [[FBO alloc] initWithWidth:width height:height];
    
    float twoPixelsX = _px * 2.0;
    float twoPixelsY = _py * 2.0;
    
    // =================================    
    _advectVelocity = [[QuadMesh alloc] initWithX:1.0 - twoPixelsX
                                                Y:1.0 - twoPixelsY
                                          vShader:"kernel"
                                          fShader:"advect"
                                         textures:@{@(fl_velocity):_velocity0,@(fl_source):_velocity0}];
    
    [_advectVelocity setVector2:fl_px value:&px];
    [_advectVelocity setVector2:fl_px1 value:&px1];
    [_advectVelocity setFloat:fl_scale_f value:1.0];
    [_advectVelocity setFloat:fl_dt value:options.step];
    
    _advectVelocity.fbo = _velocity1;
    // =================================
    _addForceKernel = [[QuadMesh alloc] initWithX: twoPixelsX * options.cursor_size
                                                Y: twoPixelsY * options.cursor_size
                                          vShader:"cursor"
                                          fShader:"addForce"
                                         textures:nil];
    _addForceKernel.blend = true;
    
    GLKVector2 scalev = { options.cursor_size*_px, options.cursor_size*_py };
    
    [_addForceKernel setVector2:fl_px value:&px];
    [_addForceKernel setVector2:fl_scale_v2 value:&scalev];
    _addForceKernel.fbo = _velocity1;
    //=====================================
    _velocityBoundaryKernel = [[BoundaryMesh alloc] initWithX:_px
                                                            Y:_py
                                                      vShader:"boundary"
                                                      fShader:"advect"
                                                     textures:@{@(fl_velocity):_velocity0,@(fl_source):_velocity0}];
    
    [_velocityBoundaryKernel setVector2:fl_px value:&px];
    [_velocityBoundaryKernel setFloat:fl_scale_f value:-1.0];
    [_velocityBoundaryKernel setFloat:fl_dt value:1.0f/60.0f];
    _velocityBoundaryKernel.fbo = _velocity1;
        
    //=========================================
    
    _divergence = [[FBO alloc] initWithWidth:width height:height];
    
    _divergenceKernel = [[QuadMesh alloc] initWithX:1
                                                  Y:1
                                            vShader:"kernel"
                                            fShader:"divergence"
                                           textures:@{@(fl_velocity):_velocity1}];
    
    [_divergenceKernel setVector2:fl_px value:&px];
    _divergenceKernel.fbo = _divergence;
    
    //=========================================
    
    [self testFBO:_divergence];
}

-(void)update:(NSTimeInterval)dt
{
    bool doClear = true;
    
    // Use velocity0 as texture
    // Render to velocity1 using Quad (kernel/advect)
    //=====================================================
    [_advectVelocity renderToFBOWithClear:doClear];

    // Render to velocity1 using Quad (cursor/adforce)
    //=====================================================
    GLKVector2 force = GLKVector2Make( _delta_x * _px * options.cursor_size * options.mouse_force,
                                      -_delta_y * _py * options.cursor_size * options.mouse_force);
    
    GLKVector2 center = GLKVector2Make(  _input_x * _px * 2 - 1.0f,
                                       -(_input_y * _py * 2 - 1.0f) );
    
    [_addForceKernel setVector2:fl_force value:&force];
    [_addForceKernel setVector2:fl_center value:&center];
    [_addForceKernel renderToFBOWithClear:doClear];
    
    // Use velocity0 as texture
    // Render to velocity1 using Boundary (boudry/advect)
    //=====================================================
    [_velocityBoundaryKernel renderToFBOWithClear:false];
    
    
    // Use velocity1 as texture
    // Render to divergence using Quad (kernal/divergence)
    //=====================================================
    [_divergenceKernel renderToFBOWithClear:doClear];
    
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    //[_addForceKernel render:w h:h];
}

-(void)testFBO:(FBO *)fbo
{
    [self appendChild:[[TestFBO alloc] initWithTexture:fbo]];
}
@end
