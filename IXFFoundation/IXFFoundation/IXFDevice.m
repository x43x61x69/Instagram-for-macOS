//
//  IXFDevice.m
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

- (nullable instancetype)initWithDefaults
{
    return [self initWithModel:@"Nexus 5"
                      codename:@"hammerhead"
                  manufacturer:@"LGE/google"
                         major:6
                         minor:0
                      revision:1
                           api:23
                           dpi:480
                         width:1776
                        height:1080];
}

- (BOOL)integrity
{
    return (_model.length && _codename.length &&
            _manufacturer.length && _identifier.length &&
            _GUID.length) == YES;
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
