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
    _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
    _mocker = [_coordTestCtx newMocker];
    _observer = [_coordTestCtx newObserver];
    _reports = [[FPReports alloc] initWithLocalDao:_coordDao.localDao errorBlk:[_coordTestCtx newLocalFetchErrBlkMaker]()];
  });
  
  context(@"Reporting object works", ^{
    
    beforeEach(^{
      [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
      _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
      _user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      _v1 = [_coordDao vehicleWithName:@"My Bimmer" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]];
      [_coordDao saveNewVehicle:_v1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      _fs1 = [_coordDao fuelStationWithName:@"Exxon" street:nil city:nil state:nil zip:nil latitude:nil longitude:nil];
      [_coordDao saveNewFuelStation:_fs1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    });
    
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
      [[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
      [[_reports overallAvgPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_reports overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
      // max price per gallon
      [[_reports yearToDateMaxPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_reports yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
      [[_reports overallMaxPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_reports overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
    });
    
    it(@"When there is only 1 gas record", ^{
      FPFuelPurchaseLog *fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                                   octane:[NSNumber numberWithInt:87]
                                                              gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                                               gotCarWash:NO
                                                 carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                  logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // money spent on gas
      [[[_reports yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      [[[_reports yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      [[[_reports yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      [[[_reports totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      [[[_reports totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      [[[_reports totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      // avg price per gallon
      [[[_reports yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      // max price per gallon
      [[[_reports yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
    });
    
    it(@"When there are multiple gas records", ^{
      FPFuelPurchaseLog *fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                                   octane:[NSNumber numberWithInt:87]
                                                              gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                                               gotCarWash:NO
                                                 carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                  logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPFuelPurchaseLog *fplog2 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"17.92"]
                                                                   octane:[NSNumber numberWithInt:87]
                                                              gallonPrice:[NSDecimalNumber decimalNumberWithString:@"2.159"]
                                                               gotCarWash:NO
                                                 carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                  logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog2 forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // money spent on gas
      [[[_reports yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      // avg price per gallon
      [[[_reports yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
      [[[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
      [[[_reports overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
      [[[_reports overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
      // max price per gallon
      [[[_reports yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      
      // now, we'll create a 2nd vehicle, and 3rd fplog for that vehicle, and make sure things still work
      FPVehicle *v2 = [_coordDao vehicleWithName:@"My Mazda" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"18.25"]];
      [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPFuelPurchaseLog *fplog3 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"5.01"]
                                                                    octane:[NSNumber numberWithInt:87]
                                                               gallonPrice:[NSDecimalNumber decimalNumberWithString:@"2.899"]
                                                                gotCarWash:NO
                                                  carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                   logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog3 forUser:_user vehicle:v2 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // money spent on gas
      [[[_reports yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      [[[_reports yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      [[[_reports totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      [[[_reports totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      // avg price per gallon
      [[[_reports yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      [[[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      [[[_reports overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      [[[_reports overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      // max price per gallon
      [[[_reports yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      
      // now let's add a gas log that goes back to the previous year, for vehicle _v1
      NSDate *now = [NSDate date];
      NSCalendar *calendar = [NSCalendar currentCalendar];
      NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                 fromDate:now];
      [components setYear:([components year] - 1)];
      NSDate *logDate = [calendar dateFromComponents:components];
      FPFuelPurchaseLog *fplog4 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"7.50"]
                                                                    octane:[NSNumber numberWithInt:87]
                                                               gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.099"]
                                                                gotCarWash:NO
                                                  carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                                   logDate:logDate];
      [_coordDao saveNewFuelPurchaseLog:fplog4 forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // money spent on gas (only totals should change)
      [[[_reports yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      [[[_reports yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      [[[_reports yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
      [[[_reports totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
      [[[_reports totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"120.45178"]];
      [[[_reports totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
      // avg price per gallon
      [[[_reports yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      [[[_reports yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
      [[[_reports overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.00175"]];
      [[[_reports overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.00175"]];
      // max price per gallon
      [[[_reports yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      [[[_reports overallMinPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.159"]];
      [[[_reports overallMinPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.159"]];
    });
  });
});

SPEC_END
