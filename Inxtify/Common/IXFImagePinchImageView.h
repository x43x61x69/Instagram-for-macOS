//
//  IXFImagePinchImageView.h
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

#define kPinchViewZoomDidChangedNotificationKey @"PinchViewZoomDidChangedNotificationKey"

#import <Cocoa/Cocoa.h>

@protocol IXFImagePinchImageViewDelegate <NSObject>
@optional
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingEnded:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
@end

@interface IXFImagePinchImageView : NSImageView {
    NSPoint lastDragLocation;
    NSPoint lastOrigin;
}

@property (nonatomic, assign)   id <IXFImagePinchImageViewDelegate> delegate;
@property (nonatomic, retain)   NSTrackingArea *trackingArea;

@end
