//
//  IXFCommentsViewController.h
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

#define IXFCommentCollectionViewItemIdentifier @"IXFCommentCollectionViewItem" // Should be the same as Nib name, or registerNib: first.
#define kCommentsSegueKey   @"CommentsSegue"

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "IXFCommentCollectionViewItem.h"

@interface IXFCommentsViewController : NSViewController
<NSCollectionViewDataSource,
NSCollectionViewDelegate,
NSCollectionViewDelegateFlowLayout,
NSTextFieldDelegate,
NSControlTextEditingDelegate,
IXFCommentCollectionViewItemDelegate>

@property (nonatomic, assign) IXFFoundation *api;

@property (nonatomic, strong) NSMutableArray<IXFCommentItem *> *commentsDataSource;
@property (nonatomic, strong) IXFFeedItem *feedItem;

@property (nonatomic) BOOL  isAutocompleting;
@property (nonatomic) BOOL  backspaceKey;

@property (weak) IBOutlet NSScrollView          *containerView;
@property (weak) IBOutlet NSCollectionView      *collectionView;
@property (weak) IBOutlet NSTextField           *label;
@property (weak) IBOutlet NSTextField           *message;
@property (weak) IBOutlet NSProgressIndicator   *progressIndicator;
@property (weak) IBOutlet NSImageView           *commenterAvatar;
@property (weak) IBOutlet NSImageView           *mediaPreview;
@property (weak) IBOutlet NSTextField           *mediaCaption;
@property (weak) IBOutlet NSTextField           *mediaUserLabel;
@property (weak) IBOutlet NSTextField           *mediaLocationLabel;
@property (weak) IBOutlet NSButton              *reloadButton;

@end
