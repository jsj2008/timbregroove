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

@interface Generic : TG3dObject {
@protected
    NSMutableArray * _buffers;
}

@property (nonatomic, strong) Texture * texture;
@property (nonatomic) GLKVector4 color;

@property (nonatomic) bool       lighting;
@property (nonatomic) GLKVector3 lightDir;
@property (nonatomic) GLKVector3 dirColor;
@property (nonatomic) GLKVector3 ambient;


-(id)init;
-(id)initWithColor:(GLKVector4)color;
-(id)initWithTextureFile:(const char *)fileName;

// these are order dependant
//==============================================

// write your own version of this:
-(void)createBuffer;

// that calls this:
-(void)createBufferDataByType:(NSArray *)svars
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices;

// or this
-(void)createBufferDataByType:(NSArray *)svar
                  numVertices:(unsigned int)numVerticies
                   numIndices:(unsigned int)numIndices
                     uniforms:(NSDictionary*)uniformNames;

// which will call you back here:
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData;

// write your own version this:
-(void)createTexture;

// that calls this:
-(void)setTextureWithFile:(const char *)fileName;
// or these ( or property setter)
-(void)addTextureObject:(Texture *)texture;
-(void)replaceTextures:(NSArray *)textures;


-(void)configureLighting;

// default behavoirs of these should be fine:
-(void)createShader;
-(void)getBufferLocations;
-(void)getTextureLocations;
-(Texture *)getTextureObject:(int)index;
@end
