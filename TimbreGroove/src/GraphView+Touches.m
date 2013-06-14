//
//  GraphView+Touches.m
//  TimbreGroove
//
//  Created by victor on 2/19/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphView.h"
#import "Global.h"
#import "Scene.h"
#import "Names.h"
#import "ObjectGestures.h"
#import "Camera.h"

@interface ViewTriggers : NSObject {
@public
    PointParamBlock    _triggerDirection;
    FloatParamBlock    _triggerPinch;
    PointParamBlock    _triggerTapPos;
    PointParamBlock    _triggerTap1;
    
    FloatParamBlock    _triggerPanX;
    FloatParamBlock    _triggerPanY;
    FloatParamBlock    _triggerPanX2Fing;
    FloatParamBlock    _triggerPanY2Fing;
    IntParamBlock      _triggerPanDone;
    
    Vector3ParamBlock  _triggerDrag1;
    PointParamBlock    _triggerDragPos;
    PointParamBlock    _triggerDblTap;
    FloatParamBlock    _triggerTweakX;
    FloatParamBlock    _triggerTweakY;
    
    NSDictionary * _targetedParams;
}
@end
@implementation ViewTriggers
-(void)triggersChanged:(Scene *)scene
{
    if( scene )
    {
        TriggerMap * tm = scene.triggers;
        _triggerDirection = [tm getPointTrigger:kTriggerDirection];
        _triggerPinch     = [tm getFloatTrigger:kTriggerPinch];
        _triggerTapPos    = [tm getPointTrigger:kTriggerTapPos];
        _triggerTap1      = [tm getPointTrigger:kTriggerTap1];
        
        _triggerPanX      = [tm getFloatTrigger:kTriggerPanX];
        _triggerPanY      = [tm getFloatTrigger:kTriggerPanY];
        _triggerPanX2Fing = [tm getFloatTrigger:kTriggerPanX2];
        _triggerPanY2Fing = [tm getFloatTrigger:kTriggerPanY2];
        _triggerPanDone   = [tm getIntTrigger:kTriggerPanDone];
        
        _triggerDblTap    = [tm getPointTrigger:kTriggerDblTap];
        
        // object movers/tweakers:
        _triggerDrag1     = [tm getVector3Trigger:kTriggerDrag1];
        _triggerDragPos   = [tm getPointTrigger:kTriggerDragPos];
        _triggerTweakX    = [tm getFloatTrigger:kTriggerTweakX];
        _triggerTweakY    = [tm getFloatTrigger:kTriggerTweakY];
    }
    else
    {
        _triggerDirection = nil;
        _triggerPinch     = nil;
        _triggerTapPos    = nil;
        _triggerTap1      = nil;
        _triggerPanX      = nil;
        _triggerPanY      = nil;
        _triggerPanX2Fing = nil;
        _triggerPanY2Fing = nil;
        _triggerPanDone   = nil;
        _triggerDrag1     = nil;
        _triggerDragPos   = nil;
        _triggerDblTap    = nil;
    }
}
@end

@implementation GraphView (Touches)

-(void)pushTriggers
{
    _currentTriggers = [ViewTriggers new];
    if( !_triggerStack )
        _triggerStack = [NSMutableArray new];
    [_triggerStack addObject:_currentTriggers];
}

-(void)popTriggers
{
    [_currentTriggers triggersChanged:nil];
    [_triggerStack removeLastObject];
    _currentTriggers = [_triggerStack lastObject];
}

-(void)triggersChanged:(Scene *)scene
{
    if( !_currentTriggers )
        [self pushTriggers];
    
    [_currentTriggers triggersChanged:scene];
    
    if( scene )
    {
        [self setupTouches];
    }
    else
    {
        [[self gestureRecognizers] each:^(UIGestureRecognizer * gr) {
            [self removeGestureRecognizer:gr];
        }];
    }
}

-(void)setTargetedParam:(NSDictionary *)targetedParams
{
    _currentTriggers->_targetedParams = targetedParams;
}

-(void)setupTouches
{
    UITapGestureRecognizer * dblTap = nil;
    
    if( _currentTriggers->_triggerDblTap )
    {
        dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dblTap:)];
        dblTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:dblTap];
    }
    
    if( _currentTriggers->_triggerTap1 || _currentTriggers->_triggerTapPos )
    {
        UITapGestureRecognizer * tap;
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        if( dblTap )
           [tap requireGestureRecognizerToFail:dblTap];
        [self addGestureRecognizer:tap];
    }
    
    if( _currentTriggers->_triggerPinch )
    {
        UIPinchGestureRecognizer * pnch;
        pnch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [self addGestureRecognizer:pnch];
    }

    MoveGesture * mg = nil;
    
    if( _currentTriggers->_triggerDrag1 || _currentTriggers->_triggerDragPos ||
        _currentTriggers->_triggerTweakX || _currentTriggers->_triggerTweakY)
    {
        mg = [[MoveGesture alloc] initWithTarget:self action:@selector(moveObject:)];
        [self addGestureRecognizer:mg];
    }
    
    if( _currentTriggers->_triggerPanX || _currentTriggers->_triggerPanY )
    {
        UIPanGestureRecognizer * pgr;
        pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
        pgr.maximumNumberOfTouches = 1;
        if( mg )
           [pgr requireGestureRecognizerToFail:mg];
        [self addGestureRecognizer:pgr];
    }

    if( _currentTriggers->_triggerPanX2Fing || _currentTriggers->_triggerPanY2Fing )
    {
        UIPanGestureRecognizer * pgr;
        pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning2:)];
        pgr.minimumNumberOfTouches = 2;
        [self addGestureRecognizer:pgr];
    }

    if( _currentTriggers->_triggerDirection )
    {
        UISwipeGestureRecognizerDirection dirs[4] = {
            UISwipeGestureRecognizerDirectionRight,
            UISwipeGestureRecognizerDirectionLeft,
            UISwipeGestureRecognizerDirectionUp,
            UISwipeGestureRecognizerDirectionDown
        };
        UISwipeGestureRecognizer * sgr;
        for( int i = 0; i < 4; i++ )
        {
            sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
            sgr.direction = dirs[i];
            [self addGestureRecognizer:sgr];
        }
    }
}

-(Parameter *)paramWrapperForObject:(Node3d *)targetObject
                          parameter:(Parameter *)parameterToWrap
{
    char nativeType = parameterToWrap.nativeType;

    targetObject.interactive = true;

    if( nativeType == TGC_VECTOR3 || nativeType == TGC_POINT )
    {
        Vector3ParamBlock orgBlock = [parameterToWrap getParamBlockOfType:TGC_VECTOR3];
        
        return [Parameter withBlock:[^(TGVector3 vec3) {
            if( _targetedObject == targetObject )
            {
                orgBlock(vec3);
            }
        } copy]];
    }
    else if( nativeType == _C_FLT )
    {
        FloatParamBlock orgBlock = [parameterToWrap getParamBlockOfType:_C_FLT];
        
        return [Parameter withBlock:[^(float f) {
            if( _targetedObject == targetObject )
            {
                orgBlock(f);
            }
        } copy]];
        
    }

    TGLog(LLShitsOnFire, @"Invalid param type for targeted parameter");
    exit(-1);
    return nil;
}


-(void)swipe:(UISwipeGestureRecognizer *)sgr
{
    if( sgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = (CGPoint){0,0};
        switch (sgr.direction)
        {
            case UISwipeGestureRecognizerDirectionLeft:
                pt.x = 1;
                break;
            case UISwipeGestureRecognizerDirectionRight:
                pt.x = -1;
                break;
            case UISwipeGestureRecognizerDirectionUp:
                pt.y = 1;
                break;
            case UISwipeGestureRecognizerDirectionDown:
                pt.y = -1;
                break;
        }
        _currentTriggers->_triggerDirection(pt);
    }
}

-(void)pinch:(UIPinchGestureRecognizer *) pnch
{
    if( pnch.state == UIGestureRecognizerStateChanged )
    {
        float scale = pnch.scale;
        if( scale < 0.0 )
        {
            scale = -scale;
        }
        else
        {
            if( scale < 2.0 )
                scale -= 1.0;
            else
                scale = 1.0;
        }
        _currentTriggers->_triggerPinch(scale);
    }
}

-(CGPoint)nativeToTG:(CGPoint)pt
{
    CGSize sz       = self.frame.size;
    pt.x /= sz.width;
    pt.y = 1.0 - (pt.y / sz.height); // up is up damn it
    pt.x = (pt.x - 0.5) * 2.0;
    pt.y = (pt.y - 0.5) * 2.0;
    return pt;
}

-(void)tap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt      = [tgr locationInView:self];
        
        if( _currentTriggers->_triggerTapPos )
            _currentTriggers->_triggerTapPos(pt);
        if( _currentTriggers->_triggerTap1 )
            _currentTriggers->_triggerTap1([self nativeToTG:pt]);        
    }
}

-(void)dblTap:(UITapGestureRecognizer *)tgr
{
    if( tgr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint pt = [tgr locationInView:self];
        _currentTriggers->_triggerDblTap([self nativeToTG:pt]);
    }
}

#define PT_DIFF(a,b) (CGPoint){a.x-b.x,a.y-b.y}

-(void)panning:(UIPanGestureRecognizer *)pgr
{
    [self _innerPanning:pgr
            panXTrigger:_currentTriggers->_triggerPanX
            panYTrigger:_currentTriggers->_triggerPanY];    
}

-(void)panning2:(UIPanGestureRecognizer *)pgr
{
    [self _innerPanning:pgr
            panXTrigger:_currentTriggers->_triggerPanX2Fing
            panYTrigger:_currentTriggers->_triggerPanY2Fing];
}

-(void)_innerPanning:(UIPanGestureRecognizer *)pgr
         panXTrigger:(FloatParamBlock)panXTrigger
         panYTrigger:(FloatParamBlock)panYTrigger
{
    if( pgr.state == UIGestureRecognizerStateBegan )
    {
        _panLast = [pgr locationInView:self];
        _panPivot = _panLast;
        TGLog(LLGestureStuff, @"Panning starting: {%.1f, %.1f}",_panPivot.x, _panPivot.y);
    }    
    else if( pgr.state == UIGestureRecognizerStateChanged )
    {
        CGPoint pt  = [pgr locationInView:self];

        bool bSkipPan = false;
        CGPoint diff = PT_DIFF(pt,_panLast);
        if( !_xPanning && !_yPanning )
        {
            _xPanning = fabsf(diff.x) > fabsf(diff.y);
            _yPanning = !_xPanning;
            TGLog(LLGestureStuff, @"Panning axis chosen: x:%d y:%d", _xPanning, _yPanning);
        }
        
        float currentPos = 0;
        float testPos   = 0;
        if( _xPanning )
        {
            currentPos = pt.x;
            testPos   = _panLast.x;
        }
        else // yPanning
        {
            currentPos = pt.y;
            testPos   = _panLast.y;
        }
        
        if( currentPos == testPos )
        {
            bSkipPan = true;
        }
        else if( _panDir )
        {
            if( _panDir == 1 )
            {
                if( currentPos < testPos )
                {
                    _panDir = -1;
                    _panPivot = pt;
                    TGLog(LLGestureStuff, @"Direction changed to %d (pivot: {%.1f, %.1f}",_panDir,pt.x,pt.y);
                    bSkipPan = true;
                }
            }
            else // panDir == -1
            {
                if( currentPos > testPos )
                {
                    _panDir = 1;
                    _panPivot = pt;
                    TGLog(LLGestureStuff, @"Direction changed to %d (pivot: {%.1f, %.1f}",_panDir,pt.x,pt.y);
                    bSkipPan = true;
                }
            }
            
        }
        else // panDir uninitialized
        {
            _panDir = currentPos > testPos ? 1 : -1;
            TGLog(LLGestureStuff, @"Panning direction chosen: %d",_panDir);
        }
        
        if( !bSkipPan )
        {
            CGSize sz = self.frame.size;
            
            if( _xPanning && panXTrigger )
            {
                float fdiff = (_panPivot.x - pt.x) / sz.width;
                TGLog(LLGestureStuff, @"Sending X pan: %f (dir:%d pos:{%.1f,%.1f}) ) ",fdiff,_panDir,pt.x,pt.y);
                panXTrigger(fdiff);
            }
            else if( _yPanning && panYTrigger )
            {
                float fdiff = (_panPivot.y - pt.y) / sz.width;
                TGLog(LLGestureStuff, @"Sending Y pan: %f (dir:%d pos:{%.1f,%.1f}) ) ",fdiff,_panDir,pt.x,pt.y);
                panYTrigger(fdiff);
            }
        }
    
        _panLast = pt;

    }
    else if( pgr.state == UIGestureRecognizerStateEnded || pgr.state == UIGestureRecognizerStateCancelled )
    {
        TGLog(LLGestureStuff, @"Panning over");
        _xPanning = _yPanning = 0;
        _panDir = 0;
        if( _currentTriggers->_triggerPanDone )
            _currentTriggers->_triggerPanDone(1);
    }
}

-(TGVector3)unprojectPoint:(CGPoint)local_pt forObject:(Node3d*)object
{
    GLKVector3 window_coord = GLKVector3Make(local_pt.x,local_pt.y, 0.0f);
    bool result;
    CGSize sz = self.frame.size;
    int viewport[4] = { 0, 0, (int)sz.width, (int)sz.height };
    GLKMatrix4 modelView = GLKMatrix4Identity; // um, is this supposed to LookAt?
    GLKVector3 near_pt = GLKMathUnproject(window_coord,
                                          modelView,
                                          [object.camera projectionMatrix],
                                          &viewport[0],
                                          &result);
    window_coord = GLKVector3Make(local_pt.x,local_pt.y, 1.0f);
    GLKVector3 far_pt = GLKMathUnproject(window_coord,
                                          modelView,
                                          [object.camera projectionMatrix],
                                          &viewport[0],
                                          &result);

    //need to get z=0 from
    //assumes near and far are on opposite sides of z=0
    float z_magnitude = fabs(far_pt.z-near_pt.z);
    float near_pt_factor = fabs(near_pt.z)/z_magnitude;
    float far_pt_factor = fabs(far_pt.z)/z_magnitude;
    GLKVector3 vec3 = GLKVector3Add( GLKVector3MultiplyScalar(near_pt, far_pt_factor),
                                        GLKVector3MultiplyScalar(far_pt, near_pt_factor));
    vec3.y = -vec3.y; // er...
    return *(TGVector3 *)&vec3;
}

-(void)moveObject:(MoveGesture *)mg
{
    if( mg.state == UIGestureRecognizerStateBegan )
    {
        _targetedObject = mg.targetedObject;
    }
    else if( mg.state == UIGestureRecognizerStateChanged )
    {
        CGPoint pt  = [mg locationInView:self];
        if( _currentTriggers->_triggerDrag1 )
        {
            TGVector3 vec3 = [self unprojectPoint:pt forObject:_targetedObject];
            TGLog(LLGestureStuff, @"Sending object drag pt: %@", NSStringFromGLKVector3(TG3(vec3)));
            _currentTriggers->_triggerDrag1(vec3);
        }
        if( _currentTriggers->_triggerDragPos )
        {
            TGLog(LLGestureStuff, @"Sending native drag pt: {%.4f, %.4f}",pt.x, pt.y);
            _currentTriggers->_triggerDragPos(pt);
        }
        if( _currentTriggers->_triggerTweakX || _currentTriggers->_triggerTweakY )
        {
            [self _innerPanning:mg
                    panXTrigger:_currentTriggers->_triggerTweakX
                    panYTrigger:_currentTriggers->_triggerTweakY ];
        }
    }
    else if( mg.state == UIGestureRecognizerStateEnded )
    {
        _targetedObject = nil;
    }
    
}
@end
