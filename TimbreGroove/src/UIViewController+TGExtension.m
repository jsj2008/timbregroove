//
//  UIViewController+TimbreGrooveUI.m
//  TimbreGroove
//
//  Created by victor on 1/25/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "UIViewController+TGExtension.h"

@implementation UIViewController (TGExtension)
-(UITapGestureRecognizer *)getMenuInvokerGesture;
{
    Class tgrClass = [UITapGestureRecognizer class];
    for( UIViewController * vc in self.childViewControllers )
    {
        NSArray * tgrs = [vc.view gestureRecognizers];
        for( UIGestureRecognizer * gr in tgrs )
        {
            if( [gr isKindOfClass:tgrClass] )
            {
                UITapGestureRecognizer * tgr = (UITapGestureRecognizer *)gr;
                if( tgr.numberOfTapsRequired == 2 )
                    return tgr;
            }
        }
    }
    
    return nil;
}

@end
