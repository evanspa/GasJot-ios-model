//
//  FPAuthTokenDelegateForTesting.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import Foundation;
#import "PEAuthTokenDelegate.h"

@interface FPAuthTokenDelegateForTesting : NSObject <PEAuthTokenDelegate>

- (id)initWithBlockForNewAuthTokenReceived:(void(^)(NSString *))authTokenReceivedBlk
                           authRequiredBlk:(void(^)(HCAuthentication *))authRequiredBlk;

@end
