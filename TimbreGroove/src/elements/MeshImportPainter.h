//
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"
#import "MeshSceneAnimation.h"

#ifndef SKIP_MESH_IMPORT_DECLS
extern NSString * const kImportedAnimation;
#endif

@class MeshSceneArmatureNode;

@interface MeshImportPainter : Painter<JointDictionary>

@property (nonatomic,strong) AnimationDictionary * animations;

// startup options read from config.plist
@property (nonatomic,strong) NSString * colladaFile;
@property (nonatomic) bool  runEmitter;
@property (nonatomic) float cameraZ;
@end

