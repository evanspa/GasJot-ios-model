//
//  FPCoordinatorDaoTests_5.m
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
#import <PELocal-Data/PELMDDL.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import "PEUserCoordinatorDao.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_5)

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
    it(@"Sync-in-progress entity goes from YES to NO after failed sync attempt", ^{
      FPUser *user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      _mocker(@"http-response.login.POST.200", 0, 0);
      user = (FPUser *)[_coordDao.userCoordinatorDao newLocalUserWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao.userCoordinatorDao loginWithEmail:@"evansp@test.com"
                                          password:@"1n53cur3"
   andLinkRemoteUserToLocalUser:user
  preserveExistingLocalEntities:YES
                remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
              completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
          localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil]; // sanity check
      [[[user updatedAt] should] equal:[NSDate dateWithTimeIntervalSince1970:1433472979.065]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      FPVehicle *newVehicle = [_coordDao vehicleWithName:@"My Z Car"
                                           defaultOctane:@87
                                            fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]
                                                isDiesel:NO
                                           hasDteReadout:NO
                                           hasMpgReadout:NO
                                           hasMphReadout:NO
                                   hasOutsideTempReadout:NO
                                                     vin:nil
                                                   plate:nil];
      [_coordDao saveNewVehicle:newVehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(3)];
      _mocker(@"http-response.vehicles.POST.500", 0, 0);
      
      __block float overallFlushProgress = 0.0;
      __block BOOL allDone = NO;
      NSInteger totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                               entityNotFoundBlk:nil
                                                                      successBlk:nil
                                                              remoteStoreBusyBlk:nil
                                                              tempRemoteErrorBlk:^(float progress) {
                                                                overallFlushProgress += progress;
                                                              }
                                                                  remoteErrorBlk:nil
                                                                     conflictBlk:nil
                                                                 authRequiredBlk:nil
                                                                         allDone:^{ allDone = YES; }
                                                                           error:nil];
      [[expectFutureValue(theValue(allDone)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue(totalNumToSync) should] equal:theValue(1)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // vehicle not pruned (because it didn't get synced)
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]]; // user was rightfully not pruned either (sanity check)
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      // now lets refetch the vehicle
      newVehicle = [[_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()] objectAtIndex:2];
      [newVehicle shouldNotBeNil];
      [[[newVehicle name] should] equal:@"My Z Car"]; // sanity check to make sure that the zeroth element is our new addition
      [[theValue([newVehicle synced]) should] beNo];
      [[theValue([newVehicle syncInProgress]) should] beNo];
      [[[newVehicle syncHttpRespCode] should] equal:[NSNumber numberWithInt:500]];
      [[newVehicle syncRetryAt] shouldBeNil];
      [[[newVehicle syncErrMask] should] equal:[NSNumber numberWithInt:0]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(3)];
      
      _mocker(@"http-response.vehicles.POST.422", 0, 0);
      overallFlushProgress = 0.0;
      allDone = NO;
      totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                     entityNotFoundBlk:nil
                                                            successBlk:nil
                                                    remoteStoreBusyBlk:nil
                                                    tempRemoteErrorBlk:nil
                                                        remoteErrorBlk:^(float progress, NSInteger errMask) {
                                                          overallFlushProgress += progress;
                                                        }
                                                           conflictBlk:nil
                                                       authRequiredBlk:nil
                                                               allDone:^{ allDone = YES; }
                                                                 error:nil];
      [[expectFutureValue(theValue(allDone)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue(totalNumToSync) should] equal:theValue(1)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      newVehicle = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()][2];
      [[[newVehicle name] should] equal:@"My Z Car"];
      [[theValue([newVehicle synced]) should] beNo];
      [[theValue([newVehicle syncInProgress]) should] beNo];
      [[[newVehicle syncHttpRespCode] should] equal:[NSNumber numberWithInt:422]];
      [[newVehicle syncRetryAt] shouldBeNil];
      [[[newVehicle syncErrMask] should] equal:[NSNumber numberWithInt:6]];
      
      // we need to clear-out the err-mask field of the vehicle so that a new sync is re-attempted
      [_coordDao prepareVehicleForEdit:newVehicle
                               forUser:user
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [newVehicle setSyncErrMask:nil];
      [_coordDao saveVehicle:newVehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao markAsDoneEditingVehicle:newVehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      _mocker(@"http-response.vehicles.POST.503", 0, 0);
      overallFlushProgress = 0.0;
      allDone = NO;
      totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                     entityNotFoundBlk:nil
                                                            successBlk:nil
                                                    remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                                      overallFlushProgress += progress;
                                                    }
                                                    tempRemoteErrorBlk:nil
                                                        remoteErrorBlk:nil
                                                           conflictBlk:nil
                                                       authRequiredBlk:nil
                                                               allDone:^{ allDone = YES; }
                                                                 error:nil];
      [[expectFutureValue(theValue(allDone)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue(totalNumToSync) should] equal:theValue(1)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      newVehicle = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()][2];
      [[[newVehicle name] should] equal:@"My Z Car"];
      [[theValue([newVehicle synced]) should] beNo];
      [[theValue([newVehicle syncInProgress]) should] beNo];
      [[[newVehicle syncHttpRespCode] should] equal:[NSNumber numberWithInt:503]];
      [[newVehicle syncRetryAt] shouldNotBeNil];
      [[newVehicle syncErrMask] shouldBeNil];
      
      [_coordDao prepareVehicleForEdit:newVehicle
                               forUser:user
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [newVehicle setSyncRetryAt:nil];
      [_coordDao saveVehicle:newVehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao markAsDoneEditingVehicle:newVehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      _mocker(@"http-response.vehicles.POST.401", 0, 0);
      overallFlushProgress = 0.0;
      allDone = NO;
      totalNumToSync = [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                                     entityNotFoundBlk:nil
                                                            successBlk:nil
                                                    remoteStoreBusyBlk:nil
                                                    tempRemoteErrorBlk:nil
                                                        remoteErrorBlk:nil
                                                           conflictBlk:nil
                                                       authRequiredBlk:^(float progress) {
                                                         overallFlushProgress += progress;
                                                       }
                                                               allDone:^{ allDone = YES; }
                                                                 error:nil];
      [[expectFutureValue(theValue(allDone)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue(totalNumToSync) should] equal:theValue(1)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      newVehicle = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()][2];
      [[[newVehicle name] should] equal:@"My Z Car"];
      [[theValue([newVehicle synced]) should] beNo];
      [[theValue([newVehicle syncInProgress]) should] beNo];
      [[[newVehicle syncHttpRespCode] should] equal:[NSNumber numberWithInt:401]];
      [[newVehicle syncRetryAt] shouldBeNil];
      [[newVehicle syncErrMask] shouldBeNil];
    });
  });
});

SPEC_END
