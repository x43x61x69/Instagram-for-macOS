//
//  IXFClient.h
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
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
- (nonnull NSString *)version;

@end
