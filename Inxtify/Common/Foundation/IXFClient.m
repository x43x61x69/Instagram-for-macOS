//
//  IXFClient.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import "IXFClient.h"

@implementation IXFClient

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _signature          = [decoder decodeObjectForKey:@"signature"];
        _major              = [decoder decodeIntegerForKey:@"major"];
        _minor              = [decoder decodeIntegerForKey:@"minor"];
        _revision           = [decoder decodeIntegerForKey:@"revision"];
        _signatureVersion   = [decoder decodeIntegerForKey:@"signatureVersion"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_signature            forKey:@"signature"];
    [encoder encodeInteger:_major               forKey:@"major"];
    [encoder encodeInteger:_minor               forKey:@"minor"];
    [encoder encodeInteger:_revision            forKey:@"revision"];
    [encoder encodeInteger:_signatureVersion    forKey:@"signatureVersion"];
}

- (nullable instancetype)initWithSignature:(nonnull NSString *)signature
                                     major:(NSUInteger)major
                                     minor:(NSUInteger)minor
                                  revision:(NSUInteger)revision
                          signatureVersion:(NSUInteger)version
{
    if (self = [super init]) {
        if (signature.length) {
            _signature          = signature;
            _major              = major;
            _minor              = minor;
            _revision           = revision;
            _signatureVersion   = version;
        } else {
            return nil;
        }
    }
    return self;
}

- (nonnull NSString *)version
{
    return [NSString stringWithFormat:@"%lu.%lu.%lu",
            _major, _minor, _revision];
}

@end
