//
//  IXFCommentCollectionViewItem.m
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

#import "IXFCommentCollectionViewItem.h"

@interface IXFCommentCollectionViewItem ()

@end

@implementation IXFCommentCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    
    _profileImageView.wantsLayer = YES;
    _profileImageView.layer.masksToBounds = YES;
    _profileImageView.layer.backgroundColor = [[NSColor gridColor] colorWithAlphaComponent:.3f].CGColor;
    _profileImageView.layer.borderColor = [[NSColor gridColor] colorWithAlphaComponent:.5f].CGColor;
    _profileImageView.layer.borderWidth = 1.f;
    _profileImageView.layer.cornerRadius = _profileImageView.bounds.size.width / 2.f;
    _profileImageView.layer.needsDisplayOnBoundsChange = YES;
    
    _deleteButton.wantsLayer = YES;
    _deleteButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    NSImage *i = [_deleteButton.image copy];
    i.template = NO;
    _deleteButton.image = [i imageTintedWithColor:[NSColor whiteColor]];
}

+ (NSSet *)keyPathsForValuesAffectingTextColor
{
    return [NSSet setWithObjects:@"selected", nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self updateBackgroundColorForSelectionState:self.isSelected];
    
}

- (void)updateBackgroundColorForSelectionState:(BOOL)flag
{
    if (flag) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = .5f;
            self.view.animator.layer.backgroundColor = [NSColor alternateSelectedControlColor].CGColor;
            _usernameLabel.animator.textColor = [NSColor alternateSelectedControlTextColor];
            _messageLabel.animator.textColor = [NSColor alternateSelectedControlTextColor];
            if (_isOwnItem) {
                _deleteButton.hidden = NO;
            }
        } completionHandler:nil];
    } else {
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 1.f;
            self.view.animator.layer.backgroundColor = [NSColor clearColor].CGColor;
            _usernameLabel.animator.textColor = [NSColor alternateSelectedControlColor];
            _messageLabel.animator.textColor = [NSColor controlTextColor];
            _deleteButton.hidden = YES;
        } completionHandler:nil];
    }
}

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    [self updateBackgroundColorForSelectionState:flag];
}

#pragma mark -

- (IBAction)delete:(id)sender
{
    if ([_delgate respondsToSelector:@selector(shouldDeleteComments:)]) {
        [_delgate shouldDeleteComments:@[self.representedObject]];
    }
}

@end
