//
//  UIControl+TGViewExtensions.m
//  TimbreGroove
//
//  Created by victor on 1/7/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "UIView+TGViewExtensions.h"
#import "objc/runtime.h"

static NSString * __tgve_member_name;

@implementation UIView (TGViewExtensions)

-(NSString *)memberName
{
    return (NSString *)objc_getAssociatedObject(self,&__tgve_member_name);
}

-(void)setMemberName:(NSString *)memberName
{
    objc_setAssociatedObject(self, &__tgve_member_name, memberName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
