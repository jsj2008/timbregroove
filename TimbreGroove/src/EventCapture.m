//
//  TGCapture.m
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "EventCapture.h"
#import "Node3d.h"
#import "Shader.h"
#import "MeshBuffer.h"
#import "Interactive.h"
#import "FBO.h"
#import "Graph.h"
#import "GraphView.h"

#define _NTC(n) ((n&0xFF)/255.0f)
#define NTC(n) { _NTC((n>>16)), _NTC((n>>8)), _NTC(n), 1.0 }

typedef enum CapVarNames {
    cv_pos,
    cv_LAST_ATTR = cv_pos,
    cv_pvm,
    cv_color
} CapVarNames;

static const char * capVarNames[] = { "a_position", "u_pvm", "u_color" };

static Shader * getCaptureShader()
{
    return [Shader shaderFromPoolWithVertex:"capture"
                                andFragment:"capture"
                                andVarNames:capVarNames
                                andNumNames:3
                                andLastAttr:cv_LAST_ATTR
                                 andHeaders:nil];
}

@interface EventCapture() {
}
@end

typedef void (^CaptureRecurseBlock)(Node3d *);

@implementation EventCapture

+(id)getGraphViewTapChildElementOf:(Node3d *)graph inView:(UIView *)view atPt:(CGPoint)pt
{
    NSMutableDictionary * _objDict;
    __block unsigned int  _currentColor;
    GLuint                _posLocation;
    LogLevel              prevLogLevel;
    Shader *              shader;
	uint8_t               pix[4];
    
    CGSize sz = view.frame.size;
    FBO * fbo = [[FBO alloc] initWithWidth:sz.width height:sz.height];
    
    _currentColor    = 1;
    _objDict         = [NSMutableDictionary new];
    prevLogLevel     = TGSetLogLevel(LLShitsOnFire);
    shader           = getCaptureShader();
    TGSetLogLevel(prevLogLevel);
    
    _posLocation     = [shader location:cv_pos];
    
    [fbo bindToRender];
    glViewport(0, 0, fbo.width, fbo.height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [shader use];

    static CaptureRecurseBlock renderObj = nil;
    
    renderObj = ^(Node3d * child)
    {
        if( child.interactive )
        {
            GLKVector4 color = NTC(_currentColor);
            [shader writeToLocation:cv_color type:TG_VECTOR4 data:color.v];
            [shader writeToLocation:cv_pvm type:TG_MATRIX4 data:[child calcPVM].m];
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
