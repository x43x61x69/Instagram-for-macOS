//
//  IXFCommentsViewController.m
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

#import "IXFCommentsViewController.h"
#import "IXFCommentCollectionViewItem.h"
#import "IXFFeedCollectionViewItem.h"
#import "IXFFeedViewController.h"
#import "IXFCommentUserDetailViewController.h"

@interface IXFCommentsViewController ()

@end

@implementation IXFCommentsViewController

- (void)loadView
{
    [super loadView];
    
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userChanged:)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dupeCheck:)
                                                 name:kShouldDisplayCommentEditorNotificationKey
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.window.hidesOnDeactivate = NO;
    self.view.window.movableByWindowBackground = YES;
    [self.view.window setLevel:NSPopUpMenuWindowLevel];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColors = @[[NSColor clearColor]];
    
    _containerView.wantsLayer = YES;
    
    _progressIndicator.wantsLayer = YES;
    _progressIndicator.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    _commenterAvatar.wantsLayer = YES;
    _commenterAvatar.layer.masksToBounds = YES;
    _commenterAvatar.layer.backgroundColor = [[NSColor gridColor] colorWithAlphaComponent:.3f].CGColor;
    _commenterAvatar.layer.borderColor = [[NSColor gridColor] colorWithAlphaComponent:.5f].CGColor;
    _commenterAvatar.layer.borderWidth = 1.f;
    _commenterAvatar.layer.cornerRadius = _commenterAvatar.bounds.size.width / 2.f;
    _commenterAvatar.layer.needsDisplayOnBoundsChange = YES;
    
    _mediaCaption.delegate = self;
    _message.delegate = self;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self userChanged:nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    _mediaPreview.image = _feedItem.previewImage;
    _mediaUserLabel.stringValue = _feedItem.user.name;
    
    if (_feedItem.caption != nil) {
        _mediaCaption.stringValue = _feedItem.caption;
        _mediaCaption.toolTip = _feedItem.caption;
    }
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    _mediaLocationLabel.toolTip = [dateFormatter stringFromDate:_feedItem.date];
    
    if (_feedItem.location.name != nil) {
        _mediaLocationLabel.stringValue = _feedItem.location.name;
    } else {
        if (_mediaLocationLabel.toolTip) {
            _mediaLocationLabel.stringValue = _mediaLocationLabel.toolTip;
        }
    }
}

#pragma mark - NSControlTextEditingDelegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSuggestionsDisabledKey]) {
        return;
    }
    
    if (_isAutocompleting == NO  &&
        !_backspaceKey) {
        _isAutocompleting = YES;
        [[[notification userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
        _isAutocompleting = NO;
    } else if (_backspaceKey == YES) {
        _backspaceKey = NO;
    }
}

- (NSArray<NSString *> *)control:(NSControl *)control
                        textView:(NSTextView *)textView
                     completions:(NSArray<NSString *> *)words
             forPartialWordRange:(NSRange)charRange
             indexOfSelectedItem:(NSInteger *)index
{
//    LOGD(@"forPartialWordRange: %@, %ld, %ld, %ld", [textView.string substringWithRange:charRange], charRange.location, charRange.length, *index);
    
    if (charRange.location == 0 ||
        charRange.length < 1) {
        return nil;
    }
    NSArray *suggestions;
    NSString *keyword = [textView.string substringWithRange:NSMakeRange(charRange.location-1, 1)];
    if ([keyword isEqualToString:@"#"]) {
        keyword = [textView.string substringWithRange:charRange];
        suggestions = [_api hashtag:keyword];
    } else if ([keyword isEqualToString:@"@"]) {
        keyword = [textView.string substringWithRange:charRange];
        suggestions = [_api users:keyword];
    }
    return suggestions;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(deleteBackward:)) {
        _backspaceKey = YES;
    }
    return NO;
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return _commentsDataSource.count;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView
                  layout:(NSCollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger itemIndex = indexPath.item;
    IXFCommentItem *commentObj = [_commentsDataSource objectAtIndex:itemIndex];
    
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100.f, 17.f)];
    label.font = [NSFont systemFontOfSize:13.f weight:NSFontWeightMedium];
    label.stringValue = commentObj.user.name;
    [label sizeToFit];
    CGFloat nameWidth = label.frame.size.width;
    CGFloat width = collectionView.frame.size.width - 80.f - nameWidth;
    
    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, width, 17.f)];
    textView.font = [NSFont systemFontOfSize:13.f];
    textView.string = commentObj.text;
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
    NSRange lineRange;
    for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++){
        (void)[layoutManager lineFragmentRectForGlyphAtIndex:index
                                              effectiveRange:&lineRange];
        index = NSMaxRange(lineRange);
    }
    
    return CGSizeMake(collectionView.frame.size.width,
                      numberOfLines * 17.f + 30.f);
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
     itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger itemIndex = indexPath.item;
    IXFCommentItem *commentObj = [_commentsDataSource objectAtIndex:itemIndex];
    IXFCommentCollectionViewItem *item = [collectionView makeItemWithIdentifier:IXFCommentCollectionViewItemIdentifier
                                                                   forIndexPath:indexPath];
    item.representedObject = commentObj;
    item.delgate = self;
    
    item.isOwnItem = (_api.user.identifier == _feedItem.user.identifier);
    item.usernameLabel.stringValue = commentObj.user.name;
    item.messageLabel.stringValue = commentObj.text;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    item.messageLabel.toolTip = [dateFormatter stringFromDate:commentObj.date];
    
    item.profileImageView.image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:commentObj.user.avatarURL]];
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSIndexSet *indexes = [collectionView selectionIndexes];
    
    LOGD(@"%@", indexes);
    
    if ([indexes count] == 1) {
        
        IXFUser *userForDetail;
        IXFCommentItem *commentObj = [_commentsDataSource objectAtIndex:[[indexPaths allObjects] firstObject].item];
        if (commentObj != nil &&
            commentObj.user.identifier > 0 &&
            commentObj.user.identifier != _api.user.identifier &&
            (userForDetail = [_api userInfoWithIdentifier:commentObj.user.identifier]) != nil) {
            
            [self performSegueWithIdentifier:kUserDetailSegueKey sender:userForDetail];
        }
    }
    
    NSMutableString *mentions = [NSMutableString string];
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        IXFCommentItem *commentObj = [_commentsDataSource objectAtIndex:indexPath.item];
        if (commentObj != nil &&
            [commentObj.user.name isEqualToString:_api.user.name] == NO) {
            NSString *user = [NSString stringWithFormat:@"@%@ ", commentObj.user.name];
            if ([_message.stringValue containsString:user] == NO) {
                [mentions appendString:user];
            }
        }
    }
    _message.stringValue = [NSString stringWithFormat:@"%@%@%@",
                            _message.stringValue,
                            _message.stringValue.length == 0 ? @"" : @" ",
                            mentions];
}

#pragma mark - Segue

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kUserDetailSegueKey]) {
        if ([sender isKindOfClass:[IXFUser class]]) {
            IXFCommentUserDetailViewController *vc = (IXFCommentUserDetailViewController *)segue.destinationController;
            vc.userForDetail = (IXFUser *)sender;
        }
    }
}

#pragma mark - IXFCommentCollectionViewItemDelegate

- (void)shouldDeleteComments:(NSArray<IXFCommentItem *> *)comments
{
    if (![comments count]) {
        return;
    }
    NSString *error;
    if ([_api deleteComments:_feedItem
                    comments:comments error:&error]) {
        [self comments:_reloadButton];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[NSUUID UUID] UUIDString];
            noc.title = @"Failed to Delete Comments";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [noc setValue:_feedItem.previewImage forKey:@"_identityImage"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        });
    }
}

#pragma mark - Methods

- (void)userChanged:(NSUserNotification *)notification
{
    self.view.window.title = [NSString stringWithFormat:@"Comments of #%ld", _feedItem.identifier];
    _message.placeholderString = [NSString stringWithFormat:@"Comment as @%@", _api.user.name];
    _commenterAvatar.image = _api.user.avatar;
    _commenterAvatar.toolTip = [NSString stringWithFormat:@"@%@", _api.user.name];
    [_collectionView reloadData];
}

- (void)dupeCheck:(NSUserNotification *)notification
{
    IXFFeedItem *newFeedItem = [[notification userInfo] objectForKey:kFeedObjectKey];
    
    if ([newFeedItem.mediaID isEqualToString:_feedItem.mediaID]) {
        [self.view.window close];
    }
}

- (IBAction)comments:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_feedItem.mediaID) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _reloadButton.enabled = NO;
                [_progressIndicator startAnimation:self];
                _containerView.hidden = YES;
                _progressIndicator.hidden = NO;
            });
            
            _commentsDataSource = [[_api comments:_feedItem] mutableCopy];
            
            NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:kDataSourceSortKey
                                                                 ascending:YES];
            [_commentsDataSource sortUsingDescriptors:@[desc]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_collectionView reloadData];
                [_progressIndicator stopAnimation:self];
                _progressIndicator.hidden = YES;
                _containerView.hidden = NO;
                _reloadButton.enabled = YES;
            });
        }
    });
}

- (IBAction)commentSend:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([_message.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length < 1 ||
            _feedItem.mediaID == nil) {
            return;
        }
        
        IXFFeedItem *item = [[IXFFeedItem alloc] init];
        
        item.mediaID = [NSString stringWithFormat:@"%ld_%ld",
                        _commentsDataSource.firstObject.identifier,
                        _commentsDataSource.firstObject.user.identifier];
        
        NSString *error;
        IXFCommentItem *comment = [_api comment:_feedItem
                                           text:_message.stringValue
                                          error:&error];
        if (comment != nil) {
            _message.stringValue = @"";
            [_commentsDataSource addObject:comment];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_collectionView reloadData];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[NSUUID UUID] UUIDString];
                noc.title = @"Failed to Comment";
                noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
                [noc setValue:_feedItem.previewImage forKey:@"_identityImage"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
        }
    });
}

- (IBAction)editCaption:(id)sender
{
    if (_feedItem.mediaID == nil) {
        return;
    }
    
    if ([_mediaCaption.stringValue isEqualToString:_feedItem.caption] == NO) {
        
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Caption Changed";
        alert.informativeText = @"Would you like to apply current changes to the item?";
        alert.alertStyle = NSInformationalAlertStyle;
        
        [alert addButtonWithTitle:@"Apply"];
        [alert addButtonWithTitle:@"Cancel"];
        
        // Move window to forground.
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
        
        NSModalResponse response = [alert runModal];
        
        LOGD(@"%ld", response);
        
        if (response != NSAlertFirstButtonReturn) {
            if (_feedItem.caption != nil) {
                _mediaCaption.stringValue = _feedItem.caption;
                _mediaCaption.toolTip = _feedItem.caption;
            }
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *oldCaption = _feedItem.caption;
            
            _feedItem.caption = _mediaCaption.stringValue;
            
            if ([_api editMedia:_feedItem] == NO) {
                
                _feedItem.caption = oldCaption;
                if (_feedItem.caption != nil) {
                    _mediaCaption.stringValue = _feedItem.caption;
                    _mediaCaption.toolTip = _feedItem.caption;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                    noc.identifier = [[NSUUID UUID] UUIDString];
                    noc.title = @"Failed to Edit Caption";
                    [noc setValue:_feedItem.previewImage forKey:@"_identityImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                        object:self
                                                                      userInfo:@{kNotificationObjectKey : noc}];
                });
            }
        });
    }
}

@end
