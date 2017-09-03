//
//  IXFImagePinchView.m
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

#define kInstagramAspectRatio  1.25f
#define kScrollerAlphaValue    .0f

#import "IXFImagePinchView.h"
#import "IXFImagePinchClipView.h"
//#import <IXFFoundation/IXFFoundation.h>

@implementation NSView (IXFImagePinchViewExtended)

- (void)constraintsToView:(NSView *)superview
{
    NSLayoutConstraint *width = [NSLayoutConstraint
                                 constraintWithItem:self
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                 toItem:superview
                                 attribute:NSLayoutAttributeWidth
                                 multiplier:1.f
                                 constant:.0f];
    
    NSLayoutConstraint *height = [NSLayoutConstraint
                                  constraintWithItem:self
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                  toItem:superview
                                  attribute:NSLayoutAttributeHeight
                                  multiplier:1.0
                                  constant:.0f];
    
    NSLayoutConstraint *top = [NSLayoutConstraint
                               constraintWithItem:self
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                               toItem:superview
                               attribute:NSLayoutAttributeTop
                               multiplier:1.f
                               constant:.0f];
    
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:self
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:superview
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.f
                                   constant:.0f];
    
    [superview addConstraint:top];
    [superview addConstraint:leading];
    [superview addConstraint:width];
    [superview addConstraint:height];
}

@end

@implementation IXFImagePinchView

- (instancetype)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
        self.allowsMagnification = YES;
        self.minMagnification = 0.f;
        self.maxMagnification = 1.f;
        self.horizontalScrollElasticity = NSScrollElasticityAutomatic;
        self.verticalScrollElasticity = NSScrollElasticityAutomatic;
        self.hasHorizontalScroller = YES;
        self.hasVerticalScroller = YES;
        self.autohidesScrollers = YES;
        self.scrollerStyle = NSScrollerStyleOverlay;
//        self.horizontalScroller.alphaValue = kScrollerAlphaValue;
//        self.verticalScroller.alphaValue = kScrollerAlphaValue;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        self.drawsBackground = NO;
//        self.borderType = NSBezelBorder;
        
        _clipView = [[IXFImagePinchClipView alloc] initWithFrame:self.contentView.bounds];
        self.contentView = _clipView;
        self.contentView.copiesOnScroll = YES;
        self.contentView.drawsBackground = NO;
        self.contentView.postsBoundsChangedNotifications = YES;
//        [self.contentView constraintsToView:self];
        
        _imageView = [[IXFImagePinchImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.delegate = self;
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.documentView = _imageView;
        [self.documentView constraintsToView:self.contentView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(boundsDidChange:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:nil];
        [self adjustMagnification];
//        _imageView.wantsLayer = YES;
//        _imageView.layer.backgroundColor = [NSColor greenColor].CGColor;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

#pragma mark - Gesture Events

//- (void)magnifyWithEvent:(NSEvent *)theEvent
//{
//    [super magnifyWithEvent:theEvent];

//    [[NSNotificationCenter defaultCenter] postNotificationName:kPinchViewZoomDidChangedNotificationKey
//                                                        object:self];
    
//    if ([theEvent magnification] != 0.f) {
//        [[NSCursor pointingHandCursor] push];
//    } else {
//        [[NSCursor pointingHandCursor] pop];
//    }
//}

#pragma mark - NSViewBoundsDidChangeNotification

- (void)boundsDidChange:(NSNotification *)notification
{
    if (_previousMagnification != self.magnification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPinchViewZoomDidChangedNotificationKey
                                                            object:self];
    }
    if (NSEqualRects(self.bounds, _previousRect) == NO) {
        [self adjustMagnification];
        _previousRect = self.bounds;
    }
    // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html#//apple_ref/doc/uid/TP40003463-SW3
//    CGRect visibleRect = [self convertRect:self.bounds toView:_imageView];
//    LOGD(@"%@, %@", CGRectCreateDictionaryRepresentation(_imageView.visibleRect), CGRectCreateDictionaryRepresentation(_imageView.visibleRect));
//    [self reflectScrolledClipView:self.contentView];
}

#pragma mark - IXFImagePinchImageViewDelegate

- (void)didSetImage:(NSImage *)image
{
    [self setImage:image];
}

#pragma mark - Methods

- (void)zoomIn
{
    if (_imageView.image != nil) {
        CGFloat verticalScroller = self.verticalScroller.floatValue;
        CGFloat horizontalScroller = self.horizontalScroller.floatValue;
        
        self.magnification = MIN(self.maxMagnification,
                                 self.magnification + self.maxMagnification / self.magnification * .05f);
        
        self.verticalScroller.floatValue = verticalScroller;
        self.horizontalScroller.floatValue = horizontalScroller;
    }
}

- (void)zoomOut
{
    if (_imageView.image != nil) {
        CGFloat verticalScroller = self.verticalScroller.floatValue;
        CGFloat horizontalScroller = self.horizontalScroller.floatValue;
        
        self.magnification = MAX(self.minMagnification,
                                 self.magnification - self.maxMagnification / self.magnification * .05f);
        
        self.verticalScroller.floatValue = verticalScroller;
        self.horizontalScroller.floatValue = horizontalScroller;
    }
}

- (BOOL)canZoomIn
{
    if (_imageView.image != nil) {
        return (self.magnification < self.maxMagnification);
    }
    return NO;
}

- (BOOL)canZoomOut
{
    if (_imageView.image != nil) {
        return (self.magnification > self.minMagnification);
    }
    return NO;
}

- (void)setIsSquareMode:(BOOL)isSquareMode
{
    _isSquareMode = isSquareMode;
    [self adjustMagnification];
}

- (void)adjustMagnification
{
    if (_imageView.image != nil) {
        NSSize size = _imageView.image.size;
        CGFloat max = MAX(size.width, size.height);
        CGFloat min = MIN(size.width, size.height);
        CGFloat magMultiplier = MAX(2.f, min / kInstagramSize);
        CGFloat multiplier = (_isSquareMode) ? max / min : MIN(max / min, kInstagramAspectRatio);
        CGFloat mag = (self.frame.size.width / multiplier) / min;
        // If maxMagnification < minMagnification, exception will rise.
        // So the order to set the values is important!!
        
        self.maxMagnification = (self.minMagnification = 0) + 1;
        
        if (_videoData == nil) {
//            self.horizontalScroller.alphaValue = kScrollerAlphaValue;
//            self.verticalScroller.alphaValue = kScrollerAlphaValue;
            self.maxMagnification = mag * magMultiplier;
            self.minMagnification = mag;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPinchViewZoomDidChangedNotificationKey
                                                                object:self];
        } else {
//            self.horizontalScroller.alphaValue = .0f;
//            self.verticalScroller.alphaValue = .0f;
            self.minMagnification = mag;
            self.maxMagnification = self.minMagnification;
        }
        self.magnification = self.minMagnification;
        _imageView.hidden = NO;
    } else {
        _imageView.hidden = YES;
//        self.horizontalScroller.alphaValue = .0f;
//        self.verticalScroller.alphaValue = .0f;
    }
}

- (void)setImage:(NSImage *)image
{
    if (image == nil || [image isValid] == NO) {
        _videoData = nil;
        _videoMeta = nil;
        _videoAsset = nil;
        [_imageView setImage:nil];
        [self adjustMagnification];
        return;
    }
    
    // Fix images with abnormal DPI.
    image = [image imageWithRepresentation];
    
    if ([image isEqual:_imageView.image]) {
        return;
    }
    CGFloat max = MAX(image.size.width, image.size.height);
    if (max < kInstagramSize) {
        BOOL isLandscape = (image.size.width > image.size.height) == YES;
        CGFloat multiplier = max / MIN(image.size.width, image.size.height);
        image = [image resize:NSMakeSize(isLandscape ? kInstagramSize * multiplier : kInstagramSize,
                                         isLandscape ? kInstagramSize : kInstagramSize * multiplier)];
    }
    [_imageView setImage:image];
    [self adjustMagnification];
    
    if ([self.window isVisible]) {
        // If our window is visiable, make it key.
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
}

#pragma mark Video

- (nullable NSImage *)previewImageFromAsset:(CGFloat)seconds
{
    if (_videoAsset == nil) {
        return nil;
    }
    
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_videoAsset];
    CMTime duration = _videoAsset.duration;
    //    CGFloat durationInSeconds = duration.value / duration.timescale;
    CMTime time = CMTimeMakeWithSeconds(seconds, (int)duration.value);
    NSError *err;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time
                                                 actualTime:NULL
                                                      error:&err];
    
    if (err != nil) {
        LOGD(@"%@", [err description]);
        return nil;
    }
    
    CIImage *image = [CIImage imageWithCGImage:imageRef];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:image];
    NSImage *result = [[NSImage alloc] initWithSize:rep.size];
    [result addRepresentation:rep];
    CGImageRelease(imageRef);
    
    result = [result resize:kInstagramUploadMaxSize];
    
    if (result != nil) {
        [_videoPreviews setObject:result forKey:@(floor(seconds))];
    }
    return result;
}

- (void)changePreviewFrame:(CGFloat)seconds
{
    [self previewImage:seconds
     completionHandler:^(NSImage *image) {
        if (image != nil) {
            [self setImage:image];
        }
    }];
}

- (void)previewImage:(CGFloat)seconds completionHandler:(void (^)(NSImage * image))completionHandler
{
    if (_videoAsset == nil) {
        completionHandler(nil);
        return;
    }
    
    CGFloat roundTime = floor(seconds);
    
    NSImage *image;
    
    if ((image = [_videoPreviews objectForKey:@(roundTime)]) != nil) {
        completionHandler(image);
        return;
    }
    
    LOGD(@"%.f: %@", roundTime, [_videoPreviews allKeys]);
    
    image = [self previewImageFromAsset:roundTime];
    
    completionHandler(image);
}

- (NSImage *)previewImage:(CGFloat)seconds
{
    if (_videoData == nil) {
        return nil;
    }
    
    if ((_videoAsset = [_videoData AVAsset]) == nil) {
        return nil;
    }
    
    CGFloat roundTime = floor(seconds);
    
    NSImage *image = [self previewImageFromAsset:roundTime];
    
    return image;
}

- (CGFloat)videoPixelHeight
{
    if (_videoMeta == nil) {
        return .0f;
    }
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemPixelHeight] floatValue];
}

- (CGFloat)videoPixelWidth
{
    if (_videoMeta == nil) {
        return .0f;
    }
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemPixelWidth] floatValue];
}

- (CGFloat)videoDurationSeconds
{
    if (_videoMeta == nil) {
        return .0f;
    }
    return [[_videoMeta objectForKey:(__bridge NSString *)kMDItemDurationSeconds] floatValue];
}

#pragma mark - Drag and Drop

- (void)setAlpha:(CGFloat)alpha
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .5f;
        self.animator.alphaValue = alpha;
    } completionHandler:nil];
}

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSFilesPromisePboardType, nil]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([self hasFileURLOrPromisedFileURLWithDraggingInfo:sender]) {
        [self setAlpha:.7f];
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [self draggingEntered:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    [self setAlpha:1.f];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    if (NSPointInRect([self convertPoint:[sender draggingLocation]
                                fromView:nil],
                      [self bounds]) == NO) {
        [self setAlpha:1.f];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return [self hasFileURLOrPromisedFileURLWithDraggingInfo:sender];
}

//- (NSURL *)fileURLWithDraggingInfo:(id <NSDraggingInfo>)sender
//{
//    NSPasteboard *pasteboard = [sender draggingPasteboard];
//    NSDictionary *options = [NSDictionary dictionaryWithObject:@YES forKey:NSPasteboardURLReadingFileURLsOnlyKey];
//    NSArray *results = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:options];
//    return [results lastObject];
//}

- (BOOL)hasFileURLOrPromisedFileURLWithDraggingInfo:(id <NSDraggingInfo>)sender
{
    NSArray *relevantTypes = @[@"com.apple.pasteboard.promised-file-url", @"public.file-url", @"mp4", @"mov", @"m4v", kIXFQueueItemFileExtension];
    for (NSPasteboardItem *item in [[sender draggingPasteboard] pasteboardItems]) {
        if ([item availableTypeFromArray:relevantTypes] != nil) {
            return YES;
        }
    }
    return NO;
}

- (void)checkFileReadability:(void (^)(void))completeionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (_watchedPath &&
               !(_isReadable = [[NSFileManager defaultManager] isReadableFileAtPath:_watchedPath])) {
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            completeionHandler();
        });
    });
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    [self setAlpha:1.f];
    
    _watchedPath = nil;
    
    NSArray *allowedTypes = [NSArray arrayWithObjects:@"mp4", @"mov", @"m4v", kIXFQueueItemFileExtension, nil];
    NSMutableArray *dragPaths = [NSMutableArray arrayWithArray:[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType]];
    NSArray *promisePaths = [[sender draggingPasteboard] propertyListForType:NSFilesPromisePboardType];
    
    if ([promisePaths count] > 0) {
        // We have promised files! Create a temp folder for them:
        NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
        
        if ([[NSFileManager defaultManager] createDirectoryAtURL:tempURL
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:nil]) {
            
            NSArray *createdPromisePaths;
            
            if ([(createdPromisePaths = [sender namesOfPromisedFilesDroppedAtDestination:tempURL]) count] > 0) {
                NSURL *URL = [tempURL URLByAppendingPathComponent:[createdPromisePaths firstObject]];
                _watchedPath = [URL path];
                [dragPaths insertObject:[URL path] atIndex:0];
            }
        }
    }
    
    LOGD(@"dragPaths: %@", dragPaths);
    
    CFStringRef fileExtension;
    CFStringRef fileUTI;
    
    for (NSString *path in dragPaths) {
        
        BOOL isDir = NO;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
            
            NSDirectoryEnumerator *enumerator = [[[NSFileManager alloc] init] enumeratorAtURL:[NSURL fileURLWithPath:path]
                                                                   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLIsDirectoryKey, nil]
                                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                 errorHandler:nil];
            for (NSURL *theURL in enumerator) {
                
                NSString *fileName;
                NSNumber *isDirectory;
                
                [theURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
                [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                
                fileExtension = (__bridge CFStringRef)[fileName pathExtension];
                fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
                // if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) NSLog(@"It's a movie");
                
                if ((!UTTypeConformsTo(fileUTI, kUTTypeImage)) &&
                    (![allowedTypes containsObject:[fileName pathExtension]]) &&
                    (![isDirectory boolValue])) {
                    [enumerator skipDescendants];
                } else if (![isDirectory boolValue]) {
                    LOGD(@"Dragged in fileName = %@", fileName);
                    [self checkFileReadability:^{
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                            [self newQueueImage:theURL];
                        } else if ([[fileName pathExtension] isEqualToString:kIXFQueueItemFileExtension]) {
                            [self newQueueItem:theURL];
                        } else {
                            [self newQueueVideo:theURL];
                        }
                    }];
                    return YES;
                }
            }
        } else {
            LOGD(@"Dragged in path = %@", path);
            fileExtension = (__bridge CFStringRef)[path pathExtension];
            fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                [self checkFileReadability:^{
                    [self newQueueImage:[NSURL fileURLWithPath:path]];
                }];
                return YES;
            } else if ([[path pathExtension] isEqualToString:kIXFQueueItemFileExtension]) {
                [self checkFileReadability:^{
                    [self newQueueItem:[NSURL fileURLWithPath:path]];
                }];
                return YES;
            } else if ([allowedTypes containsObject:[path pathExtension]]) {
                [self checkFileReadability:^{
                    [self newQueueVideo:[NSURL fileURLWithPath:path]];
                }];
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - IXFImagePinchViewDelegate

- (void)newQueueItem:(NSURL *)URL
{
    if ([_delegate respondsToSelector:@selector(newQueueItem:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate newQueueItem:URL];
        });
    }
}

- (void)newQueueImage:(NSURL *)URL
{
    NSImage *preview = [[NSImage alloc] initWithContentsOfURL:URL];
    if (preview != nil) {
        
        _videoData = nil;
        _videoMeta = nil;
        _videoAsset = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setImage:preview];
        });
        if ([_delegate respondsToSelector:@selector(newQueueImage:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate newQueueImage:URL];
            });
        }
    }
}

- (void)newQueueVideo:(NSURL *)URL
{
    NSData *videoData = [[NSData alloc] initWithContentsOfURL:URL];
    NSDictionary *videoMeta =
    (NSDictionary *)CFBridgingRelease(MDItemCopyAttributes(MDItemCreateWithURL(NULL, (CFURLRef)URL),
                                                           (CFArrayRef)[NSArray arrayWithObjects:
                                                                        (id)kMDItemPixelHeight,
                                                                        (id)kMDItemPixelWidth,
                                                                        //(id)kMDItemAudioBitRate,
                                                                        //(id)kMDItemCodecs,
                                                                        //(id)kMDItemMediaTypes,
                                                                        //(id)kMDItemVideoBitRate,
                                                                        //(id)kMDItemTotalBitRate,
                                                                        (id)kMDItemDurationSeconds,
                                                                        nil]));
    
    CGFloat duration = [[videoMeta objectForKey:(__bridge NSString *)kMDItemDurationSeconds] floatValue];
    
    if (duration < 3 || duration > 60) {
        // Invalid length.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUserNotification *noc = [[NSUserNotification alloc] init];
            noc.identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
            noc.title = @"Invalid Video Duration";
            noc.subtitle = [NSString stringWithFormat:@"This video is about %.f sec%@ long. It must length between 3 - 60 secs.",
                            floor(duration),
                            (floor(duration) == 1.f) ? @"" : @"s"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationObjectKey
                                                                object:self
                                                              userInfo:@{kNotificationObjectKey : noc}];
        });
        
        return;
    }
    
    _videoData = videoData;
    _videoMeta = videoMeta;
    
    NSImage *preview = [self previewImage:.0f];
    if (preview != nil) {
        
        _videoPreviews = [NSMutableDictionary dictionary];
        
        // Generate previews in the background.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSUInteger i = 1; i < floor(duration); i++) {
                [self previewImage:i];
            }
        });
        
        LOGD(@"%@", _videoMeta);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setImage:preview];
        });
        if ([_delegate respondsToSelector:@selector(newQueueVideo:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate newQueueVideo:URL];
            });
        }
    } else {
        _videoData = nil;
        _videoAsset = nil;
        _videoPreviews = nil;
        _videoMeta = nil;
    }
}

@end
