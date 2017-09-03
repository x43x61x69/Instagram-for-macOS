//
//  IXFImagePinchClipView.m
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

#import "IXFImagePinchClipView.h"
#import "IXFImagePinchImageView.h"

@implementation IXFImagePinchClipView

// FIXME: If clipview size > image size, centering will fail.
- (NSRect)constrainBoundsRect:(NSRect)proposedBounds
{
    NSRect constrainedBounds = [super constrainBoundsRect:proposedBounds];
    NSRect documentFrame = [self.documentView frame];
    NSSize imageFrame = [((NSImageView *)self.documentView).image size];
    
    // If proposed clip view bounds width is greater than document view frame width, center it horizontally.
    if (proposedBounds.size.width >= documentFrame.size.width || // Image W <= Clip W
        (proposedBounds.size.width >= imageFrame.width &&        // Image H >= Image W && Image W <= Clip W
         imageFrame.height >= imageFrame.width))
    {
        constrainedBounds.origin.x = centeredCoordinateUnit(proposedBounds.size.width,
                                                            documentFrame.size.width);
    }
    
    // If proposed clip view bounds is hight is greater than document view frame height, center it vertically.
    if (proposedBounds.size.height >= documentFrame.size.height || // Image H <= Clip H
        (proposedBounds.size.height >= imageFrame.height &&
         imageFrame.width >= imageFrame.height))
    {
        constrainedBounds.origin.y += centeredCoordinateUnit(proposedBounds.size.height,
                                                             documentFrame.size.height);
    }
    return constrainedBounds;
}


CGFloat centeredCoordinateUnit(CGFloat proposedContentViewBoundsDimension,
                               CGFloat documentViewFrameDimension)
{
    CGFloat result = floor((proposedContentViewBoundsDimension - documentViewFrameDimension)/(-2.f));
    return result;
}

@end
