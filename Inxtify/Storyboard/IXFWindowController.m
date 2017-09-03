//
//  IXFWindowController.m
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

#import "IXFWindowController.h"

@interface IXFWindowController ()

@end

@implementation IXFWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - NSWindowDelegate

- (void)awakeFromNib
{
    self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kFloatingMainWindowKey] == YES) {
        self.window.level = NSFloatingWindowLevel;
    } else {
        self.window.level = NSNormalWindowLevel;
    }
    
    [self repositionStandardWindowButtons];
}

- (void)windowWillClose:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults boolForKey:kBackgroundInfoKey] != YES) {
            
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Running in the Background";
            alert.informativeText = @"Your scheduled items will be handled even when Inxtify is running in the background.";
            alert.alertStyle = NSInformationalAlertStyle;
            alert.accessoryView = _backgroundAccessoryView;
            
            [alert addButtonWithTitle:@"OK"];
            
            if ([alert runModal]) {
                [defaults setObject:([_backgroundCheckBox state] == NSOnState) ? @YES : @NO
                             forKey:kBackgroundInfoKey];
                [defaults synchronize];
            }
        }
    });
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    // Force update the tracking areas of NSWindowButton at launch. Do only once.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRect frame = [self.window frame];
        frame.size = NSMakeSize(frame.size.width, frame.size.height+1.f);
        [self.window setFrame:frame display:NO animate:NO];
        frame.size = NSMakeSize(frame.size.width, frame.size.height-1.f);
        [self.window setFrame:frame display:NO animate:YES];
    });
}

- (void)windowDidResize:(NSNotification *)notification
{
    [self repositionStandardWindowButtons];
}

- (void)repositionStandardWindowButtons
{
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    NSRect closeButtonFrame = [closeButton frame];
    
    NSButton *minimizeButton = [self.window standardWindowButton:NSWindowMiniaturizeButton];
    NSRect minimizeButtonFrame = [minimizeButton frame];
    
    NSButton *zoomButton = [self.window standardWindowButton:NSWindowZoomButton];
    NSRect zoomButtonFrame = [zoomButton frame];
    
    NSView *superview = self.window.contentView;
    CGFloat y = CGRectGetMaxY(superview.frame) - 12.f;
    
    [closeButton setFrame:NSMakeRect(closeButtonFrame.origin.x,
                                     y - closeButtonFrame.size.height,
                                     closeButtonFrame.size.width,
                                     closeButtonFrame.size.height)];
    
    [minimizeButton setFrame:NSMakeRect(minimizeButtonFrame.origin.x,
                                        y - minimizeButtonFrame.size.height,
                                        minimizeButtonFrame.size.width,
                                        minimizeButtonFrame.size.height)];
    
    [zoomButton setFrame:NSMakeRect(zoomButtonFrame.origin.x,
                                    y - zoomButtonFrame.size.height,
                                    zoomButtonFrame.size.width,
                                    zoomButtonFrame.size.height)];
    
    [closeButton removeFromSuperview];
    [minimizeButton removeFromSuperview];
    [zoomButton removeFromSuperview];
    
    [superview addSubview:closeButton];
    [superview addSubview:minimizeButton];
    [superview addSubview:zoomButton];
}

@end
