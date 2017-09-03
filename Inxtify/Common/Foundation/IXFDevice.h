//
//  IXFDevice.h
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
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
- (nonnull NSString *)version;
- (nonnull NSString *)resolution;

@end
