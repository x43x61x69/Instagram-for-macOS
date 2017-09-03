//
//  IXFSidebarViewController.h
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

#define kUserInfoSegueIdentifier    @"UserInfoSegue"
#define kQueueSegueIdentifier       @"QueueSegue"
#define kQueueTipSegueIdentifier    @"QueueTipSegue"
#define kFeedSegueIdentifier        @"FeedSegue"

#define kShouldDisplayQueueNotificationKey          @"ShouldDisplayQueueNotificationKey"
#define kShouldDisplayFeedNotificationKey           @"ShouldDisplayFeedNotificationKey"
#define kShouldDisplayQueueTipNotificationKey       @"ShouldDisplayQueueTipNotificationKey"
#define kShouldLogoutCurrentUserNotificationKey     @"ShouldLogoutCurrentUserNotificationKey"
#define kShouldDisplayPictureTakerNotificationKey   @"ShouldDisplayPictureTakerNotificationKey"

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "IXFFeedViewController.h"

@interface IXFSidebarViewController : NSViewController <IXFFeedCollectionViewDelegate>

@property (nonatomic, assign)   IXFFoundation *api;
@property (nonatomic, assign)   NSMutableArray *feedDataSource;
@property (nonatomic, strong)   CAGradientLayer *gradientLayer;

@property (weak) IBOutlet NSVisualEffectView *visualEffectView;
@property (weak) IBOutlet NSButton *avatarButton;
@property (weak) IBOutlet NSButton *homeButton;

@end
