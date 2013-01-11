//
//  TGGenericElement.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"

@class MeshBuffer;
@class Texture;
@class Shader;

@interface TGGeneric3dObject : TG3dObject

@property (nonatomic) GLKVector4 color;
@property (nonatomic) float      opacity;

-(id)init;
-(id)initWithColor:(GLKVector4)color;
-(id)initWithFile:(const char *)fileName;

// For derived classes (w/some default impl.)
// these are order dependant
//==============================================
// create buffer

// write your own version of this:
-(void)createBuffer;

// that calls this:
-(void)createBufferDataByType:(NSArray *)svars
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices;

// which will call you back here:
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData;

// write your own version this:
-(void)createTexture;

// that calls this:
-(void)addTexture:(const char *)fileName;

-(void)configureLighting;

// default behavoirs of these should be fine:
-(Shader *)createShader;
-(void)getBufferLocations;
-(void)getTextureLocations;

@end