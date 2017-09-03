//
//  IXFSidebarViewController.m
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

#import <QuartzCore/QuartzCore.h>
//#import <IXFFoundation/IXFFoundation.h>
#import "IXFSidebarViewController.h"

#import "IXFContentViewController.h"
#import "IXFUserInfoViewController.h"

@interface IXFSidebarViewController () {
    NSString *maxID;
    NSString *lastMaxID;
}

@end

@implementation IXFSidebarViewController

- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    _feedDataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).feedDataSource;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userInfoDidChanged:)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayQueueTip)
                                                 name:kShouldDisplayQueueTipNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayFeed:)
                                                 name:kShouldDisplayFeedNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayQueue:)
                                                 name:kShouldDisplayQueueNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logout:)
                                                 name:kShouldLogoutCurrentUserNotificationKey
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.frame = self.view.frame;
    
    
    _gradientLayer.colors = @[(id)NSColorFromRGB(0x02b875).CGColor,
                              (id)NSColorFromRGB(0x4068da).CGColor,
                              (id)NSColorFromRGB(0x4068da).CGColor];
    
    _visualEffectView.wantsLayer = YES;
    _visualEffectView.layer = _gradientLayer;
    _visualEffectView.layer.needsDisplayOnBoundsChange = YES;
    _visualEffectView.material = NSVisualEffectMaterialSidebar;
    
    _avatarButton.wantsLayer = YES;
    _avatarButton.layer.masksToBounds = YES;
    _avatarButton.layer.backgroundColor = [NSColor colorWithWhite:1.f alpha:.3f].CGColor;
    _avatarButton.layer.borderColor = [NSColor colorWithWhite:1.f alpha:.5f].CGColor;
    _avatarButton.layer.borderWidth = 1.f;
    _avatarButton.layer.cornerRadius = _avatarButton.bounds.size.width / 2.f;
    _avatarButton.layer.needsDisplayOnBoundsChange = YES;
    _avatarButton.image = _api.user.avatar;
    
    // Inner Shadow
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

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self animateLayer];
    });
}

- (void)animateLayer
{
    NSArray *fromColors = _gradientLayer.colors;
    NSArray *toColors = @[(id)NSColorFromRGB(0x363842).CGColor,
                          (id)NSColorFromRGB(0x363842).CGColor,
                          (id)NSColorFromRGB(0x363842).CGColor]; //[[fromColors reverseObjectEnumerator] allObjects];
    
    [_gradientLayer setColors:toColors];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    
    animation.fromValue             = fromColors;
    animation.toValue               = toColors;
    animation.duration              = 30.f;
    animation.repeatCount           = HUGE_VALF;
    animation.autoreverses          = YES;
    animation.removedOnCompletion   = YES;
    animation.fillMode              = kCAFillModeForwards;
    animation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.delegate              = self;
    
    // Add the animation to our layer
    
    [_gradientLayer addAnimation:animation forKey:@"animateGradient"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Segue

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:kUserInfoSegueIdentifier]) {
        if (![_api.user integrity] || ![_api syncUserInfo:YES]) {
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kFeedSegueIdentifier]) {
        IXFFeedViewController *vc = (IXFFeedViewController *)segue.destinationController;
        vc.delgate = self;
        vc.maxID = maxID;
        vc.lastMaxID = lastMaxID;
    }
}

#pragma mark -

- (void)setMaxID:(NSString *)__maxID lastMaxID:(NSString *)__lastMaxID
{
    maxID = __maxID;
    lastMaxID = __lastMaxID;
}

#pragma mark - Methods

- (void)userInfoDidChanged:(NSNotification *)notification
{
    IXFUser *user = [[notification userInfo] objectForKey:kUserObjectKey];
    if (user != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _avatarButton.toolTip = [NSString stringWithFormat:@"@%@", user.name];
            [user avatar:^(NSImage *image){
                [_api storeUsersToKeychain:nil];
                if (image != nil && ![_avatarButton.animator.image isEqual:image]) {
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = .2f;
                        _avatarButton.animator.alphaValue = .0f;
                    } completionHandler:^{
                        _avatarButton.animator.image = image;
                        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                            context.duration = .2f;
                            _avatarButton.animator.alphaValue = 1.f;
                        } completionHandler:nil];
                    }];
                }
            }];
        });
    } else {
        [_api storeUsersToKeychain:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            _avatarButton.toolTip = nil;
            if (_avatarButton.animator.image != nil) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = .2f;
                    _avatarButton.animator.alphaValue = .0f;
                } completionHandler:^{
                    _avatarButton.animator.image = nil;
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = .2f;
                        _avatarButton.animator.alphaValue = 1.f;
                    } completionHandler:nil];
                }];
            }
        });
    }
    
    maxID = nil;
    lastMaxID = nil;
    [_feedDataSource removeAllObjects];
}

- (void)logout:(NSNotification *)notification
{
    [_api logout];
}

#pragma mark - IBAction

- (void)displayQueueTip
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kQueueTipSegueIdentifier sender:self];
    });
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kShouldDisplayQueueTipNotificationKey];
    [defaults synchronize];
}

- (IBAction)displayFeed:(id)sender
{
    if ([[self presentedViewControllers] count] != 0) {
        for (NSViewController *vc in [self presentedViewControllers]) {
            [self dismissViewController:vc];
        }
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kFeedSegueIdentifier sender:self];
    });
}

- (IBAction)displayQueue:(id)sender
{
    if ([[self presentedViewControllers] count] != 0) {
        for (NSViewController *vc in [self presentedViewControllers]) {
            [self dismissViewController:vc];
        }
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kQueueSegueIdentifier sender:self];
    });
}

- (IBAction)userAction:(id)sender
{
    if ([[self presentedViewControllers] count] != 0) {
        for (NSViewController *vc in self.presentedViewControllers) {
            [self dismissViewController:vc];
        }
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kUserInfoSegueIdentifier sender:self];
    });
}

- (IBAction)tutorial:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayPinchViewTipNotificationKey
                                                            object:self];
    });
}

@end
