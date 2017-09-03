//
//  IXFFeedItem.h
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


#import <Cocoa/Cocoa.h>
#import "IXFUser.h"
#import "IXFLocation.h"
#import "IXFCommentItem.h"

/*
{
    "taken_at":1464796558,
    "pk":1263127544916275551,
    "id":"1263127544916275551_1815469027",
    "device_timestamp":1464796440000,
    "media_type":1,
    "code":"BGHh89MvvFf7cfIGb2-EtaZsiSjlvnqV6KRTbY0",
    "client_cache_key":"MTI2MzEyNzU0NDkxNjI3NTU1MQ==.2",
    "filter_type":0,
    "image_versions2":{
        "candidates":[
                      {
                          "url":"http://scontent.cdninstagram.com/t51.2885-15/e35/13266917_252083528493935_562038659_n.jpg?ig_cache_key=MTI2MzEyNzU0NDkxNjI3NTU1MQ%3D%3D.2",
                          "width":1080,
                          "height":870
                      },
                      {
                          "url":"http://scontent.cdninstagram.com/t51.2885-15/s750x750/sh0.08/e35/13266917_252083528493935_562038659_n.jpg?ig_cache_key=MTI2MzEyNzU0NDkxNjI3NTU1MQ%3D%3D.2",
                          "width":750,
                          "height":604
                      },
                      {
                          "url":"http://scontent.cdninstagram.com/t51.2885-15/s640x640/sh0.08/e35/13266917_252083528493935_562038659_n.jpg?ig_cache_key=MTI2MzEyNzU0NDkxNjI3NTU1MQ%3D%3D.2",
                          "width":640,
                          "height":515
                      },
                        ......
                      {
                          "url":"http://scontent.cdninstagram.com/t51.2885-15/s240x240/e35/c105.0.870.870/13266917_252083528493935_562038659_n.jpg?ig_cache_key=MTI2MzEyNzU0NDkxNjI3NTU1MQ%3D%3D.2.c",
                          "width":240,
                          "height":240
                      },
                      {
                          "url":"http://scontent.cdninstagram.com/t51.2885-15/s150x150/e35/c105.0.870.870/13266917_252083528493935_562038659_n.jpg?ig_cache_key=MTI2MzEyNzU0NDkxNjI3NTU1MQ%3D%3D.2.c",
                          "width":150,
                          "height":150
                      }
                      ]
    },
    "original_width":1080,
    "original_height":870,
    "user":{
        "username":"tester13337",
        "has_anonymous_profile_picture":false,
        "is_unpublished":false,
        "profile_pic_url":"http://scontent.cdninstagram.com/t51.2885-19/s150x150/12105185_1487710028198469_1969158376_a.jpg",
        "full_name":"Tester",
        "pk":1815469027,
        "is_verified":false,
        "is_private":true
    },
    "organic_tracking_token":"eyJ2ZXJzaW9uIjo1LCJwYXlsb2FkIjp7ImlzX2FuYWx5dGljc190cmFja2VkIjpmYWxzZSwidXVpZCI6ImZiOTU3MzdjODNiMDQzMWY4OTRjMjBhZDRhNTY2NmI2MTI2MzEyNzU0NDkxNjI3NTU1MSIsInNlcnZlcl90b2tlbiI6IjE0NjQ4MDQ2NzUzNDd8MTI2MzEyNzU0NDkxNjI3NTU1MXwxODE1NDY5MDI3fDNhOTRhN2MzMjRiY2MyN2QxNDliMjAxNGEyZTJmZGUzM2IwM2FlMGNiNDI1ZmMyZmQzNmY3N2VmZmI5YzJiNTEifSwic2lnbmF0dXJlIjoiIn0=",
    "likers":[  
    
    ],
    "like_count":0,
    "has_liked":false,
    "has_more_comments":false,
    "max_num_visible_preview_comments":2,
    "comments":[  
    
    ],
    "comment_count":0,
    "caption":null,
    "caption_is_edited":false,
    "photo_of_you":false
},*/

@interface IXFFeedItem : NSObject

@property (nonatomic, strong, nonnull) IXFUser     *user;
@property (nonatomic, strong, nonnull) IXFLocation *location;

@property (nonatomic, copy, nullable) NSString   *caption;
@property (nonatomic, copy, nullable) NSString   *code;
@property (nonatomic, copy, nonnull)  NSString   *mediaID;

@property (nonatomic, copy, nonnull) NSImage    *image;
@property (nonatomic, copy, nonnull) NSImage    *previewImage;

@property (nonatomic, copy, nonnull) NSString   *imageURL;
@property (nonatomic, copy, nonnull) NSString   *previewImageURL;

@property (nonatomic, copy, nonnull) NSDate     *date;

@property (nonatomic, copy, nullable) NSMutableArray<IXFUser *> *likers;
@property (nonatomic, copy, nullable) NSMutableArray<IXFCommentItem *> *comments;

@property (nonatomic, assign) CGFloat       width;
@property (nonatomic, assign) CGFloat       height;
@property (nonatomic, assign) NSInteger     identifier;
@property (nonatomic, assign) NSUInteger    type;
@property (nonatomic, assign) NSUInteger    likeCount;
@property (nonatomic, assign) NSUInteger    commentsCount;
@property (nonatomic, assign) BOOL          captionIsEdited;
@property (nonatomic, assign) BOOL          hasLiked;

- (nullable NSURL *)URL;

@end
