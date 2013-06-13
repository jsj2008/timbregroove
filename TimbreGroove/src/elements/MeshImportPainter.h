//
//  GenericImport.h
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"

@class MeshSceneArmatureNode;

@interface MeshImportPainter : Painter
// startup options read from config.plist
@property (nonatomic,strong) NSString * colladaFile;
@property (nonatomic) bool  runEmitter;
@property (nonatomic) float cameraZ;

-(void)queueAnimation:(NSString *)name;
-(void)addAnimation:(NSString *)name
         animations: (NSArray *)animations;

-(MeshSceneArmatureNode *)findJointWithName:(NSString *)name;
-(Node3d *)findMeshPainterWithName:(NSString *)name;
@end

