//
//  Bezier.m
//  TimbreGroove
//
//  Created by victor on 2/14/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Bezier.h"
#import "Shader.h"
#import "Line.h"

@implementation Bezier

-(id)wireUp
{
    [super wireUp];
    Shader * shader = self.shader;
    [shader use];
    CGPoint pt1 = (CGPoint){0,0};
    CGPoint pt2 = (CGPoint){0.5,1};
    CGPoint pt3 = (CGPoint){1,0};
    [shader writeToLocation:gv_p1 type:TG_VECTOR2 data:&pt1];
    [shader writeToLocation:gv_p2 type:TG_VECTOR2 data:&pt2];
    [shader writeToLocation:gv_p3 type:TG_VECTOR2 data:&pt3];
    return self;
}

- (NSString *)getShaderHeader
{
    return [[super getShaderHeader] stringByAppendingString:@"#define BEZIER\n"];
}

-(void)setCurveHeight:(float)height width:(float)width offset:(float)offset
{
    self.position = (GLKVector3){ offset, -1, 0 };
    self.scale = (GLKVector3){ width, height, 0 };
}

-(void)createBuffer
{
    Line * line = [[Line alloc] initWithIndicesIntoNames:@[@(gv_pos)]
                                               isDynamic:false
                                                 spacing:100];
    [self addBuffer:line];
}

@end
