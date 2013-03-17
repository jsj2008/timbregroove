//
//  AssetToImage.m
//  TimbreGroove
//
//  Created by victor on 1/16/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "AssetLoader.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TGTypes.h"

@interface AssetLoader ()
- (void) loadData;
@end

@implementation AssetLoader

-(void)imageFromAsset
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        [self loadData];
    });
}

-(void)loadData
{
    TGLog(LLJustSayin, @"don't know how to load data. use AsstoTo* class");
    exit(1);
}
@end

@implementation AssetToImage

-(id)initWithURL:(NSURL *)assetURL andTarget:(id)target andKey:(id)key
{
    if( (self = [super init]) )
    {
        _target = target;
        _key = key;
        self.assetURL = assetURL;
        [self imageFromAsset];
    }
    return self;
}


- (void) loadData
{
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef imageRef = rep.fullResolutionImage;
        UIImage * image = [UIImage imageWithCGImage:imageRef];
        [_target setValue:image forKey:_key];
    };
    
	
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
		TGLog(LLJustSayin, @"NOT GOT ASSET");
		
        TGLog(LLJustSayin, @"Error '%@' getting asset from library", [myerror localizedDescription]);
    };
	
	// schedules the asset read
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
	
	[assetslibrary assetForURL:self.assetURL
				   resultBlock:resultblock
				  failureBlock:failureblock];
}

@end

@implementation AssetToThumbnail

-(id)initWithURL:(NSURL *)assetURL
     andDelegate:(id<AssetLoaderDelegate>)delegate
      andUserObj:(id)userObj
{
    _delegate = delegate;
    _userObject = userObj;
    self.assetURL = assetURL;
    return self;
}

- (void) loadData
{
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        CGImageRef imageRef = [myasset thumbnail];
        UIImage * image = [UIImage imageWithCGImage:imageRef];
        [_delegate thumbnailReady:image userObj:_userObject];
    };
    
	
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
		TGLog(LLJustSayin, @"NOT GOT ASSET");
		
        TGLog(LLJustSayin, @"Error '%@' getting asset from library", [myerror localizedDescription]);
    };
	
	// schedules the asset read
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
	
	[assetslibrary assetForURL:self.assetURL
				   resultBlock:resultblock
				  failureBlock:failureblock];
}


@end