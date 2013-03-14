//
//  Global.h
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NO_GLOBAL_DECLS
extern NSString const * kGlobalScene;
extern NSString const * kGlobalRecording;
#endif


@class Scene;

@interface Global : NSObject
+(Global *)sharedInstance;

@property (nonatomic) bool recording;

// ugh
@property (nonatomic) CGSize graphViewSize;
@end
