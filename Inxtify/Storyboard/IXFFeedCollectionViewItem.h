//
//  IXFFeedCollectionViewItem.h
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

#define kImageHUDObjectKey @"IHOK"
#define kShouldDisplayImageHUDNotificationKey @"SDIHUDNK"
#define kCommentsObjectKey @"COK"
#define kShouldDisplayCommentEditorNotificationKey @"SDCENK"

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface IXFFeedCollectionViewItem : NSCollectionViewItem

@property (nonatomic, assign) IXFFoundation *api;
@property (nonatomic, assign) IXFFeedItem *item;


@property (weak) IBOutlet NSImageView *preview;
@property (weak) IBOutlet NSTextField *comments;
@property (weak) IBOutlet NSTextField *likes;
@property (weak) IBOutlet IXFImageView *commentsImage;
@property (weak) IBOutlet NSButton *openWebButton;
@property (weak) IBOutlet NSButton *deleteButton;
@property (weak) IBOutlet NSButton *likeButton;
@property (weak) IBOutlet NSButton *previewButton;
@property (weak) IBOutlet NSButton *commentsButton;

@end
