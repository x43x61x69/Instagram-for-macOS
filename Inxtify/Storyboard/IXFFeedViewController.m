//
//  IXFFeedViewController.m
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


#import "IXFFeedViewController.h"
//#import <IXFFoundation/IXFFoundation.h>
#import "IXFFeedCollectionViewItem.h"

@interface IXFFeedViewController () {
    CGFloat maxY;
}

@end

@implementation IXFFeedViewController

- (void)loadView
{
    [super loadView];
    
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    _feedDataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).feedDataSource;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshFeed:)
                                                 name:kFeedDidChangeNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:kFeedShouldReloadNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(failed:)
                                                 name:kFeedDidFailedToLoadNotificationKey
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColors = @[[NSColor clearColor]];
    
    _containerView.wantsLayer = YES;
    
    NSView *contentView = [_containerView contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundDidChange:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:contentView];
    
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    if (_feedDataSource.count == 0 &&
        _maxID == nil) {
        _containerView.hidden = YES;
        [_progressIndicator startAnimation:self];
        [_api feed:_api.user];
    } else {
        [self updateLabel];
        [_collectionView reloadData];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return _feedDataSource.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
     itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger itemIndex = indexPath.item;
    IXFFeedItem *queueObject = [_feedDataSource objectAtIndex:itemIndex];
    IXFFeedCollectionViewItem *item = [collectionView makeItemWithIdentifier:IXFFeedCollectionViewItemIdentifier
                                                                 forIndexPath:indexPath];
    item.representedObject = queueObject;
    item.item = item.representedObject;
    
    item.likes.stringValue = [NSString stringWithFormat:@"%ld%@",
                              queueObject.likeCount > 1000 ? queueObject.likeCount / 1000 : queueObject.likeCount,
                              queueObject.likeCount > 1000 ? @"k+" : @""];
    NSArray<IXFUser *> *likers = [item.item.likers copy];
    NSUInteger likersCoumt = [likers count];
    if (likersCoumt > 0) {
        item.likes.toolTip = @"by ";
        for (NSUInteger i = 0; i < likersCoumt; i++) {
            item.likes.toolTip = [item.likes.toolTip stringByAppendingString:[likers objectAtIndex:i].name];
            if (i != likersCoumt-1) {
                item.likes.toolTip = [item.likes.toolTip stringByAppendingString:@", "];
            }
        }
    }
    
    item.comments.stringValue = [NSString stringWithFormat:@"%ld%@",
                                 queueObject.commentsCount > 1000 ? queueObject.commentsCount / 1000 : queueObject.commentsCount,
                                 queueObject.commentsCount > 1000 ? @"k+" : @""];
    
    NSArray<IXFCommentItem *> *comments = [item.item.comments copy];
    NSUInteger commentsCoumt = [comments count];
    if (commentsCoumt > 0) {
        item.comments.toolTip = [NSString stringWithFormat:@"@%@, \"%@\"",
                                 [comments firstObject].user.name,
                                 [comments firstObject].text];
    }
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    item.preview.toolTip = [dateFormatter stringFromDate:queueObject.date];

//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        if ((item.item.previewImage == nil)) {
            item.item.previewImage = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:queueObject.previewImageURL]];
//            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = .0f;
                    item.preview.animator.alphaValue = .0f;
                } completionHandler:^{
                    item.preview.animator.image = item.item.previewImage;
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = 1.f;
                        item.preview.animator.alphaValue = 1.f;
                    } completionHandler:nil];
                }];
//            });
        } else {
//            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                item.preview.image = item.item.previewImage;
//            });
        }
//    });
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSIndexSet *indexes = [collectionView selectionIndexes];
    
    LOGD(@"%@", indexes);
}

#pragma mark - Methods

- (void)boundDidChange:(NSNotification *)notification
{
    if (_maxID.length &&
        ![_maxID isEqualToString:_lastMaxID]) {
        CGFloat offset = _collectionView.visibleRect.origin.y;
        
        if (maxY >= offset) {
            return;
        }
        
        CGFloat height = [_containerView.documentView frame].size.height - _collectionView.visibleRect.size.height * 1.5; // preloading when over 50%
        
        if (offset >= height) {
            maxY = offset;
            _lastMaxID = _maxID;
            [_progressIndicator startAnimation:self];
            [_api feed:_api.user maxID:_maxID];
        }
    }
}

- (void)failed:(NSUserNotification *)notification
{
    [self updateLabel];
}

- (void)refreshFeed:(NSUserNotification *)notification
{
    NSDictionary *feed = [[notification userInfo] objectForKey:kFeedObjectKey];
    
    LOGD(@"feed: %@", feed);
    
    if (feed != nil) {
        NSUInteger count = [[feed objectForKey:@"num_results"] integerValue];
        
        LOGD(@"num_results: %ld", count);
        
        if (count > 0) {
            NSArray *items = [feed objectForKey:@"items"];
            if ([items count] > 0) {
                for (NSDictionary *item in items) {
                    
                    if ([item objectForKey:@"image_versions2"] == nil ||
                        [[item objectForKey:@"image_versions2"] isKindOfClass:[NSNull class]]) {
                        continue;
                    }
                    
                    NSArray *candidates = [[item objectForKey:@"image_versions2"] objectForKey:@"candidates"];
                    if ([candidates count] > 0) {
                        
                        NSDictionary *candidate;
                        NSDictionary *previewCandidate;
                        CGFloat width = 0;
                        CGFloat pWidth = CGFLOAT_MAX;
                        for (NSDictionary *c in candidates) {
                            CGFloat cWidth = [[c objectForKey:@"width"] floatValue];
                            CGFloat cHeight = [[c objectForKey:@"height"] floatValue];
                            if (cWidth > width) {
                                width = cWidth;
                                candidate = c;
                            }
                            if (cWidth == cHeight &&
                                cWidth < pWidth) {
                                pWidth = cWidth;
                                previewCandidate = c;
                            }
                        }
                        
                        IXFFeedItem *itemObj = [[IXFFeedItem alloc] init];
                        
                        itemObj.imageURL        = [candidate objectForKey:@"url"];
                        itemObj.previewImageURL = [previewCandidate objectForKey:@"url"];
                        itemObj.mediaID         = [item objectForKey:@"id"];
                        
                        if ([itemObj.imageURL length] &&
                            [itemObj.previewImageURL length] &&
                            [itemObj.mediaID length]) {
                            
                            itemObj.code        = [item objectForKey:@"code"];
                            itemObj.identifier  = [[item objectForKey:@"pk"] integerValue];
                            itemObj.type        = [[item objectForKey:@"media_type"] integerValue];
                            itemObj.date        = [NSDate dateWithTimeIntervalSince1970:[[item objectForKey:@"taken_at"] integerValue]];
                            itemObj.width       = [[item objectForKey:@"original_width"] floatValue];
                            itemObj.height      = [[item objectForKey:@"original_height"] floatValue];
                            
                            
                            if ([item objectForKey:@"caption"] != nil &&
                                ![[item objectForKey:@"caption"] isKindOfClass:[NSNull class]]) {
                                itemObj.caption     = [[item objectForKey:@"caption"] objectForKey:@"text"];
                            }
                            
                            itemObj.likeCount   = [[item objectForKey:@"like_count"] integerValue];
                            itemObj.commentsCount   = [[item objectForKey:@"comment_count"] integerValue];
                            itemObj.captionIsEdited = [[item objectForKey:@"caption_is_edited"] boolValue];
                            itemObj.hasLiked    = [[item objectForKey:@"has_liked"] boolValue];
                            
                            NSArray *likers = [item objectForKey:@"likers"];
                            for (NSDictionary *liker in likers) {
                                IXFUser *likerObj = [_api userWithDictionary:liker];
                                if (likerObj != nil) {
                                    [itemObj.likers addObject:likerObj];
                                }
                            }
                            
                            // Comments
                            NSArray *comments = [item objectForKey:@"comments"];
                            for (NSDictionary *comment in comments) {
                                IXFCommentItem *commentObj = [_api commentWithDictionary:comment];
                                if (commentObj != nil) {
                                    [itemObj.comments addObject:commentObj];
                                }
                                NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:kDataSourceSortKey
                                                                                     ascending:NO];
                                [itemObj.comments sortUsingDescriptors:@[desc]];
                            }
                            
                            // User
                            NSDictionary *user = [item objectForKey:@"user"];
                            if (user != nil &&
                                ![user isKindOfClass:[NSNull class]]) {
                                itemObj.user = [_api userWithDictionary:user];
                            }
                            
                            // Location
                            NSDictionary *location  = [item objectForKey:@"location"];
                            if (location != nil &&
                                ![location isKindOfClass:[NSNull class]]) {
                                itemObj.location            = [[IXFLocation alloc] init];
                                itemObj.location.name       = [location objectForKey:@"name"];
                                itemObj.location.address    = [location objectForKey:@"address"];
                                itemObj.location.latitude   = [location objectForKey:@"lat"];
                                itemObj.location.longitude  = [location objectForKey:@"lng"];
                                itemObj.location.externalID = [[location objectForKey:@"facebook_places_id"] integerValue];
                                itemObj.location.externalIDSource = [location objectForKey:@"external_source"];
                            }
                            
                            [_feedDataSource addObject:itemObj];
                        }
                    }
                }
            }
            
            _maxID = [feed objectForKey:@"next_max_id"];
            BOOL moreAvailable  = [[feed objectForKey:@"moreAvailable"] boolValue];
            LOGD(@"moreAvailable: %hhd -> %@", moreAvailable, _maxID);
            if (moreAvailable &&
                _maxID.length) {
                [_progressIndicator startAnimation:self];
                [_api feed:_api.user maxID:_maxID];
            }
        }
    }
    
    [self reloadData];
    
    LOGD(@"_feedDataSource: %ld", _feedDataSource.count);
    
}

- (void)reloadData
{
    NSUInteger items = _feedDataSource.count;
    
    if (items) {
        NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:kDataSourceSortKey
                                                             ascending:NO];
        [_feedDataSource sortUsingDescriptors:@[desc]];
        [_collectionView reloadData];
    }
    
    [self updateLabel];
    
    [_delgate setMaxID:_maxID lastMaxID:_lastMaxID];
}

- (void)updateLabel
{
    [_progressIndicator stopAnimation:self];
    
    NSUInteger items = _feedDataSource.count;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .2f;
        _label.animator.alphaValue = .0f;
    } completionHandler:^{
        _containerView.animator.hidden = (items == 0);
        NSString *number;
        if (items > 0) {
            number = [NSString stringWithFormat:@"%ld", items];
        } else {
            number = @"No";
        }
        _label.animator.stringValue = [NSString stringWithFormat:@"%@ %@.%@",
                                       number,
                                       items == 1 ? @"entry": @"entries",
                                       _maxID.length ? @" Scroll down to load more." : @""];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = .2f;
            _label.animator.alphaValue = 1.f;
        } completionHandler:nil];
    }];
}

- (IBAction)reload:(id)sender
{
    _maxID = nil;
    _lastMaxID = nil;
    [_feedDataSource removeAllObjects];
    [self reloadData];
    [_progressIndicator startAnimation:self];
    [_api feed:_api.user];
}

@end
