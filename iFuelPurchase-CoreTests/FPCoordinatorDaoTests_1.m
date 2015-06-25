//
//  FPCoordinatorDaoTests.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import <UIKit/UIKit.h>
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_1)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingObserver _observer;

describe(@"FPCoordinatorDao", ^{
  
  beforeAll(^{
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:[NSBundle bundleForClass:[self class]]];
    _coordDao = [_coordTestCtx newStoreCoord];
    [_coordDao deleteAllUsers:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
    _mocker = [_coordTestCtx newMocker];
    _observer = [_coordTestCtx newObserver];
  });
  
  afterAll(^{
  });

  context(@"Tests", ^{
    it(@"Can create and edit an environment log by itself and have it sync", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
          [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
        });
      // First we need to create a vehicle.
      FPVehicle *vehicle = [_coordDao vehicleWithName:@"Volkswagen CC"
                                        defaultOctane:@87
                                         fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.0"]];
      [_coordDao saveNewVehicle:vehicle
                        forUser:user
                          error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPEnvironmentLog *envLog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"95648"]
                                                        reportedAvgMpg:[NSDecimalNumber decimalNumberWithString:@"26.2"]
                                                        reportedAvgMph:[NSDecimalNumber decimalNumberWithString:@"28.4"]
                                                   reportedOutsideTemp:[PEUtils nullSafeNumberFromString:@"75"]
                                                               logDate:[NSDate date]
                                                           reportedDte:[NSDecimalNumber decimalNumberWithString:@"174.3"]];
      [_coordDao saveNewEnvironmentLog:envLog
                               forUser:user
                               vehicle:vehicle
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // sanity check the main/master ids
      [[vehicle localMainIdentifier] shouldNotBeNil];
      [[envLog localMainIdentifier] shouldNotBeNil];
      [[vehicle localMasterIdentifier] shouldBeNil];
      [[envLog localMasterIdentifier] shouldBeNil];
      [[theValue([_coordDao numUnsyncedVehiclesForUser:user]) should] equal:theValue(1)];
      [[theValue([_coordDao numUnsyncedEnvironmentLogsForUser:user]) should] equal:theValue(1)];
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      _mocker(@"http-response.envlogs.POST.201", 0, 0);
      __block float overallFlushProgress = 0.0;
      __block NSInteger totalSynced = 0;
      NSInteger totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                                      successBlk:^(float progress) {
                                                                        overallFlushProgress += progress;
                                                                        totalSynced++;
                                                                      }
                                                              remoteStoreBusyBlk:nil
                                                              tempRemoteErrorBlk:nil
                                                                  remoteErrorBlk:nil
                                                                 authRequiredBlk:nil
                                                                           error:nil];
      [[theValue(totalNumToSync) should] equal:theValue(2)];
      [[expectFutureValue(theValue(totalSynced)) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(2)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // vehicle synced but NOT pruned (because child envlog instance couldn't be pruned)
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // still pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:0]]; // still pruned
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:1]];
    });
  });
});

SPEC_END
