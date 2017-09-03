//
//  IXFUser.m
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

#import "IXFUser.h"

@implementation IXFUser

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _device         = [decoder decodeObjectForKey:@"device"];
        _client         = [decoder decodeObjectForKey:@"client"];
        _name           = [decoder decodeObjectForKey:@"name"];
        _email          = [decoder decodeObjectForKey:@"email"];
        _phone          = [decoder decodeObjectForKey:@"phone"];
        _bio            = [decoder decodeObjectForKey:@"bio"];
        _fullname       = [decoder decodeObjectForKey:@"fullname"];
        _externalURL    = [decoder decodeObjectForKey:@"externalURL"];
        _password       = [decoder decodeObjectForKey:@"password"];
        _avatar         = [decoder decodeObjectForKey:@"avatar"];
        _avatarURL      = [decoder decodeObjectForKey:@"avatarURL"];
        _identifier     = [decoder decodeIntegerForKey:@"identifier"];
        _gender         = [decoder decodeIntegerForKey:@"gender"];
        _followers      = [decoder decodeIntegerForKey:@"followers"];
        _mediaCount     = [decoder decodeIntegerForKey:@"mediaCount"];
        _isPrivate      = [decoder decodeBoolForKey:@"isPrivate"];
        _verified       = [decoder decodeBoolForKey:@"verified"];
        _hasAnonymousProfilePicture = [decoder decodeBoolForKey:@"hasAnonymousProfilePicture"];
        _cookies        = [decoder decodeObjectForKey:@"cookies"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_device           forKey:@"device"];
    [encoder encodeObject:_client           forKey:@"client"];
    [encoder encodeObject:_name             forKey:@"name"];
    [encoder encodeObject:_email            forKey:@"email"];
    [encoder encodeObject:_phone            forKey:@"phone"];
    [encoder encodeObject:_bio              forKey:@"bio"];
    [encoder encodeObject:_fullname         forKey:@"fullname"];
    [encoder encodeObject:_externalURL      forKey:@"externalURL"];
    [encoder encodeObject:_password         forKey:@"password"];
    [encoder encodeObject:_avatar           forKey:@"avatar"];
    [encoder encodeObject:_avatarURL        forKey:@"avatarURL"];
    [encoder encodeInteger:_identifier      forKey:@"identifier"];
    [encoder encodeInteger:_gender          forKey:@"gender"];
    [encoder encodeInteger:_followers       forKey:@"followers"];
    [encoder encodeInteger:_mediaCount      forKey:@"mediaCount"];
    [encoder encodeBool:_isPrivate          forKey:@"isPrivate"];
    [encoder encodeBool:_verified           forKey:@"verified"];
    [encoder encodeBool:_hasAnonymousProfilePicture forKey:@"hasAnonymousProfilePicture"];
    [encoder encodeObject:_cookies          forKey:@"cookies"];
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

- (nullable instancetype)initWithName:(nonnull NSString *)name
                             password:(nonnull NSString *)password
{
    if (self = [super init]) {
        if (name.length && password.length) {
            _name       = name;
            _password   = password;
            _device     = [[IXFDevice alloc] initWithDefaults];
            _client     = [[IXFClient alloc] initWithDefaults];
        } else {
            return nil;
        }
    }
    return self;
}

- (BOOL)clientNeedsUpgrade
{
    return ([[_client version] isEqualToString:[[[IXFClient alloc] initWithDefaults] version]]) == NO;
}

- (BOOL)upgradeClient
{
    IXFClient *client = [[IXFClient alloc] initWithDefaults];
    if ([client integrity] == NO) {
        return NO;
    }
    _client = client;
    return YES;
}

- (BOOL)integrity
{
    return (self != nil &&
            _name.length && _password.length &&
            _device && [_device integrity] &&
            _client && [_client integrity]) == YES;
}

- (nullable NSDictionary *)deviceDictionary
{
    if (_device == nil) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[[_device.manufacturer componentsSeparatedByString:@"/"] objectAtIndex:0]
             forKey:@"manufacturer"];
    [dict setObject:_device.model          forKey:@"model"];
    [dict setObject:@(_device.api)         forKey:@"android_version"];
    [dict setObject:[_device version]      forKey:@"android_release"];
    return dict;
}

- (nullable NSString *)identifierString
{
    if (_identifier == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%lu", _identifier];
}

- (void)avatar:(void (^ _Nullable)(NSImage * _Nullable image))completionHandler
{
    if (_hasAnonymousProfilePicture == YES) {
        NSImage *placeholder = [NSImage imageNamed:@"avatarPlaceholder"];
        _avatar = placeholder;
    }
    if (_avatarURL.length) {
        // NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:_avatarURL] resolvingAgainstBaseURL:YES];
        // components.scheme = @"https";
        LOGD(@"avatarURL: %@", _avatarURL);
        // NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:_avatarURL]];
        // _avatar = [[NSImage alloc] initWithData:imageData];
        _avatar = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:_avatarURL]];
        if (_avatar != nil) {
            completionHandler(_avatar);
            return;
        }
    }
    completionHandler(_avatar);
}

- (nullable NSString *)userAgent
{
    if (!_device || ![_device integrity] ||
        !_client || ![_client integrity]) {
        return nil;
    }
    return [NSString stringWithFormat:@"Instagram %@ Android (%lu/%@; %ludpi; %@; %@; %@; %@; %@; %@)",
            [_client version],
            _device.api,
            [_device version],
            _device.dpi,
            [_device resolution],
            _device.manufacturer,
            _device.model,
            _device.codename,
            _device.codename,
            @"en_US"]; //[[NSLocale currentLocale] localeIdentifier]];
}

- (void)setCookiesWithStorage:(nullable NSHTTPCookieStorage *)cookies
{
    _cookies = [NSMutableArray array];
    
    if (cookies == nil) {
        return;
    }
    
    for (NSHTTPCookie *cookie in [cookies cookies]) {
        NSMutableDictionary *cookieDict = [NSMutableDictionary new];
        cookieDict[NSHTTPCookieName]    = cookie.name;
        cookieDict[NSHTTPCookieValue]   = cookie.value;
        cookieDict[NSHTTPCookieDomain]  = cookie.domain;
        cookieDict[NSHTTPCookiePath]    = cookie.path;
        cookieDict[NSHTTPCookieSecure]  = (cookie.isSecure ? @"YES" : @"NO");
        cookieDict[NSHTTPCookieVersion] = [NSString stringWithFormat:@"%lu", (unsigned long)cookie.version];
        if (cookie.expiresDate) cookieDict[NSHTTPCookieExpires] = cookie.expiresDate;
        [_cookies addObject:cookieDict];
    }
    LOGD(@"%@", _cookies);
}

- (void)restoreCookies
{
    if (_cookies == nil) {
        return;
    }
    LOGD(@"%@", _cookies);
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSDictionary *cookieDict in _cookies) {
        [cookieStorage setCookie:[NSHTTPCookie cookieWithProperties:cookieDict]];
    }
}

@end
