//
//  FPCoordinatorDaoTests_2.m
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
#import "FPNotificationNames.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_2)

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
    it(@"Can create and edit a fuel purchase log by itself and have it sync", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      // First we need to create a vehicle and fuel station.
      FPVehicle *vehicle =
        [_coordDao vehicleWithName:@"My Bimmer" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]];
      [_coordDao saveNewVehicle:vehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPFuelStation *fuelStation =
        [_coordDao fuelStationWithName:@"Exxon Mobile"
                                street:nil
                                  city:@"Charlotte"
                                 state:@"NC"
                                   zip:@"28277"
                              latitude:nil
                             longitude:nil];
      [_coordDao saveNewFuelStation:fuelStation forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPFuelPurchaseLog *fplog =
      [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                        octane:[NSNumber numberWithInt:93]
                                   gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                    gotCarWash:NO
                      carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                       logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog
                                forUser:user
                                vehicle:vehicle
                            fuelStation:fuelStation
                                  error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      NSArray *fplogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle
                                                     pageSize:10
                                                        error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:1];
      fplogs = [_coordDao fuelPurchaseLogsForFuelStation:fuelStation
                                                pageSize:10
                                                   error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:1];
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      _mocker(@"http-response.fuelstations.POST.201", 0, 0);
      _mocker(@"http-response.fplogs.POST.201", 0, 0);
      //FPToggler *sysPruneObserver = _observer(@[FPSystemPruningComplete]);
      FPToggler *vehSyncedObserver = _observer(@[FPVehicleSynced]);
      FPToggler *fuelStationSyncedObserver = _observer(@[FPFuelStationSynced]);
      FPToggler *fplogSyncedObserver = _observer(@[FPFuelPurchaseLogSynced]);
      _flusher(0.0); // flush to master, prune and pause
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      //[[expectFutureValue(theValue([sysPruneObserver observedCount])) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
      [[expectFutureValue(theValue([vehSyncedObserver observedCount])) shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
      [[expectFutureValue(theValue([fuelStationSyncedObserver observedCount])) shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
      // vehicle synced but NOT pruned (because child FP-log instance couldn't be pruned)
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      // fuel station synced but NOT pruned (because child FP-log instance cound't be pruned)
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // synced
      // fuel purchase log NOT synced because vehicle and fuel station's hadn't
      // synced yet (yes - even through the req/resp latencies are set to 0,
      // their completion blocks will not have executed yet), and therefore also
      // counldn't get pruned.
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:0]]; // not synced
      // just to be safe, we'll sleep for 2 seconds and will then issue another
      // flush job.
      _flusher(0.0); // flush to master, pause
      [[expectFutureValue(theValue([fplogSyncedObserver observedCount])) shouldEventuallyBeforeTimingOutAfter(5)] beGreaterThanOrEqualTo:theValue(1)];
      // at this point, the FP-log will get synced
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // sycned
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      // just to be safe, we'll sleep for 2 seconds and will then issue another
      // flush/prune job.
      _flusher(0.0); // flush to master, prune and pause
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      //[[expectFutureValue(theValue([sysPruneObserver observedCount])) shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(3)];
      // Now everything will have been pruned.
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // sycned
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      
      // Now, starting "fresh", lets edit our fplog
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      NSArray *vehicles = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[vehicles should] haveCountOf:1];
      vehicle = vehicles[0];
      fplogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle
                                            pageSize:10
                                               error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:1];
      fplog = fplogs[0];
      BOOL prepareForEditSuccess =
        [_coordDao prepareFuelPurchaseLogForEdit:fplog
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
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]];
      
      // Let's re-get the fplog, and make sure its 'edit in progress' field is true (but, we need to start
      // with first re-getting the user and vehicle from the database - this is because when we did the
      // prepareForEdit call on our fplog, the associated vehicle was copied down to main; however, our
      // 'vehicle' object in-memory was not mutated; it was mutated in the database.  So, in order to have
      // a consistent view of our data model, we need to refetch things from the database.
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      vehicles = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[vehicles should] haveCountOf:1]; // sanity check
      vehicle = vehicles[0];
      fplogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle
                                            pageSize:10
                                               error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:1];
      fplog = fplogs[0];
      [[theValue([fplog editInProgress]) should] beYes];
    });
  });
});

SPEC_END
