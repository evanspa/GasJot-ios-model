//
//  FPStats.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPStats.h"
#import "PEUtils.h"
#import <PEObjc-Commons/NSDate+PEAdditions.h>

typedef id (^FPValueBlock)(void);

@implementation FPStats {
  FPLocalDao *_localDao;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithLocalDao:(FPLocalDao *)localDao errorBlk:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _localDao = localDao;
    _errorBlk = errorBlk;
  }
  return self;
}

#pragma mark - Helpers

- (NSDate *)firstDayOfYearOfDate:(NSDate *)date {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                             fromDate:date];
  [components setDay:1];
  [components setMonth:1];
  return [calendar dateFromComponents:components];
}

- (NSDecimalNumber *)totalSpentFromFplogs:(NSArray *)fplogs {
  NSDecimalNumber *total = [NSDecimalNumber zero];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    if (![PEUtils isNil:fplog.numGallons] && ![PEUtils isNil:fplog.gallonPrice]) {
      total = [total decimalNumberByAdding:[fplog.numGallons decimalNumberByMultiplyingBy:fplog.gallonPrice]];
    }
  }
  return total;
}

- (NSDecimalNumber *)avgGallonPriceFromFplogs:(NSArray *)fplogs {
  NSInteger numFplogs = [fplogs count];
  if (numFplogs > 0) {
    NSInteger numRelevantLogs = 0;
    NSDecimalNumber *gallonPriceSum = [NSDecimalNumber zero];
    for (FPFuelPurchaseLog *fplog in fplogs) {
      if (![PEUtils isNil:fplog.gallonPrice]) {
        numRelevantLogs++;
        gallonPriceSum = [gallonPriceSum decimalNumberByAdding:fplog.gallonPrice];
      }
    }
    return [gallonPriceSum decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:numRelevantLogs]];
  }
  return nil;
}

#pragma mark - Gas Cost Per Mile

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
  return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
}

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle
                              onOrBeforeDate:(NSDate *)onOrBeforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                              onOrBeforeDate:onOrBeforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle
                                                            onOrBeforeDate:onOrBeforeDate
                                                             onOrAfterDate:onOrAfterDate
                                                                     error:_errorBlk];
  return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
}

- (NSDecimalNumber *)costPerMileForMilesDriven:(NSDecimalNumber *)milesDriven
                               totalSpentOnGas:(NSDecimalNumber *)totalSpentOnGas {
  if ([milesDriven compare:[NSDecimalNumber zero]] == NSOrderedSame) {
    // this means that the user has only 1 odometer log recorded, and thus
    // we can't do this computation
    return nil;
  } else {
    if ([totalSpentOnGas compare:[NSDecimalNumber zero]] == NSOrderedSame) {
      // we have odometer logs, but no gas logs
      return nil;
    }
  }
  return [totalSpentOnGas decimalNumberByDividingBy:milesDriven];
}

- (NSDecimalNumber *)yearToDateGasCostPerMileForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [self firstDayOfYearOfDate:now];
  NSArray *vehicles = [_localDao vehiclesForUser:user error:_errorBlk];
  NSDecimalNumber *totalMilesDriven = [NSDecimalNumber zero];
  NSDecimalNumber *totalSpentOnGas = [NSDecimalNumber zero];
  for (FPVehicle *vehicle in vehicles) {
    totalMilesDriven = [totalMilesDriven decimalNumberByAdding:[self milesRecordedForVehicle:vehicle
                                                                              onOrBeforeDate:now
                                                                               onOrAfterDate:firstDayOfCurrentYear]];
    totalSpentOnGas = [totalSpentOnGas decimalNumberByAdding:[self yearToDateSpentOnGasForVehicle:vehicle]];
  }
  return [self costPerMileForMilesDriven:totalMilesDriven totalSpentOnGas:totalSpentOnGas];
}

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user {
  NSArray *vehicles = [_localDao vehiclesForUser:user error:_errorBlk];
  NSDecimalNumber *totalMilesDriven = [NSDecimalNumber zero];
  NSDecimalNumber *totalSpentOnGas = [NSDecimalNumber zero];
  for (FPVehicle *vehicle in vehicles) {
    totalMilesDriven = [totalMilesDriven decimalNumberByAdding:[self milesRecordedForVehicle:vehicle]];
    totalSpentOnGas = [totalSpentOnGas decimalNumberByAdding:[self yearToDateSpentOnGasForVehicle:vehicle]];
  }
  return [self costPerMileForMilesDriven:totalMilesDriven totalSpentOnGas:totalSpentOnGas];
}

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [self firstDayOfYearOfDate:now];
  NSDecimalNumber *milesDriven = [self milesRecordedForVehicle:vehicle
                                                onOrBeforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear];
  NSDecimalNumber *totalSpentOnGas = [self yearToDateSpentOnGasForVehicle:vehicle];
  return [self costPerMileForMilesDriven:milesDriven totalSpentOnGas:totalSpentOnGas];
}

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
  NSDecimalNumber *milesDriven = [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
  NSDecimalNumber *totalSpentOnGas = [self totalSpentOnGasForVehicle:vehicle];
  return [self costPerMileForMilesDriven:milesDriven totalSpentOnGas:totalSpentOnGas];
}

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                 onOrBeforeDate:now
                                                                  onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:now
                                                                     onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                        onOrBeforeDate:now
                                                                         onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation error:_errorBlk]];
}

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     onOrBeforeDate:now
                                                                      onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                     onOrBeforeDate:now
                                                                      onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                        onOrBeforeDate:now
                                                                         onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                          onOrBeforeDate:now
                                           onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                 onOrBeforeDate:now
                                                  onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

#pragma mark - Min Price Per Gallon

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                          onOrBeforeDate:now
                                           onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                 onOrBeforeDate:now
                                                  onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

#pragma mark - Odometer Log Reports

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                                      user:(FPUser *)user {
  NSDecimalNumber *odometer = [odometerLog odometer];
  if (![PEUtils isNil:odometer]) {
    NSArray *odometerLogs =
      [_localDao environmentLogsForUser:user pageSize:1 beforeDateLogged:[odometerLog logDate] error:_errorBlk];
    if ([odometerLogs count] > 0) {
      NSDecimalNumber *lastOdometer = [odometerLogs[0] odometer];
      if (![PEUtils isNil:lastOdometer]) {
        return [odometer decimalNumberBySubtracting:lastOdometer];
      }
    }
  }
  return nil;
}

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                        user:(FPUser *)user {
  NSArray *odometerLogs =
    [_localDao environmentLogsForUser:user pageSize:1 beforeDateLogged:[odometerLog logDate] error:_errorBlk];
  if ([odometerLogs count] > 0) {
    NSDate *dateOfLastLog = [odometerLogs[0] logDate];
    if (dateOfLastLog) {
      return @([[odometerLog logDate] daysFromDate:dateOfLastLog]);
    }
  }
  return nil;
}

- (NSNumber *)temperatureLastYearFromLog:(FPEnvironmentLog *)odometerLog
                                    user:(FPUser *)user {
  NSInteger plusMinusDays = 15;
  NSDate *logDate = [odometerLog logDate];
  if (logDate) {
    NSDate *oneYearAgo = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:logDate options:0];
    NSDate *oneYearAgoMinusSome = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:plusMinusDays toDate:oneYearAgo options:0];
    NSArray *odometerLogs =
      [_localDao environmentLogsForUser:user pageSize:5 beforeDateLogged:oneYearAgoMinusSome error:_errorBlk];
    if ([odometerLogs count] > 0) {
      // so we got at most 5 hits; use the one nearest to our 1-year-ago date.
      FPEnvironmentLog *nearestToAYearAgoLog = odometerLogs[0];
      for (NSInteger i = 1; i < odometerLogs.count; i++) {
        NSDate *atLeastYearAgoLogDate = [odometerLogs[i] logDate];
        if ([atLeastYearAgoLogDate daysFromDate:oneYearAgo] < [nearestToAYearAgoLog.logDate daysFromDate:oneYearAgo]) {
          nearestToAYearAgoLog = odometerLogs[i];
        }
      }
      // so we have our odometer log that is neareset to 1-year-ago, but, is it
      // within our plus/minus variance?
      if ([nearestToAYearAgoLog.logDate daysFromDate:oneYearAgo] <= plusMinusDays) {
        return [nearestToAYearAgoLog reportedOutsideTemp];
      }
    }
  }
  return nil;
}

@end
