//
//  IXFLocation.m
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

#import "IXFLocation.h"

@implementation IXFLocation

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _name               = [decoder decodeObjectForKey:@"name"];
        _address            = [decoder decodeObjectForKey:@"address"];
        _externalIDSource   = [decoder decodeObjectForKey:@"externalIDSource"];
        _location           = [decoder decodeObjectForKey:@"location"];
        _latitude           = [decoder decodeObjectForKey:@"latitude"];
        _longitude          = [decoder decodeObjectForKey:@"longitude"];
        _externalID         = [decoder decodeIntegerForKey:@"externalID"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_name             forKey:@"name"];
    [encoder encodeObject:_address          forKey:@"address"];
    [encoder encodeObject:_externalIDSource forKey:@"externalIDSource"];
    [encoder encodeObject:_location         forKey:@"location"];
    [encoder encodeObject:_latitude         forKey:@"latitude"];
    [encoder encodeObject:_longitude        forKey:@"longitude"];
    [encoder encodeInteger:_externalID      forKey:@"externalID"];
}

- (nullable NSDictionary *)locationDictionary
{
    if (![_name length] ||
        ![_address length] ||
        !CLLocationCoordinate2DIsValid(_location.coordinate)) {
        return nil;
    }
    
    NSMutableDictionary *locationDict = [NSMutableDictionary new];
    
    [locationDict setObject:_name               forKey:@"name"];
    [locationDict setObject:_address            forKey:@"address"];
    [locationDict setObject:[NSString stringWithFormat:@"%@", _latitude]   forKey:@"lat"];
    [locationDict setObject:[NSString stringWithFormat:@"%@", _longitude]  forKey:@"lng"];
    [locationDict setObject:_externalIDSource   forKey:@"external_source"];
    [locationDict setObject:@(_externalID)      forKey:@"facebook_places_id"];
    
    LOGD(@"%@", locationDict);
    
    return locationDict;
}

- (nullable NSString *)locationJSON
{
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:[self locationDictionary]
                                                          options:0
                                                            error:&error];
    if (error) {
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    LOGD(@"%@", JSONString);
    
    return JSONString;
}

@end
