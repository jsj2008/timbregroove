//
//  TGGenericElement.h
//  TimbreGroove
//
//  Created by victor on 12/16/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TG3dObject.h"
#import "GenericShader.h"

@class MeshBuffer;
@class Texture;
@class Shader;
@class Light;

@interface GenericBase : TG3dObject {
@protected
    NSMutableArray * _buffers;
}

@property (nonatomic, readonly) bool hasTexture;


@property (nonatomic,strong) Light * light;

@property (nonatomic) GLKVector4 color;
@property (nonatomic) bool       useColor;

// derivations write these
-(void)createBuffer;
-(void)configureLighting;

// default behavoirs of these should be fine:
-(void)createShader;
-(void)getBufferLocations;
-(void)getTextureLocations;
-(void)addBuffer:(MeshBuffer *)buffer;
@end


/*
  Simple single texture shader support
*/
@interface Generic : GenericBase 
// NSString or filename or NSURL to asset-library
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
