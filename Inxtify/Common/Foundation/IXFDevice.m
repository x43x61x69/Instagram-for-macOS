//
//  IXFDevice.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import "IXFDevice.h"

@implementation IXFDevice

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _model              = [decoder decodeObjectForKey:@"model"];
        _codename           = [decoder decodeObjectForKey:@"codename"];
        _manufacturer       = [decoder decodeObjectForKey:@"manufacturer"];
        _identifier         = [decoder decodeObjectForKey:@"identifier"];
        _GUID               = [decoder decodeObjectForKey:@"GUID"];
        _major              = [decoder decodeIntegerForKey:@"major"];
        _minor              = [decoder decodeIntegerForKey:@"minor"];
        _revision           = [decoder decodeIntegerForKey:@"revision"];
        _api                = [decoder decodeIntegerForKey:@"api"];
        _dpi                = [decoder decodeIntegerForKey:@"dpi"];
        _width              = [decoder decodeIntegerForKey:@"width"];
        _height             = [decoder decodeIntegerForKey:@"height"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_model            forKey:@"model"];
    [encoder encodeObject:_codename         forKey:@"codename"];
    [encoder encodeObject:_manufacturer     forKey:@"manufacturer"];
    [encoder encodeObject:_identifier       forKey:@"identifier"];
    [encoder encodeObject:_GUID             forKey:@"GUID"];
    [encoder encodeInteger:_major           forKey:@"major"];
    [encoder encodeInteger:_minor           forKey:@"minor"];
    [encoder encodeInteger:_revision        forKey:@"revision"];
    [encoder encodeInteger:_api             forKey:@"api"];
    [encoder encodeInteger:_dpi             forKey:@"dpi"];
    [encoder encodeInteger:_width           forKey:@"width"];
    [encoder encodeInteger:_height          forKey:@"height"];
}

- (nullable instancetype)initWithModel:(nonnull NSString *)model
                              codename:(nonnull NSString *)codename
                          manufacturer:(nonnull NSString *)manufacturer
                                 major:(NSUInteger)major
                                 minor:(NSUInteger)minor
                              revision:(NSUInteger)revision
                                   api:(NSUInteger)api
                                   dpi:(NSUInteger)dpi
                                 width:(NSUInteger)width
                                height:(NSUInteger)height
{
    if (self = [super init]) {
        if (model.length && codename.length && manufacturer.length &&
            api && dpi && width && height) {
            _model          = model;
            _codename       = codename;
            _manufacturer   = manufacturer;
            _major          = major;
            _minor          = minor;
            _revision       = revision;
            _api            = api;
            _dpi            = dpi;
            _width          = width;
            _height         = height;
            _identifier     = [self uuid];
            _GUID           = [self guid];
        } else {
            return nil;
        }
    }
    return self;
}

- (nonnull NSString *)guid
{
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

- (nonnull NSString *)uuid
{
    return [NSString stringWithFormat:@"android-%@",
            [[[self guid] stringByReplacingOccurrencesOfString:@"-"
                                                    withString:@""]
             substringToIndex:16]];
}

- (nonnull NSString *)version
{
    return [NSString stringWithFormat:@"%lu.%lu.%lu",
            _major, _minor, _revision];
}

- (nonnull NSString *)resolution
{
    return [NSString stringWithFormat:@"%lux%lu",
            _height, _width];
}

@end
