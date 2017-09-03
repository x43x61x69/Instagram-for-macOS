//
//  NSURL+IXFExtended.m
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

#import "NSURL+IXFExtended.h"

@implementation NSURL (IXFExtended)

#pragma mark - EXIF

- (nullable NSDictionary *)EXIF
{
    if (self != nil) {
        
        NSDictionary *exifDict = nil;
        
        // load the bit image from the file url
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)self,
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
            
            LOGD(@"EXIF: %@", exifDict);
            
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

@end
