//
//  IXFUser.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import "IXFUser.h"

@implementation IXFUser

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _name       = [decoder decodeObjectForKey:@"name"];
        _fullname   = [decoder decodeObjectForKey:@"fullname"];
        _password   = [decoder decodeObjectForKey:@"password"];
        _cookies    = [decoder decodeObjectForKey:@"cookies"];
        _avatar     = [decoder decodeObjectForKey:@"avatar"];
        _identifier = [decoder decodeIntegerForKey:@"identifier"];
        _isPrivate  = [decoder decodeBoolForKey:@"isPrivate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_name         forKey:@"name"];
    [encoder encodeObject:_fullname     forKey:@"fullname"];
    [encoder encodeObject:_password     forKey:@"password"];
    [encoder encodeObject:_cookies      forKey:@"cookies"];
    [encoder encodeObject:_avatar       forKey:@"avatar"];
    [encoder encodeInteger:_identifier  forKey:@"identifier"];
    [encoder encodeBool:_isPrivate      forKey:@"isPrivate"];
}

- (nullable instancetype)initWithName:(nonnull NSString *)name
                             password:(nonnull NSString *)password
                               device:(nonnull IXFDevice *)device
                               client:(nonnull IXFClient *)client
{
    if (self = [super init]) {
        if (name.length && password.length) {
            _name       = name;
            _password   = password;
            _device     = device;
            _client     = client;
        } else {
            return nil;
        }
    }
    return self;
}

- (nullable NSString *)CSRFToken
{
    NSDate *date = [NSDate date];
    for (NSHTTPCookie *cookie in _cookies) {
        if ([cookie.name isEqualToString:@"csrftoken"] &&
            !cookie.sessionOnly &&
            [[cookie.expiresDate earlierDate:date] isEqual:date]) {
            return cookie.value;
        }
    }
    return nil;
}

- (BOOL)updateAvatarWithURL:(nullable NSURL *)URL
{
    if (URL) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:URL
                                                 resolvingAgainstBaseURL:YES];
        components.scheme = @"https";
        NSData *imageData = [NSData dataWithContentsOfURL:components.URL];
        if (imageData != nil) {
            _avatar = [[NSImage alloc] initWithData:imageData];
            return YES;
        }
    }
    return NO;
}

@end
