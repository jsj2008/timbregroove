//
//  TGTypes.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_TGTypes_h
#define TimbreGroove_TGTypes_h


typedef enum {
    SV_NONE = -2,
    SV_ERROR = -1,
    
    sv_acolor = 0,
    sv_normal,
    sv_pos,
    sv_uv,
    
    SV_LAST_ATTR = sv_uv,
    
    sv_opacity,
    sv_pvm,
    sv_sampler,
    sv_ucolor,
    sv_useLighting,
    
    NUM_SVARIABLES,
    sv_custom,
    sv_stride,
    sv_buffer
    
} SVariables;

typedef enum {
    TG_FLOAT,
    TG_VECTOR2,
    TG_VECTOR3,
    TG_VECTOR4,
    TG_MATRIX4,
    TG_BOOL,
    TG_TEXTURE
} TGUniformType;

typedef enum {
    TG_POINTS = GL_POINTS, // etc.
    TG_LINES,
    TG_LINE_LOOP,
    TG_LINE_STRIP,
    TG_TRIANGLES,      // default
    TG_TRIANGLE_STRIP,
    TG_TRIANGLE_FAN
} TGDrawType;

typedef struct TGVertexStride {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    SVariables   tgVarType;
    const char * shaderAttrName;
    GLuint       location;
} TGVertexStride;

typedef struct TGGenericElementParams
{
    TGVertexStride * strides;
    unsigned int     numStrides;
    void *           vertexData;
    unsigned int     numVertices;
    unsigned int *   indexData;
    unsigned int     numIndices;
    
} TGGenericElementParams;


#define GL_ERROR_C { GLenum __e = glGetError(); if(__e) { NSLog(@"glError(%d/%04X) %s:%d",__e,__e,__FILE__,__LINE__); }}
#define GL_CALL(f) { NSLog(@"calling: %s", f); }
static inline NSMutableDictionary * d( NSDictionary * a )
{
    return [[NSMutableDictionary alloc] initWithDictionary:a];
}

static inline NSMutableArray * a(NSArray *a)
{
    return [[NSMutableArray alloc] initWithArray:a];
}
#endif
