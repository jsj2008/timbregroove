//
//  AssetToImage.h
//  TimbreGroove
//
//  Created by victor on 1/16/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AssetLoaderDelegate <NSObject>
-(void)thumbnailReady:(UIImage *)image userObj:(id)userObj;
@end

@interface AssetLoader : NSObject
@property (nonatomic,strong) NSURL * assetURL;
-(void)imageFromAsset;
@end

@interface AssetToImage : AssetLoader
@property (nonatomic,strong) id target;
@property (nonatomic,strong) NSString * key;
-(id)initWithURL:(NSURL *)assetURL
       andTarget:(id)target
          andKey:(NSString *)key;
@end


@interface AssetToThumbnail : AssetLoader
@property (nonatomic,strong) id<AssetLoaderDelegate> delegate;
@property (nonatomic,strong) id userObject;
-(id)initWithURL:(NSURL *)assetURL
       andDelegate:(id<AssetLoaderDelegate>)delegate
      andUserObj:(id)userObj;
@end