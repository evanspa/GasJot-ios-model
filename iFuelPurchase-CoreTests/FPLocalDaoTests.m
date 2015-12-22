 //
//  FPLocalDaoTests.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/5/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDaoImpl.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import "FPLocalDaoImpl.h"
#import <FMDB/FMDatabase.h>
#import "FPCoordDaoTestContext.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import "FPEnvironmentLog.h"
#import "FPFuelStationType.h"
#import <Kiwi/Kiwi.h>

//static const int ddLogLevel = LOG_LEVEL_VERBOSE;

SPEC_BEGIN(FPLocalDaoSpec)

describe(@"FPLocalDao", ^{
  
  // even though this is a test spec for FPLocalDao, it's just easier to get the
  // LocalDao instance 'bootstrapped' using FPCoordDaoTestContext and FPCoordinatorDao.
  // This is because I wrote the coordinator DAO tests first.

  __block FPCoordDaoTestContext *_coordTestCtx;
  __block FPCoordinatorDaoImpl *_coordDao;
  __block FPUser *_user;
  __block FPVehicle *_v1;
  __block FPFuelStation *_fs1;
  __block NSDateFormatter *_dateFormatter;
  
  beforeAll(^{
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MM/dd/yyyy"];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:[NSBundle bundleForClass:[self class]]];
    _coordDao = [_coordTestCtx newStoreCoord];
  });
  
  beforeEach(^{
    [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) {[_coordTestCtx setErrorDeletingUser:YES];}];
    _user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
    });
    _v1 = [_coordDao vehicleWithName:@"My Bimmer"
                       defaultOctane:@87
                        fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]
                            isDiesel:NO
                       hasDteReadout:NO
                       hasMpgReadout:NO
                       hasMphReadout:NO
               hasOutsideTempReadout:NO
                                 vin:nil
                               plate:nil];
    [_coordDao saveNewVehicle:_v1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
    _fs1 = [_coordDao fuelStationWithName:@"Exxon"
                                     type:[[FPFuelStationType alloc] initWithIdentifier:@(0) name:@"Other" iconImgName:@""]
                                   street:nil
                                     city:nil
                                    state:nil
                                      zip:nil
                                 latitude:nil
                                longitude:nil];
    [_coordDao saveNewFuelStation:_fs1 forUser:_user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
  });
  
  context(@"Nearest odometer log functionality", ^{
    it(@"works when there are no odometer logs", ^{
      NSArray *nearestLog = [_coordDao odometerLogNearestToDate:[NSDate date]
                                                     forVehicle:_v1
                                                          error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLog shouldBeNil];
    });
    
    it (@"works when there are multiple odometer logs", ^{
      FPEnvironmentLog *envlog1 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1008"]
                                                        reportedAvgMpg:nil
                                                        reportedAvgMph:nil
                                                   reportedOutsideTemp:nil
                                                               logDate:[_dateFormatter dateFromString:@"10/01/2015"]
                                                           reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog1 forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPEnvironmentLog *envlog2 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1009"]
                                                        reportedAvgMpg:nil
                                                        reportedAvgMph:nil
                                                   reportedOutsideTemp:nil
                                                               logDate:[_dateFormatter dateFromString:@"10/14/2015"]
                                                           reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog2 forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPEnvironmentLog *envlog3 = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1010"]
                                                         reportedAvgMpg:nil
                                                         reportedAvgMph:nil
                                                    reportedOutsideTemp:nil
                                                                logDate:[_dateFormatter dateFromString:@"10/28/2015"]
                                                            reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog3 forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // should match envlog1
      NSArray *nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/01/2015"]
                                                        forVehicle:_v1
                                                             error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      FPEnvironmentLog *nearestLog = nearestLogVal[0];
      NSInteger distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog1];
      [[theValue(distance) should] equal:theValue(0)];
      
      // should still match envlog1
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/05/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog1];
      [[theValue(distance) should] equal:theValue(4)];
      
      // should still match envlog1
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"09/05/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog1];
      [[theValue(distance) should] equal:theValue(26)];
      
      // should match envlog2
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/14/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog2];
      [[theValue(distance) should] equal:theValue(0)];
      
      // should still match envlog2
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/15/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog2];
      [[theValue(distance) should] equal:theValue(1)];
      
      // should still match envlog2
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/20/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog2];
      [[theValue(distance) should] equal:theValue(6)];
      
      // should match envlog3
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/22/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog3];
      [[theValue(distance) should] equal:theValue(6)];
      
      // should still match envlog3
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/28/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog3];
      [[theValue(distance) should] equal:theValue(0)];
      
      // should still match envlog3
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/29/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog3];
      [[theValue(distance) should] equal:theValue(1)];
    });
    
    it (@"works when there is 1 odometer log", ^{
      FPEnvironmentLog *envlog = [_coordDao environmentLogWithOdometer:[NSDecimalNumber decimalNumberWithString:@"1008"]
                                                        reportedAvgMpg:nil
                                                        reportedAvgMph:nil
                                                   reportedOutsideTemp:nil
                                                               logDate:[_dateFormatter dateFromString:@"10/01/2015"]
                                                           reportedDte:nil];
      [_coordDao saveNewEnvironmentLog:envlog forUser:_user vehicle:_v1 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      
      // make sure it works when searching the exact log date
      NSArray *nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/01/2015"]
                                                        forVehicle:_v1
                                                             error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      FPEnvironmentLog *nearestLog = nearestLogVal[0];
      NSInteger distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog];
      [[theValue(distance) should] equal:theValue(0)];
      
      // make sure it works when searching after the log date
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"10/02/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog];
      [[theValue(distance) should] equal:theValue(1)];
      
      // make sure it works when searching befre the log date
      nearestLogVal = [_coordDao odometerLogNearestToDate:[_dateFormatter dateFromString:@"09/27/2015"]
                                               forVehicle:_v1
                                                    error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [nearestLogVal shouldNotBeNil];
      nearestLog = nearestLogVal[0];
      distance = [nearestLogVal[1] integerValue];
      [[nearestLog should] equal:envlog];
      [[theValue(distance) should] equal:theValue(4)];
    });
  });
});

SPEC_END
