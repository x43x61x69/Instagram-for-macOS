//
//  IXFFoundation.m
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


#define kDefaultError               [[NSError errorWithDomain:NSCocoaErrorDomain code:NSNotFound userInfo:nil] localizedDescription]

#define kRetries                    3
#define kVersion                    @"1.0"
#define kHTTPResponseSuccessful     2 // HTTP Code: 2xx
#define kLastUserKey                @"@IXFLastUserKey"

#import "IXFFoundation.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if_var.h>
#import <netinet/in.h>

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import <Security/Security.h>
#import <SystemConfiguration/SCNetworkReachability.h>

@implementation IXFFoundation

#pragma mark - Utils

- (instancetype)init
{
    if (self = [super init]) {
        _busy = 0;
        _users = [NSMutableDictionary new];
        [self resetSession];
        return self;
    }
    return nil;
}


- (instancetype)initWithName:(NSString *)name
                    password:(NSString *)password
{
    return [self initWithUser:[[IXFUser alloc] initWithName:name
                                                   password:password]];
}

- (instancetype)initWithUser:(IXFUser *)user
{
    if (self = [super init]) {
        if (user != nil && [user integrity]) {
            _busy = 0;
            _user = user;
            _users = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      _user.name, kLastUserKey,
                      user, _user.name,
                      nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kUsersListDidChangedNotificationKey
                                                                    object:self];
            });
            [self resetSession];
            return self;
        }
    }
    return nil;
}

- (instancetype)initWithUsers:(NSDictionary *)users
{
    if (self = [super init]) {
        if (users != nil) {
            NSString *lastUserKey = [users objectForKey:kLastUserKey];
            if ((_user = (IXFUser *)[users objectForKey:lastUserKey])) {
                _busy = 0;
                _users = [users mutableCopy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUsersListDidChangedNotificationKey
                                                                        object:self];
                });
                [self resetSession];
                return self;
            }
        }
    }
    return nil;
}

- (instancetype)initFromKeychain
{
    
    if (self = [super init]) {
        if ((_users = [[self getUsersFromKeychain:nil] mutableCopy])) {
            NSString *lastUserKey = [_users objectForKey:kLastUserKey];
            if ((_user = (IXFUser *)[_users objectForKey:lastUserKey])) {
                _busy = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                        object:self
                                                                      userInfo:@{kUserObjectKey : _user}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUsersListDidChangedNotificationKey
                                                                        object:self];
                });
                LOGD(@"%@", _users);
                return self;
            }
        }
    }
    return nil;
}

- (id)getUsersFromKeychain:(NSString **)error
{
    LOGD();
    return [IXFKeychain unarchiveObjectWithService:kStoredUserObjectKey error:error];
}

- (BOOL)storeUsersToKeychain:(NSString **)error
{
    LOGD();
    return [IXFKeychain archiveDataWithRootObject:_users forService:kStoredUserObjectKey error:error];
}

- (BOOL)clearUsersFromKeychain:(NSString **)error
{
    LOGD();
    return [IXFKeychain clearService:kStoredUserObjectKey error:error];
}

- (NSArray *)allUsers
{
    if (_users == nil) {
        return nil;
    }
    
    NSMutableArray *sortedUsers = [[_users.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    [sortedUsers removeObject:kLastUserKey];
    
    return sortedUsers;
}

- (NSArray *)otherUsers
{
    NSMutableArray *sortedUsers = [[self allUsers] mutableCopy];
    [sortedUsers removeObject:_user.name];
    
    return sortedUsers;
}

- (IXFUser *)nextUser
{
    NSArray *sortedUsers = [self allUsers];
    
    IXFUser *user = nil;
    for (NSUInteger i = 0; i < sortedUsers.count; i++) {
        if ([[sortedUsers objectAtIndex:i] isEqualToString:_user.name]) {
            if (i == sortedUsers.count - 1) {
                user = [_users objectForKey:[sortedUsers firstObject]];
            } else {
                user = [_users objectForKey:[sortedUsers objectAtIndex:i+1]];
            }
            if ([user.name isEqualToString:_user.name]) {
                user = nil;
            }
            break;
        }
    }
    return user;
}

- (IXFUser *)previousUser
{
    NSArray *sortedUsers = [self allUsers];
    
    IXFUser *user = nil;
    for (NSUInteger i = 0; i < sortedUsers.count; i++) {
        if ([[sortedUsers objectAtIndex:i] isEqualToString:_user.name]) {
            if (i == 0) {
                user = [_users objectForKey:[sortedUsers lastObject]];
            } else {
                user = [_users objectForKey:[sortedUsers objectAtIndex:i-1]];
            }
            if ([user.name isEqualToString:_user.name]) {
                user = nil;
            }
            break;
        }
    }
    return user;
}

- (NSString *)lastUser
{
    return [_users objectForKey:kLastUserKey];
}

- (BOOL)userExistsWithIdentifier:(NSInteger)identifier
{
    return ([self userWithIdentifier:identifier] != nil);
}

- (IXFUser *)userWithIdentifier:(NSInteger)identifier
{
    if (identifier < 1) {
        return nil;
    }
    
    NSMutableDictionary *users = [_users mutableCopy];
    [users removeObjectForKey:kLastUserKey];
    
    for (IXFUser *user in [users allValues]) {
        if (user.identifier == identifier) {
            return user;
        }
    }
    return nil;
}

- (BOOL)userExistsWithName:(NSString *)name
{
    return ([self userWithName:name] != nil);
}

- (IXFUser *)userWithName:(NSString *)name
{
    if (name == nil) {
        return nil;
    }
    IXFUser *user = [_users objectForKey:name];
    if ([user integrity]) {
        return user;
    }
    return nil;
}

- (BOOL)addThenSwitchToUser:(IXFUser *)user
{
    if (user != nil &&
        [user integrity] &&
        [self addNewUser:user]) {
        _user = (IXFUser *)[_users objectForKey:user.name];
        [_users setObject:_user.name forKey:kLastUserKey];
        [self storeUsersToKeychain:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                            object:self
                                                          userInfo:@{kUserObjectKey : _user}];
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
            LOGD(@"%@", [self cookies]);
            [_user restoreCookies];
        }];
        return YES;
    }
    return NO;
}

- (BOOL)switchUserWithIdentifier:(NSInteger)identifier forced:(BOOL)forced
{
    if (identifier < 1 ||
        (identifier == _user.identifier &&
         !forced)) {
        return NO;
    }
    IXFUser *user = [self userWithIdentifier:identifier];
    if ([user integrity]) {
        _user = user;
        [_users setObject:_user.name forKey:kLastUserKey];
        [self storeUsersToKeychain:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                            object:self
                                                          userInfo:@{kUserObjectKey : _user}];
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
            [_user restoreCookies];
            if ([[self cookies] count] < 1 ||
                forced) {
                [self login];
            }
        }];
        return YES;
    }
    return NO;
}

- (BOOL)switchUserWithName:(NSString *)name forced:(BOOL)forced
{
    if (name == nil || ([name isEqualToString:_user.name] && !forced)) {
        return NO;
    }
    IXFUser *user = [_users objectForKey:name];
    if ([user integrity]) {
        _user = user;
        [_users setObject:_user.name forKey:kLastUserKey];
        [self storeUsersToKeychain:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                            object:self
                                                          userInfo:@{kUserObjectKey : _user}];
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
            [_user restoreCookies];
            if ([[self cookies] count] < 1 ||
                forced) {
                [self login];
            }
        }];
        return YES;
    }
    return NO;
}

- (BOOL)switchToNextUser
{
    IXFUser *user = [self nextUser];
    if (user != nil) {
        return [self switchUserWithName:user.name forced:NO];
    }
    return NO;
}

- (BOOL)switchToPreviousUser
{
    IXFUser *user = [self previousUser];
    if (user != nil) {
        return [self switchUserWithName:user.name forced:NO];
    }
    return NO;
}

- (BOOL)switchToNextUserAndRemoveCurrent
{
    NSString *currentUser = _user.name;
    if ([self switchToNextUser]) {
        [self removeUser:currentUser];
        return YES;
    }
    [self removeUser:currentUser];
    return NO;
}

- (BOOL)addNewUser:(IXFUser *)user
{
    if ([user integrity]) {
        if ([self userWithName:user.name] == nil) {
            [_users setObject:user forKey:user.name];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kUsersListDidChangedNotificationKey
                                                                    object:self];
            });
            [self storeUsersToKeychain:nil];
            return YES;
        }
    }
    return NO;
}

- (void)removeUser:(NSString *)name
{
    if (name == nil) {
        return;
    }
    [_users removeObjectForKey:name];
    NSString *lastUser = [self lastUser];
    if (lastUser != nil && [lastUser isEqualToString:name]) {
        [_users removeObjectForKey:kLastUserKey];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kUsersListDidChangedNotificationKey
                                                            object:self];
    });
    [self storeUsersToKeychain:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///
/// Module version.
///
- (NSString *)version
{
    return kVersion;
}

///
/// Generate random GUID.
///
+ (NSString *)guid
{
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

+ (NSString *)guidWithoutDash
{
    return [[[self class] guid] stringByReplacingOccurrencesOfString:@"-"
                                                  withString:@""];
}

///
/// Generate HMAC signature for data.
///
- (NSString *)sig:(NSData *)data forUser:(IXFUser *)user
{
    return [self hmac:data secret:user.client.signature];
}

///
/// Calculate HMAC signature for data with a secret.
///
- (NSString *)hmac:(NSData *)data
            secret:(NSString *)secret
{
    const char *cData = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData  *hmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [hmac hexEncoding];
}

///
/// Sign data with signature.
///
- (NSData *)sign:(NSData *)data
{
    return [self sign:data forUser:_user];
}

- (NSData *)sign:(NSData *)data forUser:(IXFUser *)user
{
    NSString *sig = [self sig:data forUser:user];
    if (!sig) {
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    LOGD(@"%@", JSONString);
    
    return [[NSString stringWithFormat:@"%@%lu%@%@.%@",
             kIXFig_sig_key_version,
             user.client.signatureVersion,
             kIXFsigned_body,
             sig,
             [JSONString urlencode]]
            dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Network Connection

+ (IXFNetworkStatus)networkStatus
{
    struct sockaddr_in nullAddr;
    bzero(&nullAddr, sizeof(nullAddr));
    nullAddr.sin_len    = sizeof(nullAddr);
    nullAddr.sin_family = AF_INET;
    SCNetworkReachabilityRef reachabilityRef
    = SCNetworkReachabilityCreateWithAddress(NULL,
                                             (struct sockaddr *)&nullAddr);
    SCNetworkReachabilityFlags flags;
    BOOL retrievedFlags = SCNetworkReachabilityGetFlags(reachabilityRef,
                                                        &flags);
    CFRelease(reachabilityRef);
    if (!retrievedFlags) {
        return NotReachable;
    }
    BOOL isReachable        = ((flags & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection    = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
    if (isReachable && !needsConnection) {
        BOOL isDirectConnection = ((flags & kSCNetworkReachabilityFlagsIsDirect) != 0);
        if (isDirectConnection) {
            return ReachableWiFiDirect;
        } else {
            return ReachableViaWiFi;
        }
    } else {
        return NotReachable;
    }
}

+ (BOOL)internetAccess
{
    return ([IXFFoundation networkStatus] == ReachableViaWiFi) == YES;
}

- (BOOL)responseSuccessful:(NSInteger)statusCode
{
    return (statusCode / 100 == kHTTPResponseSuccessful) == YES;
}

#pragma mark Requests
// URL must be HTTPS or it will fail due to Apple's App Transport Security.

- (BOOL)shouldProcessRequest
{
    BOOL hasInternet = [IXFFoundation internetAccess];
    if (!hasInternet) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"No Internet Connection"];
        [alert setInformativeText:@"Please check your Internet connection then retry."];
        [alert setAlertStyle:NSWarningAlertStyle];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert runModal];
        });
    }
    return hasInternet;
}

- (void)sendRequest:(NSMutableURLRequest *)request
  completionHandler:(void (^)(NSData *data,
                              NSURLResponse *response,
                              NSError *error))completionHandler
{
    if (![self shouldProcessRequest]) {
        completionHandler(nil, nil,
                          [NSError errorWithDomain:NSURLErrorDomain
                                              code:NSURLErrorNotConnectedToInternet
                                          userInfo:nil]);
        return;
    }
    [self sendRequestRegardless:request
                        forUser:_user
              completionHandler:completionHandler];
}

- (void)sendRequest:(NSMutableURLRequest *)request
            forUser:(IXFUser *)user
  completionHandler:(void (^)(NSData *data,
                              NSURLResponse *response,
                              NSError *error))completionHandler
{
    if (![self shouldProcessRequest]) {
        completionHandler(nil, nil,
                          [NSError errorWithDomain:NSURLErrorDomain
                                              code:NSURLErrorNotConnectedToInternet
                                          userInfo:nil]);
        return;
    }
    [self sendRequestRegardless:request
                        forUser:user
              completionHandler:completionHandler];
}

- (void)sendRequestRegardless:(NSMutableURLRequest *)request
                      forUser:(IXFUser *)user
            completionHandler:(void (^)(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error))completionHandler
{
    
//    LOGD(@"OLD - %@\n%@",
//         [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies],
//         user.cookies);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data,
                                                         NSURLResponse *response,
                                                         NSError *error)
      {
          // Store cookie
          [user setCookiesWithStorage:[NSHTTPCookieStorage sharedHTTPCookieStorage]];
          [self storeUsersToKeychain:nil];
//          LOGD(@"NEW - %@\n%@",
//               [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies],
//               user.cookies);
#ifdef DEBUG
          LOGD(@"Status Code :%ld (%@)", [(NSHTTPURLResponse *)response statusCode], response.URL);
//          LOGD(@"Status Code :%ld (%@)\nCookie: %@", [(NSHTTPURLResponse *)response statusCode], response.URL, [array description]);
#endif
          if (completionHandler != nil) { completionHandler(data, response, error); }
      }] resume];
}

- (BOOL)connectionStatusWithResponse:(NSURLResponse *)response
                          statusCode:(NSInteger  * _Nullable)statusCode
{
    NSHTTPURLResponse *ne = (NSHTTPURLResponse *)response;
    *statusCode = [ne statusCode];
    return [self responseSuccessful:[ne statusCode]];
}

- (NSString *)errorMessageForStatusCode:(NSInteger)statusCode
{
    return [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
}

- (NSDictionary *)dictionaryWithJSONData:(NSData *)data
                                   error:(NSError * _Nullable *)error
{
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:error];
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                           forUser:(IXFUser *)user
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr {
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         // Store cookie
                                         
                                         if (user != nil) {
                                             [user setCookiesWithStorage:[NSHTTPCookieStorage sharedHTTPCookieStorage]];
                                             [self storeUsersToKeychain:nil];
                                         }
                                         
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }  
                                         if (error == nil) {  
                                             result = data;  
                                         }  
                                         dispatch_semaphore_signal(sem);  
                                     }] resume];  
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);  
    
    return result;  
}

#pragma mark Cookie

- (void)resetSession
{
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        if (_user) _user.cookies = nil;
        _busy = 0;
    }];
}

- (NSArray *)cookies
{
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
}

- (NSString *)CSRFToken
{
    for (NSHTTPCookie *cookie in [self cookies]) {
        if ([cookie.name isEqualToString:kIXFCsrftoken]) {
            return cookie.value;
        }
    }
    return NO;
}

- (BOOL)cookiesExpired
{
   return [self cookiesExpired:_user];
}

- (BOOL)cookiesExpired:(IXFUser *)user
{
    NSDate *date = [NSDate date];
    for (NSHTTPCookie *cookie in [self cookies]) {
//        if ([cookie.name isEqualToString:@"sessionid"] &&
//            !cookie.sessionOnly &&
//            [[cookie.expiresDate earlierDate:date] isEqual:date]) {
//            for (NSHTTPCookie *cookie in [self cookies]) {
//                if ([cookie.name isEqualToString:@"checkpoint_step"] &&
//                    !cookie.sessionOnly &&
//                    [[cookie.expiresDate earlierDate:date] isEqual:date]) {
//                    return YES;
//                }
//            }
//            return NO;
//        } else
        if ([cookie.name isEqualToString:@"ds_user_id"] &&
            [cookie.value integerValue] == user.identifier &&
            [[cookie.expiresDate earlierDate:date] isEqual:date]) {
            return NO;
        }
    }
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
    
    }];
    return YES;
}

#pragma mark - Error Handlers

- (BOOL)shouldHandleError:(IXFQueueItem *)queueItem
             JSONResponce:(NSDictionary *)dictionary
        completionHandler:(void (^)(IXFQueueItem *queueItem))completionHandler
{
    return [self shouldHandleError:queueItem
                           forUser:_user
                      JSONResponce:dictionary
                 completionHandler:completionHandler];
}

- (BOOL)shouldHandleError:(IXFQueueItem *)queueItem
                  forUser:(IXFUser *)user
             JSONResponce:(NSDictionary *)dictionary
        completionHandler:(void (^)(IXFQueueItem *queueItem))completionHandler
{
    NSString *errMessage = [dictionary objectForKey:kIXFMessage];
    
    if ([errMessage isEqualToString:kIXFCheckpoint_Required]) {
        NSString *checkpointURL = [dictionary objectForKey:kIXFCheckpoint_Url];
        if (checkpointURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kCheckpointNotificationKey
                                                                    object:self
                                                                  userInfo:@{kCheckpointObjectKey : checkpointURL}];
                
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
                noc.title = @"Attention Required";
                noc.subtitle = [NSString stringWithFormat:@"Check Point for @%@", user.name];
                noc.informativeText = @"Please login and varify the mentioned Instagram account.";
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
        }
    } else if ([errMessage isEqualToString:kIXFLogin_Required]) {
        if (queueItem.retries < queueItem.maxAttempts ||
            (queueItem.maxAttempts == 0 && queueItem.retries < kRetries)) {
            LOGD(@"login_required: %@", user.name);
            queueItem.retries++;
            queueItem.status = IXFQueueStatusFailed;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self switchUserWithName:queueItem.user forced:YES];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (queueItem && completionHandler) {
                        completionHandler(queueItem);
                    }
                });
            });
            return YES;
        }
    } else if ([errMessage isEqualToString:@"feedback_required"]) {
        NSString *title = [dictionary objectForKey:@"feedback_title"];
        NSString *message = [dictionary objectForKey:@"feedback_message"];
        if (title && message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUserNotification *noc = [[NSUserNotification alloc] init];
                noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
                noc.title = title;
                noc.subtitle = message;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                    object:self
                                                                  userInfo:@{kNotificationObjectKey : noc}];
            });
            return YES;
        }
    }
    return NO;
}

#pragma mark - Account Management

#pragma mark Challenge (GET)
- (void)challenge:(IXFUser *)user
{
    _busy++;
    NSString *userAgent = [user userAgent];
    
    if (!userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
//    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",
                                        kAPIBaseURL,
                                        kIXFChallengeFormat,
                                        [[self class] guidWithoutDash]]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    [self sendRequest:request
              forUser:user
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToLoginWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
                if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLoginWithErrorMessage:[self errorMessageForStatusCode:errorCode]];
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loginWithUser:user];
                });
            }
        }
        _busy--;
    }];
}

#pragma mark Login (POST)

- (void)login
{
    if (_user) {
        [self loginWithUser:_user];
    }
}

- (void)loginWithUser:(IXFUser *)user
{
    _busy++;
    
    if ([_delegate respondsToSelector:@selector(shouldLogin)]) {
        if (![_delegate shouldLogin]) {
            _busy--;
            return;
        }
    }
    
    if (![user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    if ([self CSRFToken] == nil) {
        [self challenge:user];
        _busy--;
        return;
    }
    
    if (![self cookiesExpired:user]) {
        if ([user clientNeedsUpgrade]) {
            [user upgradeClient];
            LOGD(@"%@", [user.client version]);
        }
        [self addThenSwitchToUser:user];
        if ([_delegate respondsToSelector:@selector(wasLoggedIn)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                    object:self
                                                                  userInfo:@{kUserObjectKey : user}];
                [_delegate wasLoggedIn];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:user.name               forKey:kIXFUsername];
    [requestDict setObject:user.password           forKey:kIXFPassword];
    [requestDict setObject:user.device.GUID        forKey:kIXFGuid];
    [requestDict setObject:user.device.identifier  forKey:kIXFDevice_id];
    [requestDict setObject:@0                      forKey:kIXFlogin_attempt_count];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    requestData = [self sign:requestData forUser:user];
    NSString *userAgent = [user userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, kIXFLogin]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
              forUser:user
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([_delegate respondsToSelector:@selector(willFinishLoggingIn)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate willFinishLoggingIn];
            });
        }
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToLoginWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLoginWithErrorMessage:[jsonError localizedDescription]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:nil
                                        forUser:user
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didFailToLoginWithErrorMessage:(errMessage.length) ? errMessage : [self errorMessageForStatusCode:errorCode]];
                        });
                    }
                    _busy--;
                    return;
                } else {
                    NSDictionary *logged_in_user = [jsonDictionary objectForKey:kIXFlogged_in_user];
                    
                    if ([logged_in_user objectForKey:kIXFpk] &&
                        [logged_in_user objectForKey:kIXFfull_name] &&
                        [logged_in_user objectForKey:kIXFis_private] &&
                        [logged_in_user objectForKey:kIXFhas_anonymous_profile] &&
                        [logged_in_user objectForKey:kIXFprofile_pic_url]) {
                        user.identifier = [[logged_in_user objectForKey:kIXFpk] integerValue];
                        user.fullname = [logged_in_user objectForKey:kIXFfull_name];
                        user.isPrivate = [[logged_in_user objectForKey:kIXFis_private] boolValue];
                        user.hasAnonymousProfilePicture = [[logged_in_user objectForKey:kIXFhas_anonymous_profile] boolValue];
                        user.avatarURL = [logged_in_user objectForKey:kIXFprofile_pic_url];
                        user.verified = [[logged_in_user objectForKey:kIXFis_verified] boolValue];
                        if ([_delegate respondsToSelector:@selector(didReceiveLoginJSONResponse:statusCode:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didReceiveLoginJSONResponse:jsonDictionary statusCode:errorCode];
                            });
                        }
                    } else {
                        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToLoginWithErrorMessage:kDefaultError];
                            });
                        }
                        _busy--;
                        return;
                    }
                }
            }
        }
        BOOL switched = [self addThenSwitchToUser:user];
        if (switched == YES) {
            [self storeUsersToKeychain:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                    object:self
                                                                  userInfo:@{kUserObjectKey : _user}];
            });
            if ([_delegate respondsToSelector:@selector(didFinishLoggingIn)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFinishLoggingIn];
                });
            }
        } else {
            if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToLoginWithErrorMessage:kDefaultError];
                });
            }
        }
        _busy--;
    }];
}

#pragma mark Logout (POST)
- (void)logout
{
    _busy++;
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLogoutWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, kIXFLogout]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([_delegate respondsToSelector:@selector(willFinishLoggingOut)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate willFinishLoggingOut];
            });
        }
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToLogoutWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLogoutWithErrorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                    [self errorMessageForStatusCode:errorCode],
                                                                    [jsonError localizedDescription]]];
                    });
                }
                _busy--;
                return;
            } else {
                [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                    if ([self switchToNextUserAndRemoveCurrent] == NO) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldDisplayLoginNotificationKey
                                                                                object:self];
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                                object:self
                                                                              userInfo:nil];
                        });
                        LOGD(@"%@, %@", _user.name, [self allUsers]);
                    }
                    if ([_delegate respondsToSelector:@selector(didReceiveLogoutJSONResponse:statusCode:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didReceiveLogoutJSONResponse:jsonDictionary statusCode:errorCode];
                        });
                    }
                    if ([_delegate respondsToSelector:@selector(didFinishLoggingOut)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didFinishLoggingOut];
                        });
                    }
                }];
            }
        }
        _busy--;
    }];
}

#pragma mark - Upload

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                              data:(NSArray<NSDictionary *>*)dataArray
                             field:(NSString *)field
{
    NSMutableData *body = [NSMutableData data];
    
    // add params (all params are strings)
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey,
                                                    NSString *parameterValue,
                                                    BOOL *stop)
    {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:kIXFContent_Disposition, parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // add image data
    
    for (NSDictionary *dataDict in dataArray) {
        NSString *filename  = [dataDict objectForKey:@"f"];
        NSString *mimetype  = [dataDict objectForKey:@"m"];
        NSData *data        = [dataDict objectForKey:@"d"];
        
        if (filename != nil &&
            mimetype != nil &&
            data != nil) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:kIXFContent_Disposition_FN, field, filename] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:kIXFContent_Type, mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:data];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return body;
}

#pragma mark Upload Image (POST)
- (void)uploadImage:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if ([_delegate respondsToSelector:@selector(shouldUploadImage)]) {
        if (![_delegate shouldUploadImage]) {
            _busy--;
            return;
        }
    }
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    [queueItem generateUUID];
    NSString *timestemp = [queueItem timestemp];
    
    if (timestemp == nil) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *compressionDict = [NSMutableDictionary new];
    
    [compressionDict setObject:@"jt"            forKey:@"lib_name"];
    [compressionDict setObject:kJTLibVersion    forKey:@"lib_version"];
    [compressionDict setObject:@(kJTLibQuality) forKey:@"quality"];
    
    NSData *compressionData = [NSJSONSerialization dataWithJSONObject:compressionDict
                                                              options:0
                                                                error:nil];
    NSString *compression = [[NSString alloc] initWithData:compressionData encoding:NSUTF8StringEncoding];
    
    NSDictionary *params = @{@"upload_id"           : timestemp,
                             @"_uuid"               : _user.device.GUID,
                             @"_csrftoken"          : [self CSRFToken],
                             @"image_compression"   : compression};
    
    NSData *requestData = [self createBodyWithBoundary:queueItem.UUID
                                            parameters:params
                                                  data:@[@{@"f" : [NSString stringWithFormat:@"pending_media_%@.jpg", timestemp],
                                                           @"m" : kHTTPApplicationOctectStream,
                                                           @"d" : [queueItem.image data]}]
                                                 field:@"photo"];
    
    NSString *userAgent = [_user userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/upload/photo/"]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", queueItem.UUID]
   forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([_delegate respondsToSelector:@selector(willFinishUploadingImage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate willFinishUploadingImage:queueItem.UUID ];
            });
        }
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadImage:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                         [self errorMessageForStatusCode:errorCode],
                                                         [jsonError localizedDescription]]];
                    });
                }
            } else {
                LOGD(@"%@", jsonDictionary);
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadImage:queueItem.UUID
                                                   errorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self configureImage:queueItem];
                    });
                }
            }
        }
        _busy--;
    }];
}

#pragma mark Configure Image (POST)
- (void)configureImage:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *caption = [queueItem.caption captionString];
    
    NSMutableDictionary *editsDict = [NSMutableDictionary new];
    
    [editsDict setObject:@(1.f)                     forKey:@"crop_zoom"];
    [editsDict setObject:@[@(0.f), @(-0.f)]         forKey:@"crop_center"];
    //[editsDict setObject:@(0.f)                     forKey:@"black_pixels_ratio"];
    [editsDict setObject:[queueItem imageSize]      forKey:@"crop_original_size"];
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:[queueItem timestemp]    forKey:@"upload_id"];
    [requestDict setObject:@3                       forKey:@"source_type"];
    [requestDict setObject:[self CSRFToken]         forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID        forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)      forKey:@"_uid"];
    [requestDict setObject:[_user deviceDictionary] forKey:@"device"];
    [requestDict setObject:editsDict                forKey:@"edits"];
    [requestDict setObject:caption                  forKey:@"caption"];
    
    // 9.1.5
    [requestDict setObject:[[queueItem date] dateStringWithFormat:kInstagramDateFormat] forKey:@"date_time_original"];
    [requestDict setObject:[[queueItem date] dateStringWithFormat:kInstagramDateFormat] forKey:@"date_time_digitalized"];
    [requestDict setObject:_user.device.model       forKey:@"camera_model"];
    [requestDict setObject:[[_user.device.manufacturer componentsSeparatedByString:@"/"] objectAtIndex:0]
                    forKey:@"camera_make"];
    
    if (queueItem.location != nil) {
        // NSDictionary *locDict = [queueItem.location locationDictionary];
        NSString *locJSON = [queueItem.location locationJSON];
        if (locJSON != nil) {
            [requestDict setObject:locJSON  forKey:@"location"];
            [requestDict setObject:@(-1)    forKey:@"suggested_venue_position"];
            [requestDict setObject:@NO      forKey:@"is_suggested_venue"];
        }
    }
    
    LOGD(@"requestDict: %@", requestDict);
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadImage:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
//    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL,@"/media/configure/"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadImage:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_delegate didFailToUploadImage:queueItem.UUID
//                                           errorMessage:[self errorMessageForStatusCode:errorCode]];
//                    });
//                }
//            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                         [self errorMessageForStatusCode:errorCode],
                                                         [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadImage:queueItem.UUID
                                                   errorMessage:errMessage];
                            });
                        }
                    }
                    
                } else {
                    NSString *mediaID = [[jsonDictionary objectForKey:@"media"] objectForKey:@"id"];
                    if (mediaID != nil) {
                        queueItem.mediaID = mediaID;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self permalink:queueItem];
                        });
                    } else {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadImage:queueItem.UUID
                                                   errorMessage:kDefaultError];
                            });
                        }
                    }
                }
            }
        }
        _busy--;
    }];
}

#pragma mark Configuring Video (POST)
- (void)uploadVideo:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if ([_delegate respondsToSelector:@selector(shouldUploadVideo)]) {
        if (![_delegate shouldUploadVideo]) {
            _busy--;
            return;
        }
    }
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    [queueItem generateUUID];
    NSString *timestemp = [queueItem timestemp];
    
    if (timestemp == nil) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableData *requestData = [[NSMutableData alloc] init];
    
    // upload_id
    [requestData appendData:[[NSString stringWithFormat:@"upload_id=%@",
                              timestemp]
                             dataUsingEncoding:NSUTF8StringEncoding]];
    // media_type
    [requestData appendData:[[NSString stringWithFormat:@"&media_type=%d",
                              3]
                             dataUsingEncoding:NSUTF8StringEncoding]];
    // _uuid
    [requestData appendData:[[NSString stringWithFormat:@"&_uuid=%@",
                              _user.device.GUID]
                             dataUsingEncoding:NSUTF8StringEncoding]];
    // upload_media_duration_ms
    [requestData appendData:[[NSString stringWithFormat:@"&upload_media_duration_ms=%.f",
                              roundf([queueItem videoDurationSeconds] * 1000)]
                             dataUsingEncoding:NSUTF8StringEncoding]];
    
    // _csrftoken
    [requestData appendData:[[NSString stringWithFormat:@"&_csrftoken=%@",
                              [self CSRFToken]]
                             dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *userAgent = [_user userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/upload/video/"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadVideo:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_delegate didFailToUploadVideo:queueItem.UUID
//                                           errorMessage:[self errorMessageForStatusCode:errorCode]];
//                    });
//                }
//            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                         [self errorMessageForStatusCode:errorCode],
                                                         [jsonError localizedDescription]]];
                    });
                }
            } else {
                LOGD(@"%@", jsonDictionary);
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    NSDictionary *url = [[jsonDictionary objectForKey:@"video_upload_urls"] objectAtIndex:0];
                    if ([url objectForKey:@"url"] && [url objectForKey:@"job"]) {
                        queueItem.videoURL = [url objectForKey:@"url"];
                        queueItem.videoJob = [url objectForKey:@"job"];
                        queueItem.videoStage = 0;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self stageVideo:queueItem];
                        });
                    } else {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:kDefaultError];
                            });
                        }
                    }
                }
            }
        }
        _busy--;
    }];
}

#pragma mark Stage Video (POST)
- (void)stageVideo:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *timestemp = [queueItem timestemp];
    
    if (timestemp == nil) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    if (!queueItem.videoURL || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    NSData *videoData = [queueItem videoChunk];
    NSUInteger dataLength = videoData.length;
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:queueItem.videoURL];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:kHTTPContentType];
    [request addValue:@"$Version=1" forHTTPHeaderField:@"Cookie2"];
    [request setValue:@"attachment; filename=\"video.mov\"" forHTTPHeaderField:@"Content-Disposition"];
    [request setValue:[NSString stringWithFormat:@"bytes %ld-%ld/%ld",
                       [queueItem currentStageOffset],
                       [queueItem currentStageOffset] + dataLength - 1,
                       queueItem.video.length] forHTTPHeaderField:@"Content-Range"];
    [request setValue:queueItem.videoJob forHTTPHeaderField:@"job"];
    [request setValue:timestemp forHTTPHeaderField:@"Session-ID"];
    [request setValue:[NSString stringWithFormat:@"%ld", dataLength] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:videoData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
//    LOGD(@"%@", [request allHTTPHeaderFields]);
    
    LOGD(@"bytes %ld-%ld/%ld",
         [queueItem currentStageOffset],
         [queueItem currentStageOffset] + dataLength - 1,
         queueItem.video.length);
    
    queueItem.videoStage++;
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadVideo:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_delegate didFailToUploadVideo:queueItem.UUID
//                                           errorMessage:[self errorMessageForStatusCode:errorCode]];
//                    });
//                }
//            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([queueItem videoChunk] != nil) {
                    [self stageVideo:queueItem];
                } else {
                    NSError *jsonError;
                    NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
                    if (jsonError) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                 [self errorMessageForStatusCode:errorCode],
                                                                 [jsonError localizedDescription]]];
                            });
                        }
                    } else {
                        LOGD(@"%@", jsonDictionary);
                        NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                        if (![status isEqualToString:kIXFOK] ||
                            ![self responseSuccessful:errorCode]) {
                            
                            if ([self shouldHandleError:queueItem
                                           JSONResponce:jsonDictionary
                                      completionHandler:nil]) {
                                _busy--;
                                return;
                            }
                            
                            NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                            if (errMessage.length) {
                                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadVideo:queueItem.UUID
                                                           errorMessage:errMessage];
                                    });
                                }
                            }
                        } else {
                            if ([jsonDictionary objectForKey:@"result"]) {
                                queueItem.videoResult = [jsonDictionary objectForKey:@"result"];
                                [self uploadCover:queueItem];
                            } else {
                                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadVideo:queueItem.UUID
                                                           errorMessage:kDefaultError];
                                    });
                                }
                            }
                        }
                    }
                    
                }
            });
        }
        _busy--;
    }];
}

#pragma mark Upload Video Cover Image (POST)
- (void)uploadCover:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *timestemp = [queueItem timestemp];
    
    if (timestemp == nil) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *compressionDict = [NSMutableDictionary new];
    
    [compressionDict setObject:@"jt"            forKey:@"lib_name"];
    [compressionDict setObject:kJTLibVersion    forKey:@"lib_version"];
    [compressionDict setObject:@(kJTLibQuality) forKey:@"quality"];
    
    NSData *compressionData = [NSJSONSerialization dataWithJSONObject:compressionDict
                                                              options:0
                                                                error:nil];
    NSString *compression = [[NSString alloc] initWithData:compressionData encoding:NSUTF8StringEncoding];
    
    NSDictionary *params = @{@"upload_id"           : timestemp,
                             @"_uuid"               : _user.device.GUID,
                             @"_csrftoken"          : [self CSRFToken],
                             @"image_compression"   : compression};
    
    NSData *requestData = [self createBodyWithBoundary:queueItem.UUID
                                            parameters:params
                                                  data:@[@{@"f" : [NSString stringWithFormat:@"pending_media_%@.jpg", timestemp],
                                                           @"m" : @"application/octet-stream",
                                                           @"d"     : [queueItem.image data]}]
                                                 field:@"photo"];
    
    NSString *userAgent = [_user userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/upload/photo/"]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", queueItem.UUID]
   forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadVideo:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_delegate didFailToUploadVideo:queueItem.UUID
//                                           errorMessage:[self errorMessageForStatusCode:errorCode]];
//                    });
//                }
//            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                         [self errorMessageForStatusCode:errorCode],
                                                         [jsonError localizedDescription]]];
                    });
                }
            } else {
                LOGD(@"%@", jsonDictionary);
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self configureCover:queueItem];
                    });
                }
            }
        }
        _busy--;
    }];
}

#pragma mark Configure Cover (POST)
- (void)configureCover:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *caption = [queueItem.caption captionString];
    
    NSMutableDictionary *clipsDict = [NSMutableDictionary new];
    
    CGFloat length = round([queueItem videoDurationSeconds] * 1000) / 1000.f;
    
    [clipsDict setObject:@(length)  forKey:@"length"];
    [clipsDict setObject:@3         forKey:@"source_type"];
    [clipsDict setObject:@"back"    forKey:@"camera_position"];
    
    NSMutableDictionary *extraDict = [NSMutableDictionary new];
    
    [extraDict setObject:@(lroundf([queueItem videoPixelWidth]))
                  forKey:@"source_width"];
    [extraDict setObject:@(lroundf([queueItem videoPixelHeight]))
                  forKey:@"source_height"];
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:@0                           forKey:@"poster_frame_index"];
    [requestDict setObject:@(length)                    forKey:@"length"];
    [requestDict setObject:@NO                          forKey:@"audio_muted"];
    [requestDict setObject:@0                           forKey:@"filter_type"];
    [requestDict setObject:queueItem.videoResult        forKey:@"video_result"];
    [requestDict setObject:[queueItem timestemp]        forKey:@"upload_id"];
    [requestDict setObject:@3                           forKey:@"source_type"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    [requestDict setObject:[_user deviceDictionary]     forKey:@"device"];
    [requestDict setObject:extraDict                    forKey:@"extra"];
    [requestDict setObject:@[clipsDict]                 forKey:@"clips"];
    [requestDict setObject:caption                      forKey:@"caption"];
    
    if (queueItem.location != nil) {
        // NSDictionary *locDict = [queueItem.location locationDictionary];
        NSString *locJSON = [queueItem.location locationJSON];
        if (locJSON != nil) {
            [requestDict setObject:locJSON  forKey:@"location"];
            [requestDict setObject:@(-1)    forKey:@"suggested_venue_position"];
            [requestDict setObject:@NO      forKey:@"is_suggested_venue"];
        }
    }
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToUploadVideo:queueItem.UUID
                                   errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/media/configure/?video=1"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToUploadVideo:queueItem.UUID
                                       errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_delegate didFailToUploadVideo:queueItem.UUID
//                                           errorMessage:[self errorMessageForStatusCode:errorCode]];
//                    });
//                }
//            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                         [self errorMessageForStatusCode:errorCode],
                                                         [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    NSString *mediaID = [[jsonDictionary objectForKey:@"media"] objectForKey:@"id"];
                    if (mediaID != nil) {
                        queueItem.mediaID = mediaID;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self permalink:queueItem];
                        });
                    } else {
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:kDefaultError];
                            });
                        }
                    }
                }
            }
        }
//        if ([_delegate respondsToSelector:@selector(didFinishUploadingVideo:)]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [_delegate didFinishUploadingVideo:queueItem.UUID];
//            });
//        }
        _busy--;
    }];
}

#pragma mark Delete Media (POST)
- (void)deleteMedia:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (![_user.name isEqualToString:queueItem.user] ||
        ![_user integrity] || queueItem.mediaID.length == 0) {
        if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:queueItem.mediaID            forKey:@"media_id"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/delete/?media_type=%@",
                                        kAPIBaseURL,
                                        queueItem.mediaID,
                                        (queueItem.mode == IXFQueueModeImage) ? @"PHOTO" : @"VIDEO"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                                     [self errorMessageForStatusCode:errorCode],
                                                                                     [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    [[jsonDictionary objectForKey:@"did_delete"] boolValue] != YES ||
                    ![self responseSuccessful:errorCode]) {
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToDeleteMedia:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToDeleteMedia:queueItem.UUID errorMessage:errMessage];
                            });
                        }
                    }
                }
            }
        }
        if ([_delegate respondsToSelector:@selector(didFinishDeletingMedia:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFinishDeletingMedia:queueItem.UUID];
            });
        }
        _busy--;
    }];
}

#pragma mark Edit Media (POST)
- (BOOL)editMedia:(IXFFeedItem *)feedItem
{
    _busy++;
    
    if (![_user.name isEqualToString:feedItem.user.name] ||
        ![_user integrity] ||
        feedItem.mediaID.length == 0) {
        _busy--;
        return NO;
    }
    
    /* signed_body=c1a8a18bbfca50e3fdd6eed7b855196f83861e5ff77b05096340b7407e6efada.{"caption_text":"A","_csrftoken":"206761838c70e903cafbea38f8c983fd","usertags":"{\"in\":[]}","_uid":"1815469027","_uuid":"b3b4b4ab-2663-48d1-92dd-635d4901a5e9","location":"{}"}&ig_sig_key_version=4 */
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:feedItem.caption             forKey:@"caption_text"];
//    [requestDict setObject:@{@"in" : @[]}               forKey:@"usertags"];
    
//    if (feedItem.location != nil) {
//        [requestDict setObject:[feedItem.location locationJSON]
//                        forKey:@"location"];
//    } else {
//        [requestDict setObject:@{}
//                        forKey:@"location"];
//    }
    
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        _busy--;
        return NO;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        _busy--;
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/edit_media/",
                                        kAPIBaseURL,
                                        feedItem.mediaID]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *data;
    NSURLResponse *response;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&error];
    // Needs Internet no more.
    _busy--;
    
    if (error) {
        return NO;
    } else if (response) {
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&error];
        LOGD(@"%@", jsonDictionary);
        if (error) {
            return NO;
        } else {
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}



#pragma mark Permalink (GET)

- (void)permalink:(IXFQueueItem *)queueItem
{
    _busy++;
    
    if (queueItem.mediaID == nil) {
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            default:
                break;
        }
        _busy--;
        return;
    }
    
    if (![_user integrity]) {
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            default:
                break;
        }
        _busy--;
        return;
    }
    
    NSString *timestemp = [queueItem timestemp];
    
    if (timestemp == nil) {
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            default:
                break;
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadImage:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToUploadVideo:queueItem.UUID
                                           errorMessage:kDefaultError];
                    });
                }
                break;
            default:
                break;
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/permalink/",
                                        kAPIBaseURL,
                                        queueItem.mediaID]];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPMethod:@"GET"];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(willFinishUploadingImage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate willFinishUploadingImage:queueItem.UUID ];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(willFinishUploadingVideo:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate willFinishUploadingVideo:queueItem.UUID ];
                    });
                }
                break;
            default:
                break;
        }
        if (error) {
            switch (queueItem.mode) {
                case IXFQueueModeImage:
                    if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didFailToUploadImage:queueItem.UUID
                                               errorMessage:[error localizedDescription]];
                        });
                    }
                    break;
                case IXFQueueModeVideo:
                    if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didFailToUploadVideo:queueItem.UUID
                                               errorMessage:[error localizedDescription]];
                        });
                    }
                    break;
                default:
                    break;
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
//            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
//                switch (queueItem.mode) {
//                    case IXFQueueModeImage:
//                        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                [_delegate didFailToUploadImage:queueItem.UUID
//                                                   errorMessage:[self errorMessageForStatusCode:errorCode]];
//                            });
//                        }
//                        break;
//                    case IXFQueueModeVideo:
//                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                [_delegate didFailToUploadVideo:queueItem.UUID
//                                                   errorMessage:[self errorMessageForStatusCode:errorCode]];
//                            });
//                        }
//                        break;
//                    default:
//                        break;
//                }
//            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                switch (queueItem.mode) {
                    case IXFQueueModeImage:
                        if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadImage:queueItem.UUID
                                                   errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                 [self errorMessageForStatusCode:errorCode],
                                                                 [jsonError localizedDescription]]];
                            });
                        }
                        break;
                    case IXFQueueModeVideo:
                        if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToUploadVideo:queueItem.UUID
                                                   errorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                 [self errorMessageForStatusCode:errorCode],
                                                                 [jsonError localizedDescription]]];
                            });
                        }
                        break;
                    default:
                        break;
                }
            } else {
                LOGD(@"%@", jsonDictionary);
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:queueItem
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        switch (queueItem.mode) {
                            case IXFQueueModeImage:
                                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadImage:queueItem.UUID
                                                           errorMessage:errMessage];
                                    });
                                }
                                break;
                            case IXFQueueModeVideo:
                                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadVideo:queueItem.UUID
                                                           errorMessage:errMessage];
                                    });
                                }
                                break;
                            default:
                                break;
                        }
                    }
                } else {
                    NSString *permalink = [jsonDictionary objectForKey:@"permalink"];
                    if (permalink != nil) {
                        queueItem.URL = [NSURL URLWithString:permalink];
                        switch (queueItem.mode) {
                            case IXFQueueModeImage:
                                if ([_delegate respondsToSelector:@selector(didReceiveUploadImage:JSONResponse:statusCode:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didReceiveUploadImage:queueItem.UUID
                                                            JSONResponse:jsonDictionary
                                                              statusCode:errorCode];
                                    });
                                }
                                break;
                            case IXFQueueModeVideo:
                                if ([_delegate respondsToSelector:@selector(didReceiveUploadVideo:JSONResponse:statusCode:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didReceiveUploadVideo:queueItem.UUID
                                                            JSONResponse:jsonDictionary
                                                              statusCode:errorCode];
                                    });
                                }
                                break;
                            default:
                                break;
                        }
                    } else {
                        switch (queueItem.mode) {
                            case IXFQueueModeImage:
                                if ([_delegate respondsToSelector:@selector(didFailToUploadImage:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadImage:queueItem.UUID
                                                           errorMessage:kDefaultError];
                                    });
                                }
                                break;
                            case IXFQueueModeVideo:
                                if ([_delegate respondsToSelector:@selector(didFailToUploadVideo:errorMessage:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_delegate didFailToUploadVideo:queueItem.UUID
                                                           errorMessage:kDefaultError];
                                    });
                                }
                                break;
                            default:
                                break;
                        }
                    }
                }
            }
        }
        switch (queueItem.mode) {
            case IXFQueueModeImage:
                if ([_delegate respondsToSelector:@selector(didFinishUploadingImage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFinishUploadingImage:queueItem.UUID];
                    });
                }
                break;
            case IXFQueueModeVideo:
                if ([_delegate respondsToSelector:@selector(didFinishUploadingVideo:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFinishUploadingVideo:queueItem.UUID];
                    });
                }
                break;
            default:
                break;
        }
        _busy--;
    }];
}

#pragma mark - Locations

- (void)nearbyLocations:(CLLocationCoordinate2D)coordinate
      completionHandler:(void (^)(NSArray *locations,
                                  NSError *error))completionHandler
{
    if (![_user integrity] || ![_user identifierString]) {
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/location_search/?rank_token=%@_%@&latitude=%f&longitude=%f",
                                        kAPIBaseURL,
                                        [_user identifierString],
                                        _user.device.GUID,
                                        coordinate.latitude,
                                        coordinate.longitude]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completionHandler(nil, error);
        } else if (!error && response) {
            NSInteger errorCode;
            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
                completionHandler(nil, nil);
            }
            
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                completionHandler(nil, jsonError);
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if ([status isEqualToString:kIXFOK] &&
                    [self responseSuccessful:errorCode]) {
                    NSMutableArray *nearbyArray = [NSMutableArray array];
                    if ([jsonDictionary objectForKey:@"venues"]) {
                        for (NSDictionary *item in [[jsonDictionary objectForKey:@"venues"] allObjects]) {
                            IXFLocation *location = [IXFLocation new];
                            location.name = [item objectForKey:@"name"];
                            location.address = [item objectForKey:@"address"];
                            location.externalID = [[item objectForKey:@"external_id"] integerValue];
                            location.externalIDSource = [item objectForKey:@"external_id_source"];
                            location.location = [[CLLocation alloc] initWithLatitude:[[item objectForKey:@"lat"] floatValue]
                                                                           longitude:[[item objectForKey:@"lng"] floatValue]];
                            location.latitude = [item objectForKey:@"lat"];
                            location.longitude = [item objectForKey:@"lng"];
                            
                            if (location.name.length < 1 ||
                                location.address.length < 1 ||
                                [location.name isEqualToString:@"<<not-applicable>>"] ||
                                [location.address isEqualToString:@"<<not-applicable>>"]) {
                                continue;
                            } else {
                                [nearbyArray addObject:location];
                            }
                        }
//                        LOGD(@"Locations: %@", [[jsonDictionary objectForKey:@"venues"] allObjects]);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(nearbyArray, nil);
                        });
                    }
                }
            }
        }
        
    }];
}

#pragma mark - Profile Picture

#pragma mark Change Profile Picture (POST)
- (void)changeProfilePicture:(NSImage *)image
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToChangeProfilePictureWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *signedBodyDict = [NSMutableDictionary new];
    
    [signedBodyDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [signedBodyDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [signedBodyDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *signedBodyData = [NSJSONSerialization dataWithJSONObject:signedBodyDict
                                                             options:0
                                                               error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToChangeProfilePictureWithErrorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    signedBodyData = [self sign:signedBodyData];
    
    NSString *signedBodyString = [[NSString alloc] initWithData:signedBodyData
                                                       encoding:NSUTF8StringEncoding];
    
    NSData *resizedImageData = [[image resizeWithMaxLength:kInstagramSize] data];
    
    if (!signedBodyString || !resizedImageData) {
        if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToRemoveProfilePictureWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSString *boundary = [[[NSUUID UUID] UUIDString] lowercaseString];
    
    NSDictionary *params = @{@"ig_sig_key_version"  : [NSString stringWithFormat:@"%ld", _user.client.signatureVersion],
                             @"signed_body"         : signedBodyString};
    
    NSData *requestData = [self createBodyWithBoundary:boundary
                                            parameters:params
                                                  data:@[@{@"f" : @"profile_pic",
                                                           @"m" : @"application/octet-stream",
                                                           @"d" : resizedImageData}]
                                                 field:@"profile_pic"];
    
    NSString *userAgent = [_user userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToChangeProfilePictureWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/accounts/change_profile_picture/"]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
   forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToChangeProfilePictureWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToChangeProfilePictureWithErrorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                                  [self errorMessageForStatusCode:errorCode],
                                                                                  [jsonError localizedDescription]]];
                    });
                }
            } else {
                LOGD(@"%@", jsonDictionary);
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToChangeProfilePictureWithErrorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    NSDictionary *logged_in_user = [jsonDictionary objectForKey:@"user"];
                    
//                    {
//                        status = ok;
//                        user =     {
//                            biography = "";
//                            "external_url" = "";
//                            "full_name" = t1337;
//                            "has_anonymous_profile_picture" = 0;
//                            "hd_profile_pic_url_info" =         {
//                                height = 150;
//                                url = "http://scontent-tpe1-1.cdninstagram.com/t51.2885-19/13277520_709939619146902_1259356147_a.jpg";
//                                width = 150;
//                            };
//                            "is_private" = 1;
//                            pk = 3294592948;
//                            "profile_pic_id" = "1264447861205898569_3294592948";
//                            "profile_pic_url" = "http://scontent-tpe1-1.cdninstagram.com/t51.2885-19/13277520_709939619146902_1259356147_a.jpg";
//                            username = t13337;
//                        };
                    
                    if ([[logged_in_user objectForKey:kIXFpk] integerValue] == _user.identifier) {
                        if ([logged_in_user objectForKey:kIXFfull_name]) {
                            _user.fullname = [logged_in_user objectForKey:kIXFfull_name];
                        }
                        if ([logged_in_user objectForKey:kIXFhas_anonymous_profile]) {
                            _user.hasAnonymousProfilePicture = [[logged_in_user objectForKey:kIXFhas_anonymous_profile] boolValue];
                        }
                        if ([logged_in_user objectForKey:kIXFis_private]) {
                            _user.isPrivate = [[logged_in_user objectForKey:kIXFis_private] boolValue];
                        }
                        if ([logged_in_user objectForKey:kIXFprofile_pic_url]) {
                            _user.avatarURL = [logged_in_user objectForKey:kIXFprofile_pic_url];
                        }
                        if ([logged_in_user objectForKey:kIXFis_verified]) {
                            _user.verified = [[logged_in_user objectForKey:kIXFis_verified] boolValue];
                        }
                        [self storeUsersToKeychain:nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                                object:self
                                                                              userInfo:@{kUserObjectKey : _user}];
                        });
                        if ([_delegate respondsToSelector:@selector(didFinishChangingProfilePicture)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFinishChangingProfilePicture];
                            });
                        }
                    } else {
                        NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                        if (errMessage.length) {
                            if ([_delegate respondsToSelector:@selector(didFailToChangeProfilePictureWithErrorMessage:)]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [_delegate didFailToChangeProfilePictureWithErrorMessage:kDefaultError];
                                });
                            }
                        }
                    }
                }
            }
        }
        _busy--;
    }];
}

#pragma mark Remove Profile Picture (POST)
- (void)removeProfilePicture
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToRemoveProfilePictureWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToRemoveProfilePictureWithErrorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToRemoveProfilePictureWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, @"/accounts/remove_profile_picture/"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToRemoveProfilePictureWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToRemoveProfilePictureWithErrorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                                  [self errorMessageForStatusCode:errorCode],
                                                                                  [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToRemoveProfilePictureWithErrorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToRemoveProfilePictureWithErrorMessage:errMessage];
                            });
                        }
                    }
                }
            }
        }
        _user.avatar = nil;
        _user.avatarURL = nil;
        _user.hasAnonymousProfilePicture = YES;
        [self storeUsersToKeychain:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoDidChangeNotificationKey
                                                                object:self
                                                              userInfo:@{kUserObjectKey : _user}];
        });
        if ([_delegate respondsToSelector:@selector(didFinishRemovingProfilePicture)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFinishRemovingProfilePicture];
            });
        }
        _busy--;
    }];
}

#pragma mark - Private Account

#pragma mark Set Private (POST)

- (void)togglePrivate
{
    [self setPrivate:!_user.isPrivate];
}

- (void)setPrivate:(BOOL)option
{
    _busy++;
    
    if (![_user integrity]) {
        if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToSetPrivateWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToSetPrivateWithErrorMessage:[error localizedDescription]];
            });
        }
        _busy--;
        return;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToSetPrivateWithErrorMessage:kDefaultError];
            });
        }
        _busy--;
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                        kAPIBaseURL,
                                        (option) ? @"/accounts/set_private/" : @"/accounts/set_public/"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToSetPrivateWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToSetPrivateWithErrorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                        [self errorMessageForStatusCode:errorCode],
                                                                        [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        _busy--;
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToSetPrivateWithErrorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToSetPrivateWithErrorMessage:errMessage];
                            });
                        }
                    }
                }
            }
        }
        _user.isPrivate = option;
        [self storeUsersToKeychain:nil];
        if ([_delegate respondsToSelector:@selector(didFinishSettingPrivate:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFinishSettingPrivate:option];
            });
        }
        _busy--;
    }];
}

#pragma mark - Timeline

- (void)feed:(IXFUser *)user
{
    [self feed:user maxID:nil];
}

#pragma mark Timeline (GET)
- (void)feed:(IXFUser *)user maxID:(NSString *)maxID
{
    NSString *userAgent = [user userAgent];
    
    if (!userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToFetchFeedWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToFetchFeedWithErrorMessage:kDefaultError];
            });
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // Timeline
//    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/feed/timeline/?phone_id=%@&timezone_offset=%ld",
//                                        kAPIBaseURL,
//                                        user.device.GUID,
//                                        [[NSTimeZone systemTimeZone] secondsFromGMT]]];
    
    // Feed
    
    NSString *maxPara = @"";
    if (maxID.length > 0) {
        maxPara = [NSString stringWithFormat:@"?max_id=%@", maxID];
    }
    
    // test: id = 1584903722
    
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/feed/user/%ld/%@",
                                        kAPIBaseURL,
                                        user.identifier,
                                        maxPara]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    [self sendRequest:request
              forUser:user
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToFetchFeedWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToFetchFeedWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToFetchFeedWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToFetchFeedWithErrorMessage:[NSString stringWithFormat:@"%@: %@",
                                                                        [self errorMessageForStatusCode:errorCode],
                                                                        [jsonError localizedDescription]]];
                    });
                }
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        return;
                    }
                    
                    NSString *errMessage = [jsonDictionary objectForKey:kIXFMessage];
                    if (errMessage.length) {
                        if ([_delegate respondsToSelector:@selector(didFailToFetchFeedWithErrorMessage:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [_delegate didFailToFetchFeedWithErrorMessage:errMessage];
                            });
                        }
                    }
                } else {
                    if ([_delegate respondsToSelector:@selector(didFinishFetchingFeed:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_delegate didFinishFetchingFeed:jsonDictionary];
                        });
                    }
                }
            }
        }
    }];
}

#pragma mark - Hashtag

#pragma mark Hashtag (GET)
- (NSArray<NSString *>*)hashtag:(NSString *)hashtag
{
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    // /api/v1/tags/search/?timezone_offset=28800&q=edit&count=50
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/tags/search/?timezone_offset=%ld&q=%@&count=%d",
                                        kAPIBaseURL,
                                        [[NSTimeZone systemTimeZone] secondsFromGMT],
                                        [hashtag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                                        10]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    NSData *data;
    NSURLResponse *response;
    NSError *error;
    
    data = [self sendSynchronousRequest:request
                                forUser:nil
                      returningResponse:&response
                                  error:&error];
    
    if (error) {
        return nil;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return nil;
        } else {
//            LOGD(@"%@", jsonDictionary);
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return nil;
            } else {
                NSArray *result = [jsonDictionary objectForKey:kIXFResults];
                if (result == nil) {
                    return nil;
                }
                NSMutableArray *suggestions = [NSMutableArray array];
                for (NSDictionary *item in result) {
                    // {"media_count": 7742183, "name": "edit", "id": 17843750815046334}
                    NSString *tag;
                    if (((tag = [item objectForKey:@"name"]) != nil)) {
                        [suggestions addObject:tag];
                    }
                }
                return suggestions;
            }
        }
    }
    return nil;
}

#pragma mark User Search (GET)
- (NSArray<NSString *>*)users:(NSString *)user
{
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/search/?timezone_offset=%ld&q=%@&count=%d",
                                        kAPIBaseURL,
                                        [[NSTimeZone systemTimeZone] secondsFromGMT],
                                        [user stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
                                        10]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    NSData *data;
    NSURLResponse *response;
    NSError *error;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&error];
    
    if (error) {
        return nil;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return nil;
        } else {
//            LOGD(@"%@", jsonDictionary);
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return nil;
            } else {
                NSArray *result = [jsonDictionary objectForKey:kIXFUsers];
                if (result == nil) {
                    return nil;
                }
                NSMutableArray *suggestions = [NSMutableArray array];
                for (NSDictionary *item in result) {
                    // {"media_count": 7742183, "name": "edit", "id": 17843750815046334}
                    NSString *tag;
                    if (((tag = [item objectForKey:kIXFUsername]) != nil)) {
                        [suggestions addObject:tag];
                    }
                }
                return suggestions;
            }
        }
    }
    return nil;
}

#pragma mark - Like & Comment

#pragma mark Like Media (POST)
- (BOOL)like:(IXFFeedItem *)media option:(BOOL)option
{
    _busy++;
    
    if (media.mediaID == nil ||
        ![_user integrity]) {
        _busy--;
        return NO;
    }
    
    /* signed_body=02d7a2550b490af02de8fb02f6b333f2796c45896f22ffe4d060054d8eb5948c.{"module_name":"feed_timeline","media_id":"1267856684221640204_3302372218","_csrftoken":"ce46701e5349d8354bd4fef647df5094","_uid":"3302372218","_uuid":"b3b4b4ab-2663-48d1-92dd-635d4901a5e9"}&ig_sig_key_version=4&d=0 */
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:@"feed_timeline"             forKey:@"module_name"];
    [requestDict setObject:media.mediaID                forKey:@"media_id"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&error];
    
    if (error) {
        _busy--;
        return NO;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        _busy--;
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    // request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/%@like/",
                                        kAPIBaseURL,
                                        media.mediaID,
                                        (option) ? @"" : @"un"]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *data;
    NSURLResponse *response;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&error];
    _busy--;
    
    if (error) {
        return NO;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return NO;
        } else {
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark Comments (GET)

- (IXFCommentItem *)commentWithDictionary:(NSDictionary *)dictionary
{
    if ([[dictionary objectForKey:kIXFpk] integerValue] > 0) {
        
        IXFCommentItem *comment = [[IXFCommentItem alloc] init];
        
        if ([dictionary objectForKey:@"user"]) {
            
            comment.user = [self userWithDictionary:[dictionary objectForKey:@"user"]];
            
            if (comment.user == nil) {
                return nil;
            }
        }
        
        comment.identifier = [[dictionary objectForKey:kIXFpk] integerValue];
        
        if ([dictionary objectForKey:@"text"]) {
            comment.text = [dictionary objectForKey:@"text"];
        } else {
            return nil;
        }
        
        if ([dictionary objectForKey:@"created_at"]) {
            comment.date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"created_at"] integerValue]];
        } else {
            return nil;
        }
        
        if ([dictionary objectForKey:@"content_type"]) {
            comment.contentType = [dictionary objectForKey:@"content_type"];
        }
        
        if ([dictionary objectForKey:@"type"]) {
            comment.type = [[dictionary objectForKey:@"type"] integerValue];
        }
        
        if ([dictionary objectForKey:kIXFStatus]) {
            comment.status = [dictionary objectForKey:kIXFStatus];
        }
        
        return comment;
    }
    return nil;
}

- (IXFUser *)userWithDictionary:(NSDictionary *)dictionary
{
    if ([[dictionary objectForKey:kIXFpk] integerValue] > 0) {
        
        IXFUser *user = [[IXFUser alloc] init];
        
        user.identifier = [[dictionary objectForKey:kIXFpk] integerValue];
        
        if ([dictionary objectForKey:kIXFUsername]) {
            user.name = [dictionary objectForKey:kIXFUsername];
        }
        if ([dictionary objectForKey:kIXFfull_name]) {
            user.fullname = [dictionary objectForKey:kIXFfull_name];
        }
        if ([dictionary objectForKey:kIXFhas_anonymous_profile]) {
            user.hasAnonymousProfilePicture = [[dictionary objectForKey:kIXFhas_anonymous_profile] boolValue];
        }
        if ([dictionary objectForKey:kIXFis_private]) {
            user.isPrivate = [[dictionary objectForKey:kIXFis_private] boolValue];
        }
        if ([dictionary objectForKey:kIXFprofile_pic_url]) {
            user.avatarURL = [dictionary objectForKey:kIXFprofile_pic_url];
        }
        if ([dictionary objectForKey:kIXFis_verified]) {
            user.verified = [[dictionary objectForKey:kIXFis_verified] boolValue];
        }
        if ([dictionary objectForKey:@"following_count"]) {
            user.followers = [[dictionary objectForKey:@"following_count"] integerValue];
        }
        if ([dictionary objectForKey:@"media_count"]) {
            user.mediaCount = [[dictionary objectForKey:@"media_count"] integerValue];
        }
        if ([dictionary objectForKey:@"biography"]) {
            user.bio = [dictionary objectForKey:@"biography"];
        }
        if ([dictionary objectForKey:@"email"]) {
            user.email = [dictionary objectForKey:@"email"];
        }
        if ([dictionary objectForKey:@"external_url"]) {
            user.externalURL = [dictionary objectForKey:@"external_url"];
        }
        if ([dictionary objectForKey:@"phone_number"]) {
            user.phone = [dictionary objectForKey:@"phone_number"];
        }
        
        return user;
    }
    return nil;
}

- (NSArray<IXFCommentItem *>*)comments:(IXFFeedItem *)media
{
    _busy++;
    
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent ||
        media.mediaID == nil) {
        _busy--;
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/comments/",
                                        kAPIBaseURL,
                                        media.mediaID]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    NSData *data;
    NSURLResponse *response;
    NSError *error;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&error];
    _busy--;
    
    if (error) {
        return nil;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return nil;
        } else {
            LOGD(@"%@", jsonDictionary);
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return nil;
            } else {
                NSDictionary *caption = [jsonDictionary objectForKey:@"caption"];
                if (![caption isKindOfClass:[NSNull class]] && [[caption allKeys] count]) {
                    if (![[caption objectForKey:@"text"] isKindOfClass:[NSNull class]]) {
                        media.caption = [caption objectForKey:@"text"];
                    }
                    if (![[caption objectForKey:@"created_at"] isKindOfClass:[NSNull class]]) {
                        media.date = [NSDate dateWithTimeIntervalSince1970:[[caption objectForKey:@"created_at"] integerValue]];
                    }
                    if (![[caption objectForKey:@"user"] isKindOfClass:[NSNull class]]) {
                        media.user = [self userWithDictionary:[caption objectForKey:@"user"]];
                    }
                }
                
                NSArray *result = [jsonDictionary objectForKey:@"comments"];
                if (result == nil) {
                    return nil;
                }
                NSMutableArray *comments = [NSMutableArray array];
                for (NSDictionary *item in result) {
                    IXFCommentItem *comment = [self commentWithDictionary:item];
                    if (comment != nil) {
                        [comments addObject:comment];
                    }
                }
                return comments;
            }
        }
    }
    return nil;
}

#pragma mark Comment (POST)

- (IXFCommentItem *)comment:(IXFFeedItem *)media text:(NSString *)text error:(NSString **)error
{
    _busy++;
    
    if (media.mediaID.length == 0 ||
        text.length == 0 ||
        ![_user integrity]) {
        _busy--;
        return nil;
    }
    
    /* body=594dabcd38a7d51bc165388b5ef6c258f0433c6f512dbbf417a2b081fc681a16.{"user_breadcrumb":"engAkveywa3Xg55aj0d8UmrZSYcDty+mWaZimQuWpm0=\nNSAzMzkxIDAgMTQ2NTQ2NTYxMjY5NA==\n","idempotence_token":"d2896279-caa0-4e9b-a68e-0fa21329320d","_csrftoken":"ce46701e5349d8354bd4fef647df5094","_uid":"3302372218","_uuid":"b3b4b4ab-2663-48d1-92dd-635d4901a5e9","comment_text":"Hello"}&ig_sig_key_version=4 */
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    //  [requestDict setObject:@""                          forKey:@"user_breadcrumb"];
    //  [requestDict setObject:@""                          forKey:@"idempotence_token"]; // UUID ?
    [requestDict setObject:text                         forKey:@"comment_text"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *err;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&err];
    
    if (err) {
        _busy--;
        return nil;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        _busy--;
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/comment/",
                                        kAPIBaseURL,
                                        media.mediaID]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *data;
    NSURLResponse *response;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&err];
    // Needs Internet no more.
    _busy--;
    
    if (err) {
        *error = [err localizedDescription];
        return nil;
    } else if (response) {
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&err];
        LOGD(@"%@", jsonDictionary);
        if (err) {
            *error = [err localizedDescription];
            if ([self shouldHandleError:nil
                           JSONResponce:jsonDictionary
                      completionHandler:nil]) {
                return nil;
            }
        } else {
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                *error = [jsonDictionary objectForKey:kIXFMessage];
                return nil;
            } else {
                return [self commentWithDictionary:[jsonDictionary objectForKey:@"comment"]];
            }
        }
    }
    return nil;
}

#pragma mark Comment Delete (POST)

- (BOOL)deleteComments:(IXFFeedItem *)media comments:(NSArray<IXFCommentItem *> *)comments error:(NSString **)error
{
    _busy++;
    
    if (media.mediaID.length == 0 ||
        [comments count] == 0 ||
        ![_user integrity]) {
        _busy--;
        return NO;
    }
    
    NSMutableArray *ids = [NSMutableArray array];
    for (IXFCommentItem *comment in comments) {
        if (comment.identifier == 0) {
            _busy--;
            return NO;
        }
        [ids addObject:@(comment.identifier)];
    }
    NSString *idString = [ids componentsJoinedByString:@","];
    
    /* signed_body=5c25cd322e32217d87cefa07a33b59dd52957eca1a1629a055fff7ae6ca62f8b.{"comment_ids_to_delete":"17848241980098272,17848241989098272","_csrftoken":"ce46701e5349d8354bd4fef647df5094","_uid":"3302372218","_uuid":"b3b4b4ab-2663-48d1-92dd-635d4901a5e9"}&ig_sig_key_version=4 */
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:idString                     forKey:@"comment_ids_to_delete"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    NSError *err;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&err];
    
    if (err) {
        _busy--;
        return NO;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        _busy--;
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/media/%@/comment/bulk_delete/",
                                        kAPIBaseURL,
                                        media.mediaID]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *data;
    NSURLResponse *response;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&err];
    // Needs Internet no more.
    _busy--;
    
    if (err) {
        *error = [err localizedDescription];
        return NO;
    } else if (response) {
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&err];
        LOGD(@"%@", jsonDictionary);
        if (err) {
            *error = [err localizedDescription];
            return NO;
        } else {
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                *error = [jsonDictionary objectForKey:kIXFMessage];
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Inbox (GET)
- (void)inbox
{
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent) {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/news/inbox/",
                                        kAPIBaseURL]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    [self sendRequest:request
              forUser:_user
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            LOGD(@"%@", [error localizedDescription]);
        } else if (response) {
            NSInteger errorCode;
            [self connectionStatusWithResponse:response statusCode:&errorCode];
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                LOGD(@"%@", [NSString stringWithFormat:@"%@: %@",
                             [self errorMessageForStatusCode:errorCode],
                             [jsonError localizedDescription]]);
            } else {
                NSString *status = [jsonDictionary objectForKey:kIXFStatus];
                if (![status isEqualToString:kIXFOK] ||
                    ![self responseSuccessful:errorCode]) {
                    
                    LOGD(@"%@", [jsonDictionary objectForKey:kIXFMessage]);
                    
                    if ([self shouldHandleError:nil
                                   JSONResponce:jsonDictionary
                              completionHandler:nil]) {
                        return;
                    }
                } else {
//                    LOGD(@"%@", jsonDictionary);
                    
                    /*
                    "new_stories":[
                                   {
                                       "pk":"A3JLIH23tpHxpi8HXGeGEoQGqDc=",
                                       "counts":{
                                           "relationships":0,
                                           "usertags":0,
                                           "likes":0,
                                           "comments":0
                                       },
                                       "args":{
                                           "media":[
                                                    {
                                                        "image":"https://scontent.cdninstagram.com/t51.2885-15/s150x150/e15/c216.0.648.648/12142720_1537838379839686_394519325_n.jpg?ig_cache_key=MTEwODMwNTU2NTAyMjM1MjAwNg%3D%3D.2.c",
                                                        "id":"1108305565022352006_1815469027"
                                                    }
                                                    ],
                                           "links":[
                                                    {  
                                                        "start":0,
                                                        "end":13,
                                                        "id":"2055436033",
                                                        "type":"user"
                                                    }
                                                    ],
                                           "text":"simplesam_usa liked your video.",
                                           "profile_id":2055436033,
                                           "profile_image":"http://scontent.cdninstagram.com/t51.2885-19/s150x150/11420906_496215913862651_1717634931_a.jpg",
                                           "timestamp":1446561289.62512
                                       },
                                       "type":1
                                   }
                                   ],
                    
                    */
                    
                    NSArray *newStories = [jsonDictionary objectForKey:@"new_stories"];
                    
                    if (newStories != nil &&
                        [newStories count] > 0) {
                        
                        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                        
                        for (NSDictionary *n in newStories) {
                            
                            IXFPushNotification *push = [[IXFPushNotification alloc] initWithDictionary:n];
                            
                            if (push != nil) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSUserNotification *noc = [[NSUserNotification alloc] init];
                                    noc.identifier = [NSString stringWithFormat:@"%@",
                                                      push.identifier];
                                    
                                    
                                    if (push.media != nil &&
                                        push.media.mediaID != nil &&
                                        push.media.previewImageURL != nil) {
                                        noc.userInfo = @{@"media"   :   push.media.mediaID,
                                                         @"image"   :   push.media.previewImageURL};
                                    }
                                    
                                    noc.title = @"New Notification";
                                    noc.subtitle = push.text;
                                    noc.informativeText = [dateFormatter stringFromDate:push.date];
                                    [noc setValue:push.user.avatar forKey:@"_identityImage"];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                                        object:self
                                                                                      userInfo:@{kNotificationObjectKey : noc}];
                                });
                            }
                        }
                    }
                }
            }
        }
    }];
}

#pragma mark - Profile

#pragma mark User Info By ID (GET)
- (IXFUser *)userInfoWithIdentifier:(NSUInteger)identifier
{
    _busy++;
    
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent ||
        identifier < 1) {
        _busy--;
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%ld/info/",
                                        kAPIBaseURL,
                                        identifier]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    NSData *data;
    NSURLResponse *response;
    NSError *error;
    
    data = [self sendSynchronousRequest:request
                                forUser:nil
                      returningResponse:&response
                                  error:&error];
    _busy--;
    
    if (error) {
        return nil;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return nil;
        } else {
            LOGD(@"%@", jsonDictionary);
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                return nil;
            } else {
                NSDictionary *userDict = [jsonDictionary objectForKey:@"user"];
                if ([userDict isKindOfClass:[NSNull class]] || ![[userDict allKeys] count]) {
                    return nil;
                }
                return [self userWithDictionary:userDict];
            }
        }
    }
    return nil;
}


#pragma mark Current User Info (GET)
- (BOOL)syncUserInfo:(BOOL)editOption
{
    _busy++;
    
    NSString *userAgent = [_user userAgent];
    
    if (!userAgent ||
        ![_user integrity]) {
        _busy--;
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/accounts/current_user/%@",
                                        kAPIBaseURL,
                                        (editOption == YES) ? @"?edit=true" : @""]];
    
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    NSData *data;
    NSURLResponse *response;
    NSError *error;
    
    data = [self sendSynchronousRequest:request
                                forUser:nil
                      returningResponse:&response
                                  error:&error];
    _busy--;
    
    if (error) {
        return NO;
    } else if (response) {
        NSError *jsonError;
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&jsonError];
        if (jsonError) {
            return NO;
        } else {
            LOGD(@"%@", jsonDictionary);
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                if ([self shouldHandleError:nil
                               JSONResponce:jsonDictionary
                          completionHandler:nil]) {
                    return NO;
                }
                return NO;
            } else {
                NSDictionary *dictionary = [jsonDictionary objectForKey:@"user"];
                if ([dictionary isKindOfClass:[NSNull class]] ||
                    ![[dictionary allKeys] count]) {
                    return NO;
                }
                
                if ([[dictionary objectForKey:kIXFpk] integerValue] > 0) {
                    
                    _user.identifier = [[dictionary objectForKey:kIXFpk] integerValue];
                    
                    if ([dictionary objectForKey:kIXFfull_name]) {
                        _user.fullname = [dictionary objectForKey:kIXFfull_name];
                    }
                    if ([dictionary objectForKey:kIXFhas_anonymous_profile]) {
                        _user.hasAnonymousProfilePicture = [[dictionary objectForKey:kIXFhas_anonymous_profile] boolValue];
                    }
                    if ([dictionary objectForKey:kIXFis_private]) {
                        _user.isPrivate = [[dictionary objectForKey:kIXFis_private] boolValue];
                    }
                    if ([dictionary objectForKey:kIXFprofile_pic_url]) {
                        _user.avatarURL = [dictionary objectForKey:kIXFprofile_pic_url];
                    }
                    if ([dictionary objectForKey:kIXFis_verified]) {
                        _user.verified = [[dictionary objectForKey:kIXFis_verified] boolValue];
                    }
                    if ([dictionary objectForKey:@"following_count"]) {
                        _user.followers = [[dictionary objectForKey:@"following_count"] integerValue];
                    }
                    if ([dictionary objectForKey:@"media_count"]) {
                        _user.mediaCount = [[dictionary objectForKey:@"media_count"] integerValue];
                    }
                    if ([dictionary objectForKey:@"biography"]) {
                        _user.bio = [dictionary objectForKey:@"biography"];
                    }
                    if ([dictionary objectForKey:@"email"]) {
                        _user.email = [dictionary objectForKey:@"email"];
                    }
                    if ([dictionary objectForKey:@"external_url"]) {
                        _user.externalURL = [dictionary objectForKey:@"external_url"];
                    }
                    if ([dictionary objectForKey:@"phone_number"]) {
                        _user.phone = [dictionary objectForKey:@"phone_number"];
                    }
                    if ([dictionary objectForKey:@"gender"]) {
                        _user.gender = [[dictionary objectForKey:@"gender"] integerValue];
                    }
                    
                    if ([dictionary objectForKey:kIXFUsername]) {
                        NSString *newUsername = [dictionary objectForKey:kIXFUsername];
                        if ([_user.name isEqualToString:newUsername] == NO) {
                            NSString *oldUsername = _user.name;
                            _user.name = [dictionary objectForKey:kIXFUsername];
                            [_users setObject:_user.name forKey:kLastUserKey];
                            [_users setObject:_user forKey:_user.name];
                            [self removeUser:oldUsername];
                        }
                    }
                    
                    return YES;
                }
            }
        }
    }
    return NO;
}


#pragma mark Edit Profile (POST)

/* {
    "external_url":"http://google.com",
    "gender":"2",
    "phone_number":"",
    "_csrftoken":"ce46701e5349d8354bd4fef647df5094",
    "username":"t13339",
    "first_name":"t1338a",
    "_uid":"3302372218", //
    "biography":"My bio",
    "_uuid":"b3b4b4ab-2663-48d1-92dd-635d4901a5e9", //
    "email":"t1338@leeching.net"
} */

- (BOOL)editProfile:(NSString **)error
{
    _busy++;
    
    if (![_user integrity]) {
        _busy--;
        return NO;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    if (_user.externalURL != nil) [requestDict setObject:_user.externalURL  forKey:@"external_url"];
    if (_user.gender > 0) [requestDict setObject:@(_user.gender)        forKey:@"gender"];
    if (_user.phone != nil) [requestDict setObject:_user.phone          forKey:@"phone_number"];
    if (_user.name != nil) [requestDict setObject:_user.name            forKey:@"username"];
    if (_user.fullname != nil) [requestDict setObject:_user.fullname    forKey:@"first_name"];
    if (_user.bio != nil) [requestDict setObject:_user.bio              forKey:@"biography"];
    if (_user.email != nil) [requestDict setObject:_user.email          forKey:@"email"];
    [requestDict setObject:[self CSRFToken]             forKey:@"_csrftoken"];
    [requestDict setObject:_user.device.GUID            forKey:@"_uuid"];
    [requestDict setObject:@(_user.identifier)          forKey:@"_uid"];
    
    LOGD(@"%@", requestDict);
    
    NSError *err;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict
                                                          options:0
                                                            error:&err];
    
    if (err) {
        _busy--;
        return NO;
    }
    
    NSString *userAgent = [_user userAgent];
    
    requestData = [self sign:requestData];
    
    if (!requestData || !userAgent) {
        _busy--;
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/accounts/edit_profile/",
                                        kAPIBaseURL]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *data;
    NSURLResponse *response;
    
    data = [self sendSynchronousRequest:request
                                forUser:_user
                      returningResponse:&response
                                  error:&err];
    // Needs Internet no more.
    _busy--;
    
    if (err) {
        *error = [err localizedDescription];
        return NO;
    } else if (response) {
        NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data
                                                              error:&err];
        LOGD(@"%@", jsonDictionary);
        if (err) {
            *error = [err localizedDescription];
            return NO;
        } else {
            NSString *status = [jsonDictionary objectForKey:kIXFStatus];
            if (![status isEqualToString:kIXFOK]) {
                NSArray *errors = [[jsonDictionary objectForKey:kIXFMessage] objectForKey:@"errors"];
                if (errors != nil && errors.count) {
                    *error = [errors componentsJoinedByString:@"\n"];
                }
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}


@end
