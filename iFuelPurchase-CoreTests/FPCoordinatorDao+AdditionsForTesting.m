//
//  FPCoordinatorDao+AdditionsForTesting.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <CocoaLumberjack/DDLog.h>
#import "FPCoordDaoTestContext.h"
#import "FPLogging.h"

@implementation FPCoordinatorDao (AdditionsForTesting)

- (void)deleteUser:(PELMDaoErrorBlk)errorBlk {
  FPUser *user = [self userWithError:errorBlk];
  if (user) {
    [self deleteUser:user error:errorBlk];
  }
}

@end
