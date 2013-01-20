//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "Plane.h"
#import "GridPlane.h"

@implementation Plane

-(void)createBuffer
{
    GridPlane * gp = [GridPlane gridWithIndicesIntoNames:@[@(gv_pos)]
                                                andDoUVs:false
                                            andDoNormals:false];
    [self addBuffer:gp];

}

@end
