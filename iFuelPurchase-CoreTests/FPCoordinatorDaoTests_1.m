//
//  FPCoordinatorDaoTests.m
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
#import <UIKit/UIKit.h>
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_1)

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
    it(@"Can create and edit an environment log by itself and have it sync", ^{
      TLTransaction *txn = [_txnMgr transactionWithUsecase:@(FPTxnCreateAccount)
                                                     error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, txn, ^{
          [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
        });
      // First we need to create a vehicle and fuel station.
      FPVehicle *vehicle =
        [_coordDao vehicleWithName:@"Volkswagen CC" dateAdded:[NSDate date]];
      [_coordDao saveNewVehicle:vehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPEnvironmentLog *envLog =
        [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"95648"]
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
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      _mocker(@"http-response.envlogs.POST.201", 0, 0);
      _flusher(5.0); // flush to master and pause
      // vehicle synced but NOT pruned (because child envlog instance couldn't be pruned)
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      // environment log NOT synced because vehicle hasn't
      // synced yet (yes - even through the req/resp latencies are set to 0,
      // their completion blocks will not have executed yet), and therefore also
      // counldn't get pruned.
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:0]]; // not synced
      _flusher(5.0); // flush to master and pause
      // at this point, the envlog will get synced
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:1]]; // not pruned
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      _flusher(5.0); // flush to master and pause
      // and finally, the vehicle and envlog will get pruned on next prune run
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:1]]; // synced
      
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // Now everything will have been pruned.
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // still pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_ENV_LOG) should] equal:[NSNumber numberWithInt:0]]; // still pruned
      [[_numEntitiesBlk(TBL_MASTER_ENV_LOG) should] equal:[NSNumber numberWithInt:1]];
    });
  });
});

SPEC_END