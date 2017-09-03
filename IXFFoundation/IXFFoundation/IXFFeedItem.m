//
//  IXFFeedItem.m
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

#import "IXFFeedItem.h"

@implementation IXFFeedItem

- (instancetype)init
{
    if (self = [super init]) {
        _likers = [NSMutableArray array];
        _comments = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _user               = [decoder decodeObjectForKey:@"user"];
        _location           = [decoder decodeObjectForKey:@"location"];
        _caption            = [decoder decodeObjectForKey:@"caption"];
        _code               = [decoder decodeObjectForKey:@"code"];
        _mediaID            = [decoder decodeObjectForKey:@"mediaID"];
        _date               = [decoder decodeObjectForKey:@"date"];
        _image              = [decoder decodeObjectForKey:@"image"];
        _previewImage       = [decoder decodeObjectForKey:@"previewImage"];
        _imageURL           = [decoder decodeObjectForKey:@"imageURL"];
        _previewImageURL    = [decoder decodeObjectForKey:@"previewImageURL"];
        _likers             = [decoder decodeObjectForKey:@"likers"];
        _comments           = [decoder decodeObjectForKey:@"comments"];
        _type               = [decoder decodeIntegerForKey:@"type"];
        _identifier         = [decoder decodeIntegerForKey:@"identifier"];
        _likeCount          = [decoder decodeIntegerForKey:@"likeCount"];
        _commentsCount      = [decoder decodeIntegerForKey:@"commentsCount"];
        _width              = [decoder decodeFloatForKey:@"width"];
        _height             = [decoder decodeFloatForKey:@"height"];
        _captionIsEdited    = [decoder decodeBoolForKey:@"captionIsEdited"];
        _hasLiked           = [decoder decodeBoolForKey:@"hasLiked"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_user             forKey:@"user"];
    [encoder encodeObject:_location         forKey:@"location"];
    [encoder encodeObject:_caption          forKey:@"caption"];
    [encoder encodeObject:_code             forKey:@"code"];
    [encoder encodeObject:_mediaID          forKey:@"mediaID"];
    [encoder encodeObject:_date             forKey:@"date"];
    [encoder encodeObject:_imageURL         forKey:@"imageURL"];
    [encoder encodeObject:_previewImageURL  forKey:@"previewImageURL"];
    [encoder encodeObject:_image            forKey:@"image"];
    [encoder encodeObject:_previewImage     forKey:@"previewImage"];
    [encoder encodeObject:_likers           forKey:@"likers"];
    [encoder encodeObject:_comments         forKey:@"comments"];
    [encoder encodeInteger:_type            forKey:@"type"];
    [encoder encodeInteger:_identifier      forKey:@"identifier"];
    [encoder encodeInteger:_likeCount       forKey:@"likeCount"];
    [encoder encodeInteger:_commentsCount   forKey:@"commentsCount"];
    [encoder encodeFloat:_width             forKey:@"width"];
    [encoder encodeInteger:_height          forKey:@"height"];
    [encoder encodeBool:_captionIsEdited    forKey:@"captionIsEdited"];
    [encoder encodeBool:_hasLiked           forKey:@"hasLiked"];
}

- (nullable NSURL *)URL
{
    if (_code.length) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instagram.com/p/%@/", _code]];
    }
    return nil;
}

@end
