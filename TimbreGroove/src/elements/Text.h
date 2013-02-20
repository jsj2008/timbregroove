//
//  Text.h
//  TimbreGroove
//
//  Created by victor on 2/1/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GenericWithTexture.h"

@interface Text : GenericWithTexture
-(id)init;
-(id)initWithString:(NSString *)text;
@property (nonatomic,strong) NSString * text;
@end
