//
//  Spherey.m
//  TimbreGroove
//
//  Created by victor on 3/22/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Sphere.h"
#import "Scene.h"
#import "Names.h"
#import "GraphView.h"
#import "Light.h"
#import "Material.h"


NSString * const kParamDistortionPt = @"DistortionPt";

@interface Spherey : Sphere
@end

@implementation Spherey

-(id)wireUp
{
    [super wireUp];
    self.position = (GLKVector3){-1,0,0};
    return self;
}

#if 0
-(void)configureLighting
{
    if( !self.light )
        self.light = [Light new]; // defaults are good
    float subColor = 0;
    self.light.ambientColor = (GLKVector4){subColor, subColor, 1.0, 1.0};
    
    GLKVector3 lDir = self.light.direction;
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( lDir.x, lDir.y, lDir.z );
    self.light.direction = GLKMatrix4MultiplyVector3(mx,(GLKVector3){-1, 0, -1});
}
#endif

-(void)createShader
{
    [self addShaderFeature:[[Texture alloc] initWithFileName:@"moon.png"]];
    [super createShader];
}

@end
