//
//  FPCoordinatorDaoTests_9.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <PEFuelPurchase-Common/FPTransactionCodes.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPNotificationNames.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_9)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingFlusher _flusher;
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
    _flusher = [_coordTestCtx newFlusherWithCoordDao:_coordDao];
    _observer = [_coordTestCtx newObserver];
  });
  
  afterAll(^{
    [_coordTestCtx stopTimerForAsyncWork];
  });
  
  context(@"Tests", ^{
    it(@"Can edit a user and vehicle at same time", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      BOOL prepareForEditSuccess =
        [_coordDao prepareUserForEdit:user
                          editActorId:@(FPForegroundActorId)
                    entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                        entityDeleted:[_coordTestCtx entityDeletedBlk]
                     entityInConflict:[_coordTestCtx entityInConflictBlk]
        entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [user setName:@"Paul Evans"];
      [user setEmail:@"paul.evans@example.com"];
      [_coordDao markAsDoneEditingUser:user
                           editActorId:@(FPForegroundActorId)
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPVehicle *vehicle = [_coordDao vehicleWithName:@"My Bimmer" dateAdded:[NSDate date]];
      [_coordDao saveNewVehicle:vehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // the following will prevent syncing w/remote master on first timer fire
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                             editActorId:@(FPForegroundActorId)
                       entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                           entityDeleted:[_coordTestCtx entityDeletedBlk]
                        entityInConflict:[_coordTestCtx entityInConflictBlk]
           entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      FPToggler *userSyncCompleteToggler = _observer(@[FPUserSynced]);
      _mocker(@"http-response.user.PUT.204", 0, 0);
      [_coordTestCtx startTimerForAsyncWorkWithInterval:1 coordDao:_coordDao];
      [[expectFutureValue(theValue([userSyncCompleteToggler value])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = [[_coordDao localDao] mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil]; // user not pruned from main because vehicle (child) is in main_vehicle
      [[theValue([user synced]) should] beYes];
      user = [[_coordDao localDao] masterUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil];
      [[[user name] should] equal:@"Paul Evans"];
      [[[user email] should] equal:@"paul.evans@example.com"];
      
      // now  lets put HTTP system into a state such that a vehicle-POST will
      // be successful, and then mark 'editComplete' for the vehicle.
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()]; // should now get synced/pruned on next timer fire
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // not synced
      FPToggler *vehicleSyncedToggler = _observer(@[FPVehicleSynced]);
      [[expectFutureValue(theValue([vehicleSyncedToggler value])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      
      // now we can do a system-wide prune event; our synced user instance currently sitting in
      // main_user should get pruned (since the vehicle instance should have gotten
      // pruned from main_vehicle
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[[_coordDao localDao] mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()] shouldBeNil];
      user = [[_coordDao localDao] mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
    });
  });
});

SPEC_END
