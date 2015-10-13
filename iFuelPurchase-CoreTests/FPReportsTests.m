//
//  FPReportsTests.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/13/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
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
#import "FPReports.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPReportsSpec)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingObserver _observer;
__block FPReports *_reports;
__block FPUser *_user;
__block FPVehicle *_v1;
__block FPFuelStation *_fs1;

describe(@"FPReports", ^{
  
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
    _reports = [[FPReports alloc] initWithLocalDao:_coordDao.localDao errorBlk:[_coordTestCtx newLocalFetchErrBlkMaker]()];
    _user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
    });
    _v1 = [_coordDao vehicleWithName:@"My Bimmer" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]];
    [_coordDao saveNewVehicle:_v1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    _fs1 = [_coordDao fuelStationWithName:@"Exxon" street:nil city:nil state:nil zip:nil latitude:nil longitude:nil];
    [_coordDao saveNewFuelStation:_fs1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
  });
  
  context(@"Reporting object works", ^{
    it(@"When there are no gas or odometer data records", ^{
      // money spent on gas
      [[[_reports yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber zero]];
      [[[_reports yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber zero]];
      [[[_reports yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber zero]];
      [[[_reports totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber zero]];
      [[[_reports totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber zero]];
      [[[_reports totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber zero]];
      // avg price per gallon
      [[_reports yearToDateAvgPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_reports yearToDateAvgPricePerGallonForVehicle:_v1 octane:@(87)] shouldBeNil];
      [[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
    });
    
    it(@"When there is only 1 gas record", ^{
      FPFuelPurchaseLog *fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                                   octane:[NSNumber numberWithInt:93]
                                                              gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                                               gotCarWash:NO
                                                 carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                  logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    });
  });
});

SPEC_END
