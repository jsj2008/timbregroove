//
//  TGPlane.h
//  
//
//  Created by victor on 12/15/12.
//
//

#import "TGGenericElement.h"

@interface Plane : TGGenericElement

-(Plane *)initWithColor:(GLKVector4)color;
-(Plane *)initWithFileName:(const char *)fileName;
@end
