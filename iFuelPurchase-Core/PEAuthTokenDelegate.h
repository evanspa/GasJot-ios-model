//
//  PEAuthTokenDelegate.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/13/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HCAuthentication;

@protocol PEAuthTokenDelegate <NSObject>

- (void)didReceiveNewAuthToken:(NSString *)authToken
       forUserGlobalIdentifier:(NSString *)userGlobalIdentifier;

- (void)authRequired:(HCAuthentication *)authentication;

@end
