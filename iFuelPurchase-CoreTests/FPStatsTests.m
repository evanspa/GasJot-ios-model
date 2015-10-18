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
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingObserver _observer;
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
    _mocker = [_coordTestCtx newMocker];
    _observer = [_coordTestCtx newObserver];
    _stats = [[FPStats alloc] initWithLocalDao:_coordDao.localDao errorBlk:[_coordTestCtx newLocalFetchErrBlkMaker]()];
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
    __block FPEnvironmentLog *envlog;
    __block FPEnvironmentLog *envlog2;
    beforeAll(^{
      resetUser();
      fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                octane:[NSNumber numberWithInt:87]
                                           gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                            gotCarWash:NO
                              carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                               logDate:[NSDate date]];
      [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      envlog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1008"]
                                      reportedAvgMpg:nil
                                      reportedAvgMph:nil
                                 reportedOutsideTemp:nil
                                             logDate:[NSDate date]
                                         reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      envlog2 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1324"]
                                       reportedAvgMpg:nil
                                       reportedAvgMph:nil
                                  reportedOutsideTemp:nil
                                              logDate:[NSDate date]
                                          reportedDte:[NSDecimalNumber decimalNumberWithString:@"23"]];
      // pre-fillup log
      [_coordDao saveNewEnvironmentLog:envlog2 forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // post-fillup log
      [_coordDao saveNewEnvironmentLog:[_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1324"]
                                                              reportedAvgMpg:nil
                                                              reportedAvgMph:nil
                                                         reportedOutsideTemp:nil
                                                                     logDate:[NSDate date]
                                                                 reportedDte:[NSDecimalNumber decimalNumberWithString:@"485"]]
                               forUser:_user
                               vehicle:_v1
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
      NSDate *now = [NSDate date];
      envlog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1008"]
                                      reportedAvgMpg:nil
                                      reportedAvgMph:nil
                                 reportedOutsideTemp:nil
                                             logDate:now
                                         reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      envlog2 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1324"]
                                       reportedAvgMpg:nil
                                       reportedAvgMph:nil
                                  reportedOutsideTemp:nil
                                              logDate:[NSDate date]
                                          reportedDte:[NSDecimalNumber decimalNumberWithString:@"25"]];
      // pre-fillup log
      [_coordDao saveNewEnvironmentLog:envlog2 forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // post-fillup log
      envlog3 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1324"]
                                       reportedAvgMpg:nil
                                       reportedAvgMph:nil
                                  reportedOutsideTemp:nil
                                              logDate:[NSDate date]
                                          reportedDte:[NSDecimalNumber decimalNumberWithString:@"485"]];
      [_coordDao saveNewEnvironmentLog:envlog3
                               forUser:_user
                               vehicle:_v1
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
      NSDate *now = [NSDate date];
      envlog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1008"]
                                      reportedAvgMpg:nil
                                      reportedAvgMph:nil
                                 reportedOutsideTemp:nil
                                             logDate:now
                                         reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
        fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                  octane:[NSNumber numberWithInt:87]
                                             gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                              gotCarWash:NO
                                carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                 logDate:[NSDate date]];
        [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
        fplog = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"15.2"]
                                                  octane:[NSNumber numberWithInt:87]
                                             gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.85"]
                                              gotCarWash:NO
                                carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                 logDate:[NSDate date]];
        [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
        fplog2 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"17.92"]
                                                   octane:[NSNumber numberWithInt:87]
                                              gallonPrice:[NSDecimalNumber decimalNumberWithString:@"2.159"]
                                               gotCarWash:NO
                                 carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                  logDate:[NSDate date]];
        [_coordDao saveNewFuelPurchaseLog:fplog2 forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
          fplog3 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"5.01"]
                                                     octane:[NSNumber numberWithInt:87]
                                                gallonPrice:[NSDecimalNumber decimalNumberWithString:@"2.899"]
                                                 gotCarWash:NO
                                   carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                    logDate:[NSDate date]];
          [_coordDao saveNewFuelPurchaseLog:fplog3 forUser:_user vehicle:v2 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
            fplog4 = [_coordDao fuelPurchaseLogWithNumGallons:[NSDecimalNumber decimalNumberWithString:@"7.50"]
                                                       octane:[NSNumber numberWithInt:87]
                                                  gallonPrice:[NSDecimalNumber decimalNumberWithString:@"3.099"]
                                                   gotCarWash:NO
                                     carWashPerGallonDiscount:[NSDecimalNumber decimalNumberWithString:@".08"]
                                                      logDate:logDate];
            [_coordDao saveNewFuelPurchaseLog:fplog4 forUser:_user vehicle:_v1 fuelStation:_fs1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
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
