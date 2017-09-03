//
//  IXFUser.h
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
#import "IXFDevice.h"
#import "IXFClient.h"

@interface IXFUser : NSObject

@property (nonatomic, copy, nonnull)    IXFDevice   *device;
@property (nonatomic, copy, nonnull)    IXFClient   *client;

@property (nonatomic, copy, nonnull)    NSString    *name;
@property (nonatomic, copy, nonnull)    NSString    *password;
@property (nonatomic, copy, nonnull)    NSString    *email;
@property (nonatomic, copy, nonnull)    NSString    *phone;

@property (nonatomic, copy, nullable)   NSString    *fullname;
@property (nonatomic, copy, nonnull)    NSString    *externalURL;
@property (nonatomic, copy, nullable)   NSString    *bio;
@property (nonatomic, copy, nullable)   NSImage     *avatar;
@property (nonatomic, copy, nullable)   NSString    *avatarURL;

@property (nonatomic, assign)           NSInteger   identifier;
@property (nonatomic, assign)           NSInteger   gender;
@property (nonatomic, assign)           NSUInteger  followers;
@property (nonatomic, assign)           NSUInteger  mediaCount;
@property (nonatomic, assign)           BOOL        isPrivate;
@property (nonatomic, assign)           BOOL        verified;
@property (nonatomic, assign)           BOOL        hasAnonymousProfilePicture;

@property (nonatomic, copy, nullable)   NSMutableArray  *cookies;

///
/// Initialize IXFUser with name, password, device and client.
/// Returns nil if failed.
///
- (nullable instancetype)initWithName:(nonnull NSString *)name
                             password:(nonnull NSString *)password
                               device:(nonnull IXFDevice *)device
                               client:(nonnull IXFClient *)client;

///
/// Initialize IXFUser with name, password and default device/client.
/// Returns nil if failed.
///
- (nullable instancetype)initWithName:(nonnull NSString *)name
                             password:(nonnull NSString *)password;
- (BOOL)clientNeedsUpgrade;
- (BOOL)upgradeClient;
- (BOOL)integrity;
- (nullable NSDictionary *)deviceDictionary;
- (nullable NSString *)identifierString;
- (void)avatar:(void (^ _Nullable)(NSImage * _Nullable image))completionHandler;

///
/// Generate User-Agent. Returns nil if either the device or the client was empty.
///
- (nullable NSString *)userAgent;

- (void)setCookiesWithStorage:(nullable NSHTTPCookieStorage *)cookies;
- (void)restoreCookies;

@end
