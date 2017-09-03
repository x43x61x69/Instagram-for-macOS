//
//  IXFContentViewController.m
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

#define kDisabledGeoTaggingString   @"(Location Disabled)"
#define kStatusErrorColor           NSColorFromRGB(0xe06c75)
#define kStatusWarningColor         NSColorFromRGB(0xe2c08d)

#import <AppKit/AppKit.h>
#import "IXFContentViewController.h"
#import "IXFSidebarViewController.h"
#import "IXFLoginViewController.h"
#import "IXFCheckpointViewController.h"
#import "IXFFeedCollectionViewItem.h"
#import "IXFCommentsViewController.h"

@interface IXFContentViewController () {
    CLLocationManager *locationManager;
    NSArray *nearbyLocations;
    IXFLocation *taggedLocation;
    NSUInteger tutorialStep;
    BOOL tutorialMode;
}

@end

@implementation IXFContentViewController

- (void)loadView
{
    [super loadView];
    _api = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).api;
    _dataSource = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).dataSource;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceDidChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceDidChanged:)
                                                 name:kStatusDidChangedNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userInfoDidChanged:)
                                                 name:kUserInfoDidChangeNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetCheck)
                                                 name:kResetEditorNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(importFromOpen:)
                                                 name:kDidOpenFileNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(import:)
                                                 name:kImportEditorNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(export:)
                                                 name:kExportEditorNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadQueueItemWithNotification:)
                                                 name:kQueueEditNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkLoginStatus:)
                                                 name:kCheckpointViewDismissNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUsers)
                                                 name:kUsersListDidChangedNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustZoom)
                                                 name:kPinchViewZoomDidChangedNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayLogin:)
                                                 name:kShouldDisplayLoginNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayNews)
                                                 name:kShouldDisplayNewsNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayImageHUD:)
                                                 name:kShouldDisplayImageHUDNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayCommentEditor:)
                                                 name:kShouldDisplayCommentEditorNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayCheckpoint:)
                                                 name:kCheckpointNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayPinchViewTip)
                                                 name:kShouldDisplayPinchViewTipNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(popoverDidClose:)
                                                 name:NSPopoverDidCloseNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.frame;
    gradientLayer.colors = @[(id)NSColorFromRGB(0x252833).CGColor,
                             (id)NSColorFromRGB(0x252833).CGColor];
    _background.wantsLayer = YES;
    _background.layer = gradientLayer;
    _background.layer.needsDisplayOnBoundsChange = YES;
    _background.material = NSVisualEffectMaterialSidebar;
    
    // PinchView
    _pinchView.delegate = self;
    
    // Date Picker
    _datePicker.minDate = [NSDate date];
    _datePicker.dateValue = _datePicker.minDate;
    
    // Location Manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [locationManager startUpdatingLocation];
    
    // MapView
    _mapView.layer.borderColor = [NSColor windowFrameColor].CGColor;
    _mapView.layer.borderWidth = 1.f;
    _mapView.layer.cornerRadius = 4.f;
    
    // Slider
    _previewSlider.alphaValue = .6f;
    _previewSlider.hidden = YES;
    _previewSlider.wantsLayer = YES;
    _previewSlider.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    // Zoom Button
    _zoomButton.alphaValue = .6f;
    _zoomButton.hidden = YES;
    _zoomButton.wantsLayer = YES;
    _zoomButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    // Square Mode Switch
    _squareModeSwitch.hidden = YES;
    _squareModeSwitch.disabledBorderColor = [NSColor controlShadowColor];
    [_squareModeSwitch bind:@"checked"
              toObject:_pinchView
           withKeyPath:@"isSquareMode"
               options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
    
    // Attempts Slider
    [self attemptsChanged:_attemptSlider];
    
    // Status
    _statusProgress.wantsLayer = YES;
    
    // Caption
    
    // Users
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    // Init locations
    [self searchLocation:nil];
    
    // News
    if ([_api cookiesExpired] ||
        [[NSUserDefaults standardUserDefaults] boolForKey:kDidShowTutorialKey]) {
        [self displayTutorial];
    }
}

#pragma mark - NSControlTextEditingDelegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSuggestionsDisabledKey]) {
        return;
    }
    
    if (_isAutocompleting == NO  &&
        !_backspaceKey) {
        _isAutocompleting = YES;
        [[[notification userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
        _isAutocompleting = NO;
    } else if (_backspaceKey == YES) {
        _backspaceKey = NO;
    }
    
}

- (NSArray<NSString *> *)control:(NSControl *)control
                        textView:(NSTextView *)textView
                     completions:(NSArray<NSString *> *)words
             forPartialWordRange:(NSRange)charRange
             indexOfSelectedItem:(NSInteger *)index
{
    LOGD(@"forPartialWordRange: %@, %ld, %ld, %ld", [textView.string substringWithRange:charRange], charRange.location, charRange.length, *index);
    
    if (charRange.location == 0 ||
        charRange.length < 1) {
        return nil;
    }
    NSArray *suggestions;
    NSString *keyword = [textView.string substringWithRange:NSMakeRange(charRange.location-1, 1)];
    if ([keyword isEqualToString:@"#"]) {
        keyword = [textView.string substringWithRange:charRange];
        suggestions = [_api hashtag:keyword];
    } else if ([keyword isEqualToString:@"@"]) {
        keyword = [textView.string substringWithRange:charRange];
        suggestions = [_api users:keyword];
    }
    return suggestions;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (commandSelector == @selector(deleteBackward:)) {
        _backspaceKey = YES;
    }
    return NO;
}

#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification
{
    if (tutorialMode == YES &&
        [[notification.userInfo valueForKey:@"NSPopoverCloseReasonUserInfoKey"] integerValue] == 0) {
        // User click next!
        switch (tutorialStep) {
            case 0:
                [self performSegueWithIdentifier:kLocationTipSegueIdentifier sender:self];
                break;
            case 1:
                [self performSegueWithIdentifier:kCaptionTipSegueIdentifier sender:self];
                break;
            case 2:
                [self performSegueWithIdentifier:kRetriesTipSegueIdentifier sender:self];
                break;
            case 3:
                [self performSegueWithIdentifier:kScheduleTipSegueIdentifier sender:self];
                break;
            case 4:
                [self performSegueWithIdentifier:kUserTipSegueIdentifier sender:self];
                break;
            case 5:
                [self performSegueWithIdentifier:kSendTipSegueIdentifier sender:self];
                break;
            default:
                break;
        }
        tutorialStep++;
    } else {
        tutorialMode = NO;
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kCheckpointWebViewSegueIdentifier]) {
        IXFCheckpointViewController *vc = (IXFCheckpointViewController *)segue.destinationController;
        vc.URL = _checkpointURL;
    } else if ([segue.identifier isEqualToString:kCommentsSegueKey]) {
        IXFCommentsViewController *vc = (IXFCommentsViewController *)segue.destinationController;
        vc.commentsDataSource = [_comments mutableCopy];
        vc.feedItem = _feedItem;
    }
}

#pragma mark - IXFImagePinchViewDelegate

- (void)newQueueItem:(NSURL *)URL
{
    [self importFromURL:URL];
}

- (void)newQueueImage:(NSURL *)URL
{
    _previewSlider.hidden = YES;
    
    [self adjustZoom];
    _zoomButton.hidden = NO;
    _squareModeSwitch.hidden = NO;
    
    if ([[_datePicker.dateValue earlierDate:[NSDate date]] isEqualToDate:_datePicker.dateValue]) {
        _datePicker.dateValue = [NSDate date];
    }
    
    [self setLocationWithURL:URL];
    
    // Tip
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldDisplayPinchViewZoomTipNotificationKey] == NO) {
        [self performSegueWithIdentifier:kPinchViewZoomTipSegueIdentifier sender:self];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kShouldDisplayPinchViewZoomTipNotificationKey];
        [defaults synchronize];
    }
}

- (void)newQueueVideo:(NSURL *)URL
{
    CGFloat duration = [_pinchView videoDurationSeconds];
    if (duration > 0) {
        _previewSlider.maxValue = floor(duration);
        _previewSlider.floatValue = _previewSlider.minValue;
        _previewSlider.numberOfTickMarks = _previewSlider.maxValue + 1;
        _previewSlider.hidden = NO;
        _zoomButton.hidden = YES;
        _squareModeSwitch.hidden = YES;
    }
    if ([[_datePicker.dateValue earlierDate:[NSDate date]] isEqualToDate:_datePicker.dateValue]) {
        _datePicker.dateValue = [NSDate date];
    }
    
    [self setLocationWithURL:URL];
    
    // Tip
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldDisplayPinchViewVideoCoverTipNotificationKey] == NO) {
        [self performSegueWithIdentifier:kPinchViewVideoCoverTipSegueIdentifier sender:self];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kShouldDisplayPinchViewVideoCoverTipNotificationKey];
        [defaults synchronize];
    }
}

#pragma mark - MapKit

- (void)setLocationWithURL:(NSURL *)URL
{
    CLLocationCoordinate2D coordinate = [URL GPS];
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location
                       completionHandler:^(NSArray<CLPlacemark *> *placemarks,
                                           NSError *error)
         {
             if ([placemarks count]) {
                 CLPlacemark *placemark = [placemarks firstObject];
                 LOGD(@"placemark: %@", [placemark description]);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSUserNotification *noc = [[NSUserNotification alloc] init];
                     noc.identifier = [[NSUUID UUID] UUIDString];
                     noc.title = @"GPS Location Found";
                     noc.subtitle = placemark.name;
                     if (placemark.country) {
                         noc.informativeText = [NSString stringWithFormat:@"Near %@%@%@%@%@%@%@.",
                                                (placemark.locality) ? placemark.locality : @"",
                                                (placemark.locality) ? @", " : @"",
                                                (placemark.subAdministrativeArea) ? placemark.subAdministrativeArea : @"",
                                                (placemark.subAdministrativeArea) ? @", " : @"",
                                                (placemark.administrativeArea) ? placemark.administrativeArea : @"",
                                                (placemark.administrativeArea) ? @", " : @"",
                                                placemark.country];
                     }
                     [noc setValue:_pinchView.imageView.image forKey:@"_identityImage"];
                     [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                         object:self
                                                                       userInfo:@{kNotificationObjectKey : noc}];
                 });
             }
         }];
        
        _locationPopupButton.enabled = NO;
        [_locationPopupButton removeAllItems];
        [_locationPopupButton.menu addItemWithTitle:kDisabledGeoTaggingString
                                             action:nil
                                      keyEquivalent:@""];
        
        [_api nearbyLocations:coordinate
            completionHandler:^(NSArray *locations, NSError *error) {
                nearbyLocations = locations;
                if ([locations count] > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (IXFLocation *location in locations) {
                            [_locationPopupButton.menu addItemWithTitle:location.name
                                                                 action:nil
                                                          keyEquivalent:@""];
                        }
                        if ([_locationPopupButton.menu.itemArray count] > 1) {
                            [_locationPopupButton selectItemAtIndex:1];
                            _locationPopupButton.enabled = YES;
                            taggedLocation = [nearbyLocations objectAtIndex:0];
                            LOGD(@"taggedLocation %@", [taggedLocation locationDictionary]);
                            
                            [self addAnnotation:nil
                                 withCoordinate:coordinate];
                            
                            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 250, 250);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_mapView setRegion:region animated:YES];
                            });
                        }
                    });
                }
            }];
    }
}

- (void)addAnnotation:(NSString *)title withCoordinate:(CLLocationCoordinate2D)coordinate
{
    [_mapView removeAnnotations:_mapView.annotations];
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.title = title;
    annotation.coordinate = coordinate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapView addAnnotation:annotation];
    });
    
}

- (void)searchLocation:(NSString *)address
{
    // Halve the width and height in the zoom level.
    // If you want a constant zoom level, just set .longitude/latitudeDelta to the
    // constant amount you would like.
    // Note: a constant longitude/latitude != constant distance depending on distance
    //       from poles or equator.
    //    MKCoordinateSpan span = {
    //        .longitudeDelta = _mapView.region.span.longitudeDelta / 2,
    //        .latitudeDelta = _mapView.region.span.latitudeDelta  / 2 };
    
    _locationPopupButton.enabled = NO;
    [_locationPopupButton removeAllItems];
    [_locationPopupButton.menu addItemWithTitle:kDisabledGeoTaggingString
                                         action:nil
                                  keyEquivalent:@""];
    
    if (![address length]) {
        [_api nearbyLocations:locationManager.location.coordinate
            completionHandler:^(NSArray *locations, NSError *error) {
                nearbyLocations = locations;
                if ([locations count] > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (IXFLocation *location in locations) {
                            [_locationPopupButton.menu addItemWithTitle:location.name
                                                                 action:nil
                                                          keyEquivalent:@""];
                        }
                        if ([_locationPopupButton.menu.itemArray count] > 1) {
                            [_locationPopupButton selectItemAtIndex:0];
                            _locationPopupButton.enabled = YES;
                            [self selectLocation];
                        }
                    });
                }
            }];
        // Create a new MKMapRegion with the new span, using the center we want.
        //        MKCoordinateRegion region = { .center = locationManager.location.coordinate, .span = span };
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate, 250, 250);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView setRegion:region animated:YES];
        });
        return;
    }
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        CLLocation *location = placemark.location;
        CLLocationCoordinate2D coordinate = location.coordinate;
        [self addAnnotation:placemark.name withCoordinate:coordinate];
        [_api nearbyLocations:coordinate
            completionHandler:^(NSArray *locations, NSError *error) {
                nearbyLocations = locations;
                if ([locations count] > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (IXFLocation *location in locations) {
                            [_locationPopupButton.menu addItemWithTitle:location.name
                                                                 action:nil
                                                          keyEquivalent:@""];
                        }
                        if ([_locationPopupButton.menu.itemArray count] > 1) {
                            [_locationPopupButton selectItemAtIndex:1];
                            _locationPopupButton.enabled = YES;
                            [self selectLocation];
                        }
                    });
                }
            }];
        // Create a new MKMapRegion with the new span, using the center we want.
        //        MKCoordinateRegion region = { .center = coordinate, .span = span };
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 250, 250);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView setRegion:region animated:YES];
        });
        LOGD(@"Latitude %f, Longitude %f", coordinate.latitude, coordinate.longitude);
    }];
}

- (void)selectLocation
{
    if ([_locationPopupButton indexOfSelectedItem] == 0) {
        taggedLocation = nil;
        [[[_locationSearchField cell] cancelButtonCell] performClick:self];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate, 250, 250);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView setRegion:region animated:YES];
        });
        
        return;
    }
    
    IXFLocation *selected = [nearbyLocations objectAtIndex:[_locationPopupButton indexOfSelectedItem] - 1];
    CLLocationCoordinate2D coordinate = selected.location.coordinate;
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        taggedLocation = selected;
        [self addAnnotation:selected.name withCoordinate:coordinate];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 250, 250);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView setRegion:region animated:YES];
        });
    }
    LOGD(@"selectLocation: %@", selected);
}

#pragma mark - Methods

- (IBAction)selectLocation:(id)sender
{
    [self selectLocation];
}

- (IBAction)searchAddress:(id)sender
{
    if ([[sender stringValue] length] > 0) {
        [self searchLocation:[sender stringValue]];
    }
}

- (void)checkLoginStatus:(NSNotification *)notification
{
    if ([_api allUsers].count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayLoginNotificationKey
                                                                object:self];
        });
    }
}

- (void)updateUsers
{
    [_userPopupButton removeAllItems];
    for (NSString *user in [_api allUsers]) {
        [_userPopupButton.menu addItemWithTitle:user
                                         action:nil
                                  keyEquivalent:@""];
    }
    
    // Invalidate all old user queues.
    for (IXFQueueItem *item in _dataSource) {
        if ([_api userExistsWithName:item.user] == NO &&
            (item.status == IXFQueueStatusAwaiting ||
             (item.status == IXFQueueStatusFailed &&
              item.maxAttempts > 0 &&
              item.retries < item.maxAttempts))) {
                 // User no longer exists
                 item.ends = [NSDate date];
                 item.status = IXFQueueStatusFailed;
                 item.error = [NSString stringWithFormat:@"User \"%@\" Not Found", item.user];
                 item.retries = item.maxAttempts;
             }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_dataSource]
                 forKey:kDataSourceKey];
    [defaults synchronize];
}

- (void)displayTutorial
{
    // Tutorial
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDidShowTutorialKey] == NO) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayPinchViewTipNotificationKey
                                                                    object:self];
            });
        }
    });
}

- (void)displayNews
{
    if (([self.view.window attachedSheet] != nil)) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kNewsSegueIdentifier sender:self];
    });
}

- (void)displayImageHUD:(NSNotification *)notification
{
    IXFFeedItem *item = [[notification userInfo] objectForKey:kImageHUDObjectKey];
    
    if (item != nil) {
        CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
        CGFloat imageWidth = item.width / scale;
        CGFloat imageHeight = item.height / scale;
        
        if (_hudWindow != nil) {
            [_hudWindow close];
        }
        
        _hudWindow = [[NSPanel alloc]
                      initWithContentRect:NSMakeRect(0, //self.view.window.frame.origin.x + (self.view.window.frame.size.width - imageWidth) / 2,
                                                     0, //self.view.window.frame.origin.y + (self.view.window.frame.size.height - imageHeight) / 2,
                                                     imageWidth,
                                                     imageHeight)
                      styleMask:NSHUDWindowMask|NSClosableWindowMask|NSTitledWindowMask|NSUtilityWindowMask
                      backing:NSBackingStoreBuffered
                      defer:NO];
        
        _hudWindow.releasedWhenClosed = NO;
        _hudWindow.hidesOnDeactivate = NO;
        _hudWindow.movableByWindowBackground = YES;
        [_hudWindow setLevel:NSPopUpMenuWindowLevel];
        
        _hudImageView = [[NSImageView alloc] initWithFrame:_hudWindow.contentView.bounds];
        [_hudImageView setAutoresizingMask:NSViewNotSizable];
        [[_hudWindow contentView] addSubview:_hudImageView];
        _hudImageView.image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:item.imageURL]];
        
        [_hudWindow center];
        [_hudWindow makeKeyAndOrderFront:self];
    }
}

- (void)displayCommentEditor:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _feedItem = [[notification userInfo] objectForKey:kFeedObjectKey];
        _comments = [[[notification userInfo] objectForKey:kCommentsObjectKey] mutableCopy];
        
        NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:kDataSourceSortKey
                                                             ascending:YES];
        [_comments sortUsingDescriptors:@[desc]];
        
        LOGD(@"Comments: %@", _comments);
        
        [self performSegueWithIdentifier:kCommentsSegueKey sender:self];
    });
}

- (void)displayCheckpoint:(NSNotification *)notification
{
    _checkpointURL = [[notification userInfo] objectForKey:kCheckpointObjectKey];
    if (_checkpointURL != nil) {
        if (([self.view.window attachedSheet] != nil)) {
            //            LOGD(@"%@", [[[self.view.window attachedSheet] contentViewController] className]);
            if ([[[self.view.window attachedSheet] contentViewController] isKindOfClass:[IXFCheckpointViewController class]]) {
                IXFCheckpointViewController *vc = (IXFCheckpointViewController *)[[self.view.window attachedSheet] contentViewController];
                if ([vc.webview.mainFrameURL isEqualToString:_checkpointURL] == NO) {
                    [vc.webview setMainFrameURL:_checkpointURL];
                }
                return;
            } else if ([[[self.view.window attachedSheet] contentViewController] isKindOfClass:[IXFLoginViewController class]]) {
                IXFLoginViewController *vc = (IXFLoginViewController *)[[self.view.window attachedSheet] contentViewController];
                vc.checkpoint = YES;
                [vc dismiss:self];
                //                [self.view.window endSheet:self.view.window];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:kCheckpointWebViewSegueIdentifier sender:self];
        });
    }
}

- (void)displayPinchViewTip
{
    if ([self.view.window attachedSheet] != nil) {
        // Has sheet opened.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self displayPinchViewTip];
        });
        return;
    }
    
    tutorialMode = YES;
    tutorialStep = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kPinchViewTipSegueIdentifier sender:self];
    });
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kDidShowTutorialKey];
    [defaults synchronize];
}

- (IBAction)shareAction:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (_pinchView.imageView.image == nil) {
            return;
        }
        
        NSImage *image = nil;
        if (_pinchView.isSquareMode == YES) {
            image = [[_pinchView.imageView.image visiableImage:_pinchView.imageView.visibleRect]
                     squaredResizeWithMaxLength:kInstagramSize];
        } else {
            image = [[_pinchView.imageView.image visiableImage:_pinchView.imageView.visibleRect]
                     resizeWithMaxLength:kInstagramSize];
        }
        if (image == nil) {
            return;
        }
        
        IXFUser *user = [_api userWithName:[_userPopupButton selectedItem].title];
        
        if (user == nil) {
            _statusLabel.stringValue = @"Selected User No Longer Exists";
            _statusLabel.textColor = kStatusErrorColor;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
                                                                    object:self];
            });
            return;
        }
        
        NSDate *date;
        NSCalendar *calender = [NSCalendar currentCalendar];
        [calender rangeOfUnit:NSCalendarUnitNanosecond
                    startDate:&date
                     interval:NULL
                      forDate:_datePicker.dateValue];
        
        IXFQueueItem *queueItem;
        if (_pinchView.videoData != nil && _pinchView.videoMeta != nil) {
            queueItem = [[IXFQueueItem alloc] initWithUser:user
                                                     image:image
                                                     video:_pinchView.videoData
                                                 videoMeta:_pinchView.videoMeta
                                                   caption:_captionField.stringValue
                                                      date:date
                                                  location:taggedLocation
                                                      mode:IXFQueueVideo
                                                     frame:_previewSlider.floatValue];
        } else if (_pinchView.videoData == nil && _pinchView.videoMeta == nil) {
            queueItem = [[IXFQueueItem alloc] initWithUser:user
                                                     image:image
                                                   caption:_captionField.stringValue
                                                      date:date
                                                  location:taggedLocation
                                                      mode:IXFQueueImage];
        } else {
            _statusLabel.stringValue = @"Unable to Create the Queue";
            _statusLabel.textColor = kStatusErrorColor;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kStatusDidChangedNotificationKey
                                                                    object:self];
            });
            return;
        }
        
        if (_attemptSlider.integerValue > 0) {
            queueItem.maxAttempts = _attemptSlider.integerValue;
        }
        
        if (queueItem != nil) {
            [_dataSource addObject:queueItem];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kDataSourceDidChangedNotificationKey
                                                                    object:self];
            });
        }
        
        if ([[_datePicker.minDate earlierDate:[NSDate date]] isEqualToDate:_datePicker.minDate]) {
            _datePicker.minDate = [NSDate date];
        }
        if ([[_datePicker.dateValue earlierDate:[NSDate date]] isEqualToDate:_datePicker.dateValue]) {
            _datePicker.dateValue = [NSDate date];
        }
    });
}

- (BOOL)resetCheck
{
    if (_pinchView.imageView.image != nil ||
        _captionField.stringValue.length != 0) {
        
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Queue Not Scheduled";
        alert.informativeText = @"If continued, your current editing status will be lost.\n\nDo you wish to continue?";
        alert.alertStyle = NSCriticalAlertStyle;
        
        [alert addButtonWithTitle:@"Continue"];
        [alert addButtonWithTitle:@"Cancel"];
        
        // Move window to forground.
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
        
        if ([alert runModal] != NSAlertFirstButtonReturn) {
            return NO;
        }
    }
    
    [_pinchView setImage:nil];
    _previewSlider.hidden = YES;
    _zoomButton.hidden = YES;
    _squareModeSwitch.hidden = YES;
    
    _captionField.stringValue = @"";
    _datePicker.dateValue = [NSDate date];
    _attemptSlider.integerValue = 3;
    [self attemptsChanged:_attemptSlider];
    
    _locationPopupButton.enabled = NO;
    [_locationPopupButton removeAllItems];
    [_locationPopupButton.menu addItemWithTitle:kDisabledGeoTaggingString
                                         action:nil
                                  keyEquivalent:@""];
    nearbyLocations = nil;
    [_locationPopupButton selectItemAtIndex:0];
    [self selectLocation];
    [_userPopupButton selectItemWithTitle:_api.user.name];
    
    return YES;
}

- (IBAction)reset:(id)sender
{
    [self resetCheck];
}

- (void)importFromOpen:(NSUserNotification *)notification
{
    if ([self resetCheck]) {
        NSURL *URL = (NSURL *)[[notification userInfo] objectForKey:kOpenFileObjectKey];
        [self importFromURL:URL];
    }
}

- (void)importFromURL:(NSURL *)URL
{
    NSData *data = [[NSData alloc] initWithContentsOfURL:URL];
    if (data != nil) {
        IXFQueueItem *queueItem = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (queueItem != nil) {
            if ([self loadQueueItem:queueItem] == YES) {
                [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:URL];
                return;
            }
        }
    }
    
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"File Can't be Loaded";
    alert.informativeText = @"We were unable to load this file. Please check your selection and try again later.\n\nIf believe it's a mistake, please contact the developer with the file.";
    alert.alertStyle = NSCriticalAlertStyle;
    
    [alert addButtonWithTitle:@"OK"];
    
    // Move window to forground.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
    
    [alert runModal];
}

- (IBAction)import:(id)sender
{
    if ([self resetCheck]) {
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel setAllowedFileTypes:@[kIXFQueueItemFileExtension]];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanCreateDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setTitle:@"Import an Inxtify Queue File"];
        
//        openPanel.styleMask = NSTitledWindowMask;
//        openPanel.contentView.wantsLayer = YES;
//        openPanel.contentView.window.appearance = self.view.window.appearance;
        
        [openPanel beginSheetModalForWindow:self.view.window
                          completionHandler:^(NSInteger result)
         {
             if (result == NSFileHandlingPanelOKButton) {
                 NSURL *URL = [[openPanel URLs] firstObject];
                 [self importFromURL:URL];
             }
         }];
    }
}

- (IBAction)export:(id)sender
{
    if (_pinchView.imageView.image == nil) {
        
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Empty Queue";
        alert.informativeText = @"You have to choose one image or video to create an Inxtify Queue File.";
        alert.alertStyle = NSCriticalAlertStyle;
        
        [alert addButtonWithTitle:@"OK"];
        
        // Move window to forground.
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
        
        [alert runModal];
        
        return;
    }
    
    NSDateFormatter *dateFormatter;
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyyMMdd_HHmmss";
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    [savePanel setAllowedFileTypes:@[kIXFQueueItemFileExtension]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setExtensionHidden:NO];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setTitle:@"Export as an Inxtify Queue File"];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@_%@.ixf",
                                        _api.user.name,
                                        [dateFormatter stringFromDate:[NSDate date]]]];
    
//    savePanel.styleMask = NSTitledWindowMask;
//    savePanel.contentView.wantsLayer = YES;
//    savePanel.contentView.window.appearance = self.view.window.appearance;
//    
//    [savePanel runModal];
    
    [savePanel beginSheetModalForWindow:self.view.window
                      completionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSImage *image = nil;
            
            if (_pinchView.imageView.image != nil) {
                
                if (_pinchView.isSquareMode == YES) {
                    image = [[_pinchView.imageView.image visiableImage:_pinchView.imageView.visibleRect]
                             squaredResizeWithMaxLength:kInstagramSize];
                } else {
                    image = [[_pinchView.imageView.image visiableImage:_pinchView.imageView.visibleRect]
                             resizeWithMaxLength:kInstagramSize];
                }
                
            }
            
            if (image == nil) {
                goto failed;
            }
            
            NSDate *date;
            NSCalendar *calender = [NSCalendar currentCalendar];
            [calender rangeOfUnit:NSCalendarUnitMinute
                        startDate:&date
                         interval:NULL
                          forDate:_datePicker.dateValue];
            
            IXFQueueItem *queueItem;
            if (_pinchView.videoData != nil && _pinchView.videoMeta != nil) {
                queueItem = [[IXFQueueItem alloc] initWithUser:_api.user
                                                         image:image
                                                         video:_pinchView.videoData
                                                     videoMeta:_pinchView.videoMeta
                                                       caption:_captionField.stringValue
                                                          date:date
                                                      location:taggedLocation
                                                          mode:IXFQueueVideo
                                                         frame:_previewSlider.floatValue];
            } else if (_pinchView.videoData == nil && _pinchView.videoMeta == nil) {
                queueItem = [[IXFQueueItem alloc] initWithUser:_api.user
                                                         image:image
                                                       caption:_captionField.stringValue
                                                          date:date
                                                      location:taggedLocation
                                                          mode:IXFQueueImage];
            } else {
                goto failed;
            }
            
            if (_attemptSlider.integerValue > 0) {
                queueItem.maxAttempts = _attemptSlider.integerValue;
            }
            
            NSData *queueData = [NSKeyedArchiver archivedDataWithRootObject:queueItem];
            
            if (queueData == nil) {
                goto failed;
            }
            
            [queueData writeToURL:[savePanel URL] atomically:YES];
        }
        
        return;
        
    failed: {
        
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Queue Not Saved";
        alert.informativeText = @"Can't not create file from the image or its settings.\n\nIf this occored again, please contact the developer with the regarding images and settings.";
        alert.alertStyle = NSCriticalAlertStyle;
        
        [alert addButtonWithTitle:@"OK"];
        
        // Move window to forground.
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [[[NSApplication sharedApplication] windows][0] makeKeyAndOrderFront:self];
        
        [alert runModal];
    }
    }];
    
}

- (void)loadQueueItemWithNotification:(NSNotification *)notification
{
    IXFQueueItem *item = [[notification userInfo] objectForKey:kQueueEditObjectKey];
    
    if (item == nil) {
        return;
    }
    
    [self loadQueueItem:item];
    
}

- (BOOL)loadQueueItem:(IXFQueueItem *)item
{
    if (item == nil) {
        return NO;
    }
    
    [_pinchView setImage:item.image];
    
    if (item.mode == IXFQueueVideo) {
        _pinchView.videoData = item.video;
        _pinchView.videoMeta = item.videoMeta;
        CGFloat duration = [_pinchView videoDurationSeconds];
        if (duration > 0) {
            _previewSlider.maxValue = floor(duration);
            _previewSlider.floatValue = MIN(MAX(item.videoFrame, _previewSlider.minValue), _previewSlider.maxValue);
            _previewSlider.numberOfTickMarks = _previewSlider.maxValue + 1;
            _previewSlider.hidden = NO;
            _zoomButton.hidden = YES;
            _squareModeSwitch.hidden = YES;
        }
    } else {
        _pinchView.videoData = nil;
        _pinchView.videoMeta = nil;
        _previewSlider.hidden = YES;
        
        [self adjustZoom];
        _zoomButton.hidden = NO;
        _squareModeSwitch.hidden = NO;
    }
    _captionField.stringValue = item.caption;
    _datePicker.dateValue = item.date;
    _attemptSlider.integerValue = item.maxAttempts;
    [self attemptsChanged:_attemptSlider];
    
    _locationPopupButton.enabled = NO;
    [_locationPopupButton removeAllItems];
    [_locationPopupButton.menu addItemWithTitle:kDisabledGeoTaggingString
                                         action:nil
                                  keyEquivalent:@""];
    
    if (item.location != nil) {
        nearbyLocations = [NSArray arrayWithObject:item.location];
        [_locationPopupButton.menu addItemWithTitle:item.location.name
                                             action:nil
                                      keyEquivalent:@""];
        [_locationPopupButton selectItemAtIndex:1];
        _locationPopupButton.enabled = YES;
    } else {
        nearbyLocations = nil;
        [_locationPopupButton selectItemAtIndex:0];
    }
    [self selectLocation];
    
    [_userPopupButton selectItemWithTitle:item.user];
    
    return YES;
}

- (IBAction)sliderDidSlided:(id)sender
{
    [_pinchView changePreviewFrame:_previewSlider.floatValue];
}

- (void)adjustZoom
{
    [_zoomButton setEnabled:[_pinchView canZoomOut] forSegment:0];
    [_zoomButton setEnabled:[_pinchView canZoomIn]  forSegment:1];
}

- (IBAction)zoomInOut:(NSSegmentedControl *)sender
{
    if (_pinchView.imageView.image != nil) {
        switch (sender.selectedSegment) {
            case 0:
                [_pinchView zoomOut];
                break;
            default:
                [_pinchView zoomIn];
                break;
        }
    }
    [self adjustZoom];
}

- (IBAction)attemptsChanged:(NSSlider *)sender
{
    if (sender.integerValue) {
        _attemptLabel.stringValue = [NSString stringWithFormat:@"%ldx",
                                     sender.integerValue];
    } else {
        _attemptLabel.stringValue = @"";
    }
}

- (void)userInfoDidChanged:(NSNotification *)notification
{
    IXFUser *user = [[notification userInfo] objectForKey:kUserObjectKey];
    if (user != nil) {
        [_userPopupButton selectItemWithTitle:user.name];
        if ([_userPopupButton selectedItem] == nil) {
            [_userPopupButton selectItemAtIndex:0];
        }
    }
}

- (void)dataSourceDidChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger done = 0;
        NSUInteger failed = 0;
        NSUInteger inProgress = 0;
        for (IXFQueueItem *item in _dataSource) {
            if (item.status == IXFQueueStatusFailed) {
                failed++;
                done++;
            } else if (item.status == IXFQueueStatusDone) {
                done++;
            } else if (item.status == IXFQueueStatusInProgress) {
                inProgress++;
            }
        }
        NSUInteger total = _dataSource.count;
        NSUInteger remain = total - done;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *status = @"";
            NSColor *statusColor = [NSColor disabledControlTextColor];
            if (remain > 0) {
                NSApplication.sharedApplication.dockTile.badgeLabel = [NSString stringWithFormat:@"%ld", remain];
            } else {
                NSApplication.sharedApplication.dockTile.badgeLabel = nil;
            }
            _statusProgress.hidden = YES;
            if (total == 0 || remain == 0) {
                status = @"No scheduled items";
            } else {
                status = [NSString stringWithFormat:@"%ld of %ld remaining",
                          remain,
                          total];
                _statusProgress.toolTip = [NSString stringWithFormat:@"Queue: %.f%%", roundf(done / total * 100.f)];
                _statusProgress.hidden = NO;
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = 1.f;
                    _statusProgress.animator.maxValue = _dataSource.count;
                    _statusProgress.animator.doubleValue = done;
                } completionHandler:nil];
                if (inProgress != 0) {
                    status = @"Processing";
                    if (failed == 0) {
                        status = [NSString stringWithFormat:@"%@...", status];
                    }
                    _statusProgress.indeterminate = YES;
                    [_statusProgress startAnimation:self];
                    statusColor = kStatusWarningColor;
                } else {
                    _statusProgress.indeterminate = NO;
                    [_statusProgress stopAnimation:self];
                }
            }
            if (failed > 0) {
                status = [NSString stringWithFormat:@"%@, %ld error%@",
                          status,
                          failed,
                          (failed > 1) ? @"s" : @""];
                statusColor = kStatusErrorColor;
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kQueuePausedKey] == YES) {
                status = [NSString stringWithFormat:@"%@ (Paused)", status];
                statusColor = kStatusWarningColor;
            }
            if (inProgress != 0) {
                statusColor = kStatusWarningColor;
            }
            if ([status isEqualToString:_statusLabel.stringValue] == NO) {
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = .2f;
                    _statusLabel.animator.alphaValue = .0f;
                } completionHandler:^{
                    _statusLabel.stringValue = status;
                    _statusLabel.textColor = statusColor;
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = .2f;
                        _statusLabel.animator.alphaValue = 1.f;
                    } completionHandler:nil];
                }];
            }
        });
    });
}

- (void)displayLogin:(NSNotification *)notification
{
    if (([self.view.window attachedSheet] != nil)) {
        if (![[[self.view.window attachedSheet] contentViewController] isKindOfClass:[IXFCheckpointViewController class]] &&
            ![[[self.view.window attachedSheet] contentViewController] isKindOfClass:[IXFLoginViewController class]]) {
            [self.view.window endSheet:self.view.window];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
    });
}

@end
