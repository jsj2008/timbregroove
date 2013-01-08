//
//  TGView.m
//  TG1
//
//  Created by victor on 12/8/12.
//
//
#import "TG.h"
#import "TGView.h"

@implementation TGView

- (id) init
{
	if ((self = [super init])) {
        
		self.scene = [Isgl3dScene3D scene];

		CGSize viewSize = self.viewport.size;
        
		self.camera = [Isgl3dCamera cameraWithWidth:viewSize.width
                                          andHeight:viewSize.height];
		
        [self.camera setPerspectiveProjection:45
                                         near:1
                                          far:10000
                                  orientation:self.deviceViewOrientation];
        
		[self.scene addChild:self.camera];
	}
	
    return self;
}

- (void)animateProp: (const char *)prop
          targetVal: (CGFloat)targetVal
               hide:(bool) hideOnComplete;
{
    NSMutableDictionary * params = d(@{   TWEEN_DURATION: @0.5f,
                                     TWEEN_TRANSITION: TWEEN_FUNC_EASEOUTSINE,
                                     @(prop): @(targetVal)
                                     });
    
    if( hideOnComplete )
    {
        [params setObject:@"hideScene" forKey:TWEEN_ON_COMPLETE_SELECTOR];
        [params setObject:self         forKey:TWEEN_ON_COMPLETE_TARGET];
    }
    
    [Isgl3dTweener addTween:self withParameters:params];
}

- (void)hideScene
{
    self.scene.isVisible = false;
    [self deactivate];
}

- (void)showScene
{
    self.scene.isVisible = true;
    [self activate];
}

- (void) setViewport:(CGRect)viewport {
	[super setViewport:viewport];
    
	if (self.camera) {
        
        CGSize viewSize = viewport.size;
        self.camera.width = viewSize.width;
        self.camera.height = viewSize.height;
        
		[self.camera setPerspectiveProjection:self.camera.fov
                                         near:self.camera.near
                                          far:self.camera.far
                                  orientation:self.deviceViewOrientation];
		//Isgl3dLog(Info, @"TrackView : setting camera with perspective projection. Viewport size = %@", NSStringFromCGSize(viewport.size));
	}
}

#pragma mark - Animatable dimensions

- (void)setX:(CGFloat)x
{
    CGRect rc = self.viewport;
    rc.origin.x = x;
    self.viewport = rc;
}

- (CGFloat)x
{
    return self.viewport.origin.x;
}

- (void)setY:(CGFloat)y
{
    CGRect rc = self.viewport;
    rc.origin.y = y;
    self.viewport = rc;
}

- (CGFloat)y
{
    return self.viewport.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect rc = self.viewport;
    rc.size.width = width;
    self.viewport = rc;
}

- (CGFloat)width
{
    return self.viewport.size.width;
}

- (void)setHeight:(CGFloat)height
{
    CGRect rc = self.viewport;
    rc.size.height = height;
    self.viewport = rc;
}

- (CGFloat)height
{
    return self.viewport.size.height;
}

@end
