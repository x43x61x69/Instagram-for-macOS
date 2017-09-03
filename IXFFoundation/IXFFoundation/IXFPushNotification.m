//
//  IXFPushNotification.m
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

#import "IXFPushNotification.h"

@implementation IXFPushNotification

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _user               = [decoder decodeObjectForKey:@"user"];
        _media              = [decoder decodeObjectForKey:@"media"];
        _identifier         = [decoder decodeObjectForKey:@"identifier"];
        _text               = [decoder decodeObjectForKey:@"text"];
        _date               = [decoder decodeObjectForKey:@"date"];
        
        _type               = [decoder decodeIntegerForKey:@"type"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_user             forKey:@"user"];
    [encoder encodeObject:_media            forKey:@"media"];
    [encoder encodeObject:_identifier       forKey:@"identifier"];
    [encoder encodeObject:_text             forKey:@"text"];
    [encoder encodeObject:_date             forKey:@"date"];
    
    [encoder encodeInteger:_type            forKey:@"type"];
}

- (_Nullable id)initWithDictionary:( NSDictionary * _Nonnull )dictionary
{
    if (self = [super init]) {
        
        if (dictionary == nil) {
            return nil;
        }
        
        LOGD(@"%@", dictionary);
        
        _identifier = [dictionary objectForKey:@"pk"];
        if (_identifier == nil || !_identifier.length) {
            return nil;
        }
        
        NSDictionary *args = [dictionary objectForKey:@"args"];
        
        if (args == nil) {
            return nil;
        }
        
        _text = [args objectForKey:@"text"];
        if (_text == nil || !_text.length) {
            return nil;
        }
        
        _type = [[dictionary objectForKey:@"type"] integerValue];
        if (_type == 1) {
            NSArray *media = [args objectForKey:@"media"];
            if (media != nil && [media count] > 0) {
                NSDictionary *medium = [media firstObject];
                _media = [[IXFFeedItem alloc] init];
                _media.mediaID = [medium objectForKey:@"id"];
                _media.previewImageURL = [medium objectForKey:@"image"];
            }
        }
        
        _user = [[IXFUser alloc] init];
        _user.avatarURL = [args objectForKey:@"profile_image"];
        _user.avatar = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:_user.avatarURL]];
        _user.identifier = [[args objectForKey:@"profile_id"] integerValue];
        
        _date = [NSDate dateWithTimeIntervalSince1970:[[args objectForKey:@"timestamp"] floatValue]];
    }
    return self;
}

@end
