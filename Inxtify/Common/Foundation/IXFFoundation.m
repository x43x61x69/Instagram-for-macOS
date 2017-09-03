//
//  IXFFoundation.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#define kVersion                    @"1.0"
#define kHTTPResponseSuccessful     2 // HTTP Code: 2xx

#define kHTTPUserAgent              @"User-Agent"
#define kHTTPContentType            @"Content-Type"
#define kHTTPApplicationURLEncoded  @"application/x-www-form-urlencoded"

#define kAPIBaseURL                 @"https://i.instagram.com/api/v1"

#import "IXFFoundation.h"
#import "NSData+IXFExtended.h"
#import "NSString+IXFExtended.h"

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
- (instancetype)initWithUser:(IXFUser *)user
{
    self = [super init];
    if (self) {
        if (user) {
            _user = user;
        } else {
            return nil;
        }
    }
    return self;
}

///
/// Module version.
///
- (NSString *)version
{
    return kVersion;
}

///
/// Generate device dictionary. Returns nil if the device was empty.
///
- (NSDictionary *)deviceDictionary
{
    if (!_user.device) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:_user.device.manufacturer        forKey:@"manufacturer"];
    [dict setObject:_user.device.model               forKey:@"model"];
    [dict setObject:@(_user.device.api)              forKey:@"android_version"];
    [dict setObject:[_user.device version]  forKey:@"android_release"];
    return dict;
}

///
/// Generate User-Agent. Returns nil if either the device or the client was empty.
///
- (NSString *)userAgent
{
    if (!_user.device || !_user.client) {
        return nil;
    }
    NSString *agent = [NSString stringWithFormat:@"Instagram %@ Android (%lu/%@; %ludpi; %@; %@; %@; %@; %@; %@)",
                       [_user.client version],
                       _user.device.api,
                       [_user.device version],
                       _user.device.dpi,
                       [_user.device resolution],
                       _user.device.manufacturer,
                       _user.device.model,
                       _user.device.codename,
                       _user.device.codename,
                       [[NSLocale currentLocale] localeIdentifier]];
    return agent;
}

- (NSString *)timestemp
{
    return [NSString stringWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970] * 1000];
}

///
/// Generate random GUID.
///
- (NSString *)guid
{
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

#warning Move this to client!!
- (NSData *)sigString:(NSData *)data
{
    NSString *sig = [self sig:data];
    if (!sig) {
        return nil;
    }
    return [[NSString stringWithFormat:@"signed_body=%@.%@&ig_sig_key_version=%lu",
             sig,
             [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] urlencode],
             _user.client.signatureVersion]
            dataUsingEncoding:NSUTF8StringEncoding];
}

///
/// Generate HMAC signature for data.
///
- (NSString *)sig:(NSData *)data
{
    return [self hmac:data secret:_user.client.signature];
}

///
/// Calculate HMAC signature for data with a secret.
///
- (NSString *)hmac:(NSData *)data
            secret:(NSString *)secret
{
    const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = (const char *)[data bytes];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData  *hmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [hmac hexEncoding];
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

+ (BOOL)responseSuccessful:(NSInteger)statusCode
{
    return (statusCode / 100 == kHTTPResponseSuccessful) == YES;
}

#pragma mark Requests
// URL must be HTTPS or it will fail due to Apple's App Transport Security.

- (BOOL)isReady
{
    return (_user != nil &&
            _user.name.length &&
            _user.password.length &&
            _user.device != nil &&
            _user.client != nil) == YES;
}

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
              completionHandler:completionHandler];
}

- (void)sendRequestRegardless:(NSMutableURLRequest *)request
            completionHandler:(void (^)(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error))completionHandler
{
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data,
                                                         NSURLResponse *response,
                                                         NSError *error)
      {
          _user.cookies = [self cookies];
          LOGD(@"Cookie: %@", _user.cookies);
          LOGD(@"Status Code :%ld (%@)", [(NSHTTPURLResponse *)response statusCode], response.URL);
          if (completionHandler != nil) { completionHandler(data, response, error); }
      }] resume];
}

- (BOOL)connectionStatusWithResponse:(NSURLResponse *)response
                          statusCode:(NSInteger  * _Nullable)statusCode
{
    NSHTTPURLResponse *ne = (NSHTTPURLResponse *)response;
    *statusCode = [ne statusCode];
    return ([ne statusCode] / 100 == kHTTPResponseSuccessful) == YES;
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

#pragma mark Cookie

- (void)deleteCookies
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
}

- (NSArray *)cookies
{
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
}

- (BOOL)cookiesExpired
{
    return ([_user CSRFToken] == nil) == YES;
}

#pragma mark - Account Management

#pragma mark Challenge (GET)
- (void)challenge
{
    NSString *userAgent = [self userAgent];
    
    if (!userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToChallengeWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToChallengeWithErrorMessage:[[NSError errorWithDomain:NSCocoaErrorDomain
                                                                                   code:NSNotFound
                                                                               userInfo:nil] localizedDescription]];
            });
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/si/fetch_headers/?challenge_type=signup&guid=%@", kAPIBaseURL, _user.device.GUID]];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    
    [self sendRequest:request
    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if ([_delegate respondsToSelector:@selector(didFailToChallengeWithErrorMessage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate didFailToChallengeWithErrorMessage:[error localizedDescription]];
                });
            }
        } else if (response) {
            NSInteger errorCode;
            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
                if ([_delegate respondsToSelector:@selector(didFailToChallengeWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToChallengeWithErrorMessage:[self errorMessageForStatusCode:errorCode]];
                    });
                }
            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToChallengeWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToChallengeWithErrorMessage:[jsonError localizedDescription]];
                    });
                }
            } else {
                if ([_delegate respondsToSelector:@selector(didReceiveChallengeJSONResponse:statusCode:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didReceiveChallengeJSONResponse:jsonDictionary statusCode:errorCode];
                    });
                }
            }
        }
        
    }];
}

#pragma mark Login (POST)
- (void)login
{
    if ([_delegate respondsToSelector:@selector(shouldLogin)]) {
        if (![_delegate shouldLogin]) {
            return;
        }
    }
    
    if (![self isReady]) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:[[NSError errorWithDomain:NSCocoaErrorDomain
                                                                               code:NSNotFound
                                                                           userInfo:nil] localizedDescription]];
            });
        }
        return;
    }
    
    NSMutableDictionary *requestDict = [NSMutableDictionary new];
    
    [requestDict setObject:_user.name               forKey:@"username"];
    [requestDict setObject:_user.password           forKey:@"password"];
    [requestDict setObject:_user.device.GUID        forKey:@"guid"];
    [requestDict setObject:_user.device.identifier  forKey:@"device_id"];
    [requestDict setObject:@0                       forKey:@"login_attempt_count"];
    
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
        return;
    }
    
    requestData = [self sigString:requestData];
    NSString *userAgent = [self userAgent];
    
    if (!requestData || !userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLoginWithErrorMessage:[[NSError errorWithDomain:NSCocoaErrorDomain
                                                                               code:NSNotFound
                                                                           userInfo:nil] localizedDescription]];
            });
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:kAPIBaseURL @"/accounts/login/"];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPBody:requestData];
    [request setHTTPMethod:@"POST"];
    
    [self deleteCookies];
    
    [self sendRequest:request
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
            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
                if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLoginWithErrorMessage:[self errorMessageForStatusCode:errorCode]];
                    });
                }
            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToLoginWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLoginWithErrorMessage:[jsonError localizedDescription]];
                    });
                }
            } else {
                if ([_delegate respondsToSelector:@selector(didReceiveLoginJSONResponse:statusCode:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didReceiveLoginJSONResponse:jsonDictionary statusCode:errorCode];
                    });
                }
            }
        }
        if ([_delegate respondsToSelector:@selector(didFinishLoggingIn)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFinishLoggingIn];
            });
        }
        
    }];
}

#pragma mark Logout (POST)
- (void)logout
{
    if (![self isReady]) {
        if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLogoutWithErrorMessage:[[NSError errorWithDomain:NSCocoaErrorDomain
                                                                                code:NSNotFound
                                                                            userInfo:nil] localizedDescription]];
            });
        }
        return;
    }
    
    NSString *userAgent = [self userAgent];
    
    if (!userAgent) {
        if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFailToLogoutWithErrorMessage:[[NSError errorWithDomain:NSCocoaErrorDomain
                                                                                code:NSNotFound
                                                                            userInfo:nil] localizedDescription]];
            });
        }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.URL = [NSURL URLWithString:kAPIBaseURL @"/accounts/logout/"];
    [request setValue:kHTTPApplicationURLEncoded forHTTPHeaderField:kHTTPContentType];
    [request setValue:userAgent forHTTPHeaderField:kHTTPUserAgent];
    [request setHTTPMethod:@"POST"];
    
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
            if (![self connectionStatusWithResponse:response statusCode:&errorCode]) {
                if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLogoutWithErrorMessage:[self errorMessageForStatusCode:errorCode]];
                    });
                }
            }
            NSError *jsonError;
            NSDictionary *jsonDictionary = [self dictionaryWithJSONData:data error:&jsonError];
            if (jsonError) {
                if ([_delegate respondsToSelector:@selector(didFailToLogoutWithErrorMessage:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didFailToLogoutWithErrorMessage:[jsonError localizedDescription]];
                    });
                }
            } else {
                if ([_delegate respondsToSelector:@selector(didReceiveLogoutJSONResponse:statusCode:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate didReceiveLogoutJSONResponse:jsonDictionary statusCode:errorCode];
                    });
                }
            }
        }
        if ([_delegate respondsToSelector:@selector(didFinishLoggingOut)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate didFinishLoggingOut];
            });
        }
        
    }];
}

@end
