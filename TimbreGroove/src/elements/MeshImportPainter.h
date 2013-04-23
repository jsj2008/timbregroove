//
//  GenericImport.h
//  TimbreGroove
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"

@interface MeshImportPainter : Node3d
// startup options read from config.plist
@property (nonatomic,strong) NSString * colladaFile;
@property (nonatomic) GLint             bufferDrawType;
@property (nonatomic) bool              runEmitter;
@property (nonatomic) bool              runAnimations;
@property (nonatomic) float             cameraZ;
@end

