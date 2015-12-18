//
//  FPCoordinatorDaoTests_2.m
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
#import "FPFuelPurchaseLog.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_2)

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
    it(@"Can create and edit a fuel purchase log by itself and have it sync", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      // First we need to create a vehicle and fuel station.
      FPVehicle *vehicle =
        [_coordDao vehicleWithName:@"My Bimmer"
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
                                      odometer:[NSDecimalNumber decimalNumberWithString:@"10582"]
                                   gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                    gotCarWash:NO
                      carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                       logDate:[NSDate date]
                                      isDiesel:NO];
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
      [[theValue(totalNumToSync) should] equal:theValue(3)];
      [[theValue(totalSynced) should] equal:theValue(3)];
      [[theValue(overallFlushProgress) should] equal:theValue(1.0)];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // Now everything will have been synced and pruned.
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // sycned
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      
      // Now, starting "fresh", lets edit our fplog
      user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
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
                                           error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
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
      user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
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
