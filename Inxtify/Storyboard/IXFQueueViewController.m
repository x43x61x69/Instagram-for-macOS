//
//  IXFQueueViewController.m
//  Inxtify
//
//  Copyright (C) 2016  Zhi-Wei Cai. (@x43x61x69)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//

#import "IXFQueueViewController.h"

@interface IXFQueueViewController ()

@end

@implementation IXFQueueViewController

- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    
    _dataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).dataSource;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pauseQueue:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    _collectionView.backgroundColors = @[[NSColor clearColor]];
    
    [_pauseSwitch bind:@"checked"
              toObject:[NSUserDefaults standardUserDefaults]
           withKeyPath:kQueuePausedKey
               options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
    _pauseSwitch.tintColor = NSColorFromRGB(0xff5c53);
    _pauseSwitch.disabledBorderColor = [NSColor controlShadowColor];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self adjustData];
}

#pragma mark - NSCollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
     itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger itemIndex = indexPath.item;
    IXFQueueItem *queueObject = [_dataSource objectAtIndex:itemIndex];
    IXFQueueCollectionViewItem *item = [collectionView makeItemWithIdentifier:IXF_QUEUE_COLLECTION_VIEW_ITEM_IDENTIFIER
                                                                 forIndexPath:indexPath];
    item.representedObject = queueObject;
    item.delgate = self;
    if (queueObject.user != nil) {
        IXFUser *user = [_api userWithName:queueObject.user];
        item.profileImageView.toolTip = [NSString stringWithFormat:@"@%@", queueObject.user];
        if (user.avatar == nil) {
            item.profileImageView.image = user.avatar;
            
        } else if (user.avatarURL != nil) {
//            user.avatar = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:user.avatarURL]];
//            item.profileImageView.image = user.avatar;
            [user avatar:^(NSImage *image) {
                item.profileImageView.image = image;
            }];
        }
    }
    item.previewImageView.image = queueObject.image;
    item.captionLabel.stringValue = queueObject.caption;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    item.dateLabel.stringValue = [dateFormatter stringFromDate:queueObject.date];
    
    if ([[queueObject.date earlierDate:[NSDate date]] isEqualToDate:queueObject.date]) {
        item.dateLabel.textColor = NSColorFromRGB(0x5facec);
    }
    
    item.typeImage.hidden = (queueObject.mode != IXFQueueModeVideo);
    
    switch (queueObject.status) {
        case IXFQueueStatusFailed:
            if (queueObject.retries < queueObject.maxAttempts) {
                item.statusImageView.image = [NSImage imageNamed:@"issueTemplate"];
                NSUInteger remains = queueObject.maxAttempts - queueObject.retries;
                item.statusImageView.toolTip = [NSString stringWithFormat:@"%ld attempt%@ remain%@.",
                                                remains,
                                                (remains > 1) ? @"s" : @"",
                                                (remains > 1) ? @"" : @"s"];
            } else {
                item.statusImageView.image = [NSImage imageNamed:@"errorTemplate"];
                item.statusImageView.toolTip = [NSString stringWithFormat:@"Failed after %ld attempt%@.",
                                                queueObject.maxAttempts,
                                                (queueObject.maxAttempts > 1) ? @"s" : @""];
            }
            item.dateLabel.stringValue = @"Failed";
            if (queueObject.error.length > 0) {
                item.dateLabel.toolTip = queueObject.error;
            } else {
                item.dateLabel.toolTip = @"Unknown Error";
            }
            item.dateLabel.textColor = NSColorFromRGB(0xe06c75);
            break;
        case IXFQueueStatusDone:
            if (queueObject.URL &&
                queueObject.mediaID.length > 0) {
                item.statusImageView.image = [NSImage imageNamed:@"webTemplate"];
                item.statusImageView.toolTip = @"Done";
                item.dateLabel.toolTip = [queueObject.URL absoluteString];
                item.dateLabel.textColor = NSColorFromRGB(0x73c990);
            } else {
                // Deleted
                item.previewImageView.alphaValue = .3f;
                item.statusImageView.image = [NSImage imageNamed:@"deleteTemplate"];
                item.statusImageView.toolTip = @"Deleted";
                item.dateLabel.toolTip = @"Item was removed from Instagram.";
                item.dateLabel.textColor = NSColorFromRGB(0x4068da);
            }
            break;
        case IXFQueueStatusInProgress:
            item.statusImageView.image = [NSImage imageNamed:@"inProgressTemplate"];
            item.statusImageView.toolTip = @"In Progress...";
            if (queueObject.retries && queueObject.maxAttempts) {
                item.dateLabel.stringValue = [NSString stringWithFormat:@"%@ (%ld/%ld)",
                                              item.dateLabel.stringValue,
                                              queueObject.retries,
                                              queueObject.maxAttempts];
            }
            item.dateLabel.textColor = NSColorFromRGB(0xe2c08d);
            break;
        default:
            item.statusImageView.image = nil;
            item.dateLabel.textColor = [NSColor disabledControlTextColor];
            break;
    }
    
    if (queueObject.ends != nil) {
        item.dateLabel.stringValue = [dateFormatter stringFromDate:queueObject.ends];
    }
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSIndexSet *indexes = [collectionView selectionIndexes];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        _removeButton.enabled = YES;
        if (((IXFQueueItem *)_dataSource[idx]).status == IXFQueueStatusInProgress) {
            *stop = YES;
            _removeButton.enabled = NO;
        }
    }];
    
    LOGD(@"%@", indexes);
}

#pragma mark - IXFQueueCollectionViewItemDelegate

- (void)itemShouldBeRemovedAtIndex:(NSUInteger)index
{
    if (((IXFQueueItem *)_dataSource[index]).status != IXFQueueStatusInProgress) {
        [_dataSource removeObjectAtIndex:index];
        [self adjustData];
    }
}

- (void)itemShouldBeEditAtIndex:(NSUInteger)index remove:(BOOL)shouldBeRemoved
{
    IXFQueueItem *item = [_dataSource objectAtIndex:index];
    if (item != nil) {
        if (item.status == IXFQueueStatusInProgress) {
            LOGD(@"In progress!");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kQueueEditNotificationKey
                                                                object:self
                                                              userInfo:@{kQueueEditObjectKey : item}];
        });
        if (shouldBeRemoved == YES) {
            [_dataSource removeObjectAtIndex:index];
            [self adjustData];
        }
    }
}

- (void)itemShouldBeRemotelyDeleteAtIndex:(NSUInteger)index
{
    IXFQueueItem *item = ((IXFQueueItem *)_dataSource[index]);
    if (item.mediaID.length != 0) {
        item.date = [NSDate date];
        if (item.maxAttempts > 0) {
            item.retries = item.maxAttempts - 1;
        } else {
            item.retries = 0;
        }
        item.status = IXFQueueStatusAwaiting;
        ((IXFQueueItem *)_dataSource[index]).status = IXFQueueStatusAwaiting;
        [self adjustData];
    }
}

#pragma mark - Methods

- (void)adjustData
{
    if (_dataSource.count > 0) {
        _collectionViewContainer.hidden = NO;
    } else {
        _collectionViewContainer.hidden = YES;
    }
    _removeButton.hidden = _collectionViewContainer.hidden;
    _clearButton.hidden = _collectionViewContainer.hidden;
    _warningLabel.hidden = _collectionViewContainer.hidden;
    _pauseSwitch.toolTip = ([[NSUserDefaults standardUserDefaults] boolForKey:kQueuePausedKey] == YES) ? @"Paused" : @"Pause";
    
    _collectioViewLabel.hidden = !_collectionViewContainer.hidden;
    _collectionViewImage.hidden = !_collectionViewContainer.hidden;
    [_collectionView reloadData];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_dataSource]
                 forKey:kDataSourceKey];
    [defaults synchronize];
    
    LOGD(@"%ld", [_dataSource count]);
}

- (IBAction)editAndRemoveItem:(id)sender
{
    [self editItem:sender];
    [self removeItem:sender];
}

- (IBAction)editItem:(id)sender
{
    NSUInteger itemIndex = [[_collectionView selectionIndexes] firstIndex];
    IXFQueueItem *item = [_dataSource objectAtIndex:itemIndex];
    if (item != nil) {
        if (item.status == IXFQueueStatusInProgress) {
            LOGD(@"In progress!");
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kQueueEditNotificationKey
                                                                object:self
                                                              userInfo:@{kQueueEditObjectKey : item}];
        });
    }
}

- (IBAction)removeItem:(id)sender
{
    NSIndexSet *indexes = [_collectionView selectionIndexes];
    [_dataSource removeObjectsAtIndexes:indexes];
    [self adjustData];
}

- (IBAction)clearFinishedItem:(id)sender
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < _dataSource.count; i++) {
        IXFQueueItem *item = _dataSource[i];
        if (item.status == IXFQueueStatusDone) {
            [indexes addIndex:i];
        }
    }
    [self clear:indexes];
}

- (IBAction)clearFinishedAndFailedItem:(id)sender
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < _dataSource.count; i++) {
        IXFQueueItem *item = _dataSource[i];
        if (item.status == IXFQueueStatusDone ||
            item.status == IXFQueueStatusFailed) {
            [indexes addIndex:i];
        }
    }
    [self clear:indexes];
}

- (void)clear:(NSMutableIndexSet *)indexes
{
    [_dataSource removeObjectsAtIndexes:indexes];
    [self adjustData];
}

- (void)pauseQueue:(NSNotification *)notification {
    // Get the user defaults
    NSUserDefaults *defaults = (NSUserDefaults *)[notification object];
    _pauseSwitch.toolTip = ([defaults objectForKey:kQueuePausedKey]) ? @"Paused" : @"Pause";
}

@end
