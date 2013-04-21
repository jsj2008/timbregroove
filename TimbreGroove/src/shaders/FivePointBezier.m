//
//  SixPointBezier.m
//  TimbreGroove
//
//  Created by victor on 2/15/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//


#import "FivePointBezier.h"
#import "Painter.h"

/*
 attribute float a_t_spacing;
 
 uniform mat4  u_pvm;
 uniform vec3  u_controlPoints[6];
*/

// this code is here in case we ever want
// to generate coefficients on the fly
// and send them into the shader

static unsigned long power(unsigned long m, unsigned long n)
{
    unsigned long temp = 1;
    
    while (n > 0)
    {
        if (n & 0x01UL) {
            temp *= m;
        }
        m *= m;
        n >>= 1;
    }
    return temp;
}

static void cnr(int numControlPoints, int answer[])
{
    int n = numControlPoints - 1;
    unsigned long x    = (1 << n) + 1; /* 2^n + 1 */
    unsigned long mask = (1 << n) - 1; /* 2^n - 1 */
    unsigned long result;
    int i;
    
    result = power(x, (unsigned long)n);
    
    for (i=0; i<=n; i++, result >>= n) { /* retrieve data */
        int maksedResult = result & mask;
        answer[i] = maksedResult;
    }
}

enum {
    spb_t_spacing,
    SPB_LAST_ATTRIBUTE = spb_t_spacing,
    spb_pvm,
    spb_controlPoints,
    spb_color,
    SPB_NUM_VARIABLES
};

static const char * _sbp_var_names[] = {
    "a_t_spacing",
    "u_pvm",
    "u_controlPoints",
    "u_color"
};


@implementation FivePointBezier

-(id)init
{
    self = [super initWithVertex:"bezier"
                     andFragment:"bezier"
                     andVarNames:_sbp_var_names
                     andNumNames:SPB_NUM_VARIABLES
                     andLastAttr:SPB_LAST_ATTRIBUTE
                      andHeaders:nil];
    
    if( self )
    {
        _color = (GLKVector4){ 1, 1, 1, 1 };
    }
    return self;
}


-(void)prepareRender:(TG3dObject *)object
{
    [super prepareRender:object];
    GLKMatrix4 pvm = [object calcPVM];
    [self writeToLocation:spb_pvm type:TG_MATRIX4 data:pvm.m];
    [self writeToLocation:spb_color type:TG_VECTOR4 data:_color.v];
    glUniform3fv(_locations[spb_controlPoints], 5, _controlPoints[0].v);
}

@end

@implementation FivePointBezierMesh

#define BEZ_SEGMENTS 100

-(id)init
{
    self = [super init];
    if( self )
    {
        [self createBufferDataByType:@[@(st_float1)] indicesIntoNames:@[@(spb_t_spacing)]];
        self.drawType = GL_LINE_STRIP;
    }
    return self;
}

-(void)getStats:(GeometryStats *)stats
{
    stats->numVertices = BEZ_SEGMENTS;
    stats->numIndices  = 0;
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
             withUVs:(bool)withUVs
         withNormals:(bool)withNormals
{
    float * pos = vertextData;
    for( int i = 0; i < BEZ_SEGMENTS; i++ )
    {
        *pos++ = (float)i/(float)BEZ_SEGMENTS;
    }
    
}

@end
