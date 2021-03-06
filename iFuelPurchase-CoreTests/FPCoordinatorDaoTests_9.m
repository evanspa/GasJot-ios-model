//
//  FPCoordinatorDaoTests_9.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDaoImpl.h"
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
#import "PEUserCoordinatorDao.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_9)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDaoImpl *_coordDao;
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
    [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
    _mocker = [_coordTestCtx newMocker];
    _observer = [_coordTestCtx newObserver];
  });
  
  afterAll(^{
  });
  
  context(@"Tests", ^{
    it(@"Can edit a user and vehicle at same time", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      BOOL prepareForEditSuccess =
        [_coordDao prepareUserForEdit:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [user setName:@"Paul Evans"];
      [user setEmail:@"paul.evans@example.com"];
      _mocker(@"http-response.user.PUT.204", 0, 0);
      __block BOOL syncUserSuccess = NO;
      [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncUserImmediate:user
                                                      notFoundOnServerBlk:nil
                                                           addlSuccessBlk:^{
                                                             syncUserSuccess = YES;
                                                           }
                                                   addlRemoteStoreBusyBlk:nil
                                                   addlTempRemoteErrorBlk:nil
                                                       addlRemoteErrorBlk:nil
                                                          addlConflictBlk:nil
                                                      addlAuthRequiredBlk:nil
                                                                    error:nil];
      [[expectFutureValue(theValue(syncUserSuccess)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      FPVehicle *vehicle = [_coordDao vehicleWithName:@"My Bimmer"
                                        defaultOctane:@87
                                         fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]
                                             isDiesel:NO
                                        hasDteReadout:NO
                                        hasMpgReadout:NO
                                        hasMphReadout:NO
                                hasOutsideTempReadout:NO
                                                  vin:nil
                                                plate:nil];
      [_coordDao saveNewVehicle:vehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // the following will prevent syncing w/remote master on subsquent sync-attempt
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      user = (FPUser *)[_coordDao mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil]; // user not pruned from main because vehicle (child) is in main_vehicle
      [[theValue([user synced]) should] beYes];
      user = (FPUser *)[_coordDao masterUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil];
      [[[user name] should] equal:@"Paul Evans"];
      [[[user email] should] equal:@"paul.evans@example.com"];
      
      // now  lets put HTTP system into a state such that a vehicle-POST will
      // be successful, and then mark 'editComplete' for the vehicle.
      [_coordDao markAsDoneEditingVehicle:vehicle
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()]; // should now get synced/pruned on next timer fire
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // not synced
      __block float overallFlushProgress = 0.0;
      __block NSInteger totalSynced = 0;
      __block BOOL allDone = NO;
      NSInteger totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                               entityNotFoundBlk:nil
                                                                      successBlk:^(float progress) {
                                                                        overallFlushProgress += progress;
                                                                        totalSynced++;
                                                                      }
                                                              remoteStoreBusyBlk:nil
                                                              tempRemoteErrorBlk:nil
                                                                  remoteErrorBlk:nil
                                                                     conflictBlk:nil
                                                                 authRequiredBlk:nil
                                                                         allDone:^{ allDone = YES; }
                                                                           error:nil];
      [[expectFutureValue(theValue(allDone)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue(totalNumToSync) should] equal:theValue(1)];
      [[theValue(totalSynced) should] equal:theValue(1)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      
      // now we can do a system-wide prune event; our synced user instance currently sitting in
      // main_user should get pruned (since the vehicle instance should have gotten
      // pruned from main_vehicle
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_coordDao mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()] shouldBeNil];
      user = (FPUser *)[_coordDao mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
    });
  });
});

SPEC_END
