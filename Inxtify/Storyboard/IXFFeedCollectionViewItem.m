//
//  IXFFeedCollectionViewItem.m
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


#import "IXFFeedCollectionViewItem.h"
#import "IXFFeedViewController.h"

@interface IXFFeedCollectionViewItem ()

@end

@implementation IXFFeedCollectionViewItem


- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    
    _preview.wantsLayer = YES;
    _likes.wantsLayer = YES;
    _likes.layer.backgroundColor = [NSColor clearColor].CGColor;
    _comments.wantsLayer = YES;
    _comments.layer.backgroundColor = [NSColor clearColor].CGColor;
    _likeButton.wantsLayer = YES;
    _likeButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    _commentsImage.wantsLayer = YES;
    _commentsImage.layer.backgroundColor = [NSColor clearColor].CGColor;
    _openWebButton.wantsLayer = YES;
    _openWebButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    _deleteButton.wantsLayer = YES;
    _deleteButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    _previewButton.wantsLayer = YES;
    _previewButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    _commentsButton.wantsLayer = YES;
    _commentsButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    
    NSImage *i = [_likeButton.image copy];
    i.template = NO;
    _likeButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_commentsImage.image copy];
    i.template = NO;
    _commentsImage.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_openWebButton.image copy];
    i.template = NO;
    _openWebButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_deleteButton.image copy];
    i.template = NO;
    _deleteButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_previewButton.image copy];
    i.template = NO;
    _previewButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_commentsButton.image copy];
    i.template = NO;
    _commentsButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self adjustLikeStatus];
}

- (void)adjustLikeStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _likeButton.image = [_likeButton.image imageTintedWithColor: (_item.hasLiked) ? NSColorFromRGB(0xed4956) : [NSColor whiteColor]];
        _likeButton.toolTip = (_item.hasLiked) ? @"Liked" : @"Like";
        _likes.stringValue = [NSString stringWithFormat:@"%ld%@",
                              _item.likeCount > 1000 ? _item.likeCount / 1000 : _item.likeCount,
                              _item.likeCount > 1000 ? @"k+" : @""];
    });
}

+ (NSSet *)keyPathsForValuesAffectingTextColor
{
    return [NSSet setWithObjects:@"selected", nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self updateBackgroundColorForSelectionState:self.isSelected];
    
}

- (void)updateBackgroundColorForSelectionState:(BOOL)flag
{
    if (flag) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = .5f;
            self.view.animator.layer.backgroundColor = [NSColor alternateSelectedControlColor].CGColor;
            _preview.animator.alphaValue = .2f;
            _likeButton.animator.hidden = NO;
            _commentsImage.animator.hidden = NO;
            _likes.animator.hidden = NO;
            _comments.animator.hidden = NO;
            _commentsButton.animator.hidden = NO;
            if (_item.code.length) {
                _openWebButton.animator.hidden = NO;
            }
            if ([_api.user.name isEqualToString:_item.user.name] &&
                _item.mediaID.length) {
                _deleteButton.animator.hidden = NO;
            }
            if (_item.imageURL.length) {
                _previewButton.animator.hidden = NO;
            }
        } completionHandler:nil];
    } else {
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 1.f;
            self.view.animator.layer.backgroundColor = [NSColor clearColor].CGColor;
            _preview.animator.alphaValue = 1.f;
            _likeButton.animator.hidden = YES;
            _commentsImage.animator.hidden = YES;
            _likes.animator.hidden = YES;
            _comments.animator.hidden = YES;
            _commentsButton.animator.hidden = YES;
            _openWebButton.animator.hidden = YES;
            _deleteButton.animator.hidden = YES;
            _previewButton.animator.hidden = YES;
        } completionHandler:nil];
    }
}

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    [self updateBackgroundColorForSelectionState:flag];
}

- (IBAction)openURL:(id)sender
{
    if (_item.code.length) {
        [[NSWorkspace sharedWorkspace] openURL:[_item URL]];
    }
}

- (IBAction)viewInage:(id)sender
{
    if (_item.imageURL != nil &&
        _item.width != 0 &&
        _item.height != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayImageHUDNotificationKey
                                                                object:self
                                                              userInfo:@{kImageHUDObjectKey : _item}];
        });
    }
}

- (IBAction)like:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_item.mediaID) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((NSButton *)sender).enabled = NO;
            });
            if (_item.hasLiked == NO) {
                _item.hasLiked = [_api like:_item option:YES];
                if (_item.hasLiked == YES) {
                    _item.likeCount++;
                }
            } else {
                _item.hasLiked = ![_api like:_item option:NO];
                if (_item.hasLiked == NO) {
                    _item.likeCount--;
                }
            }
            [self adjustLikeStatus];
            dispatch_async(dispatch_get_main_queue(), ^{
                ((NSButton *)sender).enabled = YES;
            });
        }
    });
}

- (IBAction)comments:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_item.mediaID) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((NSButton *)sender).enabled = NO;
            });
            
            NSArray *comments = [_api comments:_item];
            
            if (comments != nil &&
                _item != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayCommentEditorNotificationKey
                                                                    object:self
                                                                  userInfo:@{kFeedObjectKey     : _item,
                                                                             kCommentsObjectKey : comments}];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                ((NSButton *)sender).enabled = YES;
            });
        }
    });
}

- (IBAction)deleteMedia:(id)sender
{
    if ([_api.user.name isEqualToString:_item.user.name] &&
        _item.mediaID.length) {
        IXFQueueItem *queueItem = [[IXFQueueItem alloc] initWithUser:[_api userWithName:_item.user.name]
                                                               image:_item.image
                                                             caption:_item.caption
                                                                date:_item.date location:_item.location
                                                                mode:IXFQueueImage];
        queueItem.mediaID = _item.mediaID;
        queueItem.UUID = [NSString stringWithFormat:@"%@%@", kFeedItemDeleteObjectKey, _item.mediaID];
        switch (_item.type) {
            case 1: // Photo
                break;
            case 2: // Video
                queueItem.mode = IXFQueueVideo;
                break;
            default:
                break;
        }
        [_api deleteMedia:queueItem];
    }
}

@end
