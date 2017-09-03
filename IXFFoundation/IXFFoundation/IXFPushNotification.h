//
//  IXFPushNotification.h
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
#import "IXFFeedItem.h"

typedef enum : NSInteger {
    IXFPushNotificationLikedType        = 0x1,
    IXFPushNotificationFriendshipType   = 0x3
} IXFPushNotificationType;

@interface IXFPushNotification : NSObject

@property (nonatomic, strong, nonnull)  IXFUser     *user;
@property (nonatomic, strong, nonnull)  IXFFeedItem *media;

@property (nonatomic, copy, nullable)   NSString   *text;

@property (nonatomic, copy, nullable)   NSDate     *date; // timestamp

@property (nonatomic, copy, nullable)   NSString *identifier;
@property (nonatomic, assign)           IXFPushNotificationType type;

- (_Nullable id)initWithDictionary:( NSDictionary * _Nonnull )dictionary;

@end
