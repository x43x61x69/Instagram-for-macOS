//
//  NSData+IXFExtended.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import "NSData+IXFExtended.h"

@implementation NSData (IXFExtended)

- (NSString *)hexEncoding
{
    NSMutableString *result = [NSMutableString string];
    unsigned char *bytes = (unsigned char *)[self bytes];
    char temp[3];
    int i = 0;
    for (i = 0; i < [self length]; i++) {
        temp[0] = temp[1] = temp[2] = 0;
        (void)sprintf(temp, "%02x", bytes[i]);
        [result appendString:[NSString stringWithUTF8String:temp]];
    }
    return result;
}

@end
