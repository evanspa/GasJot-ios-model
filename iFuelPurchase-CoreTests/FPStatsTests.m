//
//  FPStatsTests.m
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
#import "FPStats.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPStatsSpec)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block NSDateFormatter *_dateFormatter;
__block FPStats *_stats;
__block FPUser *_user;
__block FPVehicle *_v1;
__block FPFuelStation *_fs1;

describe(@"FPStats", ^{
  
  beforeAll(^{
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:[NSBundle bundleForClass:[self class]]];
    _coordDao = [_coordTestCtx newStoreCoord];
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao.localDao errorBlk:[_coordTestCtx newLocalFetchErrBlkMaker]()];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MM/dd/yyyy"];
  });
  
  void(^resetUser)(void) = ^{
    [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
    });
    _v1 = [_coordDao vehicleWithName:@"My Bimmer" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]];
    [_coordDao saveNewVehicle:_v1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    _fs1 = [_coordDao fuelStationWithName:@"Exxon" street:nil city:nil state:nil zip:nil latitude:nil longitude:nil];
    [_coordDao saveNewFuelStation:_fs1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
  };
  
  FPEnvironmentLog *(^saveOdometerLog)(FPVehicle *, NSString *, NSString *, NSString *, NSInteger, id, NSString *reportedDte) =
  ^(FPVehicle *vehicle, NSString *odometer, NSString *reportedAvgMpg, NSString *reportedAvgMph, NSInteger temp, id date, NSString *reportedDte) {
    NSDate *logDate = date;
    if ([date isKindOfClass:[NSString class]]) {
      logDate = [_dateFormatter dateFromString:date];
    }
    FPEnvironmentLog *envlog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:odometer]
                                                      reportedAvgMpg:[PEUtils nullSafeDecimalNumberFromString:reportedAvgMpg]
                                                      reportedAvgMph:[PEUtils nullSafeDecimalNumberFromString:reportedAvgMph]
                                                 reportedOutsideTemp:[NSNumber numberWithInteger:temp]
                                                             logDate:logDate
                                                         reportedDte:[PEUtils nullSafeDecimalNumberFromString:reportedDte]];
    [_coordDao saveNewEnvironmentLog:envlog
                             forUser:_user
                             vehicle:vehicle
                               error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    return envlog;
  };
  
  FPFuelPurchaseLog *(^saveGasLog)(FPVehicle *, FPFuelStation *, NSString *, NSInteger, NSString *, BOOL, NSString *, id) =
  ^(FPVehicle *vehicle, FPFuelStation *fs, NSString *numGallons, NSInteger octane, NSString *gallonPrice, BOOL gotCarWash, NSString *carWashDiscount, id date) {
    NSDate *purchasedAt = date;
    if ([date isKindOfClass:[NSString class]]) {
      purchasedAt = [_dateFormatter dateFromString:date];
    }
    FPFuelPurchaseLog *fplog = [_coordDao fuelPurchaseLogWithNumGallons:[PEUtils nullSafeDecimalNumberFromString:numGallons]
                                              octane:[NSNumber numberWithInteger:octane]
                                         gallonPrice:[PEUtils nullSafeDecimalNumberFromString:gallonPrice]
                                          gotCarWash:gotCarWash
                            carWashPerGallonDiscount:[PEUtils nullSafeDecimalNumberFromString:carWashDiscount]
                                             logDate:purchasedAt];
    [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:vehicle fuelStation:fs error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    return fplog;
  };
  
  context(@"Various odometer logs occuring over various time ranges", ^{
    beforeAll(^{
      resetUser();
      // a bunch of 2014 logs
      saveOdometerLog(_v1, @"50",  nil, nil, 40, @"01/01/2014", nil);
      saveOdometerLog(_v1, @"100", nil, nil, 50, @"03/01/2014", nil);
      saveOdometerLog(_v1, @"441", nil, nil, 60, @"06/01/2014", nil);
      saveOdometerLog(_v1, @"539", nil, nil, 62, @"09/01/2014", nil);
      saveOdometerLog(_v1, @"720", nil, nil, 52, @"12/01/2014", nil);
      // a few 2015 logs
      saveOdometerLog(_v1, @"1451", nil, nil, 54, @"03/06/2015", nil);
      saveOdometerLog(_v1, @"1658", nil, nil, 63, @"05/28/2015", nil);
    });
    
    NSNumber *(^yearAgoTemp)(NSString *, NSInteger) = ^NSNumber *(NSString *fromDate, NSInteger variance) {
      return [_stats temperatureForUser:_user
                     oneYearAgoFromDate:[_dateFormatter dateFromString:fromDate]
                     withinDaysVariance:variance];
    };
    
    it(@"Last year temperature stat works", ^{
      [[yearAgoTemp(@"01/01/2015", 0) should] equal:[NSNumber numberWithInteger:40]];
      [yearAgoTemp(@"01/02/2015", 0) shouldBeNil];
      [[yearAgoTemp(@"01/02/2015", 1) should] equal:[NSNumber numberWithInteger:40]];
      [[yearAgoTemp(@"01/03/2015", 2) should] equal:[NSNumber numberWithInteger:40]];
      [yearAgoTemp(@"01/04/2015", 2) shouldBeNil];
      [[yearAgoTemp(@"01/20/2015", 19) should] equal:[NSNumber numberWithInteger:40]];
      [[yearAgoTemp(@"01/20/2015", 20) should] equal:[NSNumber numberWithInteger:40]];
      [[yearAgoTemp(@"01/20/2015", 500) should] equal:[NSNumber numberWithInteger:40]];
      [yearAgoTemp(@"01/20/2015", 18) shouldBeNil];
      
      [yearAgoTemp(@"05/01/2015", 20) shouldBeNil];
      [[yearAgoTemp(@"04/15/2015", 100) should] equal:[NSNumber numberWithInteger:50]];
      [[yearAgoTemp(@"04/14/2015", 100) should] equal:[NSNumber numberWithInteger:50]];
      [[yearAgoTemp(@"04/17/2015", 100) should] equal:[NSNumber numberWithInteger:60]];
    });
  });

  context(@"There are no gas or odometer logs", ^{
    it(@"YTD and total spend on gas stats work", ^{
      [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber zero]];
      [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber zero]];
      [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber zero]];
      [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber zero]];
      [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber zero]];
      [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber zero]];
    });
    
    it(@"YTD and overall average price of gas stats work", ^{
      [[_stats yearToDateAvgPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_stats yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
      [[_stats overallAvgPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_stats overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
    });
    
    it(@"YTD and overall max price of gas stats work", ^{
      [[_stats yearToDateMaxPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_stats yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
      [[_stats overallMaxPricePerGallonForUser:_user octane:@(87)] shouldBeNil];
      [[_stats overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] shouldBeNil];
    });
  });
  
  context(@"3 odometer logs and 1 gas log", ^{
    __block FPFuelPurchaseLog *fplog;
    __block FPEnvironmentLog *envlog2;
    beforeAll(^{
      resetUser();
      fplog = saveGasLog(_v1, _fs1, @"15.2", 87, @"3.85", NO, @"0.08", [NSDate date]);
      saveOdometerLog(_v1, @"1008", nil, nil, 60, [NSDate date], nil);
      envlog2= saveOdometerLog(_v1, @"1324", nil, nil, 60, [NSDate date], nil);
      saveOdometerLog(_v1, @"1324", nil, nil, 60, [NSDate date], nil);
    });

    it(@"Miles recorded", ^{
      [[[_stats milesRecordedForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"Miles driven", ^{
      [[[_stats milesDrivenSinceLastOdometerLogAndLog:envlog2 user:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"YTD and overall gas cost per mile for user and vehicle", ^{
      [[[_stats yearToDateGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
      [[[_stats yearToDateGasCostPerMileForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
      [[[_stats overallGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
      [[[_stats overallGasCostPerMileForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
    });
  });
  
  context(@"3 odometer logs and no gas logs", ^{
    __block FPEnvironmentLog *envlog;
    __block FPEnvironmentLog *envlog2;
    __block FPEnvironmentLog *envlog3;
    beforeAll(^{
      resetUser();
      envlog = saveOdometerLog(_v1, @"1008", nil, nil, 60, [NSDate date], nil);
      [_coordDao saveNewEnvironmentLog:envlog forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      envlog2 = saveOdometerLog(_v1, @"1324", nil, nil, 60, [NSDate date], nil);
      envlog3 = saveOdometerLog(_v1, @"1324", nil, nil, 60, [NSDate date], nil);
    });
    
    it(@"Miles recorded", ^{
      [[[_stats milesRecordedForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"Miles driven", ^{
      [[[_stats milesDrivenSinceLastOdometerLogAndLog:envlog2 user:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"YTD and overall gas cost per mile for user and vehicle", ^{
      [[_stats yearToDateGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats yearToDateGasCostPerMileForUser:_user] shouldBeNil];
      [[_stats overallGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallGasCostPerMileForUser:_user] shouldBeNil];
    });
  });
  
  context(@"1 odometer log and no gas logs", ^{
    __block FPEnvironmentLog *envlog;
    beforeAll(^{
      resetUser();
      envlog = saveOdometerLog(_v1, @"1008", nil, nil, 60, [_dateFormatter stringFromDate:[NSDate date]], nil);
    });
    
    it(@"Miles recorded", ^{
      [[[_stats milesRecordedForVehicle:_v1] should] equal:[NSDecimalNumber zero]];
    });
    
    it(@"Miles driven", ^{
      [[_stats milesDrivenSinceLastOdometerLogAndLog:envlog user:_user] shouldBeNil];
    });
    
    it(@"YTD and overall gas cost per mile for user and vehicle", ^{
      [[_stats yearToDateGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats yearToDateGasCostPerMileForUser:_user] shouldBeNil];
      [[_stats overallGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallGasCostPerMileForUser:_user] shouldBeNil];
    });
    
    context(@"When there is only 1 gas record", ^{
      __block FPFuelPurchaseLog *fplog;
      beforeAll(^{
        resetUser();
        fplog = saveGasLog(_v1, _fs1, @"15.2", 87, @"3.85", NO, @"0.08", [NSDate date]);
      });
      
      it(@"YTD and total spend on gas stats work", ^{
        [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
      });
      
      it(@"YTD and overall average price of gas stats work", ^{
        [[[_stats yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      });
      
      it(@"YTD and overall max price of gas stats work", ^{
        [[[_stats yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      });
    });
    
    context(@"When there are multiple gas records", ^{
      __block FPFuelPurchaseLog *fplog;
      __block FPFuelPurchaseLog *fplog2;
      
      beforeAll(^{
        resetUser();
        fplog  = saveGasLog(_v1, _fs1, @"15.2",  87, @"3.85",  NO, @"0.08", [NSDate date]);
        fplog2 = saveGasLog(_v1, _fs1, @"17.92", 87, @"2.159", NO, @"0.08", [NSDate date]);
      });
      
      it(@"YTD and total spend on gas stats work", ^{
        [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
      });
      
      it(@"YTD and overall average price of gas stats work", ^{
        [[[_stats yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
        [[[_stats yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
        [[[_stats overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
        [[[_stats overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.0045"]];
      });
      
      it(@"YTD and overall max price of gas stats work", ^{
        [[[_stats yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        [[[_stats overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
      });
      
      context(@"create a 2nd vehicle, and 3rd fplog for that vehicle", ^{
        __block FPVehicle *v2;
        __block FPFuelPurchaseLog *fplog3;
        beforeAll(^{
          v2 = [_coordDao vehicleWithName:@"My Mazda" defaultOctane:@87 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"18.25"]];
          [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
          fplog3  = saveGasLog(v2, _fs1, @"5.01", 87, @"2.899", NO, @"0.08", [NSDate date]);
        });
        
        it(@"YTD and total spend on gas stats work", ^{
          [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
          [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
          [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
        });
        
        it(@"YTD and overall average price of gas stats work", ^{
          [[[_stats yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
          [[[_stats yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
          [[[_stats overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
          [[[_stats overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
        });
        
        it(@"YTD and overall max price of gas stats work", ^{
          [[[_stats yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
          [[[_stats yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
          [[[_stats overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
          [[[_stats overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
        });
        
        context(@"add a gas log that goes back to the previous year, for vehicle _v1", ^{
          __block FPFuelPurchaseLog *fplog4;
          beforeAll(^{
            NSDate *now = [NSDate date];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                       fromDate:now];
            [components setYear:([components year] - 1)];
            NSDate *logDate = [calendar dateFromComponents:components];
            fplog4  = saveGasLog(_v1, _fs1, @"7.50", 87, @"3.099", NO, @"0.08", logDate);
          });
          
          it(@"YTD and total spend on gas stats work", ^{
            [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
            [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
            [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
            [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
            [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"120.45178"]];
            [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
          });
          
          it(@"YTD and overall average price of gas stats work", ^{
            [[[_stats yearToDateAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
            [[[_stats yearToDateAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.96933333333333333333333333333333333333"]];
            [[[_stats overallAvgPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.00175"]];
            [[[_stats overallAvgPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.00175"]];
          });
          
          it(@"YTD and overall max price of gas stats work", ^{
            [[[_stats yearToDateMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
            [[[_stats yearToDateMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
            [[[_stats overallMaxPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
            [[[_stats overallMaxPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"3.85"]];
            [[[_stats overallMinPricePerGallonForUser:_user octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.159"]];
            [[[_stats overallMinPricePerGallonForFuelstation:_fs1 octane:@(87)] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.159"]];
          });
        });
      });
    });
  });
});

SPEC_END
