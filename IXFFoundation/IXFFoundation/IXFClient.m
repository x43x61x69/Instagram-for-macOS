//
//  IXFClient.m
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

- (nullable instancetype)initWithDefaults
{
    return [self initWithSignature:kSignature
                             major:kSignatureMajor
                             minor:kSignatureMinor
                          revision:kSignatureRev
                  signatureVersion:kSignatureVer];
}

- (BOOL)integrity
{
    return (_signature.length > 0) == YES;
}

- (nonnull NSString *)version
{
    return [NSString stringWithFormat:@"%lu.%lu.%lu",
            _major, _minor, _revision];
}

@end
