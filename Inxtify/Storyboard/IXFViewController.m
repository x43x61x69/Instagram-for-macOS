//
//  IXFViewController.m
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

#import "IXFViewController.h"
#import "IXFLoginViewController.h"
#import "IXFFeedViewController.h"

@implementation IXFViewController

- (void)loadView
{
    [super loadView];
    
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    _api.delegate = self;
    
    _dataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).dataSource;
    _feedDataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).feedDataSource;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.wantsLayer = YES;
    
    NSVisualEffectView *vibrant = [[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
    [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [vibrant setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [self.view addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    if (![_api.user integrity]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayLoginNotificationKey
                                                                object:self];
        });
    } else {
        [_api login];
    }
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - IXFDelegate

#pragma mark Login (POST)

- (void)wasLoggedIn
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginResultNotificationKey
                                                            object:self
                                                          userInfo:@{kLoginResultKey : @YES}];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                            object:self
                                                          userInfo:@{kUserObjectKey : _api.user}];
    });
}

- (void)didFailToLoginWithErrorMessage:(NSString *)error
{
    LOGD(@"%@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginResultNotificationKey
                                                            object:self
                                                          userInfo:@{kLoginResultKey        : @NO,
                                                                     kLoginResultDetailKey  : (error) ? error : @"Unknown Error"}];
        if ([error isEqualToString:@"checkpoint_required"] == NO) {
            [_api switchToNextUser];
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Attention Required";
            noc.subtitle = (error && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        }
    });
}

- (void)didFinishLoggingIn
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginResultNotificationKey
                                                            object:self
                                                          userInfo:@{kLoginResultKey : @YES}];
    });
}

#pragma mark Upload Image (POST)

- (void)didFailToUploadImage:(NSString *)UUID errorMessage:(NSString *)error
{
    LOGD(@"%@: %@", UUID, error);
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            item.status = IXFQueueStatusFailed;
            item.ends = [NSDate date];
            item.retries++;
            if (error) item.error = ([error isEqualToString:@"checkpoint_required"] == NO) ? error : @"Attention Required";
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = item.UUID;
                noc.title = @"Uploading Failed";
                noc.subtitle = item.error;
                [noc setValue:item.image forKey:@"_identityImage"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsImageFailedKey] + 1)
                 forKey:kStatisticsImageFailedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

- (void)didFinishUploadingImage:(NSString *)UUID
{
    LOGD(@"%@", UUID);
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            if (item.status != IXFQueueStatusFailed) {
                item.status = IXFQueueStatusDone;
                item.ends = [NSDate date];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                    noc.identifier = item.UUID;
                    noc.title = @"Image Uploaded";
                    noc.subtitle = (item.caption != nil && item.caption.length) ? item.caption : @"(No Caption)";
                    noc.informativeText = [item.URL absoluteString];
                    [noc setValue:item.image forKey:@"_identityImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                        object:self
                                                                      userInfo:@{kNotificationObjectKey : noc}];
                });
            }
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsImageSuccessedKey] + 1)
                 forKey:kStatisticsImageSuccessedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

- (void)didReceiveUploadImage:(NSString *)UUID JSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode
{
    LOGD(@"%@", dictionary);
}

#pragma mark Upload Video (POST)

- (void)didFailToUploadVideo:(NSString *)UUID errorMessage:(NSString *)error
{
    LOGD(@"%@: %@", UUID, error);
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            item.status = IXFQueueStatusFailed;
            item.retries++;
            item.ends = [NSDate date];
            if (error) item.error = ([error isEqualToString:@"checkpoint_required"] == NO) ? error : @"Attention Required";
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = item.UUID;
                noc.title = @"Uploading Failed";
                noc.subtitle = item.error;
                [noc setValue:item.image forKey:@"_identityImage"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsVideoFailedKey] + 1)
                 forKey:kStatisticsVideoFailedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

- (void)didFinishUploadingVideo:(NSString *)UUID
{
    LOGD(@"%@", UUID);
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            if (item.status != IXFQueueStatusFailed) {
                item.status = IXFQueueStatusDone;
                item.ends = [NSDate date];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                    noc.identifier = item.UUID;
                    noc.title = @"Video Uploaded";
                    noc.subtitle = (item.caption != nil && item.caption.length) ? item.caption : @"(No Caption)";
                    noc.informativeText = [item.URL absoluteString];
                    [noc setValue:item.image forKey:@"_identityImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                        object:self
                                                                      userInfo:@{kNotificationObjectKey : noc}];
                });
            }
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsVideoSuccessedKey] + 1)
                 forKey:kStatisticsVideoSuccessedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

- (void)didReceiveUploadVideo:(NSString *)UUID JSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode
{
    LOGD(@"%@", dictionary);
}


#pragma mark Delete Media (POST)

- (void)didFailToDeleteMedia:(NSString *)UUID errorMessage:(NSString *)error
{
    LOGD(@"%@: %@", UUID, error);
    
    if ([UUID hasPrefix:kFeedItemDeleteObjectKey]) {
        NSString *mediaID = [UUID substringFromIndex:[kFeedItemDeleteObjectKey length]];
        for (IXFFeedItem *item in _feedDataSource) {
            if ([mediaID isEqualToString:item.mediaID]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                    noc.identifier = [[NSUUID UUID] UUIDString];
                    noc.title = @"Failed to Delete Media";
                    noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";;
                    [noc setValue:item.previewImage forKey:@"_identityImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                        object:self
                                                                      userInfo:@{kNotificationObjectKey : noc}];
                });
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kFeedDidChangeNotificationKey
                                                                    object:self];
                return;
            }
        }
        UUID = nil;
    }
    
    if (UUID == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[NSUUID UUID] UUIDString];
            noc.title = @"Failed to Unknown Delete Media";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        });
        return;
    }
    
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            item.status = IXFQueueStatusFailed;
            item.retries++;
            item.ends = [NSDate date];
            if (error) item.error = ([error isEqualToString:@"checkpoint_required"] == NO) ? error : @"Attention Required";
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = item.UUID;
                noc.title = @"Failed to Delete Media";
                noc.subtitle = item.error;
                [noc setValue:item.image forKey:@"_identityImage"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsDeleteFailedKey] + 1)
                 forKey:kStatisticsDeleteFailedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

- (void)didFinishDeletingMedia:(NSString *)UUID
{
    LOGD(@"%@", UUID);
    
    if ([UUID hasPrefix:kFeedItemDeleteObjectKey]) {
        NSString *mediaID = [UUID substringFromIndex:[kFeedItemDeleteObjectKey length]];
        if (mediaID.length) {
            for (IXFFeedItem *item in _feedDataSource) {
                if (item.mediaID.length && [mediaID isEqualToString:item.mediaID]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSUserNotification *noc = [[NSUserNotification alloc] init];
                        noc.identifier = [[NSUUID UUID] UUIDString];
                        noc.title = @"Media Deleted";
                        noc.subtitle = (item.caption != nil && item.caption.length) ? item.caption : @"(No Caption)";
                        noc.informativeText = @"Item was removed from Instagram successfully.";
                        [noc setValue:item.previewImage forKey:@"_identityImage"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                            object:self
                                                                          userInfo:@{kNotificationObjectKey : noc}];
                    });
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFeedShouldReloadNotificationKey
                                                                        object:self];
                    return;
                }
            }
        }
        UUID = nil;
    }
    
    if (UUID == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[NSUUID UUID] UUIDString];
            noc.title = @"Unknown Media Deleted";
            noc.informativeText = @"Item was removed from Instagram successfully.";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        });
        return;
    }
    
    for (IXFQueueItem *item in _dataSource) {
        if ([item.UUID isEqualToString:UUID]) {
            if (item.status != IXFQueueStatusFailed) {
                item.status = IXFQueueStatusDone;
                item.URL = nil;
                item.mediaID = nil;
                item.ends = [NSDate date];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                    noc.identifier = item.UUID;
                    noc.title = @"Media Deleted";
                    noc.subtitle = (item.caption != nil && item.caption.length) ? item.caption : @"(No Caption)";
                    noc.informativeText = @"Item was removed from Instagram successfully.";
                    [noc setValue:item.image forKey:@"_identityImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                        object:self
                                                                      userInfo:@{kNotificationObjectKey : noc}];
                });
            }
            break;
        }
    }
    
    // Store Statistics
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@([defaults integerForKey:kStatisticsTotalKey] + 1)
                 forKey:kStatisticsTotalKey];
    [defaults setObject:@([defaults integerForKey:kStatisticsVideoSuccessedKey] + 1)
                 forKey:kStatisticsVideoSuccessedKey];
    [defaults synchronize];
    
    [self storeDataSource];
}

#pragma mark Change Profile Picture (POST)

- (void)didFailToChangeProfilePictureWithErrorMessage:(NSString *)error
{
    LOGD(@"%@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([error isEqualToString:@"checkpoint_required"] == NO) {
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Failed to Change Profile Picture";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        }
    });
}

#pragma mark Remove Profile Picture (POST)

- (void)didFailToRemoveProfilePictureWithErrorMessage:(NSString *)error
{
    LOGD(@"%@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([error isEqualToString:@"checkpoint_required"] == NO) {
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Failed to Remove Profile Picture";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        }
    });
}

#pragma mark Set Private (POST)

- (void)didFailToSetPrivateWithErrorMessage:(NSString *)error
{
    LOGD(@"%@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([error isEqualToString:@"checkpoint_required"] == NO) {
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Failed to Change Account Status";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        }
    });
}

- (void)didFinishSettingPrivate:(BOOL)isPrivate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserNotification *noc = [[NSUserNotification alloc] init];
        noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
        noc.title = @"Account Status Changed";
        noc.subtitle = [NSString  stringWithFormat:@"Timeline for @%@ is now \"%@\".",
                        _api.user.name,
                        (isPrivate) ? @"Private" : @"Public"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                            object:self
                                                          userInfo:@{kNotificationObjectKey : noc}];
    });
}

#pragma mark Timeline (GET)

- (void)didFailToFetchFeedWithErrorMessage:(NSString *)error
{
    LOGD(@"%@", error);
    
    if (error != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFeedDidFailedToLoadNotificationKey
                                                            object:self
                                                          userInfo:@{kFeedObjectKey : error}];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([error isEqualToString:@"checkpoint_required"] == NO) {
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Failed to Load Feed";
            noc.subtitle = (error != nil && error.length) ? error : @"Unknown Error";
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        }
    });
}

- (void)didFinishFetchingFeed:(NSDictionary *)dictionary
{
//    LOGD(@"%@", dictionary);
    
    if (dictionary != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFeedDidChangeNotificationKey
                                                            object:self
                                                          userInfo:@{kFeedObjectKey : dictionary}];
    }
}

#pragma mark - Methods

- (void)storeDataSource
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_dataSource]
                 forKey:kDataSourceKey];
    [defaults synchronize];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
//                                                            object:self];
//    });
}

@end
