//
//  MeshSceneBuffer.h
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshBuffer.h"
#import "MeshScene.h"

@interface MeshSceneBuffer : MeshBuffer

-(id)initWithGeometryBuffer:(MeshGeometryBuffer *)bufferInfo
     andIndexIntoShaderName:(int)iisn;

@end
