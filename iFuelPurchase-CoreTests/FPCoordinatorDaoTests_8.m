//
//  FPCoordinatorDaoTests_8.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <fuelpurchase-common/FPTransactionCodes.h>
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

SPEC_BEGIN(FPCoordinatorDaoSpec_8)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block TLTransactionManager *_txnMgr;
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
    _txnMgr = [_coordTestCtx newTxnManager];
    _coordDao = [_coordTestCtx newStoreCoordWithTxnManager:_txnMgr];
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
    it(@"Can create and edit a vehicle by itself and have it sync", ^{
      TLTransaction *txn = [_txnMgr transactionWithUsecase:@(FPTxnCreateAccount)
                                                     error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.201", 0, 0);
      user = [_coordDao userWithName:@"Joe Smith"
                               email:@"joe.smith@example.com"
                            username:@"smithjoe"
                            password:@"pa55w0rd"
                        creationDate:[NSDate date]];
      [_coordDao immediateRemoteSyncSaveNewUser:user
                                    transaction:txn
                                remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                              completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                          localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      [[theValue([_coordTestCtx success]) should] beYes];
      // sanity check that the user is ONLY in master
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      // Now lets create a vehicle
      FPVehicle *vehicle = [_coordDao vehicleWithName:@"My Bimmer" dateAdded:[NSDate date]];
      [_coordDao saveNewVehicle:vehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // our user had to have been copied down to main from master in order for the
      // new vehicle to have been saved to its main_vehicle table
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:0]];
      FPToggler *vehSyncedObserver = _observer(@[FPVehicleSynced]);
      _flusher(0.0);
      [[expectFutureValue(theValue([vehSyncedObserver observedCount]))
          shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      // now lets edit the vehicle
      vehicle = [[_coordDao vehiclesForUser:user pageSize:5 error:[_coordTestCtx newLocalSaveErrBlkMaker]()] objectAtIndex:0];
      BOOL prepareForEditSuccess =
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
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [vehicle setName:@"My Blue Bimmer"];
      _mocker(@"http-response.vehicle.PUT.200", 0, 0);
      [_coordDao saveVehicle:vehicle
                 editActorId:@(FPForegroundActorId)
                       error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      vehSyncedObserver = _observer(@[FPVehicleSynced]);
      _flusher(0.0);
      [[expectFutureValue(theValue([vehSyncedObserver observedCount]))
        shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [[[[[_coordDao vehiclesForUser:user
                           pageSize:5
                              error:[_coordTestCtx newLocalFetchErrBlkMaker]()]
          objectAtIndex:0] name] should] equal:@"My Blue Bimmer"];
    });
  });
});

SPEC_END
