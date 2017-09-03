//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import "IXFContentViewController.h"
#import "IXFSidebarViewController.h"
#import "IXFCheckpointViewController.h"
#import "IXFLoginViewController.h"
#import "IXFFeedCollectionViewItem.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)awakeFromNib
{
    
    _feedDataSource = [NSMutableArray array];
    
    // Load Previous Data Source
    NSData *encodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:kDataSourceKey];
    if (encodedObject) {
        _dataSource = [[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject] mutableCopy];
    }
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
    } else {
        for (IXFQueueItem *item in _dataSource) {
            if (item.status == IXFQueueStatusInProgress) {
                item.ends = [NSDate date];
                item.status = IXFQueueStatusFailed;
                item.retries = item.maxAttempts;
                item.error = @"Interrupted";
            }
            
            // Add identifier to existed items.
            if (item.userIdentifier < 1 &&
                [_api userWithName:item.user].identifier > 0) {
                item.userIdentifier = [_api userWithName:item.user].identifier;
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
                                                            object:self];
    });
    
    // IXFFoundation
    _api = [[IXFFoundation alloc] initFromKeychain];
    
    if (_api == nil) {
        _api = [[IXFFoundation alloc] init];
    }
    
    NSAssert((_api != nil), @"Foundation initialization failed.");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass
                            andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *URL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    LOGD(@"%@", URL);
    LOGD(@"%@, %@", [URL host], [URL lastPathComponent]);
    if ([[URL host] isEqualToString:@"checkpoint"] &&
        [[URL lastPathComponent] hasPrefix:@"dismiss"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDismissCheckpointViewNotificationKey
                                                                object:self];
        });
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortDataSource)
                                                 name:kDataSourceDidChangedNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showNotification:)
                                                 name:kNotificationObjectKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inbox)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:5.f
                                     target:self
                                   selector:@selector(uploadScheduler:)
                                   userInfo:nil
                                    repeats:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:45.f
                                     target:self
                                   selector:@selector(inboxScheduler:)
                                   userInfo:nil
                                    repeats:YES];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    // Re-display windows if all been closed/hidden.
    if (flag == NO) {
        for (NSWindow *window in sender.windows) {
            [window makeKeyAndOrderFront:self];
        }
    }
    return YES;
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    for (IXFQueueItem *item in _dataSource) {
        if (item.status == IXFQueueStatusAwaiting ||
            item.status == IXFQueueStatusInProgress) {
            
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Queue Scheduled";
            alert.informativeText = @"You still have scheduled item(s) in the queue.\n\nQuit the application now will prevent them from being carry out.";
            alert.alertStyle = NSCriticalAlertStyle;
            
            [alert addButtonWithTitle:@"Quit"];
            [alert addButtonWithTitle:@"Cancel"];
            
            // Move window to forground.
            [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
            
            NSModalResponse response = [alert runModal];
            
            LOGD(@"%ld", response);
            
            if (response != NSAlertFirstButtonReturn) {
                return NSTerminateCancel;
            }
            break;
        }
    }
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_dataSource];
    if (data != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data
                     forKey:kDataSourceKey];
        [defaults synchronize];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - NSUserNotification

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    // Move window to forground.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
    
    if ([notification.title isEqualToString:@"Attention Required"]) {
        [center removeDeliveredNotification:notification];
    } else if ([notification.title isEqualToString:@"New Notification"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *mediaID = [notification.userInfo objectForKey:@"media"];
            NSString *previewURL = [notification.userInfo objectForKey:@"image"];
            
            NSUInteger userID = [[[mediaID componentsSeparatedByString:@"_"] lastObject] integerValue];
            
            if (mediaID != nil &&
                previewURL != nil &&
                userID == _api.user.identifier) {
                
                
                IXFFeedItem *item = [[IXFFeedItem alloc] init];
                
                item.mediaID = mediaID;
                item.identifier = [[[mediaID componentsSeparatedByString:@"_"] firstObject] integerValue];
                item.previewImageURL = previewURL;
                item.previewImage = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:item.previewImageURL]];
                item.user = _api.user;
                
                NSArray *comments = [_api comments:item];
                
                if (comments != nil &&
                    item != nil) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayCommentEditorNotificationKey
                                                                            object:self
                                                                          userInfo:@{kFeedObjectKey     : item,
                                                                                     kCommentsObjectKey : comments}];
//                    });
                }
            }
        });
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayQueueNotificationKey
                                                            object:self];
    }
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    
}

#pragma mark - Documents

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    NSURL *URL = [NSURL fileURLWithPath:filename];
    
    LOGD(@"Open: %@", URL);
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:filename] &&
        URL != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidOpenFileNotificationKey
                                                            object:self
                                                          userInfo:@{kOpenFileObjectKey : URL}];
        return YES;
    }
    return NO;
}

- (IBAction)newDocument:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kResetEditorNotificationKey
                                                            object:self];
    });
}

- (IBAction)openDocument:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kImportEditorNotificationKey
                                                            object:self];
    });
}

- (IBAction)saveDocument:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kExportEditorNotificationKey
                                                            object:self];
    });
}

#pragma mark - Methods

- (void)storeDataSource
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
//                                                            object:self];
//    });
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_dataSource];
    if (data != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data
                     forKey:kDataSourceKey];
        [defaults synchronize];
    }
}

- (void)sortDataSource
{
    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:kDataSourceSortKey
                                                         ascending:NO];
    [_dataSource sortUsingDescriptors:@[desc]];
    
    [self storeDataSource];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldDisplayQueueTipNotificationKey] == NO) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayQueueTipNotificationKey
                                                                object:self];
        }
    });
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
//                                                            object:self];
//    });
}

- (void)uploadScheduler:(NSTimer *)timer
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kQueuePausedKey] != YES &&
        _dataSource.count &&
        !_api.busy) {
        for (IXFQueueItem *item in _dataSource) {
            if ((item.status == IXFQueueStatusAwaiting ||
                 (item.status == IXFQueueStatusFailed &&
                  item.maxAttempts > 0 &&
                  item.retries < item.maxAttempts)) &&
                [item isDue] //[[item.date earlierDate:[NSDate date]] isEqualToDate:item.date]
                ) {
                
                if ([_api userWithIdentifier:item.userIdentifier] ||
                    [_api userExistsWithName:item.user]) {
                    if (item.userIdentifier != _api.user.identifier &&
                        ![item.user isEqualToString:_api.user.name]) {
                        if (item.userIdentifier > 0) {
                            [_api switchUserWithIdentifier:item.userIdentifier forced:NO];
                        } else {
                            [_api switchUserWithName:item.user forced:NO];
                        }
                        LOGD(@"Switch Account!");
                        return;
                    }
                    
                    LOGD(@"Fire!");
                    item.status = IXFQueueStatusInProgress;
                    if (item.mediaID.length != 0) {
                        // Already has media ID -> Delete!
                        [_api deleteMedia:item];
                    } else {
                        switch (item.mode) {
                            case IXFQueueModeImage:
                                [_api uploadImage:item];
                                break;
                            case IXFQueueModeVideo:
                                [_api uploadVideo:item];
                                break;
                            default:
                                break;
                        }
                    }
                    [self storeDataSource];
                    return;
                } else {
                    // User no longer exists
                    item.status = IXFQueueStatusFailed;
                    item.ends = [NSDate date];
                    item.error = [NSString stringWithFormat:@"User \"%@\" Not Found", item.user];
                    item.retries = item.maxAttempts;
                    [self storeDataSource];
                }
            }
        }
    }
    _api.busy = MAX(_api.busy, 0);
    
    if (_api.busy) LOGD(@"Busy Counter: %ld / Paused: %hhd", _api.busy, [[NSUserDefaults standardUserDefaults] boolForKey:kQueuePausedKey]);
}

- (void)inboxScheduler:(NSTimer *)timer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random_uniform(10) * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self inbox];
    });
}

- (void)inbox
{
    if (_api.user != nil) {
        [_api inbox];
    }
}

- (void)showNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserNotification *noc = [[notification userInfo] objectForKey:kNotificationObjectKey];
        
        if (noc) {
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:noc];
        }
    });
}


- (IBAction)tutorial:(id)sender
{
    if ([sender respondsToSelector:@selector(resignFirstResponder)]) {
        [sender resignFirstResponder];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayPinchViewTipNotificationKey
                                                            object:self];
    });
}


- (IBAction)resetAllSettings:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Factory Reset";
        alert.informativeText = @"This will delete EVERYTHING, including account data and scheduled items.\n\nThis CAN'T be undone.";
        alert.alertStyle = NSCriticalAlertStyle;
        
        [alert addButtonWithTitle:@"RESET AND QUIT"];
        [alert addButtonWithTitle:@"Cancel"];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
            for (NSWindow *window in [NSApplication sharedApplication].windows) {
                [window close];
            }
            
            // Reset Settings
            [IXFKeychain clearService:kStoredUserObjectKey error:nil];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:kNewsInfoKey];
            [defaults removeObjectForKey:kFloatingMainWindowKey];
            [defaults removeObjectForKey:kDidShowTutorialKey];
            [defaults removeObjectForKey:kShouldDisplayQueueTipNotificationKey];
            [defaults removeObjectForKey:kShouldDisplayPinchViewZoomTipNotificationKey];
            [defaults removeObjectForKey:kShouldDisplayPinchViewVideoCoverTipNotificationKey];
            [defaults removeObjectForKey:kDataSourceKey];
            [defaults synchronize];
            LOGD(@"defaults: %@\n%@", [defaults debugDescription],
                 (NSMutableDictionary *)[IXFKeychain unarchiveObjectWithService:kStoredUserObjectKey error:nil]);
            [[NSApplication sharedApplication] terminate:self];
        }
    });
}

- (IBAction)floatingOnTop:(NSMenuItem *)sender
{
    BOOL floating = ((sender.state) == NSOnState);
    [[NSUserDefaults standardUserDefaults] setBool:floating
                                            forKey:kFloatingMainWindowKey];
    if (floating) {
        [[NSApplication sharedApplication] mainWindow].level = NSNormalWindowLevel;
    } else {
        [[NSApplication sharedApplication] mainWindow].level = NSFloatingWindowLevel;
    }
    LOGD(@"floating: %hhd", floating);
}

#pragma mark - News

- (IBAction)news:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayNewsNotificationKey
                                                            object:self];
    });
}


#pragma mark - Contact

- (IBAction)contact:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *mailtoAddress = [[NSString stringWithFormat:@"mailto:%@?Subject=%@&body=%@",
                                    kContactEmail,
                                    [[NSString stringWithFormat:@"[%@ Support] Customer Feedback - %@",
                                      [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey],
                                      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]] urlencode],
                                    [[NSString stringWithFormat:@"!! Please Do Not Remove the Following Info !!\n\n---------------\n\nVersion:\t%@ (%@)\nSystem:\t%@\nLocale:\t%@\n\n---------------\n\nYour Feedback Here:\n\n",
                                      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                      [[NSProcessInfo processInfo] operatingSystemVersionString],
                                      [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:[[NSLocale currentLocale] localeIdentifier]]] urlencode]] stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailtoAddress]];
    });
}

@end
