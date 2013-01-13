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

@interface GenericBase : TG3dObject {
@protected
    NSMutableArray * _buffers;
}

@property (nonatomic, readonly) bool hasTexture;

@property (nonatomic) GLKVector4 color;

@property (nonatomic) bool       lighting;
@property (nonatomic) GLKVector3 lightDir;
@property (nonatomic) GLKVector3 dirColor;
@property (nonatomic) GLKVector3 ambient;
// these are order dependant
//==============================================
// write your own version of this:
-(void)createBuffer;
// that calls this:
-(MeshBuffer *)createBufferDataByType:(NSArray *)svars
                          numVertices:(unsigned int)numVerticies
                           numIndices:(unsigned int)numIndices;

// or this
-(MeshBuffer *)createBufferDataByType:(NSArray *)svars
                          numVertices:(unsigned int)numVerticies
                           numIndices:(unsigned int)numIndices
                             uniforms:(NSDictionary*)uniformNames;

// which will call you back here:
-(void)getBufferData:(void *)vertextData
           indexData:(unsigned *)indexData;

-(void)configureLighting;

// default behavoirs of these should be fine:
-(void)createShader;
-(void)getBufferLocations;
-(void)getTextureLocations;
@end


/*
  Simple single texture shader support
*/
@interface Generic : GenericBase 
// NSString * or NSURL * to asset-library
@property (nonatomic, strong)   id        textureFileName;
@property (nonatomic, strong)   Texture * texture;
-(void)createTexture;
@end

/*
   Support for multiple textures.
   N.B. Generic shaders do NOT support this
*/
@interface GenericMultiTextures : Generic
-(void)createTextures;
-(void)addTextureObject:(Texture *)texture;
-(void)replaceTextures:(NSArray *)textures;

@end
