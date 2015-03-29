//
//  FPCoordinatorDao+AdditionsForTesting.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <CocoaLumberjack/DDLog.h>
#import "FPNotificationNames.h"
#import "FPCoordDaoTestContext.h"
#import "FPLogging.h"

@implementation FPCoordinatorDao (AdditionsForTesting)

- (void)deleteAllUsers:(PELMDaoErrorBlk)errorBlk {
  [[self localDao] deleteAllUsers:errorBlk];
}

- (void)asynchronousWorkSynchronously:(PELMDaoErrorBlk)errorBlk {
  if ([self authToken]) {
    PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAfter) {};
    //[self synchronousComputeOfFuelStationCoordinates];
    [self flushToRemoteMasterWithEditActorId:@(FPBackgroundActorId)
                          remoteStoreBusyBlk:remoteStoreBusyBlk
                                       error:errorBlk];
    [[self localDao] pruneAllSyncedEntitiesWithError:errorBlk
                                    systemPruneCount:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:FPSystemPruningComplete
                                                        object:nil];
  } else {
    DDLogDebug(@"Skipping asynchronous-synchronously flush to remote master due to having a nil authentication token.");
  }
}

@end
