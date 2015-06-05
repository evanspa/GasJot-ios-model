//
//  FPCoordinatorDaoTests_15.m
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

SPEC_BEGIN(FPCoordinatorDaoSpec_15)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingFlusher _flusher;

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
  });
  
  afterAll(^{
    [_coordTestCtx stopTimerForAsyncWork];
  });

  context(@"Tests", ^{
    it(@"Have sync fail on fuel purchase logs, make sure things are still kosher", ^{
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
      
      fplog =
        [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"16.3"]
                                         octane:[NSNumber numberWithInt:87]
                                    gallonPrice:[NSDecimalNumber decimalNumberWithString:@"2.79"]
                                     gotCarWash:NO
                       carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".06"]
                                        logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog
                                forUser:user
                                vehicle:vehicle
                            fuelStation:fuelStation
                                  error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // fetch by fuel station
      NSArray *fplogs =
        [_coordDao fuelPurchaseLogsForFuelStation:fuelStation pageSize:5 beforeDateLogged:nil error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:2];
      // fetch by vehicle
      fplogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle pageSize:5 beforeDateLogged:nil error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:2];
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      _mocker(@"http-response.fuelstations.POST.201", 0, 0);
      _mocker(@"http-response.fplogs.POST.500", 0, 0);
      _flusher(5.0); // flush to master, prune and pause
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_FUEL_STATION) should] equal:[NSNumber numberWithInt:1]]; // sycned
      [[_numEntitiesBlk(TBL_MAIN_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:2]]; // not-pruned
      [[_numEntitiesBlk(TBL_MASTER_FUELPURCHASE_LOG) should] equal:[NSNumber numberWithInt:0]]; // not-synced
      // fetch by fuel station again
      fplogs = [_coordDao fuelPurchaseLogsForFuelStation:fuelStation pageSize:5 beforeDateLogged:nil error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:2];
      // fetch by vehicle again
      fplogs = [_coordDao fuelPurchaseLogsForVehicle:vehicle pageSize:5 beforeDateLogged:nil error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fplogs should] haveCountOf:2];
    });
  });
});

SPEC_END
