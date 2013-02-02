//
//  View.m
//  TimbreGroove
//
//  Created by victor on 12/22/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "View.h"
#import "Camera.h"
#import "Tween.h"
#import "Tweener.h"

@implementation View

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context;
{
    self = [super initWithFrame:frame context:context];
    if (self) {
        [self wireUp];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self wireUp];
    }
    return self;
}

-(void)wireUp
{
    _backcolor = (GLKVector4){0, 0, 0, 1};
    // THIS MUST BE LEFT AS DEFAULT!
    // (otherwise the context is not setup properly)
    //self.enableSetNeedsDisplay = NO;
    self.opaque = YES;
    
    _graph = [[Graph alloc] init];
    _graph.camera = [[Camera alloc] init];
    _graph.view = self;
    
}

-(id)createNode:(NSDictionary *)params
{
    Class klass = NSClassFromString(params[@"instanceClass"]);
    TG3dObject * node = [[klass alloc] init];
    node.view = self;
    [self.graph appendChild:node];
    [node setValuesForKeysWithDictionary:params];
    [node wireUp];
    return node;
}

- (id)firstNode
{
    return _graph.firstChild;
}

- (void)update:(NSTimeInterval)dt
{
    [_graph update:dt];
}


-(void)render // drawRect:(CGRect)rect
{
    NSUInteger w = self.drawableWidth;
    NSUInteger h = self.drawableHeight;
    [_graph.camera setPerspectiveForViewWidth:w andHeight:h];
    
    glClearColor(_backcolor.r,_backcolor.g,_backcolor.b,_backcolor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [_graph render:w h:h];
}


@end
