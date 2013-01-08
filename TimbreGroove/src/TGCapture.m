//
//  TGCapture.m
//  TimbreGroove
//
//  Created by victor on 12/18/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGCapture.h"
#import "TG3dObject.h"
#import "TGGenericShader.h"
#import "Camera.h"
#import "TGVertexBuffer.h"

#define _NTC(n) ((n&0xFF)/255.0f)
#define NTC(n) { _NTC((n>>16)), _NTC((n>>8)), _NTC(n), 1.0 }


@interface TGCapture() {
    NSMutableDictionary * _objDict;
    unsigned int          _currentColor;
    GLuint                _posLocation;
}
@end

@implementation TGCapture

-(id)childElementOf:(TG3dObject *)graph
          fromScreenPt:(CGPoint)pt
{
    TGGenericShader * shader;
	uint8_t pix[4];
    int backingHeight;

    _currentColor    = 1;
    _objDict         = [NSMutableDictionary new];
    shader           = [[TGGenericShader alloc] init];
    shader.opacity   = 1; // how is this not default? ugh.
    _posLocation     = [shader location:sv_pos];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [shader use];
    [self recursive_render:graph.children shader:shader];

	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	glReadPixels((GLuint)pt.x,
                 backingHeight - (GLuint)pt.y,
                 1,
                 1,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 &pix);
    
    return _objDict[@((pix[0] << 16) | (pix[1] << 8) | pix[2])];
}


-(void)recursive_render:(NSArray *)children shader:(TGGenericShader *)shader
{
    for( TG3dObject * child in children )
    {
        if( child.interactive )
        {
            GLKVector4 color = NTC(_currentColor);
            shader.color = color;
            shader.pvm = [child calcPVM];
            [child drawBufferToShader:shader atLocation:_posLocation];
            _objDict[@(_currentColor)] = child;
            ++_currentColor;
        }
        [self recursive_render:child.children shader:shader];
    }
}

@end
