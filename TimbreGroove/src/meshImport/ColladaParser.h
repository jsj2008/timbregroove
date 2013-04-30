//
//  ColladaParser.h
//  aotkXML
//
//  Created by victor on 3/29/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

@class MeshScene;

@interface ColladaParser : NSObject

+(MeshScene *)parse:(NSString *)fileName;

@end
