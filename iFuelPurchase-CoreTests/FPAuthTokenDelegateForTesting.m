//
//  FPAuthTokenDelegateForTesting.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPAuthTokenDelegateForTesting.h"

@implementation FPAuthTokenDelegateForTesting {
  void (^_authTokenReceivedBlk)(NSString *);
  void (^_authRequiredBlk)(HCAuthentication *);
}

- (id)initWithBlockForNewAuthTokenReceived:(void(^)(NSString *))authTokenReceivedBlk
                           authRequiredBlk:(void(^)(HCAuthentication *))authRequiredBlk {
  self = [super self];
  if (self) {
    _authTokenReceivedBlk = authTokenReceivedBlk;
    _authRequiredBlk = authRequiredBlk;
  }
  return self;
}
- (void)didReceiveNewAuthToken:(NSString *)authToken
            forUsernameOrEmail:(NSString *)usernameOrEmail {
  _authTokenReceivedBlk(authToken);
}

- (void)authRequired:(HCAuthentication *)authentication {
  _authRequiredBlk(authentication);
}

-(void)invalidateTokenForUsernameOrEmail:(NSString *)usernameOrEmail {
  // do nothing...
}

@end
