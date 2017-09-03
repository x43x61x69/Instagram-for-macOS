//
//  IXFKeychain.m
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


#import "IXFKeychain.h"

@implementation IXFKeychain

+ (id)unarchiveObjectWithService:(NSString *)service
                           error:(NSString **)error
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge id)(kSecClassGenericPassword),  kSecClass,
                          service,                                  kSecAttrService,
                          kCFBooleanTrue,                           kSecReturnData,
                          nil];
    
    CFTypeRef result;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &result);
    if (err != noErr) {
        LOGD(@"SecItemCopyMatching Error: %@", (__bridge NSString *)SecCopyErrorMessageString(err, NULL));
        if (error) *error = (__bridge NSString *)SecCopyErrorMessageString(err, NULL);
        return nil;
    }
    
    if (!result) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge id)result];
}

+ (BOOL)clearService:(NSString *)service
               error:(NSString **)error
{
    return [[self class] archiveDataWithRootObject:nil
                                        forService:service
                                             error:error];
}

+ (BOOL)archiveDataWithRootObject:(id)object
                       forService:(NSString *)service
                            error:(NSString **)error
{
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge id)(kSecClassGenericPassword),  kSecClass,
                          service,                                  kSecAttrService,
                          nil];
    
    OSStatus err = SecItemDelete((__bridge CFDictionaryRef)dict);
    if (err != noErr) {
        LOGD(@"SecItemDelete Error: %@", (__bridge NSString *)SecCopyErrorMessageString(err, NULL));
//        if (error) *error = (__bridge NSString *)SecCopyErrorMessageString(err, NULL);
    }
    
    if (object == nil) {
        // "object" is nil, we just need to delete the existed.
        return YES;
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    if (data != nil) {
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                (__bridge id)(kSecClassGenericPassword),    kSecClass,
                service,                                    kSecAttrService,
                data,                                       kSecValueData,
                nil];
        
        err = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
        if (err != noErr) {
            LOGD(@"SecItemAdd Error: %@", (__bridge NSString *)SecCopyErrorMessageString(err, NULL));
            if (error) *error = (__bridge NSString *)SecCopyErrorMessageString(err, NULL);
            return NO;
        }
        
        LOGD(@"%@", (NSMutableDictionary *)[IXFKeychain unarchiveObjectWithService:service error:nil]);
        
        return YES;
    }
    
    LOGD(@"NSKeyedArchiver: data == nil!");
    
    return NO;
}

@end
