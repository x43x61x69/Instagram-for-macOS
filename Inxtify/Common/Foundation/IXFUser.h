//
//  IXFUser.h
//  Inxtify
//
//  Created by Zhi-Wei Cai on 3/28/16.
//  Copyright © 2016 Zhi-Wei Cai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IXFDevice.h"
#import "IXFClient.h"

@interface IXFUser : NSObject

@property (nonatomic, copy, nonnull)    IXFDevice   *device;
@property (nonatomic, copy, nonnull)    IXFClient   *client;

@property (nonatomic, copy, nonnull)    NSString    *name;
@property (nonatomic, copy, nonnull)    NSString    *password;

@property (nonatomic, copy, nullable)   NSString    *fullname;
@property (nonatomic, copy, nullable)   NSArray     *cookies;
@property (nonatomic, copy, nullable)   NSImage     *avatar;

@property (nonatomic, assign)           NSInteger   identifier;
@property (nonatomic, assign)           BOOL        isPrivate;

- (nullable instancetype)initWithName:(nonnull NSString *)name
                             password:(nonnull NSString *)password
                               device:(nonnull IXFDevice *)device
                               client:(nonnull IXFClient *)client;
- (nullable NSString *)CSRFToken;
- (BOOL)updateAvatarWithURL:(nullable NSURL *)URL;

@end
