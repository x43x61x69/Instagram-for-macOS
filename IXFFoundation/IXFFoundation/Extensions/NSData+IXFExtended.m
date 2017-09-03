//
//  NSData+IXFExtended.m
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

#import "NSData+IXFExtended.h"

@implementation NSData (IXFExtended)

- (nullable NSString *)hexEncoding
{
    NSMutableString *result = [NSMutableString string];
    unsigned char *bytes = (unsigned char *)[self bytes];
    char temp[3];
    int i = 0;
    for (i = 0; i < [self length]; i++) {
        temp[0] = temp[1] = temp[2] = 0;
        (void)sprintf(temp, "%02x", bytes[i]);
        [result appendString:[NSString stringWithUTF8String:temp]];
    }
    return result;
}

#pragma mark - EXIF

- (nullable NSDictionary *)EXIF
{
    if (self != nil) {
        
        NSDictionary *exifDict = nil;
        
        // load the bit image from the file url
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self,
                                                              NULL);
        if (source != nil) {
            // get image properties into a dictionary
            CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex(source,
                                                                             0,
                                                                             NULL);
            if (metadataRef != nil) {
                // cast CFDictonaryRef to NSDictionary
                exifDict = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)metadataRef];
                CFRelease(metadataRef);
            }
            CFRelease(source);
            return exifDict;
        }
    }
    return nil;
}

#pragma mark - GPS

- (CLLocationCoordinate2D)GPS
{
    NSDictionary *exifDict = [self EXIF];
    
    if (!exifDict) {
        return kCLLocationCoordinate2DInvalid;
    }
    
    id gps = [exifDict objectForKey:@"{GPS}"];
    
    if (gps != nil) {
        
        double latitude = [[gps valueForKey:@"Latitude"] doubleValue];
        double longitude = [[gps valueForKey:@"Longitude"] doubleValue];
        
        //We need to check whether the latitude is north or south latitude. The ASCII value 'N' indicates north latitude, and 'S' is south latitude
        if([[gps valueForKey:@"LatitudeRef"] isEqualToString:@"S"]) {
            latitude = latitude * -1.f; //We make it a negative value if it belongs to south
        }
        
        //Similarly check whether longitude is east or west
        if([[gps valueForKey:@"LongitudeRef"] isEqualToString:@"W"]) {
            longitude = longitude * -1.f; //We make it a negative value if it belongs to west
        }
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            return coordinate;
        }
    }
    return kCLLocationCoordinate2DInvalid;
}

#pragma mark - Video Methods

- (nullable NSImage *)previewImage
{
    return [self previewImage:.0f];
}

- (nullable AVAsset *)AVAsset
{
    // If we don't give it an extension that AVFundation supports, it will end
    // up with CGImage Error.
    NSString *tempPath = [NSString stringWithFormat:@"%@.mov", [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:tempPath
                     contents:self
                   attributes:nil];
    
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:tempPath]
                                             options:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       [manager removeItemAtPath:tempPath error:nil];
                   });
    
    return asset;
}

- (nullable NSImage *)previewImage:(CGFloat)seconds
{
    AVAsset *asset = [self AVAsset];
    
    if (asset == nil) {
        return nil;
    }
    
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CMTime duration = asset.duration;
//    CGFloat durationInSeconds = duration.value / duration.timescale;
    CMTime time = CMTimeMakeWithSeconds(seconds, (int)duration.value);
    NSError *err;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time
                                                 actualTime:NULL
                                                      error:&err];
    
    if (err != nil) {
        LOGD(@"%@", [err description]);
        return nil;
    }
    
    CIImage *image = [CIImage imageWithCGImage:imageRef];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:image];
    NSImage *result = [[NSImage alloc] initWithSize:rep.size];
    [result addRepresentation:rep];
    CGImageRelease(imageRef);
    
    return [result resize:kInstagramUploadMaxSize];
}

@end
