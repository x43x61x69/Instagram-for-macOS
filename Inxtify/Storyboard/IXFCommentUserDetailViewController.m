//
//  IXFCommentUserDetailViewController.m
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

#import "IXFCommentUserDetailViewController.h"

@interface IXFCommentUserDetailViewController ()

@end

@implementation IXFCommentUserDetailViewController

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
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    if (_userForDetail.avatarURL) {
        _profileImageView.image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:_userForDetail.avatarURL]];
    }
    if (_userForDetail.name) {
        _usernameButton.title = [NSString stringWithFormat:@"@%@", _userForDetail.name];
    }
    if (_userForDetail.verified) {
        _usernameButton.image = [NSImage imageNamed:@"verifiedTemplate"];
        _usernameButton.toolTip = @"Verified";
    }
    if (_userForDetail.fullname) {
        _fullnameLabel.stringValue = _userForDetail.fullname;
        _fullnameLabel.toolTip = _userForDetail.fullname;
    }
    if (_userForDetail.externalURL.length) {
        _websiteButton.enabled = YES;
        _websiteButton.title = _userForDetail.externalURL;
    }
    if (_userForDetail.bio) {
        _biographyLabel.stringValue = _userForDetail.bio;
        _biographyLabel.toolTip = _userForDetail.bio;
    }
    if (_userForDetail.mediaCount) {
        _postsLabel.stringValue = [NSString stringWithFormat:@"%ld%@ Post%@",
                                   (_userForDetail.mediaCount > 1000) ? _userForDetail.mediaCount / 1000 : _userForDetail.mediaCount,
                                   (_userForDetail.mediaCount > 1000) ? @"k+" : @"",
                                   (_userForDetail.mediaCount == 1) ? @"" : @"s"];
    }
    if (_userForDetail.followers) {
        _followersLabel.stringValue = [NSString stringWithFormat:@"%ld%@ Follower%@",
                                         (_userForDetail.followers > 1000) ? _userForDetail.followers / 1000 : _userForDetail.followers,
                                         (_userForDetail.followers > 1000) ? @"k+" : @"",
                                         (_userForDetail.followers == 1) ? @"" : @"s"];
    }
}

- (IBAction)feed:(id)sender
{
    if (_userForDetail.name.length) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://instagram.com/%@", _userForDetail.name]]];
    }
}

- (IBAction)website:(id)sender
{
    if (_userForDetail.externalURL) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_userForDetail.externalURL]];
    }
}

@end
