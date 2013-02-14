//
//  Mixer+Diag.h
//  TimbreGroove
//
//  Created by victor on 2/9/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer.h"

@interface Mixer (Diag)
-(void)dumpParameters:(AudioUnit)au forUnit:(NSString *)name;
- (void) printASBD: (AudioStreamBasicDescription) asbd;
-(void)dumpGraph;
-(void)dumpEQ;

@end
