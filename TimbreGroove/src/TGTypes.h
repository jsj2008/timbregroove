//
//  TGTypes.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_TGTypes_h
#define TimbreGroove_TGTypes_h

#import "Log.h"

#define R0_1()      (((float)(arc4random_uniform(0x1000000) % 255))/255.0)
#define R0_n(n)     (int)(arc4random_uniform(n))
#define NUM_ELEM(x) (sizeof(x)/sizeof(x[0]))


#define GL_ERROR_C { GLenum __e = glGetError(); if(__e) { TGLog(LLShitsOnFire, @"glError(%d/%04X) %s:%d",__e,__e,__FILE__,__LINE__); }}


typedef struct _TGVector3 {
    float x;
    float y;
    float z;
} TGVector3; // use this instead of GLKVector3 for param blocks
// because the block signature detection code rejects unions

#define TG3(tg3) *(GLKVector3 *)&tg3

typedef void (^FloatParamBlock)(float);
typedef void (^PointParamBlock)(CGPoint);
typedef void (^IntParamBlock)(int);
typedef void (^PointerParamBlock)(void *);
typedef void (^Vector3ParamBlock)(TGVector3);

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

#define TG_POINT        TG_VECTOR2
#define TG_COLOR        TG_VECTOR4

typedef struct VertexStride {
    unsigned int glType; // e.g. GL_FLOAT
    unsigned int numSize; // e.g. sizeof(float)
    unsigned int numbersPerElement;
    int          indexIntoShaderNames;
    GLuint       location;
} VertexStride;

#define POSITION_FROM_MAT(m) PositionFromMatrix(m)

static inline GLKVector3 PositionFromMatrix(GLKMatrix4 m)
{
    GLKVector4 vec4 = GLKMatrix4GetColumn(m, 3);
    return *(GLKVector3 *)&vec4;
}

/* these need to match up to shader

 const int CI_Ambient  = 0;
 const int CI_Diffuse  = 1;
 const int CI_Specular = 2;
 const int CI_Emission = 3;
 */
typedef struct _MaterialColors {
    GLKVector4 ambient, diffuse, specular, emission;
} MaterialColors;

NSString * stringFromMat(GLKMatrix4 m);
NSString * stringFromColor(GLKVector4 c);

#endif
