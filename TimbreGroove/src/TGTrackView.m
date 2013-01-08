//
//  TGTrackView.m
//  TG1
//
//  Created by victor on 12/5/12.
//
//

#import "TGTrackView.h"

@implementation TGTrackView
- (void) onResizeFromLayer
{
    CGRect rc = [Isgl3dDirector sharedInstance].windowRect;
    self.viewport = rc;
}
@end

