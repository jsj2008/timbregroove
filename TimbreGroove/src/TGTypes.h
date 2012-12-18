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
    TG_BOOL
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

typedef struct {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    SVariables   tgVarType;
    const char * shaderAttrName;
    GLuint       shaderAttr;
} TGVertexStride;

typedef struct
{
    void *           bufferData;
    unsigned int     numElements;
    TGVertexStride * strides;
    unsigned int     numStrides;
    float            opacity;
    const char *     texture;
    GLKVector4       color;
    
} TGGenericElementParams;


#define GL_ERROR_C { GLenum __e = glGetError(); if(__e) { NSLog(@"glError(%d) %s:%d",__e,__FILE__,__LINE__); }}

#endif
