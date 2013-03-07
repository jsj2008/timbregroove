//
//  GraphCollection.m
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphCollection.h"
#import "Graph.h"
#import "Config.h"

@interface GraphCollection () {
    NSMutableArray * _graphs;
}

@end

@implementation GraphCollection

-(id)createGraphBasedOnConfig:(ConfigGraphicElement *)config withViewSize:(CGSize)viewSize;
{
    Graph * graph = [Graph new];
    [graph loadFromConfig:config andViewSize:viewSize];
    if( !_graphs )
        _graphs = [NSMutableArray new];
    [_graphs addObject:graph];
    
    return graph;
}


-(id)graphAtIndex:(unsigned int)i
{
    return _graphs[i];
}

-(unsigned int)count
{
    return [_graphs count];
}

-(void)removeGraphAtIndex:(unsigned int)i
{
    Graph * graph = _graphs[i];
    [_graphs removeObjectAtIndex:i];
    [graph cleanChildren];
    graph = nil;
}


@end
