//
//  IXFCommentItem.m
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


#import "IXFCommentItem.h"

@implementation IXFCommentItem

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _user               = [decoder decodeObjectForKey:@"user"];
        _status             = [decoder decodeObjectForKey:@"status"];
        _contentType        = [decoder decodeObjectForKey:@"contentType"];
        _text               = [decoder decodeObjectForKey:@"text"];
        _date               = [decoder decodeObjectForKey:@"date"];
        
        _type               = [decoder decodeIntegerForKey:@"type"];
        _identifier         = [decoder decodeIntegerForKey:@"identifier"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_user             forKey:@"user"];
    [encoder encodeObject:_status           forKey:@"status"];
    [encoder encodeObject:_contentType      forKey:@"contentType"];
    [encoder encodeObject:_text             forKey:@"text"];
    [encoder encodeObject:_date             forKey:@"date"];
    
    [encoder encodeInteger:_type            forKey:@"type"];
    [encoder encodeInteger:_identifier      forKey:@"identifier"];
}

@end
