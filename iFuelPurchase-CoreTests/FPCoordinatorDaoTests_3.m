//
//  FPCoordinatorDaoTests_3.m
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

SPEC_BEGIN(FPCoordinatorDaoSpec_3)

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
    it(@"Can create a fuel station and have its coordinates computed successfully", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      // Now lets create a couple of fuel stations
      FPFuelStation *fuelStation =
        [_coordDao fuelStationWithName:@"Exxon Station"
                                street:nil
                                  city:@"Charlotte"
                                 state:@"NC"
                                   zip:@"28277"
                              latitude:nil
                             longitude:nil
                             dateAdded:[NSDate date]];
      [_coordDao saveNewFuelStation:fuelStation forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      fuelStation =
        [_coordDao fuelStationWithName:@"Stewarts"
                                street:@"1482 Route 7"
                                  city:@"Schenectady"
                                 state:@"NY"
                                   zip:@"12309"
                              latitude:nil
                             longitude:nil
                             dateAdded:[NSDate date]];
      [_coordDao saveNewFuelStation:fuelStation forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPToggler *toggler = _observer(@[FPFuelStationCoordinateComputeSuccess, FPFuelStationCoordinateComputeFailed]);
      [_coordTestCtx startTimerForAsyncWorkWithInterval:1 coordDao:_coordDao];
      // wait for both notififications (i.e., 1 notification for each of the 2 fuel stations)
      [[expectFutureValue(theValue([toggler totalObservedCount]))
        shouldEventuallyBeforeTimingOutAfter(60)] equal:theValue(2)];
      NSArray *fuelStations = [_coordDao fuelStationsForUser:user
                                                    pageSize:5
                                                       error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[fuelStations should] haveCountOf:2];
      fuelStation = fuelStations[0];
      [[[fuelStation name] should] equal:@"Stewarts"];
      [[[fuelStation street] should] equal:@"1482 Route 7"];
      [[[fuelStation city] should] equal:@"Schenectady"];
      [[[fuelStation state] should] equal:@"NY"];
      [[[fuelStation zip] should] equal:@"12309"];
      fuelStation = fuelStations[1];
      [[[fuelStation name] should] equal:@"Exxon Station"];
      [[[fuelStation street] should] beNil];
      [[[fuelStation city] should] equal:@"Charlotte"];
      [[[fuelStation state] should] equal:@"NC"];
      [[[fuelStation zip] should] equal:@"28277"];
      if ([toggler observedCountForNotificationName:FPFuelStationCoordinateComputeSuccess] == 2) {
        [[fuelStations[0] latitude] shouldNotBeNil];
        [[fuelStations[0] longitude] shouldNotBeNil];
        [[fuelStations[1] latitude] shouldNotBeNil];
        [[fuelStations[1] longitude] shouldNotBeNil];
      } else if ([toggler observedCountForNotificationName:FPFuelStationCoordinateComputeSuccess] == 0) {
        [[fuelStations[0] latitude] shouldBeNil];
        [[fuelStations[0] longitude] shouldBeNil];
        [[fuelStations[1] latitude] shouldBeNil];
        [[fuelStations[1] longitude] shouldBeNil];
      } else {
        if ([fuelStations[0] latitude]) {
          [[fuelStations[0] longitude] shouldNotBeNil];
          [[fuelStations[1] latitude] shouldBeNil];
          [[fuelStations[1] longitude] shouldBeNil];
        } else {
          [[fuelStations[0] longitude] shouldBeNil];
          [[fuelStations[1] latitude] shouldNotBeNil];
          [[fuelStations[1] longitude] shouldNotBeNil];
        }
      }
    });
  });
});

SPEC_END
