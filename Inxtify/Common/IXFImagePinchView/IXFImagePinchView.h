//
//  IXFImagePinchView.h
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

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "IXFImagePinchClipView.h"
#import "IXFImagePinchImageView.h"

@protocol IXFImagePinchViewDelegate <NSObject>
@optional
- (void)newQueueItem:(NSURL *)URL;
- (void)newQueueImage:(NSURL *)URL;
- (void)newQueueVideo:(NSURL *)URL;
@end

@interface IXFImagePinchView : NSScrollView <IXFImagePinchImageViewDelegate>

@property (nonatomic, assign) id <IXFImagePinchViewDelegate> delegate;

@property (nonatomic, strong) IXFImagePinchImageView    *imageView;
@property (nonatomic, strong) IXFImagePinchClipView     *clipView;
@property (nonatomic)         NSRect                    previousRect;
@property (nonatomic)         CGFloat                   previousMagnification;

@property (nonatomic, strong) AVAsset                   *videoAsset;
@property (nonatomic, strong) NSMutableDictionary       *videoPreviews;
@property (nonatomic, strong) NSData                    *videoData;
@property (nonatomic, strong) NSDictionary              *videoMeta;

@property (nonatomic, strong) NSString                  *watchedPath;
//@property (nonatomic)         BOOL                      shouldStop;
@property (nonatomic)         BOOL                      isSquareMode;
@property (nonatomic)         BOOL                      isReadable;

- (void)setImage:(NSImage *)image;
- (void)changePreviewFrame:(CGFloat)seconds;
- (CGFloat)videoPixelHeight;
- (CGFloat)videoPixelWidth;
- (CGFloat)videoDurationSeconds;
- (void)zoomIn;
- (void)zoomOut;
- (BOOL)canZoomIn;
- (BOOL)canZoomOut;

@end
