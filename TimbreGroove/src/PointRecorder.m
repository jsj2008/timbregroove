//
//  PointRecorder.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PointRecorder.h"

@interface PointPlayer () {
    CGPoint *        _points;
    NSTimeInterval * _durations;
    unsigned int     _currentPoint;
    unsigned int     _numPoints;
}
@end

@implementation PointPlayer

-(id)init
{
    NSLog(@"only a recorder can make a player");
    exit(-1);
}

-(id)initWithPoints:(CGPoint*)points
       andDurations:(NSTimeInterval *)durations
          numPoints:(unsigned int)numPts
{
    self = [super init];
    if( self )
    {
        _points    = (CGPoint *)malloc(sizeof(CGPoint)*numPts);
        _durations = (NSTimeInterval *)malloc(sizeof(NSTimeInterval)*numPts);
        
        memcpy(_points, points, sizeof(CGPoint)*numPts);
        memcpy(_durations, durations, sizeof(NSTimeInterval)*numPts);
        
        _numPoints = numPts;
        [self reset];
    }
    return self;
}

-(void)dealloc
{
    free(_points);
    free(_durations);
}

-(void)reset
{
    _currentPoint = 0;
}

-(GLKVector3)next
{
    if( _currentPoint == _numPoints )
        _currentPoint = 0;
    CGPoint pt = _points[_currentPoint++];
    return (GLKVector3){ pt.x, pt.y, 0 };
}

-(NSTimeInterval)duration
{
    unsigned int loc = _currentPoint == _numPoints ? 0 : _currentPoint;
    return _durations[loc];
}


@end
@interface PointRecorder () {
    CGPoint * _points;
    NSTimeInterval * _durations;
    unsigned int _capacity;
    unsigned int _numPoints;
    unsigned int _currentPoint;
    NSTimeInterval _startTime;
    NSTimeInterval _lastAdd;
}
@end

@implementation PointRecorder

-(id)init
{
    self = [super init];
    if( self )
    {
        [self reset];
    }
    return self;
}

-(void)dealloc
{
    free(_points);
    free(_durations);
}

-(GLKVector3)lastPt
{
    CGPoint pt = _points[_currentPoint - 1];
    return (GLKVector3){ pt.x, pt.y, 0 };
}

-(void)reset
{
    if( _points )
        free(_points);
    if( _durations )
        free(_durations);
    _startTime = 0.0;
    _lastAdd = 0.0;
    _currentPoint = 0;
    _numPoints = 0;
    _capacity = 100;
    _points = (CGPoint *)malloc(sizeof(CGPoint)*_capacity);
    _durations = (NSTimeInterval *)malloc(sizeof(NSTimeInterval)*_capacity);
    _points[0] = (CGPoint){0,0};
    _durations[0] = 0;
}

-(void)add:(CGPoint)pt
{
    if( !_startTime )
        _startTime = CACurrentMediaTime();
    
    if( _numPoints == _capacity )
    {
        _capacity += 100;
        CGPoint * newbuf = (CGPoint *)malloc(sizeof(CGPoint)*_capacity);
        memcpy(newbuf, _points, sizeof(CGPoint)*_numPoints);
        free(_points);
        _points = newbuf;
        NSTimeInterval * newtbuf = (NSTimeInterval*)malloc(sizeof(NSTimeInterval)*_capacity);
        memcpy(newtbuf, _durations, sizeof(NSTimeInterval)*_numPoints);
        free(_durations);
        _durations = newtbuf;
    }
    CFTimeInterval now = CACurrentMediaTime();
    _points[_numPoints] = pt;
    _durations[_numPoints] = _lastAdd ? now - _lastAdd : 0;
    _lastAdd = now;
    ++_numPoints;
}

-(PointPlayer *)makePlayer
{
    return [[PointPlayer alloc] initWithPoints:_points andDurations:_durations numPoints:_numPoints];
}
@end
