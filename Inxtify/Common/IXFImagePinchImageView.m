//
//  IXFImagePinchImageView.m
//  Inxtify
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

#import "IXFImagePinchImageView.h"

@implementation IXFImagePinchImageView

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark - Mouse Event

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil],
                      [self bounds]) == YES) {
        [[NSCursor openHandCursor] set];
        
        [(NSClipView *)self.superview adjustScroll:[(NSClipView *)self.superview constrainBoundsRect:[self.superview convertRect:self.visibleRect fromView:self]]];
        [(NSScrollView *)self.superview.superview reflectScrolledClipView:(NSClipView *)self.superview];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    if ([theEvent type] == NSLeftMouseDown) {
        [[NSCursor closedHandCursor] set];
    } else {
        [[NSCursor openHandCursor] set];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    if ([theEvent type] == NSLeftMouseDown ||
        [theEvent type] == NSLeftMouseDragged) {
        [[NSCursor closedHandCursor] set];
    } else {
        [[NSCursor openHandCursor] set];
    }
}

- (void)cursorUpdate:(NSEvent *)theEvent
{
    [super cursorUpdate:theEvent];
    if ([theEvent type] == NSLeftMouseDown ||
        [theEvent type] == NSLeftMouseDragged) {
        [[NSCursor closedHandCursor] set];
    } else {
        [[NSCursor openHandCursor] set];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [[NSCursor closedHandCursor] set];
    
    lastDragLocation = [NSEvent mouseLocation];
    lastOrigin = self.frame.origin;
    LOGD(@"lastDragLocation: %f x %f", lastDragLocation.x, lastDragLocation.y)
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    [[NSCursor closedHandCursor] set];
    NSPoint dragLocation = [NSEvent mouseLocation];
    NSPoint dragOrigin = self.frame.origin;
    dragOrigin.x += (-lastDragLocation.x + dragLocation.x);
    
    
    dragOrigin.y -= (-lastDragLocation.y + dragLocation.y);
    
    dragOrigin.x = MIN(0, MAX(dragOrigin.x, -self.image.size.width  + self.visibleRect.size.width));
    CGFloat y = -self.image.size.height + self.visibleRect.size.height;
    dragOrigin.y = MIN(-y, MAX(dragOrigin.y, y));
    
    LOGD(@"dragOrigin: %f x %f <- %f x %f", dragOrigin.x, dragOrigin.y, self.frame.origin.x, self.frame.origin.y);
    [self setFrameOrigin:dragOrigin];
    [self needsDisplay];
    lastDragLocation = dragLocation;
}

- (void)createTrackingArea
{
    NSTrackingAreaOptions options =
    NSTrackingActiveAlways |
    NSTrackingCursorUpdate |
    NSTrackingMouseMoved |
    NSTrackingMouseEnteredAndExited |
    NSTrackingEnabledDuringMouseDrag;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    
    NSPoint mouseLocation = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream]
                                      fromView:nil];
    
    if (NSPointInRect(mouseLocation, [self bounds])) {
        [self mouseEntered:[[NSApplication sharedApplication] currentEvent]];
    } else {
        [self mouseExited:[[NSApplication sharedApplication] currentEvent]];
    }
}

- (void)updateTrackingAreas
{
    if (_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
    }
    [self createTrackingArea];
    [super updateTrackingAreas]; // Needed, according to the NSView documentation
}

#pragma mark - IXFImagePinchImageViewDelegate

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSFilesPromisePboardType, nil]];
    [self createTrackingArea];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([_delegate respondsToSelector:@selector(draggingEntered:)]) {
        return [_delegate draggingEntered:sender];
    }
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ([_delegate respondsToSelector:@selector(draggingUpdated:)]) {
        return [_delegate draggingUpdated:sender];
    }
    return NSDragOperationCopy;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    if ([_delegate respondsToSelector:@selector(draggingEnded:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate draggingEnded:sender];
        });
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    if ([_delegate respondsToSelector:@selector(draggingExited:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate draggingExited:sender];
        });
    }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if ([_delegate respondsToSelector:@selector(performDragOperation:)]) {
        return [_delegate performDragOperation:sender];
    }
    return NO;
}

@end
