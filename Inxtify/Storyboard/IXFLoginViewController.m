//
//  IXFLoginViewController.m
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

#import "IXFLoginViewController.h"

@interface IXFLoginViewController () {
    NSString *username;
    NSString *password;
    BOOL     successed;
}

@end

@implementation IXFLoginViewController

- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _usernameField.delegate = self;
    _passwordField.delegate = self;
    
    _addButton.wantsLayer = YES;
    _cancelButton.wantsLayer = YES;
    _success.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resultHandler:)
                                                 name:kLoginResultNotificationKey
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    username = nil;
    password = nil;
    NSString *tempUsername = [[_usernameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if (tempUsername.length > 0 &&
        _passwordField.stringValue.length > 3) {
        _addButton.enabled = YES;
    } else {
        _addButton.enabled = NO;
    }
    if ([_api userWithName:tempUsername] != nil) {
        _statusLabel.textColor = NSColorFromRGB(0xe2c08d);
        _statusLabel.stringValue = [NSString stringWithFormat:@"User \"%@\" already exists. Login again will reset its settings.", tempUsername];
    } else {
        _statusLabel.textColor = [NSColor controlTextColor];
        _statusLabel.stringValue = @"";
    }
}

#pragma mark - Methods

- (void)resultHandler:(NSUserNotification *)notification
{
    [_indicator stopAnimation:self];
    BOOL result = [[[notification userInfo] objectForKey:kLoginResultKey] boolValue];
    if (result) {
        successed = YES;
        _success.hidden = NO;
        [self dismiss:self];
        return;
    } else {
        NSString *detail = [[notification userInfo] objectForKey:kLoginResultDetailKey];
        _statusLabel.stringValue = detail;
        _statusLabel.textColor = NSColorFromRGB(0xe2c08d);
    }
    LOGD(@"Users: %@", [_api allUsers]);
    username = nil;
    password = nil;
    _success.hidden = YES;
    _usernameField.hidden = NO;
    _passwordField.hidden = NO;
    _statusLabel.hidden = NO;
    _addButton.hidden = NO;
}

- (IBAction)add:(id)sender
{
    successed = NO;
    _success.hidden = YES;
    _usernameField.hidden = YES;
    _passwordField.hidden = YES;
    _statusLabel.hidden = YES;
    _addButton.hidden = YES;
    _statusLabel.stringValue = @"";
    _statusLabel.textColor = [NSColor controlTextColor];
    [_indicator startAnimation:self];
    
    username = [[_usernameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    password = _passwordField.stringValue;
    
    IXFUser *user = [[IXFUser alloc] initWithName:username
                                         password:password];
    LOGD(@"add user: %@ : %@", user.name, user.password);
    [_api loginWithUser:user];
}

- (IBAction)dismiss:(id)sender
{
    NSMutableArray *users = [[_api allUsers] mutableCopy];
    [users removeObject:username];
    
    if ([users count] < 1 &&
        successed == NO &&
        _checkpoint == NO) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"No Active Account";
            alert.informativeText = @"You haven't login to any Instagram account. Inxtify requires at least one active Instagram account to be used.\n\nIf you choose not to login now, the applicaion will quit.";
            alert.alertStyle = NSInformationalAlertStyle;
            
            [alert addButtonWithTitle:@"Quit"];
            [alert addButtonWithTitle:@"Cancel"];
            
            if ([alert runModal] == NSAlertFirstButtonReturn) {
                LOGD(@"Users: %@", [_api allUsers]);
                for (NSWindow *window in [NSApplication sharedApplication].windows) {
                    [window close];
                }
                [[NSApplication sharedApplication] terminate:self];
            }
        });
    } else {
        [self dismissController:self];
        LOGD(@"Users: %@", [_api allUsers]);
    }
}

@end
