//
//  HelloWorldView.m
//  TG1
//
//  Created by victor on 11/9/12.
//  Copyright 2012 Ass Over Teakettle. All rights reserved.
//

#import "tgHumpShader.h"
#import <UIKit/UIKit.h>
#import "TGElement.h"
#import "isgl3d.h"

static unsigned int s_regCount;

@interface TGPhoto : TGElement {
    float m_apex_rotation;
    BOOL m_touching;
    CGPoint m_prevTouchPt;
    tgHumpShader * m_shader;
    BOOL m_is_apex_rotating;
}
@property (nonatomic,strong) NSString * photoName;
@end

@implementation TGPhoto


- (void)start
{
    self.photoName = @"Alex.png";
    
    [super start];
  //  [self.view.camera setPosition:iv3(0, 3, 27)];
    [self genNodeWithPhoto:self.photoName];
}

- (void)genNodeWithPhoto:(NSString *)photoName
{
    NSString * key = [[NSString alloc] initWithFormat:@"hump%d",s_regCount++ ];

    m_shader = [tgHumpShader shaderWithKey:key];

    [m_shader setTextureFile:photoName];
    
    Isgl3dShaderMaterial * shaderMaterial1 = [Isgl3dShaderMaterial materialWithShader:m_shader];

    Isgl3dPlane *plane = [Isgl3dPlane meshWithGeometry: 5
                                                height: 5
                                                    nx: 15
                                                    ny: 15];
       
    [self.view.scene clearAll];
    
    self.node = [self.view.scene createNodeWithMesh: plane
                                 andMaterial: shaderMaterial1];
    self.node.doubleSided = YES;
    self.node.interactive = YES;
    
    UITapGestureRecognizer * tgr;
    tgr = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                  action: @selector(tap:)];
    [self.node addGestureRecognizer:tgr];
    
    
    UIPanGestureRecognizer * pgr;
    pgr = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                  action: @selector(drag:)];
    [self.node addGestureRecognizer:pgr];
    
    UIRotationGestureRecognizer * rgr;
    rgr = [[UIRotationGestureRecognizer alloc] initWithTarget: self
                                                       action: @selector(spin:)];
    [self.node addGestureRecognizer:rgr];
    
    self.animate = true;

}

-(void)tap:(UITapGestureRecognizer *)tgr
{
    m_is_apex_rotating = !m_is_apex_rotating;
}

-(void)spin:(UIRotationGestureRecognizer *)rgr
{
    float R = rgr.rotation;
    float * apex = m_shader.apex;
    apex[0] = 1.5f * sinf(R);
    apex[1] = 3.0f * cosf(R);
    m_shader.apex = apex;
}

-(void)drag:(UIPanGestureRecognizer *)pgr
{
//    NSLog(@"dragging %d",[pgr state]);
    
    if( [pgr state] == UIGestureRecognizerStateChanged )
    {
        CGPoint pt = [pgr locationInView:pgr.view];
        if( m_touching )
        {
#define Z_SPEED 0.4f
            
            float z = m_prevTouchPt.y > pt.y ? -Z_SPEED : Z_SPEED;
            if( fabs(m_shader.apex[2] + z) < 10.0f )
                [m_shader moveApexBy:0.0f y:0.0f z:z];
        }
        m_prevTouchPt = pt;
        m_touching = YES;
    }
    else
    {
        m_touching = NO;
    }
}

- (void) tick:(float)dt {
    if( self.node && m_is_apex_rotating )
    {
        m_apex_rotation += 0.4f;
        self.node.rotationY = m_apex_rotation;
        self.node.rotationX = -m_apex_rotation;
    }
}


@end


@interface TGPhotoFactory : NSObject
@end

@implementation TGPhotoFactory

-(void)invoke
{
    TGPhoto * st = [[TGPhoto alloc] init];
    [st start];
}

@end
