//
//  IXFFoundation.h
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#define kDebugMessage               "FOR DEBUG USE ONLY"
#define kDeprecated(msg)            __attribute__((deprecated(msg)))

#import <Foundation/Foundation.h>
#import "IXFUser.h"

typedef enum : NSInteger {
    NotReachable = 0,
    ReachableWiFiDirect,
    ReachableViaWiFi
} IXFNetworkStatus;

@protocol IXFDelegate <NSObject>
@optional
#pragma mark - Account Management
#pragma mark Challenge (GET)
- (void)didFailToChallengeWithErrorMessage:(NSString *)error;
- (void)didReceiveChallengeJSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
#pragma mark Login (POST)
- (BOOL)shouldLogin;
- (void)willFinishLoggingIn;
- (void)didFailToLoginWithErrorMessage:(NSString *)error;
- (void)didReceiveLoginJSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishLoggingIn;
#pragma mark Logout (POST)
- (void)willFinishLoggingOut;
- (void)didFailToLogoutWithErrorMessage:(NSString *)error;
- (void)didReceiveLogoutJSONResponse:(NSDictionary *)dictionary statusCode:(NSInteger)statusCode;
- (void)didFinishLoggingOut;
@end

@interface IXFFoundation : NSObject

#pragma mark - Properties
@property (nonatomic, assign)   id <IXFDelegate> delegate;
@property (nonatomic, copy)     IXFUser *user;

#pragma mark - Methods
#pragma mark Utils

///
/// Initialize core with an IXFUser. Returns nil if failed.
///
/// @pram user an IXFUser object.
///
- (instancetype)initWithUser:(IXFUser *)user;
- (NSString *)version;
#pragma mark Network Connection
+ (IXFNetworkStatus)networkStatus;
+ (BOOL)internetAccess;
+ (BOOL)responseSuccessful:(NSInteger)statusCode;
#pragma mark Cookie
- (void)deleteCookies;
- (NSArray *)cookies;
- (BOOL)cookiesExpired;
#pragma mark Account Management
- (void)challenge;
- (void)login;
- (void)logout;

@end
