//
//  TGTypes.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_TGTypes_h
#define TimbreGroove_TGTypes_h

#import "BKGlobals.h"
#import "NSObject+BlockObservation.h"

#define R0_1()      (((float)(arc4random_uniform(0x1000000) % 255))/255.0)
#define R0_n(n)     (int)(arc4random_uniform(n))


#define TG_MIN(a,b)            (((a) < (b)) ? (a) : (b))
#define TG_MAX(a,b)            (((a) > (b)) ? (a) : (b))
#define TG_CLAMP(x, lo, hi)      (TG_MIN((hi), TG_MAX((x), (lo))))

#define CLAMP_TO_0_1(x) (x < 0.0 ? 0.0 : x > 1.0 ? 1.0 : x)

#define GL_ERROR_C { GLenum __e = glGetError(); if(__e) { NSLog(@"glError(%d/%04X) %s:%d",__e,__e,__FILE__,__LINE__); }}
#define GL_CALL(f) { NSLog(@"calling: %s", f); }

typedef void (^FloatParamBlock)(float);
typedef void (^PointParamBlock)(CGPoint);
typedef void (^IntParamBlock)(int);
typedef void (^PointerParamBlock)(void *);


typedef enum {
    TG_FLOAT,
    TG_VECTOR2,
    TG_VECTOR3,
    TG_VECTOR4,
    TG_MATRIX3,
    TG_MATRIX4,
    TG_BOOL,
    TG_TEXTURE,
    TG_BOOL_FLOAT,
    TG_INT,
    
    TG_LAST_UTYPE = TG_INT
} TGUniformType;

#define TGParameterType TGUniformType
#define TG_POINT        TG_VECTOR2
#define TG_COLOR        TG_VECTOR4
#define TG_MIXERUPDATE  TG_LAST_UTYPE+1

typedef enum {
    TG_POINTS = GL_POINTS, // etc.
    TG_LINES,
    TG_LINE_LOOP,
    TG_LINE_STRIP,
    TG_TRIANGLES,      // default
    TG_TRIANGLE_STRIP,
    TG_TRIANGLE_FAN
} TGDrawType;

typedef enum VertexStrideType {
    st_float1 = 900,
    st_float2 = 1000,
    st_float3,
    st_float4
} VertexStrideType;

typedef struct VertexStride {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    VertexStrideType strideType;
    int          indexIntoShaderNames;
    GLuint       location;
} VertexStride;


static inline NSMutableDictionary * d( NSDictionary * a )
{
    return [[NSMutableDictionary alloc] initWithDictionary:a];
}

static inline NSMutableArray * a(NSArray *a)
{
    return [[NSMutableArray alloc] initWithArray:a];
}

static inline void DumpRect(const char *s, CGRect rc)
{
    NSLog(@"%s: %f, %f - %f x %f", s, rc.origin.x, rc.origin.y, rc.size.width, rc.size.height);
}
#endif
