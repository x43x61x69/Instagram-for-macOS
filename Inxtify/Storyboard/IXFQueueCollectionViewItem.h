//
//  IXFQueueCollectionViewItem.h
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

#define IXF_QUEUE_COLLECTION_VIEW_ITEM_IDENTIFIER   @"IXFQueueCollectionViewItem" // Should be the same as Nib name, or registerNib: first.

#import <Cocoa/Cocoa.h>

@protocol IXFQueueCollectionViewItemDelegate <NSObject>
- (void)itemShouldBeRemovedAtIndex:(NSUInteger)index;
- (void)itemShouldBeRemotelyDeleteAtIndex:(NSUInteger)index;
- (void)itemShouldBeEditAtIndex:(NSUInteger)index remove:(BOOL)shouldBeRemoved;
@end

@interface IXFQueueCollectionViewItem : NSCollectionViewItem

@property (nonatomic, assign) id<IXFQueueCollectionViewItemDelegate> delgate;
@property (nonatomic, assign) IXFQueueItem *item;

@property (weak) IBOutlet NSImageView *previewImageView;
@property (weak) IBOutlet NSTextField *captionLabel;
@property (weak) IBOutlet NSTextField *dateLabel;
@property (weak) IBOutlet NSImageView *statusImageView;
@property (weak) IBOutlet NSButton    *button;
@property (weak) IBOutlet NSBox       *bottomLine;
@property (weak) IBOutlet NSImageView *typeImage;
@property (weak) IBOutlet NSImageView *profileImageView;

@end
