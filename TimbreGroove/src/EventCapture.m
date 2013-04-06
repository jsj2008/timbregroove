//
//  TGCapture.m
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "EventCapture.h"
#import "TG3dObject.h"
#import "GenericShader.h"
#import "MeshBuffer.h"
#import "Interactive.h"
#import "FBO.h"
#import "Graph.h"
#import "GraphView.h"

#define _NTC(n) ((n&0xFF)/255.0f)
#define NTC(n) { _NTC((n>>16)), _NTC((n>>8)), _NTC(n), 1.0 }


@interface EventCapture() {
}
@end

typedef void (^CaptureRecurseBlock)(TG3dObject *);

@implementation EventCapture

+(id)getGraphViewTapChildElementOf:(TG3dObject *)graph inView:(UIView *)view atPt:(CGPoint)pt
{
    NSMutableDictionary * _objDict;
    __block unsigned int          _currentColor;
    GLuint                _posLocation;
    LogLevel              prevLogLevel;
    GenericShader *       shader;
	uint8_t               pix[4];
    
    CGSize sz = view.frame.size;
    FBO * fbo = [[FBO alloc] initWithWidth:sz.width height:sz.height];
    
    _currentColor    = 1;
    _objDict         = [NSMutableDictionary new];
    prevLogLevel     = TGSetLogLevel(LLShitsOnFire);
    shader           = [GenericShader shader];
    TGSetLogLevel(prevLogLevel);
    
    _posLocation     = [shader location:gv_pos];
    
    [fbo bindToRender];
    glViewport(0, 0, fbo.width, fbo.height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [shader use];

    static CaptureRecurseBlock renderObj = nil;
    
    renderObj = ^(TG3dObject * child)
    {
        if( child.interactive )
        {
            GLKVector4 color = NTC(_currentColor);
            [shader writeToLocation:gv_ucolor type:TG_VECTOR4 data:color.v];
            [shader writeToLocation:gv_pvm type:TG_MATRIX4 data:[child calcPVM].m];
            [child renderToCaptureAtBufferLocation:_posLocation];
            _objDict[@(_currentColor)] = child;
            ++_currentColor;
        }
        [child.children each:renderObj];
    };

    [graph.children each:renderObj];
    
    glReadPixels((GLuint)pt.x,
                 sz.height - (GLuint)pt.y,
                 1,
                 1,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 &pix);
    [fbo unbindFromRender];
/*
    glBindFramebuffer(GL_FRAMEBUFFER, orgFB);
*/    
    return _objDict[@((pix[0] << 16) | (pix[1] << 8) | pix[2])];
}
@end
