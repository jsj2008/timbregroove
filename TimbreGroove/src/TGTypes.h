//
//  TGTypes.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_TGTypes_h
#define TimbreGroove_TGTypes_h

#define R0_1() (((float)(arc4random_uniform(0x1000000) % 255))/255.0)

#define TG_MIN(a,b)            (((a) < (b)) ? (a) : (b))
#define TG_MAX(a,b)            (((a) > (b)) ? (a) : (b))
#define TG_CLAMP(x, lo, hi)      (TG_MIN((hi), TG_MAX((x), (lo))))

typedef enum {
    TG_FLOAT,
    TG_VECTOR2,
    TG_VECTOR3,
    TG_VECTOR4,
    TG_MATRIX3,
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

typedef enum TGStrideType {
    st_float2 = 1000,
    st_float3,
    st_float4
} TGStrideType;

typedef struct TGVertexStride {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    TGStrideType strideType;
    int          indexIntoShaderNames;
    GLuint       location;
} TGVertexStride;

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
