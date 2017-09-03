//
//  NSImage+IXFExtended.m
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

#import "NSImage+IXFExtended.h"

@implementation NSImage (IXFExtended)

#pragma mark - Utilities

- (nullable NSImage *)imageTintedWithColor:(nonnull NSColor *)tint
{
    NSImage *image = [self copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
        [image unlockFocus];
    }
    return image;
}


// http://stackoverflow.com/questions/9264051/nsimage-size-not-real-size-with-some-pictures

- (nullable NSImage *)imageWithRepresentation
{
    if ([self isValid] == YES) {
        NSImageRep *r = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
        NSUInteger w = [r pixelsWide];
        NSUInteger h = [r pixelsHigh];
        NSImage *i = [[NSImage alloc] initWithSize:NSMakeSize((CGFloat)w, (CGFloat)h)];
        [i addRepresentation:r];
        return i;
    }
    return nil;
}

- (nullable NSData *)data
{
    NSBitmapImageRep *r = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
    if ([[r colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] == NO) {
        r = [r bitmapImageRepByConvertingToColorSpace:[NSColorSpace genericRGBColorSpace]
                                      renderingIntent:NSColorRenderingIntentPerceptual];
    }
    return [r representationUsingType:NSJPEGFileType
                           properties:@{NSImageCompressionFactor : @(1.f)}];
}

- (nullable NSImage *)visiableImage:(NSRect)visibleRect
{
    if ([self isValid] == YES) {
        NSRect srcRect = NSZeroRect;
        NSRect dstRect = NSZeroRect;
        srcRect.size = visibleRect.size;
        dstRect.size = visibleRect.size;
        
        CGFloat w = self.size.width - visibleRect.size.width;
        //dstRect.origin.x = MAX(0, floor(MIN(w, visibleRect.origin.x)));
        dstRect.origin.x = MAX(0, (MIN(w, visibleRect.origin.x)));
        
        CGFloat h = self.size.height - visibleRect.size.height;
        //dstRect.origin.y = MAX(0, floor(MIN(h - visibleRect.origin.y, h)));
        dstRect.origin.y = MAX(0, (MIN(h - visibleRect.origin.y, h)));
        
        NSImage *result = [[NSImage alloc] initWithSize:visibleRect.size];
        [result lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [self drawInRect:srcRect
                fromRect:dstRect
               operation:NSCompositeSourceOver
                fraction:1.f
          respectFlipped:YES
                   hints:nil];
        [result unlockFocus];
        return result;
    }
    return nil;
}

- (nullable NSImage *)resize:(NSSize)size
{
    if ([self isValid] == YES) {
        CGFloat w = self.size.width;
        CGFloat h = self.size.height;
        NSPoint origin = NSZeroPoint;
        
        CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
        
        size.width /= scale;
        size.height /= scale;
        
        if (NSEqualSizes(self.size, size) == NO) {
            
            CGFloat widthFactor  = size.width / w;
            CGFloat heightFactor = size.height / h;
            
            CGFloat factor = MIN(widthFactor, heightFactor);
            
            h *= factor;
            w *= factor;
            
            if ( widthFactor < heightFactor ) {
                //origin.y = floor((size.height - h) / 2.f);
                origin.y = ((size.height - h) / 2.f);
            } else if ( widthFactor > heightFactor ) {
                //origin.x = floor((size.width - w) / 2.f);
                origin.x = ((size.width - w) / 2.f);
            }
        }
        
        NSImage *result = [[NSImage alloc] initWithSize:size];
        [result lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        NSRect rect;
        rect.origin = origin;
        rect.size.width = w;
        rect.size.height = h;
        [self drawInRect:rect
                fromRect:NSZeroRect
               operation:NSCompositeSourceOver
                fraction:1.f
          respectFlipped:YES
                   hints:nil];
        [result unlockFocus];
        return result;
    }
    return nil;
}

- (nullable NSImage *)squaredResizeWithMaxLength:(CGFloat)max
{
    return [self resizeWithMaxLength:max squared:YES];
}

- (nullable NSImage *)resizeWithMaxLength:(CGFloat)max
{
    return [self resizeWithMaxLength:max squared:NO];
}

// ???: Not sure if this works correctly.
- (nullable NSImage *)resizeWithMaxLength:(CGFloat)max
                                  squared:(BOOL)squared
{
    if ([self isValid] == YES) {
        if (self.size.width > 0 && self.size.height > 0 &&
            (MIN(self.size.width, self.size.height) > max ||
            self.size.width != self.size.height)) {
            CGFloat w = 0;
            CGFloat h = 0;
            CGFloat r = self.size.width / self.size.height;
            if (self.size.width >= self.size.height) {
                if (squared == YES) {
                    h = max;
                    w = h * r;
                } else {
                    w = max;
                    h = w / r;
                }
            } else {
                if (squared == YES) {
                    w = max;
                    h = w / r;
                } else {
                    h = max;
                    w = h * r;
                }
            }
                
            // Need to check if we need to make it into square.
            LOGD(@"%.fx%.f -> %.fx%.f\n\tAR: %f (Squared: %d)",
                 floor(self.size.width),
                 floor(self.size.height),
                 w, h,
                 MAX(w, h) / MIN(w, h),
                 squared);
                
            if (squared == YES) {
                return [self resize:NSMakeSize(max, max)];
            } else {
                return [self resize:NSMakeSize(w, h)];
            }
        }
        return self;
    }
    return nil;
}

@end
