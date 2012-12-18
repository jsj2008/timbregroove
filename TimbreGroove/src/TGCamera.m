//
//  TGCamera.m
//  TimbreGroove
//
//  Created by victor on 12/13/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "TGCamera.h"

@interface TGCamera() {

    float      _near;
    float      _far;
    float      _frustumAngle;
    GLKMatrix4 _projection;
}

@end

@implementation TGCamera

- (TGCamera *)init
{
    if( (self = [super init]) )
    {
        _near          = CAMERA_DEFAULT_NEAR;
        _far           = CAMERA_DEFAULT_FAR;
        _frustumAngle  = CAMERA_DEFAULT_frustum_ANGLE;
        
        _position = GLKVector3Make( 0.0f, 0.0f, CAMERA_DEFAULT_Z );
        _rotation = GLKVector3Make( 0.0f, 0.0f, 0.0f );
    }
    
    return self;
}

-(void)setPerspective: (float)near
             far:(float)far
   frustumAngle:(float)degrees
       viewWidth:(float)viewWidth
      viewHeight:(float)viewHeight
{
    _near = near;
    _far  = far;
    _frustumAngle = degrees;
    
    float aspect = fabsf(viewWidth/viewHeight);
    float rads = GLKMathDegreesToRadians(degrees);
    _projection = GLKMatrix4MakePerspective(rads, aspect, 0.1f, 100.0f);
    
}

-(void)setPerspectiveForViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    [self setPerspective:_near
                far:_far
      frustumAngle:_frustumAngle
          viewWidth:viewWidth
         viewHeight:viewHeight];
}

-(GLKMatrix4)projectionMatrix
{
    GLKMatrix4 mx = GLKMatrix4MakeTranslation( _position.x, _position.y, _position.z );
    
    if( _rotation.x )
        mx = GLKMatrix4Rotate(mx, _rotation.x, 1.0f, 0.0f, 0.0f);
    if( _rotation.y )
        mx = GLKMatrix4Rotate(mx, _rotation.y, 0.0f, 1.0f, 0.0f);
    if( _rotation.z )
        mx = GLKMatrix4Rotate(mx, _rotation.z, 0.0f, 0.0f, 1.0f);

    mx = GLKMatrix4Multiply(_projection, mx);
    
    return mx;
 
}

-(void)setZ:(float)z
{
    _position.z = z;
}
@end
