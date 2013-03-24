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
#import "Texture.h"

NSString * const kParamDistortionPt = @"DistortionPt";

@interface Spherey : Sphere
@end

@implementation Spherey

-(id)wireUp
{
    [super wireUp];
    self.rotation = (GLKVector3){ 0, M_PI, 0 };
    return self;
}

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

-(void)createTexture
{
    self.texture = [[Texture alloc] initWithFileName:@"moon.png"];
}
-(void)getParameters:(NSMutableDictionary *)parameters
{
    [super getParameters:parameters];
    
    Shader    * shader = self.shader;    
    [shader vec3Parameter:parameters indexIntoNames:gv_distortionPt];
    [shader floatParameter:parameters
            indexIntoNames:gv_distortionFactor
                     value:0.5
                neg11range:(FloatRange){0.01,1.0}
                 forObject:self];
    
    ((Parameter *)parameters[kParamRotationY]).targetObject = self.parent;
    
    parameters[@"ResetRotation"] = [Parameter withBlock:^(CGPoint pt) {
        self.rotation = (GLKVector3){0,0,0};
    }];
}

@end
