//
//  IXFCommentItem.h
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

typedef enum : NSInteger {
    IXFCommentCommentType   = 0x0,
    IXFCommentCaptionType   = 0x1
} IXFCommentType;

@interface IXFCommentItem : NSObject

@property (nonatomic, strong, nonnull)  IXFUser     *user;

@property (nonatomic, copy, nullable)   NSString   *status;
@property (nonatomic, copy, nullable)   NSString   *contentType; // "content_type":"comment"
@property (nonatomic, copy, nullable)   NSString   *text;

@property (nonatomic, copy, nullable)   NSDate     *date; // created_at / created_at_utc

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, assign) IXFCommentType type;

@end
