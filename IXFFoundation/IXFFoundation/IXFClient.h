//
//  IXFClient.h
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

@interface IXFClient : NSObject

@property (nonatomic, copy, nonnull)    NSString    *signature;
@property (nonatomic, assign)           NSUInteger  major;
@property (nonatomic, assign)           NSUInteger  minor;
@property (nonatomic, assign)           NSUInteger  revision;
@property (nonatomic, assign)           NSUInteger  signatureVersion;

- (nullable instancetype)initWithSignature:(nonnull NSString *)signature
                                     major:(NSUInteger)major
                                     minor:(NSUInteger)minor
                                  revision:(NSUInteger)revision
                          signatureVersion:(NSUInteger)version;
- (nullable instancetype)initWithDefaults;
- (BOOL)integrity;
- (nonnull NSString *)version;

@end
