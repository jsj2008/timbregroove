//
//  NewScenePicker.m
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NewScenePicker.h"
#import "NewSceneCell.h"
#import "NewSceneViewController.h"
#import "Config.h"

@interface NewScenePicker () {
    NSDictionary * _items;
    NSArray * _keys;
}

@end

@implementation NewScenePicker

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self getItems];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if( self )
    {
        [self getItems];
    }
    return self;
}

- (void)getItems
{
    _items = [[Config sharedInstance] getScenes];
    _keys = [_items allKeys];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_keys count];
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellName = @"NewTrackCell";
    
    NewSceneCell * cell = (NewSceneCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellName
                                                                                    forIndexPath:indexPath];
    
    ConfigScene * item = _items[_keys[indexPath.item]];
    cell.cellImage.image = [UIImage imageNamed:item.icon];
    cell.cellLabel.text = item.displayName;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    //collectionView.indexPathsForSelectedItems;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ConfigScene * item = _items[_keys[indexPath.item]];
    [self.delegate NewScene:(NewSceneViewController*)self.parentViewController selection:item];
}

// "called when the user taps on an already-selected item in multi-select mode"
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


@end
