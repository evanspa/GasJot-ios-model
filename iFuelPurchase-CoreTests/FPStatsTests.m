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
__block NSDate *(^_d)(NSString *);

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
    _d = ^(NSString *dateStr) { return [_dateFormatter dateFromString:dateStr]; };
  });
  
  void(^resetUser)(void) = ^{
    [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
    });
    _v1 = [_coordDao vehicleWithName:@"My Bimmer"
                       defaultOctane:@87
                        fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]
                            isDiesel:NO];
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
  
  FPFuelPurchaseLog *(^saveGasLog)(FPVehicle *, FPFuelStation *, NSString *, NSInteger, NSString *, NSString *, BOOL, NSString *, id) =
  ^(FPVehicle *vehicle, FPFuelStation *fs, NSString *numGallons, NSInteger octane, NSString *odometer, NSString *gallonPrice, BOOL gotCarWash, NSString *carWashDiscount, id date) {
    NSDate *purchasedAt = date;
    if ([date isKindOfClass:[NSString class]]) {
      purchasedAt = [_dateFormatter dateFromString:date];
    }
    FPFuelPurchaseLog *fplog = [_coordDao fuelPurchaseLogWithNumGallons:[PEUtils nullSafeDecimalNumberFromString:numGallons]
                                                                 octane:[NSNumber numberWithInteger:octane]
                                                               odometer:[NSDecimalNumber decimalNumberWithString:odometer]
                                                            gallonPrice:[PEUtils nullSafeDecimalNumberFromString:gallonPrice]
                                                             gotCarWash:gotCarWash
                                               carWashPerGallonDiscount:[PEUtils nullSafeDecimalNumberFromString:carWashDiscount]
                                                                logDate:purchasedAt
                                                               isDiesel:NO];
    [_coordDao saveNewFuelPurchaseLog:fplog forUser:_user vehicle:vehicle fuelStation:fs error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    return fplog;
  };
  
  context(@"A couple of odometer logs", ^{
    __block FPEnvironmentLog *envlog1;
    __block FPEnvironmentLog *envlog2;
    beforeAll(^{
      resetUser();
      envlog1 = saveOdometerLog(_v1, @"50",  nil, nil, 40, @"02/04/2013", @"450");
      envlog2 = saveOdometerLog(_v1, @"50",  nil, nil, 40, @"02/08/2013", @"450");
    });
    
    it(@"Days between odometer logs works", ^{
      NSNumber *numDays = [_stats daysSinceLastOdometerLogAndLog:envlog2 vehicle:_v1];
      [numDays shouldNotBeNil];
      [[numDays should] equal:@(4)];
    });
  });
  
  context(@"Several gas logs for 2 vehicles with non-overlapping purchased-at dates for testing user-level days-between-fillups functions", ^{
    beforeAll(^{
      resetUser();
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", @"02/04/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10584", @"4.129", NO, @"0.08", @"02/06/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10586", @"4.129", NO, @"0.08", @"02/20/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10588", @"4.129", NO, @"0.08", @"02/24/2013");
      FPVehicle *v2 = [_coordDao vehicleWithName:@"300zx"
                                   defaultOctane:@93
                                    fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]
                                        isDiesel:NO];
      [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      saveGasLog(v2, _fs1, @"15.2", 91, @"10582", @"4.129", NO, @"0.08", @"02/01/2013");
      saveGasLog(v2, _fs1, @"15.3", 91, @"10584", @"4.129", NO, @"0.08", @"02/07/2013");
      saveGasLog(v2, _fs1, @"15.0", 91, @"10586", @"4.129", NO, @"0.08", @"02/22/2013");
      saveGasLog(v2, _fs1, @"15.4", 91, @"10588", @"4.129", NO, @"0.08", @"02/24/2013");
    });
    
    it(@"Days between fillups for user stats works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"8.0"]];
      [[[_stats overallMaxDaysBetweenFillupsForUser:_user] should] equal:@(15)];
      NSArray *dataset = [_stats overallAvgDaysBetweenFillupsDataSetForUser:_user];
      [[dataset should] haveCountOf:1];
      [[dataset[0][0] should] equal:_d(@"02/01/2013")];
      [[dataset[0][1] should] equal:[NSDecimalNumber decimalNumberWithString:@"7.1666666666666666666666666666666666666"]];
      
      dataset = [_stats overallDaysBetweenFillupsDataSetForUser:_user];
      [[dataset should] haveCountOf:5];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
      [[dataset[1][0] should] equal:_d(@"02/07/2013")];
      [[dataset[1][1] should] equal:@(6)];
      [[dataset[2][0] should] equal:_d(@"02/20/2013")];
      [[dataset[2][1] should] equal:@(14)];
      [[dataset[3][0] should] equal:_d(@"02/22/2013")];
      [[dataset[3][1] should] equal:@(15)];
      [[dataset[4][0] should] equal:_d(@"02/24/2013")];
      [[dataset[4][1] should] equal:@(3.0)];
    });
  });
  
  context(@"Several gas logs for 2 vehicles with overlapping purchased-at dates for testing user-level days-between-fillups functions", ^{
    beforeAll(^{
      resetUser();
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", @"02/04/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10584", @"4.129", NO, @"0.08", @"02/06/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10586", @"4.129", NO, @"0.08", @"02/20/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10588", @"4.129", NO, @"0.08", @"02/24/2013");
      FPVehicle *v2 = [_coordDao vehicleWithName:@"300zx"
                                   defaultOctane:@93
                                    fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]
                                        isDiesel:NO];
      [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      saveGasLog(v2, _fs1, @"15.2", 91, @"10582", @"4.129", NO, @"0.08", @"02/04/2013");
      saveGasLog(v2, _fs1, @"15.3", 91, @"10584", @"4.129", NO, @"0.08", @"02/06/2013");
      saveGasLog(v2, _fs1, @"15.0", 91, @"10586", @"4.129", NO, @"0.08", @"02/20/2013");
      saveGasLog(v2, _fs1, @"15.4", 91, @"10588", @"4.129", NO, @"0.08", @"02/24/2013");
    });
    
    it(@"Days between fillups for user stats works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"6.6666666666666666666666666666666666666"]];
      [[[_stats overallMaxDaysBetweenFillupsForUser:_user] should] equal:@(14)];
      NSArray *dataset = [_stats overallDaysBetweenFillupsDataSetForUser:_user];
      [[dataset should] haveCountOf:3];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
      [[dataset[1][0] should] equal:_d(@"02/20/2013")];
      [[dataset[1][1] should] equal:@(14)];
      [[dataset[2][0] should] equal:_d(@"02/24/2013")];
      [[dataset[2][1] should] equal:@(4)];
    });
  });
  
  context(@"4 gas logs for testing days-between-fillups functions", ^{
    beforeAll(^{
      resetUser();
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", @"02/04/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10584", @"4.129", NO, @"0.08", @"02/06/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10586", @"4.129", NO, @"0.08", @"02/20/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10588", @"4.129", NO, @"0.08", @"02/24/2013");
    });
    
    it(@"Days between fillups for user stats works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"6.6666666666666666666666666666666666666"]];
      [[[_stats overallMaxDaysBetweenFillupsForUser:_user] should] equal:@(14)];
      NSArray *dataset = [_stats overallDaysBetweenFillupsDataSetForUser:_user];
      [[dataset should] haveCountOf:3];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
      [[dataset[1][0] should] equal:_d(@"02/20/2013")];
      [[dataset[1][1] should] equal:@(14)];
      [[dataset[2][0] should] equal:_d(@"02/24/2013")];
      [[dataset[2][1] should] equal:@(4)];
    });
    
    it(@"Days between fillups for vehicle stats works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"6.6666666666666666666666666666666666666"]];
      [[[_stats overallMaxDaysBetweenFillupsForVehicle:_v1] should] equal:@(14)];
      NSArray *dataset = [_stats overallDaysBetweenFillupsDataSetForVehicle:_v1];
      [[dataset should] haveCountOf:3];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
      [[dataset[1][0] should] equal:_d(@"02/20/2013")];
      [[dataset[1][1] should] equal:@(14)];
      [[dataset[2][0] should] equal:_d(@"02/24/2013")];
      [[dataset[2][1] should] equal:@(4)];
    });
  });
  
  context(@"2 gas logs for testing days-between-fillups functions", ^{
    beforeAll(^{
      resetUser();
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", @"02/04/2013");
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10584", @"4.129", NO, @"0.08", @"02/06/2013");
    });
    
    it(@"Days between fillups stats for user works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.0"]];
      [[[_stats overallMaxDaysBetweenFillupsForUser:_user] should] equal:@(2)];
      NSArray *dataset = [_stats overallDaysBetweenFillupsDataSetForUser:_user];
      [[dataset should] haveCountOf:1];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
    });
    
    it(@"Days between fillups stats for vehicle works", ^{
      [[[_stats overallAvgDaysBetweenFillupsForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"2.0"]];
      [[[_stats overallMaxDaysBetweenFillupsForVehicle:_v1] should] equal:@(2)];
      NSArray *dataset = [_stats overallDaysBetweenFillupsDataSetForVehicle:_v1];
      [[dataset should] haveCountOf:1];
      [[dataset[0][0] should] equal:_d(@"02/06/2013")];
      [[dataset[0][1] should] equal:@(2)];
    });
  });
  
  context(@"Several couple gas and odometer logs over several months for data set testing", ^{
    beforeAll(^{
      resetUser();
      // 2 logs in Feb so computation can be done
      NSString *logDate = @"02/04/2013";
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"20"); // pre-fillup odometer log
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", logDate); // 61.935 total spend
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"450"); // post-fillup odometer log
      logDate = @"02/21/2013";
      saveOdometerLog(_v1, @"391",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10584", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"391",  nil, nil, 40, logDate, @"450");
      
      // only 1 log in Mar so computation cannot be done
      logDate = @"03/06/2013";
      saveOdometerLog(_v1, @"592",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10586", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"592",  nil, nil, 40, logDate, @"450");
      
      // 3 in April so computation can be done (drove 300 miles in April, and spent $120.0892 after the first recorded odo log)
      logDate = @"04/01/2013";
      saveOdometerLog(_v1, @"792",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10588", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"792",  nil, nil, 40, logDate, @"450");
      logDate = @"04/12/2013";
      saveOdometerLog(_v1, @"992",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10590", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"992",  nil, nil, 40, logDate, @"450");
      logDate = @"04/27/2013";
      saveOdometerLog(_v1, @"1092",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10592", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"1092",  nil, nil, 40, logDate, @"450");
    });
    
    it(@"YTD and overall spent on gas data sets for vehicle", ^{
      NSArray *ds = [_stats spentOnGasDataSetForVehicle:_v1 year:2012];
      [[ds should] haveCountOf:0];
      ds = [_stats spentOnGasDataSetForVehicle:_v1 year:2013];
      [[ds should] haveCountOf:3]; //12];
      [[ds[0][0] should] equal:_d(@"02/01/2013")];
      [[ds[0][1] should] equal:[NSDecimalNumber decimalNumberWithString:@"121.9796"]];
      [[ds[1][0] should] equal:_d(@"03/01/2013")];
      [[ds[1][1] should] equal:[NSDecimalNumber decimalNumberWithString:@"60.0446"]];
      [[ds[2][0] should] equal:_d(@"04/01/2013")];
      [[ds[2][1] should] equal:[NSDecimalNumber decimalNumberWithString:@"180.1338"]];
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      NSArray *ds = [_stats avgGasCostPerMileDataSetForVehicle:_v1 year:2013];
      [ds shouldNotBeNil];
      [[ds should] haveCountOf:2];
      NSArray *dp = ds[0];
      [[dp[0] should] equal:_d(@"02/01/2013")];
      [[dp[1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.17608387096774193548387096774193548387"]];
      dp = ds[1];
      [[dp[0] should] equal:_d(@"04/01/2013")];
      [[dp[1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.40029733333333333333333333333333333333"]];      
    });
  });
  
  context(@"A single gas / odometer log-pair in a single month for data set testing", ^{
    beforeAll(^{
      resetUser();
      NSString *logDate = @"02/04/2013";
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"20"); // pre-fillup odometer log
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", logDate); // 61.935 total spend
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"450"); // post-fillup odometer log
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      // not enough odometer log data to do the calculation
      NSArray *ds = [_stats avgGasCostPerMileDataSetForVehicle:_v1 year:2013];
      [[ds should] beEmpty];
    });
  });
  
  context(@"A couple gas and odometer logs in a single month for data set testing", ^{
    beforeAll(^{
      resetUser();
      NSString *logDate = @"02/04/2013";
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"20"); // pre-fillup odometer log
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", logDate); // 61.935 total spend
      saveOdometerLog(_v1, @"50",  nil, nil, 40, logDate, @"450"); // post-fillup odometer log
      
      logDate = @"02/21/2013";
      saveOdometerLog(_v1, @"391",  nil, nil, 40, logDate, @"20");
      saveGasLog(_v1, _fs1, @"15.4", 87, @"10584", @"3.899", NO, nil, logDate); // 60.0446
      saveOdometerLog(_v1, @"391",  nil, nil, 40, logDate, @"450");
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      NSArray *ds = [_stats avgGasCostPerMileDataSetForVehicle:_v1 year:2013];
      [ds shouldNotBeNil];
      [[ds should] haveCountOf:1];
      NSArray *dp1 = ds[0];
      [[dp1[0] should] equal:_d(@"02/01/2013")];
      // only gas purchases made AFTER the first odometer log are used in the calculation
      [[dp1[1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.17608387096774193548387096774193548387"]];
    });
  });
  
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
      saveGasLog(_v1, _fs1, @"15.0", 87, @"10582", @"4.129", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 61.935 total spend
      // last year logs (grand total actual: 258.1513) (977 miles driven/recorded)
      saveOdometerLog(_v1, @"475", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"15.2", 87, @"10584", @"3.859", NO, @"0.08", [NSString stringWithFormat:@"01/02/%ld", (long)comps.year-1]); // 58.6568
      saveOdometerLog(_v1, @"683", nil, nil, 40, [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"15.1", 87, @"10586", @"3.699", NO, @"0.08", [NSString stringWithFormat:@"03/16/%ld", (long)comps.year-1]); // 55.8549
      saveOdometerLog(_v1, @"879", nil, nil, 40, [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"14.7", 87, @"10588", @"3.089", NO, @"0.08", [NSString stringWithFormat:@"06/23/%ld", (long)comps.year-1]); // 45.4083
      saveOdometerLog(_v1, @"1098", nil, nil, 40, [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"16.4", 87, @"10590", @"3.009", NO, @"0.08", [NSString stringWithFormat:@"09/09/%ld", (long)comps.year-1]); // 49.3476
      saveOdometerLog(_v1, @"1452", nil, nil, 40, [NSString stringWithFormat:@"12/30/%ld", (long)comps.year-1], nil);
      saveGasLog(_v1, _fs1, @"16.3", 87, @"10592", @"2.999", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 48.8837
      // current year logs (37 miles driven/recorded)
      saveOdometerLog(_v1, @"1462", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(_v1, @"1499", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(_v1, _fs1, @"15.9", 87, @"10594", @"3.459", NO, @"0.08", [NSString stringWithFormat:@"01/03/%ld", (long)comps.year]);   // 54.9981
      
      v2 = [_coordDao vehicleWithName:@"300zx"
                        defaultOctane:@93
                         fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]
                             isDiesel:NO];
      [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // 2 years-ago v2, _fs1 logs (404 miles driven/recorded)
      saveOdometerLog(v2, @"49", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-2], nil);
      saveOdometerLog(v2, @"453", nil, nil, 40, [NSString stringWithFormat:@"12/30/%ld", (long)comps.year-2], nil);
      saveGasLog(v2, _fs1, @"15.1", 87, @"10582", @"4.129", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 62.3479
      // last year logs (grand total actual: 251.2368) (4559 miles driven/recorded)
      saveOdometerLog(v2, @"489", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1], nil);
      saveGasLog(v2, _fs1, @"15.3", 87, @"10584", @"3.959", NO, @"0.08", [NSString stringWithFormat:@"01/02/%ld", (long)comps.year-1]); // 60.5727
      saveGasLog(v2, _fs1, @"15.2", 87, @"10586", @"3.799", NO, @"0.08", [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1]); // 57.7448
      saveGasLog(v2, _fs1, @"14.8", 87, @"10588", @"3.189", NO, @"0.08", [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1]); // 47.1972
      saveGasLog(v2, _fs1, @"16.5", 87, @"10590", @"3.109", NO, @"0.08", [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1]); // 51.2985
      saveGasLog(v2, _fs1, @"16.4", 87, @"10592", @"2.099", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 34.4236
      saveOdometerLog(v2, @"5048", nil, nil, 40, [NSString stringWithFormat:@"11/22/%ld", (long)comps.year-1], nil);
      // current year logs (39 miles driven/recorded)
      saveOdometerLog(v2, @"5055", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(v2, @"5094", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(v2, _fs1, @"16.0", 87, @"10584", @"3.559", NO, @"0.08", [NSString stringWithFormat:@"01/03/%ld", (long)comps.year]);   // 56.944
      
      fs2 = [_coordDao fuelStationWithName:@"Sunoco" street:nil city:nil state:nil zip:nil latitude:nil longitude:nil];
      [_coordDao saveNewFuelStation:fs2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      v3 = [_coordDao vehicleWithName:@"M5"
                        defaultOctane:@93
                         fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"19.1"]
                             isDiesel:NO];
      [_coordDao saveNewVehicle:v3 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // 2 years-ago v3, fs2 logs (1060 miles driven/recorded)
      saveOdometerLog(v3, @"10859", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-2], nil);
      saveOdometerLog(v3, @"11919", nil, nil, 40, [NSString stringWithFormat:@"12/30/%ld", (long)comps.year-2], nil);
      saveGasLog(v3, fs2, @"15.2", 87, @"10582", @"4.149", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-2]); // 63.0648
      // last year logs (grand total actual: 258.3863) (5076 miles driven/recorded)
      saveOdometerLog(v3, @"11928", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year-1], nil);
      saveGasLog(v3, fs2, @"15.4", 87, @"10582", @"3.879", NO, @"0.08", [NSString stringWithFormat:@"01/02/%ld", (long)comps.year-1]); // 59.7366
      saveGasLog(v3, fs2, @"15.3", 87, @"10582", @"3.619", NO, @"0.08", [NSString stringWithFormat:@"03/15/%ld", (long)comps.year-1]); // 55.3707
      saveGasLog(v3, fs2, @"14.9", 87, @"10582", @"3.009", NO, @"0.08", [NSString stringWithFormat:@"06/22/%ld", (long)comps.year-1]); // 44.8341
      saveGasLog(v3, fs2, @"16.6", 87, @"10582", @"3.029", NO, @"0.08", [NSString stringWithFormat:@"09/08/%ld", (long)comps.year-1]); // 50.2814
      saveGasLog(v3, fs2, @"16.5", 87, @"10582", @"2.919", NO, @"0.08", [NSString stringWithFormat:@"12/31/%ld", (long)comps.year-1]); // 48.1635
      saveOdometerLog(v3, @"17004", nil, nil, 40, [NSString stringWithFormat:@"11/15/%ld", (long)comps.year-1], nil);
      // current year logs (727 miles driven/recorded)
      saveOdometerLog(v3, @"17102", nil, nil, 40, [NSString stringWithFormat:@"01/01/%ld", (long)comps.year], nil);
      saveOdometerLog(v3, @"17829", nil, nil, 40, [NSString stringWithFormat:@"01/02/%ld", (long)comps.year], nil);
      saveGasLog(v3, fs2, @"15.1", 87, @"10582", @"3.459", NO, @"0.08", [NSString stringWithFormat:@"01/03/%ld", (long)comps.year]);   // 52.2309
    });
    
    it(@"Overall, YTD and last year gas cost per mile stats works", ^{
      [[[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"1.48643513513513513513513513513513513513"]];
      [[[_stats lastYearAvgGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.264228556806550665301944728761514841351"]];
      [[[_stats overallAvgGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.258857418909592822636300897170462387853"]];
      
      [[[_stats yearToDateAvgGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"1.46010256410256410256410256410256410256"]];
      [[[_stats lastYearAvgGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.055107874533889010747971046282079403377"]];
      [[[_stats overallAvgGasCostPerMileForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.07344473736372646184340931615460852329"]];
      
      [[[_stats yearToDateAvgGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.071844429160935350756533700137551581843"]];
      [[[_stats lastYearAvgGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.050903526398739164696611505122143420015"]];
      [[[_stats overallAvgGasCostPerMileForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.053612912482065997130559540889526542324"]];
    });
    
    it(@"Total, YTD and last year spend on gas stats works", ^{
      [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"164.173"]];
      [[[_stats lastYearSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"767.7744"]];
      [[[_stats overallSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"1119.2951"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"54.9981"]];
      [[[_stats lastYearSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.1513"]];
      [[[_stats overallSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"375.0844"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"56.944"]];
      [[[_stats lastYearSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"251.2368"]];
      [[[_stats overallSpentOnGasForVehicle:v2] should] equal:[NSDecimalNumber decimalNumberWithString:@"370.5287"]];
      
      [[[_stats yearToDateSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"52.2309"]];
      [[[_stats lastYearSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.3863"]];
      [[[_stats overallSpentOnGasForVehicle:v3] should] equal:[NSDecimalNumber decimalNumberWithString:@"373.682"]];
      
      [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.9421"]];
      [[[_stats lastYearSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"509.3881"]];
      [[[_stats overallSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"745.6131"]];
      
      [[[_stats yearToDateSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"52.2309"]];
      [[[_stats lastYearSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"258.3863"]];
      [[[_stats overallSpentOnGasForFuelstation:fs2] should] equal:[NSDecimalNumber decimalNumberWithString:@"373.682"]];
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
    
    it(@"YTD and overall gas cost per mile for vehicle", ^{
      [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
    });
  });

  context(@"There are no gas or odometer logs", ^{
    
    it(@"Days between fillups stats work", ^{
      [[_stats yearToDateAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats lastYearAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      
      [[_stats yearToDateMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats lastYearMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats overallMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      
      [[[_stats yearToDateDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats lastYearDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
    });
    
    it(@"YTD and total spend on gas stats work", ^{
      [[_stats yearToDateSpentOnGasForUser:_user] shouldBeNil];
      [[_stats yearToDateSpentOnGasForVehicle:_v1] shouldBeNil];
      [[_stats yearToDateSpentOnGasForFuelstation:_fs1] shouldBeNil];
      [[_stats overallSpentOnGasForUser:_user] shouldBeNil];
      [[_stats overallSpentOnGasForVehicle:_v1] shouldBeNil];
      [[_stats overallSpentOnGasForFuelstation:_fs1] shouldBeNil];
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
    
    it(@"YTD and overall gas cost per mile for vehicle", ^{
      [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
    });
  });
  
  context(@"3 odometer logs and 1 gas log", ^{
    __block FPFuelPurchaseLog *fplog;
    __block FPEnvironmentLog *envlog2;
    beforeAll(^{
      resetUser();
       saveOdometerLog(_v1, @"1008", nil, nil, 60, _d(@"01/01/2015"), nil);
      fplog = saveGasLog(_v1, _fs1, @"15.2", 87, @"10582", @"3.85", NO, @"0.08", _d(@"01/02/2015"));
      envlog2= saveOdometerLog(_v1, @"1324", nil, nil, 60, _d(@"01/03/2015"), nil);
      saveOdometerLog(_v1, @"1324", nil, nil, 60, _d(@"01/04/2015"), nil);
    });
    
    it(@"Days between fillups stats work", ^{
      [[_stats yearToDateAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats lastYearAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      
      [[_stats yearToDateMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats lastYearMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      [[_stats overallMaxDaysBetweenFillupsForVehicle:_v1] shouldBeNil];
      
      [[[_stats yearToDateDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats lastYearDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallDaysBetweenFillupsDataSetForVehicle:_v1] should] beEmpty];
    });

    it(@"Miles recorded", ^{
      [[[_stats milesRecordedForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"Miles driven", ^{
      [[[_stats milesDrivenSinceLastOdometerLogAndLog:envlog2 vehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"YTD and overall gas cost per mile for user and vehicle", ^{
      [[[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
      [[[_stats overallAvgGasCostPerMileForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      NSArray *ds = [_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1];
      [ds shouldNotBeNil];
      [[ds should] haveCountOf:1];
      NSArray *dp1 = ds[0];
      [[dp1[0] should] equal:_d(@"01/01/2015")];
      [[dp1[1] should] equal:[NSDecimalNumber decimalNumberWithString:@"0.185189873417721518987341772151898734177"]];
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
      [[[_stats milesDrivenSinceLastOdometerLogAndLog:envlog2 vehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"316"]];
    });
    
    it(@"YTD and overall gas cost per mile for vehicle", ^{
      [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
    });
    
    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
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
      [[_stats milesDrivenSinceLastOdometerLogAndLog:envlog vehicle:_v1] shouldBeNil];
    });
    
    it(@"YTD and overall gas cost per mile for vehicle", ^{
      [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
    });

    it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
      [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
    });
    
    context(@"When there is only 1 gas record", ^{
      __block FPFuelPurchaseLog *fplog;
      beforeAll(^{
        resetUser();
        fplog = saveGasLog(_v1, _fs1, @"15.2", 87, @"10582", @"3.85", NO, @"0.08", [NSDate date]);
      });
      
      it(@"YTD and total spend on gas stats work", ^{
        [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats overallSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats overallSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
        [[[_stats overallSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"58.52"]];
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
      
      it(@"YTD and overall gas cost per mile for vehicle", ^{
        [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
        [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      });
      
      it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
        [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
        [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      });
    });
    
    context(@"When there are multiple gas records", ^{
      __block FPFuelPurchaseLog *fplog;
      __block FPFuelPurchaseLog *fplog2;
      
      beforeAll(^{
        resetUser();
        fplog  = saveGasLog(_v1, _fs1, @"15.2",  87, @"10582", @"3.85",  NO, @"0.08", [NSDate date]);
        fplog2 = saveGasLog(_v1, _fs1, @"17.92", 87, @"10582", @"2.159", NO, @"0.08", [NSDate date]);
      });
      
      it(@"YTD and total spend on gas stats work", ^{
        [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats overallSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats overallSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
        [[[_stats overallSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
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
      
      it(@"YTD and overall gas cost per mile for vehicle", ^{
        [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
        [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
      });
      
      it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
        [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
        [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
      });
      
      context(@"create a 2nd vehicle, and 3rd fplog for that vehicle", ^{
        __block FPVehicle *v2;
        __block FPFuelPurchaseLog *fplog3;
        beforeAll(^{
          v2 = [_coordDao vehicleWithName:@"My Mazda"
                            defaultOctane:@87
                             fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"18.25"]
                                 isDiesel:NO];
          [_coordDao saveNewVehicle:v2 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
          fplog3  = saveGasLog(v2, _fs1, @"5.01", 87, @"10582", @"2.899", NO, @"0.08", [NSDate date]);
        });
        
        it(@"YTD and total spend on gas stats work", ^{
          [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
          [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats overallSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
          [[[_stats overallSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
          [[[_stats overallSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
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
        
        it(@"YTD and overall gas cost per mile for vehicle", ^{
          [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
          [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
        });
        
        it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
          [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
          [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
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
            fplog4  = saveGasLog(_v1, _fs1, @"7.50", 87, @"10582", @"3.099", NO, @"0.08", logDate);
          });
          
          it(@"YTD and total spend on gas stats work", ^{
            [[[_stats yearToDateSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
            [[[_stats yearToDateSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"97.20928"]];
            [[[_stats yearToDateSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"111.73327"]];
            [[[_stats overallSpentOnGasForUser:_user] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
            [[[_stats overallSpentOnGasForVehicle:_v1] should] equal:[NSDecimalNumber decimalNumberWithString:@"120.45178"]];
            [[[_stats overallSpentOnGasForFuelstation:_fs1] should] equal:[NSDecimalNumber decimalNumberWithString:@"134.97577"]];
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
          
          it(@"YTD and overall gas cost per mile for vehicle", ^{
            [[_stats yearToDateAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
            [[_stats overallAvgGasCostPerMileForVehicle:_v1] shouldBeNil];
          });
          
          it(@"YTD and overall gas cost per mile data sets for vehicle", ^{
            [[[_stats yearToDateAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
            [[[_stats overallAvgGasCostPerMileDataSetForVehicle:_v1] should] beEmpty];
          });
        });
      });
    });
  });
});

SPEC_END
