//
//  IXFFeedViewController.h
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

#define IXFFeedCollectionViewItemIdentifier @"IXFFeedCollectionViewItem" // Should be the same as Nib name, or registerNib: first.

#define kFeedDidChangeNotificationKey       @"FeedDidChangeNotificationKey"
#define kFeedDidFailedToLoadNotificationKey @"FeedDidFailedToLoadNotificationKey"
#define kFeedShouldReloadNotificationKey    @"FeedShouldReloadNotificationKey"

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@protocol IXFFeedCollectionViewDelegate <NSObject>

- (void)setMaxID:(NSString *)maxID lastMaxID:(NSString *)lastMaxID;

@end

@interface IXFFeedViewController : NSViewController
<NSCollectionViewDataSource,
NSCollectionViewDelegate,
NSCollectionViewDelegateFlowLayout>

@property (nonatomic, assign) id<IXFFeedCollectionViewDelegate> delgate;

@property (nonatomic, assign) IXFFoundation     *api;
@property (nonatomic, assign) NSMutableArray    *feedDataSource;

@property (nonatomic, strong) NSString          *lastMaxID;
@property (nonatomic, strong) NSString          *maxID;

@property (weak) IBOutlet NSScrollView          *containerView;
@property (weak) IBOutlet NSCollectionView      *collectionView;
@property (weak) IBOutlet NSTextField           *label;
@property (weak) IBOutlet NSProgressIndicator   *progressIndicator;

@end
