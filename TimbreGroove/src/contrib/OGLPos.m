//
//  OGLPos.m
//  TimbreGroove
//
//  Created by victor on 12/17/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "OGLPos.h"
#import "gluProject.h"

static GLfloat __modelview[16];
static GLfloat __projection[16];
static GLint   __viewport[4];

@implementation OGLPos

+ (void)prepare
{
    // I am doing this once at the beginning when I set the perspective view
    glGetFloatv( GL_MODELVIEW_MATRIX, __modelview );
    glGetFloatv( GL_PROJECTION_MATRIX, __projection );
    glGetIntegerv( GL_VIEWPORT, __viewport );
}

+ (void)prepare:(float*)model projection:(float *)projection view:(int *)view
{
    memcpy(__modelview, model, sizeof(__modelview));
    memcpy(__projection, projection, sizeof(__projection));
    memcpy(__viewport, view, sizeof(__viewport));
}

+(CGPoint) getOGLPos:(CGPoint)winPos
{
    
    //opengl 0,0 is at the bottom not at the top
    winPos.y = (float)__viewport[3] - winPos.y;
    // float winZ;
    //we cannot do the following in openGL ES due to tile rendering
    // glReadPixels( (int)winPos.x, (int)winPos.y, 1, 1, GL_DEPTH_COMPONENT24_OES, GL_FLOAT, &winZ );
    
    float cX, cY, cZ, fX, fY, fZ;
    //gives us camera position (near plan)
    gluUnProject( winPos.x, winPos.y, 0, __modelview, __projection, __viewport, &cX, &cY, &cZ);
    //far plane
    gluUnProject( winPos.x, winPos.y, 1, __modelview, __projection, __viewport, &fX, &fY, &fZ);
    
    //We could use some vector3d class, but this will do fine for now
    //ray
    fX -= cX;
    fY -= cY;
    fZ -= cZ;
    float rayLength = sqrtf(cX*cX + cY*cY + cZ*cZ);
    //normalize
    fX /= rayLength;
    fY /= rayLength;
    fZ /= rayLength;
    
    //T = [planeNormal.(pointOnPlane - rayOrigin)]/planeNormal.rayDirection;
    //pointInPlane = rayOrigin + (rayDirection * T);
    
    float dot1, dot2;
    
    float pointInPlaneX = 0;
    float pointInPlaneY = 0;
    float pointInPlaneZ = 0;
    float planeNormalX = 0;
    float planeNormalY = 0;
    float planeNormalZ = -1;
    
    pointInPlaneX -= cX;
    pointInPlaneY -= cY;
    pointInPlaneZ -= cZ;
    
    dot1 = (planeNormalX * pointInPlaneX) + (planeNormalY * pointInPlaneY) + (planeNormalZ * pointInPlaneZ);
    dot2 = (planeNormalX * fX) + (planeNormalY * fY) + (planeNormalZ * fZ);
    
    float t = dot1/dot2;
    
    fX *= t;
    fY *= t;
    //we don't need the z coordinate in my case
    
    return CGPointMake(fX + cX, fY + cY);
}
@end
