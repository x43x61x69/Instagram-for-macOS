//
//  NSString+IXFExtended.m
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import "NSString+IXFExtended.h"

@implementation NSString (IXFExtended)

- (NSString *)urlencode
{
    NSMutableString *result = [NSMutableString string];
    const unsigned char *src = (const unsigned char *)[self UTF8String];
    unsigned long len = strlen((const char *)src);
    for (int i = 0; i < len; ++i) {
        const unsigned char c = src[i];
        if (c == ' '){
            [result appendString:@"+"];
        } else if (c == '.' || c == '-' || c == '_' || c == '~' ||
                   (c >= 'a' && c <= 'z') ||
                   (c >= 'A' && c <= 'Z') ||
                   (c >= '0' && c <= '9')) {
            [result appendFormat:@"%c", c];
        } else {
            [result appendFormat:@"%%%02X", c];
        }
    }
    return result;
}

@end
