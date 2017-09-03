//
//  IXFQueueCollectionViewItem.m
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

#import "IXFQueueCollectionViewItem.h"
#import "IXFQueueViewController.h"

@interface IXFQueueCollectionViewItem ()

@end

@implementation IXFQueueCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.wantsLayer = YES;
    self.view.layer.borderWidth = 1.f;
    
    _profileImageView.wantsLayer = YES;
    _profileImageView.layer.masksToBounds = YES;
    _profileImageView.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:.3f].CGColor;
    _profileImageView.layer.borderColor = [[NSColor whiteColor] colorWithAlphaComponent:.5f].CGColor;
    _profileImageView.layer.borderWidth = 1.f;
    _profileImageView.layer.cornerRadius = _profileImageView.bounds.size.width / 2.f;
    _profileImageView.layer.needsDisplayOnBoundsChange = YES;
    
    _previewImageView.wantsLayer = YES;
    _previewImageView.layer.borderColor = [NSColor controlShadowColor].CGColor;
    _previewImageView.layer.borderWidth = 1.f;
    
    _typeImage.wantsLayer = YES;
    _typeImage.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    _statusImageView.wantsLayer = YES;
    _statusImageView.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    _captionLabel.backgroundColor = [NSColor clearColor];
    _dateLabel.backgroundColor = [NSColor clearColor];
    
    _button.wantsLayer = YES;
    _button.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    NSImage *i = [_button.image copy];
    i.template = NO;
    _button.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_typeImage.image copy];
    i.template = NO;
    _typeImage.image = [i imageTintedWithColor:[NSColor whiteColor]];
    i = [_statusImageView.image copy];
    i.template = NO;
    _statusImageView.image = [i imageTintedWithColor:[NSColor whiteColor]];
    
}

+ (NSSet *)keyPathsForValuesAffectingTextColor
{
    return [NSSet setWithObjects:@"selected", nil];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    _item = self.representedObject;
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self updateBackgroundColorForSelectionState:self.isSelected];
    
    [self.view.menu removeAllItems];
    if (_item.status != IXFQueueStatusInProgress) {
        
        // Edit
        NSMenuItem *edit = [[NSMenuItem alloc] init];
        [edit setTitle:@"Edit..."];
        NSMenu *submenu = [[NSMenu alloc] init];
        [submenu addItemWithTitle:@"Edit and Remove from Queue"
                           action:@selector(edit:)
                    keyEquivalent:@""];
        [submenu addItemWithTitle:@"Edit as a Duplicate"
                           action:@selector(duplicate:)
                    keyEquivalent:@""];
        [edit setSubmenu:submenu];
        [self.view.menu addItem:edit];
        
        [self.view.menu addItemWithTitle:@"Remove"
                                  action:@selector(remove:)
                           keyEquivalent:@""];
        
        if (_item.URL && _item.mediaID.length > 0) {
            [self.view.menu addItem:[NSMenuItem separatorItem]];
            
            [self.view.menu addItemWithTitle:@"Open in Browser"
                                      action:@selector(openURL:)
                               keyEquivalent:@""];
            
            [self.view.menu addItemWithTitle:@"Copy Link"
                                      action:@selector(copyURL:)
                               keyEquivalent:@""];
            if (_item.mediaID) {
                [self.view.menu addItemWithTitle:@"Delete on Instagram"
                                          action:@selector(delete:)
                                   keyEquivalent:@""];
            }
        } else if (_item.status == IXFQueueStatusDone) {
            [self.view.menu addItem:[NSMenuItem separatorItem]];
            
            [self.view.menu addItemWithTitle:@"Deleted"
                                      action:nil
                               keyEquivalent:@""];
        }
    } else {
        [self.view.menu addItemWithTitle:@"In Progress..."
                                  action:nil
                           keyEquivalent:@""];
        
        // Edit
        NSMenuItem *edit = [[NSMenuItem alloc] init];
        [edit setTitle:@"Edit..."];
        NSMenu *submenu = [[NSMenu alloc] init];
        [submenu addItemWithTitle:@"Edit and Remove from Queue"
                           action:nil
                    keyEquivalent:@""];
        [submenu addItemWithTitle:@"Edit as a Duplicate"
                           action:@selector(duplicate:)
                    keyEquivalent:@""];
        [edit setSubmenu:submenu];
        [self.view.menu addItem:edit];
        
        [self.view.menu addItemWithTitle:@"Remove"
                                  action:nil
                           keyEquivalent:@""];
    }
}

- (void)updateBackgroundColorForSelectionState:(BOOL)flag
{
    if (flag) {
        self.view.layer.borderColor = [NSColor alternateSelectedControlColor].CGColor;
        self.view.alphaValue = .5f;
    } else {
        self.view.layer.borderColor = [NSColor clearColor].CGColor;
        self.view.alphaValue = 1.f;
    }
}

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    [self updateBackgroundColorForSelectionState:flag];
}

#pragma mark - Methods

- (IBAction)openMenu:(id)sender
{
    [NSMenu popUpContextMenu:self.view.menu
                   withEvent:[[NSApplication sharedApplication] currentEvent]
                     forView:sender];
}

- (IBAction)copyURL:(id)sender
{
    if (_item.URL != nil) {
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] setString:[_item.URL absoluteString]
                                            forType:NSPasteboardTypeString];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Link Copied";
            noc.subtitle = @"Link has been copied to the pasteboard.";
            noc.informativeText = [_item.URL absoluteString];
            [noc setValue:_item.image forKey:@"_identityImage"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        });
    }
}

- (IBAction)openURL:(id)sender
{
    if (_item.URL != nil) {
        [[NSWorkspace sharedWorkspace] openURL:_item.URL];
    }
}

- (IBAction)duplicate:(id)sender
{
    if ([_delgate respondsToSelector:@selector(itemShouldBeEditAtIndex:remove:)]) {
        NSIndexPath *indexPath;
        if ((indexPath = [[self collectionView] indexPathForItem:self]) != nil) {
            [_delgate itemShouldBeEditAtIndex:indexPath.item
                                       remove:NO];
        }
    }
}

- (IBAction)edit:(id)sender
{
    if ([_delgate respondsToSelector:@selector(itemShouldBeEditAtIndex:remove:)]) {
        NSIndexPath *indexPath;
        if ((indexPath = [[self collectionView] indexPathForItem:self]) != nil) {
            [_delgate itemShouldBeEditAtIndex:indexPath.item
                                       remove:YES];
        }
    }
}

- (IBAction)delete:(id)sender
{
    if ([_delgate respondsToSelector:@selector(itemShouldBeRemotelyDeleteAtIndex:)]) {
        NSIndexPath *indexPath;
        if ((indexPath = [[self collectionView] indexPathForItem:self]) != nil) {
            [_delgate itemShouldBeRemotelyDeleteAtIndex:indexPath.item];
        }
    }
}

- (IBAction)remove:(id)sender
{
    if ([_delgate respondsToSelector:@selector(itemShouldBeRemovedAtIndex:)]) {
        NSIndexPath *indexPath;
        if ((indexPath = [[self collectionView] indexPathForItem:self]) != nil) {
            [_delgate itemShouldBeRemovedAtIndex:indexPath.item];
        }
    }
}

@end
