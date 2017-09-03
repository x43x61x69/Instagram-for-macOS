//
//  IXFQueueItem.h
//  IXFFoundation
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

#define kQueueEditNotificationKey   @"QueueEditNotification"
#define kQueueEditObjectKey         @"IXFQueueEditObjectKey"

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "IXFUser.h"
#import "IXFLocation.h"

typedef enum : NSInteger {
    IXFQueueModeImage       = 0x0,
    IXFQueueModeMatrixImage = 0x1,
    
    IXFQueueModeVideo       = 0x1 << 1
} IXFQueueMode;

typedef enum : NSInteger {
    IXFQueueImage       = IXFQueueModeImage,
    IXFQueueMatrixImage = IXFQueueModeMatrixImage
} IXFQueueImageMode;

typedef enum : NSInteger {
    IXFQueueVideo       = IXFQueueModeVideo
} IXFQueueVideoMode;

typedef enum : NSInteger {
    IXFQueueStatusAwaiting  = 0x0,
    IXFQueueStatusFailed    = 0x1,
    IXFQueueStatusDone      = 0x2,
    IXFQueueStatusInProgress = 0x3,
} IXFQueueStatus;

@interface IXFQueueItem : NSObject

@property (nonatomic, copy, nonnull)    NSString                *UUID;
@property (nonatomic, copy, nonnull)    NSString                *user;
@property (nonatomic, copy, nullable)   NSDate                  *date;
@property (nonatomic, copy, nullable)   NSDate                  *ends;
@property (nonatomic, copy, nonnull)    NSString                *caption;
@property (nonatomic, copy, nullable)   NSURL                   *URL;
@property (nonatomic, copy, nonnull)    NSImage                 *image;
@property (nonatomic, copy, nullable)   NSData                  *video;
@property (nonatomic, copy, nullable)   NSDictionary            *videoMeta;
@property (nonatomic, assign)           NSUInteger              videoStage;
@property (nonatomic, copy, nullable)   NSString                *videoURL;
@property (nonatomic, copy, nullable)   NSString                *videoJob;
@property (nonatomic, copy, nullable)   NSString                *videoResult;
@property (nonatomic, copy, nullable)   NSString                *mediaID;
@property (nonatomic, copy, nullable)   NSString                *error;
@property (nonatomic, copy, nullable)   IXFLocation             *location;
@property (nonatomic, assign)           IXFQueueMode            mode;
@property (nonatomic, assign)           IXFQueueStatus          status;
@property (nonatomic, assign)           NSInteger               userIdentifier;
@property (nonatomic, assign)           NSUInteger              maxAttempts;
@property (nonatomic, assign)           NSUInteger              retries;
@property (nonatomic, assign)           CGFloat                 videoFrame;
// Finished Date!

- (nullable instancetype)initWithUser:(nonnull IXFUser *)user
                                image:(nonnull NSImage *)image
                              caption:(nullable NSString *)caption
                                 date:(nullable NSDate *)date
                             location:(nullable IXFLocation *)location
                                 mode:(IXFQueueImageMode)mode;
- (nullable instancetype)initWithUser:(nonnull IXFUser *)user
                                image:(nonnull NSImage *)image
                                video:(nonnull NSData *)video
                            videoMeta:(nonnull NSDictionary *)videoMeta
                              caption:(nullable NSString *)caption
                                 date:(nullable NSDate *)date
                             location:(nullable IXFLocation *)location
                                 mode:(IXFQueueVideoMode)mode
                                frame:(CGFloat)frame;
- (BOOL)isDraft;
- (BOOL)isDue;
- (nullable NSArray *)imageSize;
- (nullable NSString *)timestemp;
- (CGFloat)videoPixelHeight;
- (CGFloat)videoPixelWidth;
- (CGFloat)videoDurationSeconds;
- (CLLocationCoordinate2D)coordinate;
- (void)generateUUID;
- (nullable NSData *)videoChunk;
- (NSUInteger)currentStageOffset;

@end
