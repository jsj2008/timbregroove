//
//  SimpleImage.h
//  TimbreGroove
//
//  Created by victor on 12/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Painter.h"

@class Texture;

@interface TexturePainter : Painter
-(id)initWithText:(NSString *)text;
-(id)initWithFileName:(NSString *)imageFileName;
@property (nonatomic,readonly) float gridWidth;
@property (nonatomic,strong) Texture * texture;
@end
