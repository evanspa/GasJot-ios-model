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
  
  context(@"Various gas logs over various time ranges", ^{
    __block FPVehicle *v2;
    __block FPVehicle *v3;
    __block FPFuelStation *fs2;
    beforeAll(^{
      resetUser();
      NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
      // 2 years-ago _v1, _fs1 logs (402 miles driven/recorded)
      saveOdometerLog(_v1, @"50",  nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-2], nil);
      saveOdometerLog(_v1, @"452", nil, nil, 40, [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2], nil);
      saveGasLog(_v1, _fs1, @"15.0", 87, @"4.129", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 61.935 total spend
      // last year logs (grand total actual: 258.1513) (977 miles driven/recorded)
      saveOdometerLog(_v1, @"475", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"15.2", 87, @"3.859", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1]); // 58.6568
      saveOdometerLog(_v1, @"683", nil, nil, 40, [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"15.1", 87, @"3.699", NO, @"0.08", [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1]); // 55.8549
      saveOdometerLog(_v1, @"879", nil, nil, 40, [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"14.7", 87, @"3.089", NO, @"0.08", [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1]); // 45.4083
      saveOdometerLog(_v1, @"1098", nil, nil, 40, [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"16.4", 87, @"3.009", NO, @"0.08", [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1]); // 49.3476
      saveOdometerLog(_v1, @"1452", nil, nil, 40, [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"16.3", 87, @"2.999", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 48.8837
      // current year logs (37 miles driven/recorded)
      saveOdometerLog(_v1, @"1462", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(_v1, @"1499", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(_v1, _fs1, @"15.9", 87, @"3.459", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year]);   // 54.9981
      
      v2 = [_coordDao vehicleWithName:@"300zx" defaultOctane:@93 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]];
      [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // 2 years-ago v2, _fs1 logs (404 miles driven/recorded)
      saveOdometerLog(v2, @"49", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-2], nil);
      saveOdometerLog(v2, @"453", nil, nil, 40, [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2], nil);
      saveGasLog(v2, _fs1, @"15.1", 87, @"4.129", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 62.3479
      // last year logs (grand total actual: 251.2368) (4559 miles driven/recorded)
      saveOdometerLog(v2, @"489", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1], nil);
      saveGasLog(v2, _fs1, @"15.3", 87, @"3.959", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1]); // 60.5727
      saveGasLog(v2, _fs1, @"15.2", 87, @"3.799", NO, @"0.08", [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1]); // 57.7448
      saveGasLog(v2, _fs1, @"14.8", 87, @"3.189", NO, @"0.08", [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1]); // 47.1972
      saveGasLog(v2, _fs1, @"16.5", 87, @"3.109", NO, @"0.08", [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1]); // 51.2985
      saveGasLog(v2, _fs1, @"16.4", 87, @"2.099", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 34.4236
      saveOdometerLog(v2, @"5048", nil, nil, 40, [NSString stringWithFormat:@"11/22/%ld", (long)comps.year-1], nil);
      // current year logs (39 miles driven/recorded)
      saveOdometerLog(v2, @"5055", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(v2, @"5094", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(v2, _fs1, @"16.0", 87, @"3.559", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year]);   // 56.944
      
      fs2 = [_coordDao fuelStationWithName:@"Sunoco" street:nil city:nil state:nil zip:nil latitude:nil longitude:nil];
      [_coordDao saveNewFuelStation:fs2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      v3 = [_coordDao vehicleWithName:@"M5" defaultOctane:@93 fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]];
      [_coordDao saveNewVehicle:v3 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // 2 years-ago v3, fs2 logs (1060 miles driven/recorded)
      saveOdometerLog(v3, @"10859", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-2], nil);
      saveOdometerLog(v3, @"11919", nil, nil, 40, [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2], nil);
      saveGasLog(v3, fs2, @"15.2", 87, @"4.149", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 63.0648
      // last year logs (grand total actual: 258.3863) (5076 miles driven/recorded)
      saveOdometerLog(v3, @"11928", nil, nil, 40, [NSString stringWithFormat:@"11/12/%ld", (long)comps.year-1], nil);
      saveGasLog(v3, fs2, @"15.4", 87, @"3.879", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1]); // 59.7366
      saveGasLog(v3, fs2, @"15.3", 87, @"3.619", NO, @"0.08", [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1]); // 55.3707
      saveGasLog(v3, fs2, @"14.9", 87, @"3.009", NO, @"0.08", [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1]); // 44.8341
      saveGasLog(v3, fs2, @"16.6", 87, @"3.029", NO, @"0.08", [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1]); // 50.2814
      saveGasLog(v3, fs2, @"16.5", 87, @"2.919", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 48.1635
      saveOdometerLog(v3, @"17004", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-1], nil);
      // current year logs (727 miles driven/recorded)
      saveOdometerLog(v3, @"17102", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(v3, @"17829", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(v3, fs2, @"15.1", 87, @"3.459", NO, @"0.08", [NSString stringWithFormat:@"01/01/%ld", (long)comps.year]);   // 52.2309
    });
    
    it(@"Overall, YTD and last year gas cost per mile stats works", ^{
      [[[_stats yearToDateGasCostPerMileForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.204449564134495641344956413449564134495"]];
      [[[_stats lastYearGasCostPerMileForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.072349641914813418771202412363362231436"]];
      [[[_stats overallGasCostPerMileForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.083132434640522875816993464052287581699"]];
      
      [[[_stats yearToDateGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"1.48643513513513513513513513513513513513"]];
      [[[_stats lastYearGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.264228556806550665301944728761514841351"]];
      [[[_stats overallGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.258857418909592822636300897170462387853"]];
      
      [[[_stats yearToDateGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"1.46010256410256410256410256410256410256"]];
      [[[_stats lastYearGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.055107874533889010747971046282079403377"]];
      [[[_stats overallGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.07344473736372646184340931615460852329"]];
      
      [[[_stats yearToDateGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.071844429160935350756533700137551581843"]];
      [[[_stats lastYearGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.050903526398739164696611505122143420015"]];
      [[[_stats overallGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.053612912482065997130559540889526542324"]];
    });
    
    it(@"Total, YTD and last year spend on gas stats works", ^{
      [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"164.173"]];
      [[[_stats lastYearSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"767.7744"]];
      [[[_stats totalSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"1119.2951"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"54.9981"]];
      [[[_stats lastYearSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.1513"]];
      [[[_stats totalSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"375.0844"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"56.944"]];
      [[[_stats lastYearSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"251.2368"]];
      [[[_stats totalSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"370.5287"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"52.2309"]];
      [[[_stats lastYearSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.3863"]];
      [[[_stats totalSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"373.682"]];
      
      [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.9421"]];
      [[[_stats lastYearSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"509.3881"]];
      [[[_stats totalSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"745.6131"]];
      
      [[[_stats yearToDateSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"52.2309"]];
      [[[_stats lastYearSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.3863"]];
      [[[_stats totalSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"373.682"]];
    });
  });
  
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
