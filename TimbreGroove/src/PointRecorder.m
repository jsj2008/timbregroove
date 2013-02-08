//
//  PointRecorder.m
//  TimbreGroove
//
//  Created by victor on 2/5/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "PointRecorder.h"

typedef struct RecordPoint {
    CGPoint         pt;
    NSTimeInterval  ts;
} RecordPoint;

@interface PointPlayer () {
    RecordPoint *    _points;
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

-(id)initWithPoints:(RecordPoint*)points
          numPoints:(unsigned int)numPts
{
    self = [super init];
    if( self )
    {
        size_t sz = sizeof(RecordPoint)*numPts;
        _points    = (RecordPoint *)malloc(sz);
        memcpy(_points, points, sz);
        _numPoints = numPts;
        [self reset];
    }
    return self;
}

-(void)dealloc
{
    free(_points);
}

-(void)reset
{
    _currentPoint = 0;
}

-(GLKVector3)next
{
    if( _currentPoint == _numPoints )
        _currentPoint = 0;
    CGPoint pt = _points[_currentPoint++].pt;
    return (GLKVector3){ pt.x, pt.y, 0 };
}

-(NSTimeInterval)duration
{
    unsigned int loc = _currentPoint == _numPoints ? 0 : _currentPoint;
    return _points[loc].ts;
}


@end
@interface PointRecorder () {
    RecordPoint * _points;
    unsigned int _capacity;
    unsigned int _numPoints;
    unsigned int _currentPoint;
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
}

-(unsigned int)count
{
    return _numPoints;
}

-(GLKVector3)lastPt
{
    CGPoint pt = _points[_currentPoint - 1].pt;
    return (GLKVector3){ pt.x, pt.y, 0 };
}

-(void)reset
{
    if( _points )
        free(_points);
    _lastAdd = 0.0;
    _currentPoint = 0;
    _numPoints = 0;
    _capacity = 100;
    size_t sz = sizeof(RecordPoint)*_capacity;
    _points = (RecordPoint *)malloc(sz);
    memset(_points, 0, sz);
}

-(void)add:(CGPoint)pt
{
    if( _numPoints == _capacity )
    {
        _capacity += 100;
        size_t sz = sizeof(RecordPoint)*_capacity;
        RecordPoint * newbuf = (RecordPoint *)malloc(sz);
        memset(newbuf, 0, sz);
        memcpy(newbuf, _points, sizeof(RecordPoint)*_numPoints);
        free(_points);
        _points = newbuf;
    }
    CFTimeInterval now = CACurrentMediaTime();
    _points[_numPoints].pt = pt;
    _points[_numPoints].ts = _lastAdd ? now - _lastAdd : 0;
    _lastAdd = now;
    ++_numPoints;
}

-(PointPlayer *)makePlayer
{
    return [[PointPlayer alloc] initWithPoints:_points numPoints:_numPoints];
}
@end
