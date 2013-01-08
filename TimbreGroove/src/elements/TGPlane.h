//
//  TGPlane.h
//  
//
//  Created by victor on 12/15/12.
//
//

#import "TGGenericElement.h"

@interface TGPlane : TGGenericElement

-(TGPlane *)initWithColor:(GLKVector4)color;
-(TGPlane *)initWithFileName:(NSString *)fileName;
@end
