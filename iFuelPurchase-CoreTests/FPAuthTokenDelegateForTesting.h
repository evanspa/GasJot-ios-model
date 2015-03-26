//
//  FPAuthTokenDelegateForTesting.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <fuelpurchase-common/FPAuthTokenDelegate.h>

@interface FPAuthTokenDelegateForTesting : NSObject <FPAuthTokenDelegate>

- (id)initWithBlockForNewAuthTokenReceived:(void(^)(NSString *))authTokenReceivedBlk
                           authRequiredBlk:(void(^)(HCAuthentication *))authRequiredBlk;

@end
