//
//  IXFQueueItem.m
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

#import "IXFQueueItem.h"

@implementation IXFQueueItem

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _UUID       = [decoder decodeObjectForKey:@"UUID"];
        _user       = [decoder decodeObjectForKey:@"user"];
        _date       = [decoder decodeObjectForKey:@"date"];
        _ends       = [decoder decodeObjectForKey:@"ends"];
        _caption    = [decoder decodeObjectForKey:@"caption"];
        _URL        = [decoder decodeObjectForKey:@"URL"];
        _image      = [decoder decodeObjectForKey:@"image"];
        _video      = [decoder decodeObjectForKey:@"video"];
        _videoMeta  = [decoder decodeObjectForKey:@"videoMeta"];
        _videoURL   = [decoder decodeObjectForKey:@"videoURL"];
        _videoJob   = [decoder decodeObjectForKey:@"videoJob"];
        _videoResult= [decoder decodeObjectForKey:@"videoResult"];
        _videoStage = [decoder decodeIntegerForKey:@"videoStage"];
        _mediaID    = [decoder decodeObjectForKey:@"mediaID"];
        _error      = [decoder decodeObjectForKey:@"error"];
        _location   = [decoder decodeObjectForKey:@"location"];
        _mode       = [decoder decodeIntegerForKey:@"mode"];
        _status     = [decoder decodeIntegerForKey:@"status"];
        _userIdentifier = [decoder decodeIntegerForKey:@"userIdentifier"];
        _maxAttempts= [decoder decodeIntegerForKey:@"maxAttempts"];
        _retries    = [decoder decodeIntegerForKey:@"retries"];
        _videoFrame = [decoder decodeFloatForKey:@"videoFrame"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_UUID         forKey:@"UUID"];
    [encoder encodeObject:_user         forKey:@"user"];
    [encoder encodeObject:_date         forKey:@"date"];
    [encoder encodeObject:_ends         forKey:@"ends"];
    [encoder encodeObject:_caption      forKey:@"caption"];
    [encoder encodeObject:_URL          forKey:@"URL"];
    [encoder encodeObject:_image        forKey:@"image"];
    [encoder encodeObject:_video        forKey:@"video"];
    [encoder encodeObject:_videoMeta    forKey:@"videoMeta"];
    [encoder encodeObject:_videoURL     forKey:@"videoURL"];
    [encoder encodeObject:_videoJob     forKey:@"videoJob"];
    [encoder encodeObject:_videoResult  forKey:@"videoResult"];
    [encoder encodeInteger:_videoStage  forKey:@"videoStage"];
    [encoder encodeObject:_mediaID      forKey:@"mediaID"];
    [encoder encodeObject:_error        forKey:@"error"];
    [encoder encodeObject:_location     forKey:@"location"];
    [encoder encodeInteger:_mode        forKey:@"mode"];
    [encoder encodeInteger:_status      forKey:@"status"];
    [encoder encodeInteger:_retries     forKey:@"retries"];
    [encoder encodeInteger:_userIdentifier forKey:@"userIdentifier"];
    [encoder encodeInteger:_maxAttempts forKey:@"maxAttempts"];
    [encoder encodeFloat:_videoFrame    forKey:@"videoFrame"];
}

- (nullable instancetype)initWithUser:(nonnull IXFUser *)user
                                image:(nonnull NSImage *)image
                              caption:(nullable NSString *)caption
                                 date:(nullable NSDate *)date
                             location:(nullable IXFLocation *)location
                                 mode:(IXFQueueImageMode)mode
{
    if (self = [super init]) {
        if (user.name != nil &&
            user.identifier > 0) {
            _user = user.name;
            _userIdentifier = user.identifier;
            _image = image;
            _caption = caption;
            _date = (date == nil) ? [NSDate date] : date;
            _location = location;
            _mode = (IXFQueueMode)mode;
            return self;
        }
    }
    return nil;
}

- (nullable instancetype)initWithUser:(nonnull IXFUser *)user
                                image:(nonnull NSImage *)image
                                video:(nonnull NSData *)video
                            videoMeta:(nonnull NSDictionary *)videoMeta
                              caption:(nullable NSString *)caption
                                 date:(nullable NSDate *)date
                             location:(nullable IXFLocation *)location
                                 mode:(IXFQueueVideoMode)mode
                                frame:(CGFloat)frame
{
    if (self = [super init]) {
        if (user.name != nil &&
            user.identifier > 0) {
            _user = user.name;
            _userIdentifier = user.identifier;
            _image = image;
            _video = video;
            _videoMeta = videoMeta;
            _videoStage = 0;
            _caption = caption;
            _date = (date == nil) ? [NSDate date] : date;
            _location = location;
            _mode = (IXFQueueMode)mode;
            _videoFrame = frame;
            return self;
        }
    }
    return nil;
}

- (BOOL)isDraft
{
    return (_date == nil) == YES;
}

- (BOOL)isDue
{
    NSDate *dueDate;
    NSCalendar *calender = [NSCalendar currentCalendar];
    [calender rangeOfUnit:NSCalendarUnitMinute
                startDate:&dueDate
                 interval:NULL
                  forDate:_date];
    
    return [[dueDate earlierDate:[NSDate date]] isEqualToDate:dueDate];
}

- (nullable NSString *)timestemp
{
    if (_date == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%.f", [_date timeIntervalSince1970] * 1000];
    // [NSString stringWithFormat:@"%lli", [@(floor([_date timeIntervalSince1970] * 1000)) longLongValue]];
}

- (nullable NSArray *)imageSize
{
    if (_image == nil) {
        return nil;
    }
    CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
    return @[@([[NSString stringWithFormat:@"%.f", roundf(_image.size.width * scale)] floatValue]),
             @([[NSString stringWithFormat:@"%.f", roundf(_image.size.height * scale)] floatValue])];
}

- (CGFloat)videoPixelHeight
{
    if (_videoMeta == nil) {
        return .0f;
    }
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemPixelHeight] floatValue];
}

- (CGFloat)videoPixelWidth
{
    if (_videoMeta == nil) {
        return .0f;
    }
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemPixelWidth] floatValue];
}

- (CGFloat)videoDurationSeconds
{
    if (_mode != IXFQueueModeVideo ||
        _videoMeta == nil) {
        return .0f;
    }
    
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemDurationSeconds] floatValue];
}

- (CLLocationCoordinate2D)coordinate
{
    return _location.location.coordinate;
}

- (void)generateUUID
{
    _UUID = [[[NSUUID UUID] UUIDString] lowercaseString];
}

- (nullable NSData *)videoChunk
{
    NSUInteger length = kInstagramVideoChunk;
    NSUInteger offset = [self currentStageOffset];
    
    if (offset >= _video.length) {
        return nil;
    }
    
    if (_video.length < offset + length) {
        length = _video.length % kInstagramVideoChunk;
    }
    return [_video subdataWithRange:NSMakeRange(offset, length)];
}

- (NSUInteger)currentStageOffset
{
    return kInstagramVideoChunk * _videoStage;
}

@end
