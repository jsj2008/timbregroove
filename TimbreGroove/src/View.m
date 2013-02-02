//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "View.h"
#import "Camera.h"

@implementation View

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self wireUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self wireUp];
    }
    return self;
}

-(void)wireUp
{
    _backColor = (GLKVector4){0.2, 0.2, 0.2, 1};
    
    _graph = [[Graph alloc] init];
    _graph.camera = [[Camera alloc] init];
    _graph.view = self;
    
}
- (id)firstNode
{
    return _graph.firstChild;
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
    [self setNeedsDisplay];
}


-(void)render
{
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    if( !_skipBoilerPlate )
    {
        [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
        
        glClearColor(_backColor.r,_backColor.g,_backColor.b,_backColor.a);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    
    [_graph render:w h:h];
}


@end
