//
//  IXFContentViewController.h
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

#define kResetEditorNotificationKey     @"ResetEditorNotificationKey"
#define kExportEditorNotificationKey    @"ExportEditorNotificationKey"
#define kImportEditorNotificationKey    @"ImportEditorNotificationKey"

#define kDidShowTutorialKey             @"DidShowTutorialKey"
#define kNewsSegueIdentifier            @"NewsSegue"
#define kCheckpointWebViewSegueIdentifier   @"CheckpointWebViewSegue"
#define kPinchViewTipSegueIdentifier    @"PinchViewTipSegue"
#define kLocationTipSegueIdentifier     @"LocationTipSegue"
#define kCaptionTipSegueIdentifier      @"CaptionTipSegue"
#define kRetriesTipSegueIdentifier      @"RetriesTipSegue"
#define kScheduleTipSegueIdentifier     @"ScheduleTipSegue"
#define kUserTipSegueIdentifier         @"UserTipSegue"
#define kSendTipSegueIdentifier         @"SendTipSegue"

#define kPinchViewZoomTipSegueIdentifier        @"PinchViewZoomTipSegue"
#define kPinchViewVideoCoverTipSegueIdentifier  @"PinchViewVideoCoverTipSegue"

#define kShouldDisplayNewsNotificationKey @"ShouldDisplayNewsNotificationKey"

#define kShouldDisplayPinchViewTipNotificationKey @"ShouldDisplayPinchViewTipNotificationKey"

#define kShouldDisplayPinchViewZoomTipNotificationKey @"ShouldDisplayPinchViewZoomTipNotificationKey"
#define kShouldDisplayPinchViewVideoCoverTipNotificationKey @"ShouldDisplayPinchViewVideoCoverTipNotificationKey"

#import <Cocoa/Cocoa.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "AppDelegate.h"
#import "IXFImagePinchView.h"

@interface IXFContentViewController : NSViewController <
IXFImagePinchViewDelegate,
NSControlTextEditingDelegate
>

@property (nonatomic, assign) IXFFoundation *api;
@property (nonatomic, assign) NSMutableArray *dataSource;
@property (nonatomic, strong) NSString *checkpointURL;
@property (nonatomic, strong) NSPanel *hudWindow;
@property (nonatomic, strong) NSImageView *hudImageView;

@property (nonatomic, strong) IXFFeedItem *feedItem;
@property (nonatomic, strong) NSMutableArray<IXFCommentItem *> *comments;

@property (nonatomic) BOOL  isAutocompleting;
@property (nonatomic) BOOL  backspaceKey;

@property (weak) IBOutlet NSVisualEffectView *background;

@property (weak) IBOutlet IXFImagePinchView *pinchView;
@property (weak) IBOutlet NSSlider          *previewSlider;
@property (weak) IBOutlet NSSegmentedControl *zoomButton;
@property (weak) IBOutlet NSTextField       *captionField;
@property (weak) IBOutlet NSSearchField     *locationSearchField;
@property (weak) IBOutlet NSPopUpButton     *locationPopupButton;
@property (weak) IBOutlet NSPopUpButton     *userPopupButton;
@property (weak) IBOutlet MKMapView         *mapView;
@property (weak) IBOutlet NSDatePicker      *datePicker;
@property (weak) IBOutlet NSTextField       *statusLabel;
@property (weak) IBOutlet NSProgressIndicator *statusProgress;
@property (weak) IBOutlet NSSlider          *attemptSlider;
@property (weak) IBOutlet NSTextField       *attemptLabel;
@property (weak) IBOutlet ITSwitch          *squareModeSwitch;


- (BOOL)loadQueueItem:(IXFQueueItem *)queueItem;
- (IBAction)zoomInOut:(NSSegmentedControl *)sender;

@end
