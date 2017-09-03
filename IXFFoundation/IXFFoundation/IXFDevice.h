//
//  IXFDevice.h
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

@interface IXFDevice : NSObject

@property (nonatomic, copy, nonnull)    NSString    *model;
@property (nonatomic, copy, nonnull)    NSString    *codename;
@property (nonatomic, copy, nonnull)    NSString    *manufacturer;
@property (nonatomic, copy, nonnull)    NSString    *identifier;
@property (nonatomic, copy, nonnull)    NSString    *GUID;

@property (nonatomic, assign)           NSUInteger  major;
@property (nonatomic, assign)           NSUInteger  minor;
@property (nonatomic, assign)           NSUInteger  revision;
@property (nonatomic, assign)           NSUInteger  api;
@property (nonatomic, assign)           NSUInteger  dpi;
@property (nonatomic, assign)           NSUInteger  width;
@property (nonatomic, assign)           NSUInteger  height;

- (nullable instancetype)initWithModel:(nonnull NSString *)model
                              codename:(nonnull NSString *)codename
                          manufacturer:(nonnull NSString *)manufacturer
                                 major:(NSUInteger)major
                                 minor:(NSUInteger)minor
                              revision:(NSUInteger)revision
                                   api:(NSUInteger)api
                                   dpi:(NSUInteger)dpi
                                 width:(NSUInteger)width
                                height:(NSUInteger)height;
- (nullable instancetype)initWithDefaults;
- (BOOL)integrity;
- (nonnull NSString *)version;
- (nonnull NSString *)resolution;

@end
