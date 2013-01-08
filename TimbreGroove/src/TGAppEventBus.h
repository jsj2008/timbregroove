//
//  TGAppEventBus.h
//  TG1
//
//  Created by victor on 12/9/12.
//
//

#import <Foundation/Foundation.h>

@interface TGAppEventBus : NSObject
+(id)listen:(NSString *)eventName klass:(Class)klass selName:(NSString *)selName;
+(void)invoke:(NSString *)eventName source:(id)source userInfo:(NSDictionary*)userInfo;

+(void)remove:(id)nid;
-(void)removeObserver:(id)nid;
-(void)removeAllObservers;
@end
