//
//  TestElement.m
//  TimbreGroove
//
//  Created by victor on 1/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "TestFBOTexture.h"
#import "FBO.h"
#import "Camera.h"

@interface PaintMeToTexture : Generic
@end

@implementation PaintMeToTexture

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_acolor)] numVertices:6 numIndices:0];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*(3+4)] = {
        //   x   y  z    r    g   b,  a,
        -1, -1, 0,   0,   0,  1,  1,
        -1,  1, 0,   0,   1,  0,  1,
        1, -1, 0,   1,   0,  0,  1,
        
        -1,  1, 0,   1,   1,  0,  1,
        1,  1, 0,   1,   0,  1,  1,
        1, -1, 0,   1,   1,  1,  1
    };
    
    memcpy(vertextData, v, sizeof(v));
}

-(void)update:(NSTimeInterval)dt
{
    static NSTimeInterval __dt;
    
    __dt += (dt * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(__dt);
    
    GLKVector3 rot = { r, 0, 0 };
    self.rotation = rot;
}

@end

@interface TestFBOTexture() {
    PaintMeToTexture * _tobj;
}

@end
@implementation TestFBOTexture

-(id)init
{
    if( (self = [super init]))
    {
        _tobj = [PaintMeToTexture new];
        _tobj.fbo = (FBO *)self.texture;
    }
    
    return self;
}

-(void)createBuffer
{
    [self createBufferDataByType:@[@(sv_pos),@(sv_uv)] numVertices:6 numIndices:0];
}

-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData
{
    static float v[6*(3+2)] = {
    //   x   y  z    u    v
        -1, -1, 0,   0,   0,
        -1,  1, 0,   0,   1,
         1, -1, 0,   1,   0,
        
        -1,  1, 0,   0,   1,
         1,  1, 0,   1,   1,
         1, -1, 0,   1,   0
    };
    
    memcpy(vertextData, v, sizeof(v));
}

/*
-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    [_tobj render:w h:h];
}
 */
-(void)createTexture
{
    self.texture = [[FBO alloc] initWithWidth:200 height:200];
}

-(void)update:(NSTimeInterval)dt
{
    [_tobj update:dt];
    [_tobj renderToFBO];
    
    static NSTimeInterval __dt;
    
    __dt += (dt * 50.0f);
    
    GLfloat r = GLKMathDegreesToRadians(__dt);
    
    GLKVector3 rot = { 0, r, 0 };
    self.rotation = rot;
}

@end
