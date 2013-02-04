//
//  NewTrackPicker.m
//  TimbreGroove
//
//  Created by victor on 2/3/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "NewTrackPicker.h"
#import "NewTrackCell.h"
#import "NewTrackContainerVC.h"

@interface NewTrackPicker () {
    NSDictionary * _items;
    NSArray * _keys;
}

@end

@implementation NewTrackPicker

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
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                          ofType:@"plist" ];

	_items = [[NSDictionary dictionaryWithContentsOfFile:menuPath] objectForKey:@"new_element"];
    
    _keys = [_items
             keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2)
             {
                 return [(NSNumber *)obj1[@"order"] compare:obj2[@"order"]];
             }];
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
    
    NewTrackCell * cell = (NewTrackCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellName forIndexPath:indexPath];
    
    NSDictionary * item = _items[_keys[indexPath.item]];
    cell.cellImage.image = [UIImage imageNamed:item[@"icon"]];
    cell.cellLabel.text = ((NSDictionary*)item[@"userData"])[@"instanceClass"];
    
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
   // [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    NSLog(@"selected: %d", indexPath.item);
    NSDictionary * item = _items[_keys[indexPath.item]];
    [self.delegate NewTrack:(NewTrackContainerVC*)self.parentViewController selection:item];
}

// "called when the user taps on an already-selected item in multi-select mode"
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


@end
