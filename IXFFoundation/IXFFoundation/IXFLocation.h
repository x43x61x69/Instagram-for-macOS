//
//  IXFLocation.h
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


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface IXFLocation : NSObject

@property (nonatomic, copy, nonnull)    NSString    *name;
@property (nonatomic, copy, nonnull)    NSString    *address;
@property (nonatomic, copy, nonnull)    NSString    *externalIDSource;
@property (nonatomic, copy, nonnull)    CLLocation  *location;
@property (nonatomic, copy, nonnull)    NSString    *latitude;
@property (nonatomic, copy, nonnull)    NSString    *longitude;
@property (nonatomic, assign)           NSUInteger  externalID;

- (nullable NSDictionary *)locationDictionary;
- (nullable NSString *)locationJSON;

@end
