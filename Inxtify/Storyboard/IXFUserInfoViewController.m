//
//  IXFUserInfoViewController.m
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

#import "IXFUserInfoViewController.h"
#import "IXFSidebarViewController.h"
#import <Quartz/Quartz.h>

@interface IXFUserInfoViewController ()

@end

@implementation IXFUserInfoViewController


- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userInfoDidChanged:)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    
    // Switch
    [_privateSwitch bind:@"checked"
                toObject:self
             withKeyPath:@"privateSwitchFlag"
                 options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
    _privateSwitch.tintColor = NSColorFromRGB(0xff5c53);
    _privateSwitch.disabledBorderColor = [NSColor controlShadowColor];
    
    // Avatar
    _avatarButton.wantsLayer = YES;
    _avatarButton.layer.masksToBounds = YES;
    _avatarButton.layer.backgroundColor = [NSColor colorWithWhite:1.f alpha:.3f].CGColor;
    _avatarButton.layer.borderColor = [NSColor colorWithWhite:1.f alpha:.5f].CGColor;
    _avatarButton.layer.borderWidth = 1.f;
    _avatarButton.layer.cornerRadius = _avatarButton.bounds.size.width / 2.f;
    _avatarButton.layer.needsDisplayOnBoundsChange = YES;
    
    NSRect bounds = [_avatarButton bounds];
    CAShapeLayer *shadowLayer = [CAShapeLayer layer];
    [shadowLayer setFrame:bounds];
    shadowLayer.needsDisplayOnBoundsChange = YES;
    
    // Standard shadow stuff
    [shadowLayer setShadowColor:[[NSColor controlDarkShadowColor] CGColor]];
    [shadowLayer setShadowOffset:CGSizeMake(.0f, .0f)];
    [shadowLayer setShadowOpacity:.5f];
    [shadowLayer setShadowRadius:5];
    
    // Causes the inner region in this example to NOT be filled.
    [shadowLayer setFillRule:kCAFillRuleEvenOdd];
    
    // Create the larger rectangle path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(bounds, -50, -50));
    
    // Add the inner path so it's subtracted from the outer path.
    // someInnerPath could be a simple bounds rect, or maybe
    // a rounded one for some extra fanciness.
    CGFloat radius = bounds.size.width / 2.f;
    CGMutablePathRef innerPath = CGPathCreateMutable();
    CGPathAddArc(innerPath, NULL,
                 bounds.origin.x + radius,
                 bounds.origin.y + radius,
                 radius,
                 -M_PI_2, M_PI_2*3, NO);
    CGPathAddPath(path, NULL, innerPath);
    CGPathCloseSubpath(path);
    
    [shadowLayer setPath:path];
    CGPathRelease(path);
    
    [_avatarButton.layer addSublayer:shadowLayer];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self userInfoDidChanged:nil];
}

- (IBAction)avatarAction:(NSButton *)sender
{
    [[_avatarMenu itemArray] lastObject].enabled = !_api.user.hasAnonymousProfilePicture;
    [NSMenu popUpContextMenu:_avatarMenu
                   withEvent:[[NSApplication sharedApplication] currentEvent]
                     forView:sender];
}

- (IBAction)changeAvatar:(id)sender
{
    [self dismissController:sender];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayPictureTakerNotificationKey
                                                            object:self];
    });
}

- (IBAction)removeAvatar:(id)sender
{
    [_api removeProfilePicture];
}

- (IBAction)switchTo:(id)sender
{
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        NSString *username = [(NSMenuItem *)sender title];
        LOGD(@"%@", username);
        [_api switchUserWithName:[username stringByReplacingOccurrencesOfString:@"@" withString:@""]
                          forced:NO];
    }
    [self dismissController:sender];
}

- (IBAction)addUser:(id)sender
{
    LOGD(@"%@", [(NSMenuItem *)sender title]);
    [self dismissController:sender];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayLoginNotificationKey
                                                            object:self];
    });
}

- (IBAction)logout:(id)sender
{
    LOGD(@"%@", [(NSMenuItem *)sender title]);
    [self dismissController:sender];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutCurrentUserNotificationKey
                                                            object:self];
    });
}

- (IBAction)deleteUser:(id)sender
{
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        NSString *username = [(NSMenuItem *)sender title];
        LOGD(@"%@", username);
        [_api removeUser:[username stringByReplacingOccurrencesOfString:@"@" withString:@""]];
    }
    [self dismissController:sender];
}

- (IBAction)setPrivate:(id)sender
{
    _privateSwitchFlag = !_api.user.isPrivate;
    [_api setPrivate:_privateSwitchFlag];
}

- (IBAction)takePictureForProfile:(id)sender
{
    IKPictureTaker *picTaker = [IKPictureTaker pictureTaker];
    picTaker.contentView.window.appearance = self.view.window.appearance; // [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    
    [picTaker setValue:@YES forKey:IKPictureTakerAllowsVideoCaptureKey];
    [picTaker setValue:@YES forKey:IKPictureTakerAllowsFileChoosingKey];
    [picTaker setValue:@YES forKey:IKPictureTakerShowRecentPictureKey];
    [picTaker setValue:@YES forKey:IKPictureTakerUpdateRecentPictureKey];
    [picTaker setValue:@YES forKey:IKPictureTakerUpdateRecentPictureKey];
    [picTaker setValue:@YES forKey:IKPictureTakerAllowsEditingKey];
    [picTaker setValue:@YES forKey:IKPictureTakerShowEffectsKey];
    [picTaker setValue:@YES forKey:IKPictureTakerShowAddressBookPictureKey];
    
    [picTaker setValue:[NSValue valueWithSize:CGSizeMake(kInstagramSize, kInstagramSize)]
                forKey:IKPictureTakerOutputImageMaxSizeKey];
    
    picTaker.inputImage = nil;
    //    [self.view.window endSheet:self.view.window];
    //    [picTaker beginPictureTakerSheetForWindow:self.view.window
    //                                 withDelegate:self
    //                               didEndSelector:@selector(profilePictureTakerDidEnd:returnCode:contextInfo:)
    //                                  contextInfo:nil];
    [picTaker popUpRecentsMenuForView:_anchorView//_avatarButton
                         withDelegate:self
                       didEndSelector:@selector(profilePictureTakerDidEnd:returnCode:contextInfo:)
                          contextInfo:nil];
}

- (void)profilePictureTakerDidEnd:(IKPictureTaker *)picker
                       returnCode:(NSInteger)code
                      contextInfo:(void *)contextInfo
{
    if (code == NSModalResponseOK) {
        NSImage *image = [picker outputImage];
        if (image != nil && [image isValid]) {
            [_api changeProfilePicture:image];
        }
    }
}

- (void)userInfoDidChanged:(NSNotification *)notification
{
    if (_api.user == nil) {
        [self dismissController:self];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            
//            [_api syncUserInfo:NO];
            
            _privateSwitchFlag = _api.user.isPrivate;
            _privateSwitch.checked = _api.user.isPrivate;
            _avatarButton.image = _api.user.avatar;
            
            if (_api.user.fullname) _fullname.stringValue = _api.user.fullname;
            if (_api.user.bio) {
                _biographyTextField.stringValue = _api.user.bio;
                _biographyTextField.toolTip = _api.user.bio;
            }
            
            [_username removeAllItems];
            [_username.menu addItemWithTitle:[NSString stringWithFormat:@"@%@",
                                              (_api.user.name) ? _api.user.name : @"--"]
                                      action:nil
                               keyEquivalent:@""];
            if (_api.user.verified) {
                [[_username.menu itemAtIndex:0] setImage:[NSImage imageNamed:@"verifiedTemplate"]];
            }
            if (_api.busy != 0) {
                [_username.menu addItemWithTitle:@"Actions Not Allowed While Processing"
                                          action:nil
                                   keyEquivalent:@""];
            } else {
                [_username.menu addItemWithTitle:@"Add Account..."
                                          action:@selector(addUser:)
                                   keyEquivalent:@""];
                
                NSArray *users = [_api otherUsers];
                if (users.count > 0) {
                    
                    [_username.menu addItem:[NSMenuItem separatorItem]];
                    
                    NSMenuItem *switchTo = [[NSMenuItem alloc] init];
                    [switchTo setTitle:@"Switch to..."];
                    NSMenu *switchToSubmenu = [[NSMenu alloc] init];
                    
                    NSMenuItem *remove = [[NSMenuItem alloc] init];
                    [remove setTitle:@"Remove..."];
                    NSMenu *removeSubmenu = [[NSMenu alloc] init];
                    
                    for (NSString *username in users) {
                        [switchToSubmenu addItemWithTitle:[NSString stringWithFormat:@"@%@", username]
                                                   action:@selector(switchTo:)
                                            keyEquivalent:@""];
                        [removeSubmenu addItemWithTitle:[NSString stringWithFormat:@"@%@", username]
                                                   action:@selector(deleteUser:)
                                            keyEquivalent:@""];
                    }
                    [switchTo setSubmenu:switchToSubmenu];
                    [remove setSubmenu:removeSubmenu];
                    for (NSMenuItem *item in [switchTo.submenu itemArray]) {
                        item.target = self;
                    }
                    for (NSMenuItem *item in [remove.submenu itemArray]) {
                        item.target = self;
                    }
                    [_username.menu addItem:switchTo];
                    [_username.menu addItem:remove];
                    [_username.menu addItem:[NSMenuItem separatorItem]];
                }
                [_username.menu addItemWithTitle:@"Logout"
                                          action:@selector(logout:)
                                   keyEquivalent:@""];
                
                for (NSMenuItem *item in [_username.menu itemArray]) {
                    item.target = self;
                }
            }
        });
    }
}

- (IBAction)updateBio:(NSTextField *)sender
{
    
    NSString *newBio = sender.stringValue;
    IXFUser *user = _api.user;
    NSString *currentBio = user.bio;
    
    if (newBio != nil &&
        user != nil &&
        ![newBio isEqualToString:currentBio]) {
        
        user.bio = newBio;
        
        NSString *error;
        
        if ([_api editProfile:&error] == NO) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[NSUUID UUID] UUIDString];
                noc.title = @"Failed to Update Profile";
                noc.subtitle = @"Please try again later.";
                if (error != nil) noc.informativeText = error;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
                user.bio = currentBio;
                if (currentBio != nil) {
                    sender.stringValue = currentBio;
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[NSUUID UUID] UUIDString];
                noc.title = @"Profile Updated";
                noc.informativeText = @"Biography has now changed.";
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
        }
    }
    
    [[sender window] makeFirstResponder:nil];
}

- (IBAction)updateFullname:(NSTextField *)sender
{
    
    NSString *newFullname = sender.stringValue;
    IXFUser *user = _api.user;
    NSString *currentFullname = user.fullname;
    
    if (newFullname != nil &&
        user != nil &&
        ![newFullname isEqualToString:currentFullname]) {
        
        user.fullname = newFullname;
        
        NSString *error;
        
        if ([_api editProfile:&error] == NO) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[NSUUID UUID] UUIDString];
                noc.title = @"Failed to Update Profile";
                noc.subtitle = @"Please try again later.";
                if (error != nil) noc.informativeText = error;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
                user.fullname = currentFullname;
                if (currentFullname != nil) {
                    sender.stringValue = currentFullname;
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[NSUUID UUID] UUIDString];
                noc.title = @"Profile Updated";
                noc.informativeText = @"Full name has now changed.";
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
        }
    }
    
    [[sender window] makeFirstResponder:nil];
}

@end
