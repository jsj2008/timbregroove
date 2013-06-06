//
//  GenericImport.h
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"

@class MeshSceneArmatureNode;

@interface MeshImportPainter : Painter // Node3d
// startup options read from config.plist
@property (nonatomic,strong) NSString * colladaFile;

@property (nonatomic) bool  runEmitter;
@property (nonatomic) bool  runAnimations;
@property (nonatomic) float cameraZ;
@property (nonatomic) bool  autoRotate;

-(MeshSceneArmatureNode *)findJointWithName:(NSString *)name;
-(Node3d *)findMeshPainterWithName:(NSString *)name;
@end

