//
//  IXFFoundation.h
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
//
//  Set "Other Linker Flag" to "-ObjC".
//

#define kDebugMessage       "FOR DEBUG USE ONLY"
#define kDeprecated(msg)    __attribute__((deprecated(msg)))

#define kStoredUserObjectKey                @"IXFSUOK"

#define kUsersListDidChangedNotificationKey @"ULDCNK"
#define kUserInfoDidChangeNotificationKey   @"UIDCNK"
#define kUserObjectKey                      @"IUOK"
#define kCheckpointNotificationKey          @"CPNK"
#define kCheckpointObjectKey                @"ICPOK"
#define kNotificationObjectKey              @"NOK"
#define kFeedObjectKey                      @"FOK"

#define kLoginResultKey                     @"LRK"
#define kLoginResultDetailKey               @"LRDK"
#define kLoginResultNotificationKey         @"LRNK"
#define kShouldDisplayLoginNotificationKey  @"SDLNK"

#import <Foundation/Foundation.h>

#import "NSData+IXFExtended.h"
#import "NSString+IXFExtended.h"
#import "NSImage+IXFExtended.h"
#import "NSURL+IXFExtended.h"

#import "IXFKeychain.h"
#import "IXFUser.h"
#import "IXFQueueItem.h"
#import "IXFLocation.h"
#import "IXFFeedItem.h"
#import "IXFCommentItem.h"
#import "IXFPushNotification.h"

#import "IXFImageView.h"

/*!
 * @enum NSInteger
 *
 * @discussion A network status.
 *
 * @const NotReachable No Internet connection.
 * @const ReachableWiFiDirect Has <b>WiFi Direct</b> connection(s).
 * @const ReachableViaWiFi Has WiFi connection.
 */
typedef enum : NSInteger {
    NotReachable = 0,
    ReachableWiFiDirect,
    ReachableViaWiFi
} IXFNetworkStatus;

@protocol IXFDelegate <NSObject>
@optional
#pragma mark - Account Management
#pragma mark Login (POST)
- (BOOL)shouldLogin;
- (void)wasLoggedIn;
- (void)willFinishLoggingIn;
- (void)didFailToLoginWithErrorMessage:(NSString *)error;
- (void)didReceiveLoginJSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishLoggingIn;
#pragma mark Logout (POST)
- (void)willFinishLoggingOut;
- (void)didFailToLogoutWithErrorMessage:(NSString *)error;
- (void)didReceiveLogoutJSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishLoggingOut;
#pragma mark - Upload
#pragma mark Upload Image (POST)
- (BOOL)shouldUploadImage;
- (void)willFinishUploadingImage:(NSString *)UUID;
- (void)didFailToUploadImage:(NSString *)UUID errorMessage:(NSString *)error;
- (void)didReceiveUploadImage:(NSString *)UUID JSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishUploadingImage:(NSString *)UUID;
#pragma mark Upload Video (POST)
- (BOOL)shouldUploadVideo;
- (void)willFinishUploadingVideo:(NSString *)UUID;
- (void)didFailToUploadVideo:(NSString *)UUID errorMessage:(NSString *)error;
- (void)didReceiveUploadVideo:(NSString *)UUID JSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishUploadingVideo:(NSString *)UUID;
#pragma mark Delete Media (POST)
- (void)didFailToDeleteMedia:(NSString *)UUID errorMessage:(NSString *)error;
- (void)didFinishDeletingMedia:(NSString *)UUID;
#pragma mark - Location
#pragma mark Get Nearby Locations (GET)

#pragma mark - Profile Picture
#pragma mark Change Profile Picture (POST)
- (void)didFailToChangeProfilePictureWithErrorMessage:(NSString *)error;
- (void)didFinishChangingProfilePicture;
#pragma mark Remove Profile Picture (POST)
- (void)didFailToRemoveProfilePictureWithErrorMessage:(NSString *)error;
- (void)didFinishRemovingProfilePicture;
#pragma mark - Private Account
#pragma mark Set Private (POST)
- (void)didFailToSetPrivateWithErrorMessage:(NSString *)error;
- (void)didFinishSettingPrivate:(BOOL)isPrivate;
#pragma mark - Timeline
#pragma mark Timeline (GET)
- (void)didFailToFetchFeedWithErrorMessage:(NSString *)error;
- (void)didFinishFetchingFeed:(NSDictionary *)dictionary;
#pragma mark Inbox
@end

@interface IXFFoundation : NSObject <NSURLSessionDataDelegate>

#pragma mark - Properties
@property (nonatomic, assign)   id <IXFDelegate> delegate;
@property (nonatomic, copy)     NSMutableDictionary *users;
@property (nonatomic, copy)     IXFUser *user;

@property (nonatomic, assign)   NSUInteger busy;

#pragma mark - Methods
#pragma mark Utils

/*!
 * @discussion Initialize @c IXFFoundation with Instagram login details.
 *
 * @param name a @c NSString object contains an Instagram username.
 * @param password a @c NSString object contains an Instagram password.
 *
 * @return an @c IXFFoundation object. Returns @c nil if failed.
 */
- (instancetype)initWithName:(NSString *)name password:(NSString *)password;

/*!
 * @discussion Initialize @c IXFFoundation with an @c IXFUser object.
 *
 * @param user an @c IXFUser object.
 *
 * @return an @c IXFFoundation object. Returns @c nil if failed.
 */
- (instancetype)initWithUser:(IXFUser *)user;

/*!
 * @discussion Initialize @c IXFFoundation with a @c NSDictionary object.
 *
 * @param users a @c NSDictionary object contains at least one valid @c IXFUser and a last user key.
 *
 * @return an @c IXFFoundation object. Returns @c nil if failed.
 */
- (instancetype)initWithUsers:(NSDictionary *)users;

- (instancetype)initFromKeychain;
- (id)getUsersFromKeychain:(NSString **)error;
- (BOOL)storeUsersToKeychain:(NSString **)error;
- (BOOL)clearUsersFromKeychain:(NSString **)error;
- (NSArray *)allUsers;
- (NSArray *)otherUsers;
- (IXFUser *)nextUser;
- (IXFUser *)userWithIdentifier:(NSInteger)identifier;
- (IXFUser *)userWithName:(NSString *)name;
- (BOOL)userExistsWithIdentifier:(NSInteger)identifier;
- (BOOL)userExistsWithName:(NSString *)name;
- (BOOL)switchUserWithIdentifier:(NSInteger)identifier forced:(BOOL)forced;
- (BOOL)switchUserWithName:(NSString *)name forced:(BOOL)forced;
- (BOOL)switchToNextUser;
- (BOOL)switchToNextUserAndRemoveCurrent;
- (BOOL)addNewUser:(IXFUser *)user;
- (void)removeUser:(NSString *)name;

- (NSString *)version;
#pragma mark Network Connection
+ (IXFNetworkStatus)networkStatus;
+ (BOOL)internetAccess;
#pragma mark Cookie
//- (void)deleteCookies;
- (void)resetSession;
- (NSArray *)cookies;
- (BOOL)cookiesExpired;
#pragma mark Account Management
- (void)challenge:(IXFUser *)user;
- (void)login;
- (void)loginWithUser:(IXFUser *)user;
- (void)logout;
#pragma mark Upload
- (void)uploadImage:(IXFQueueItem *)queueItem;
- (void)uploadVideo:(IXFQueueItem *)queueItem;
#pragma mark Delete Media
- (void)deleteMedia:(IXFQueueItem *)queueItem;
#pragma mark Locations
- (void)nearbyLocations:(CLLocationCoordinate2D)coordinate
      completionHandler:(void (^)(NSArray *locations,
                                  NSError *error))completionHandler;

#pragma mark Profile Picture
- (void)changeProfilePicture:(NSImage *)image;
- (void)removeProfilePicture;
#pragma mark Private Account
- (void)togglePrivate;
- (void)setPrivate:(BOOL)option;
#pragma mark - Timeline
- (void)feed:(IXFUser *)user;
- (void)feed:(IXFUser *)user maxID:(NSString *)maxID;
#pragma mark - Hashtag
- (NSArray<NSString *>*)hashtag:(NSString *)hashtag;
- (NSArray<NSString *>*)users:(NSString *)user;
#pragma mark - Like Media
- (BOOL)like:(IXFFeedItem *)media option:(BOOL)option;
#pragma mark Comments
- (IXFCommentItem *)commentWithDictionary:(NSDictionary *)dictionary;
- (IXFUser *)userWithDictionary:(NSDictionary *)dictionary;
- (NSArray<IXFCommentItem *>*)comments:(IXFFeedItem *)media;
- (IXFCommentItem *)comment:(IXFFeedItem *)media text:(NSString *)text error:(NSString **)error;
- (BOOL)deleteComments:(IXFFeedItem *)media comments:(NSArray<IXFCommentItem *> *)comments error:(NSString **)error;
- (BOOL)editMedia:(IXFFeedItem *)feedItem;
#pragma mark - Inbox (GET)
- (void)inbox;
#pragma mark - Profile
- (IXFUser *)userInfoWithIdentifier:(NSUInteger)identifier;
- (BOOL)syncUserInfo:(BOOL)editOption;
- (BOOL)editProfile:(NSString **)error;
@end
