//
//  GraphCollection.m
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "GraphCollection.h"
#import "Graph.h"

@interface GraphCollection () {
    NSMutableArray * _graphs;
}

@end

@implementation GraphCollection

-(id)createGraphBasedOnNodeType:(NSDictionary *)params withViewSize:(CGSize)viewSize
{
    Graph * graph = [Graph new];
    Class klass = NSClassFromString(params[@"instanceClass"]);
    TG3dObject * node = [[klass alloc] init];
    [graph appendChild:node];
    [node setValuesForKeysWithDictionary:params];
    [node wireUpWithViewSize:viewSize];
    
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


@end
