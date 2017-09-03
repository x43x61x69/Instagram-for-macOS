//
//  IXFQueueViewController.h
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

#import <Cocoa/Cocoa.h>
#import "IXFQueueCollectionViewItem.h"
#import "AppDelegate.h"

@interface IXFQueueViewController : NSViewController
<NSCollectionViewDataSource,
NSCollectionViewDelegate,
NSCollectionViewDelegateFlowLayout,
IXFQueueCollectionViewItemDelegate>

@property (nonatomic, assign) IXFFoundation *api;
@property (nonatomic, assign) NSMutableArray *dataSource;

@property (weak) IBOutlet NSScrollView      *collectionViewContainer;
@property (weak) IBOutlet NSCollectionView  *collectionView;

@property (weak) IBOutlet NSButton          *removeButton;
@property (weak) IBOutlet NSPopUpButton     *clearButton;
@property (weak) IBOutlet ITSwitch          *pauseSwitch;

@property (weak) IBOutlet NSTextField       *collectioViewLabel;
@property (weak) IBOutlet NSImageView       *collectionViewImage;
@property (weak) IBOutlet NSTextField       *warningLabel;

- (IBAction)editAndRemoveItem:(id)sender;
- (IBAction)editItem:(id)sender;
- (IBAction)removeItem:(id)sender;
- (IBAction)clearFinishedItem:(id)sender;
- (IBAction)clearFinishedAndFailedItem:(id)sender;
- (IBAction)pauseQueue:(NSButton *)sender;

@end
