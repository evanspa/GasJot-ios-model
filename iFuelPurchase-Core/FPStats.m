//
//  FPStats.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPStats.h"
#import "PEUtils.h"

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

- (NSDate *)dateFromCalendar:(NSCalendar *)calendar
                         day:(NSInteger)day
                       month:(NSInteger)month
              fromYearOfDate:(NSDate *)date {
  NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                             fromDate:date];
  [components setDay:day];
  [components setMonth:month];
  return [calendar dateFromComponents:components];
}

- (NSDate *)firstDayOfYearOfDate:(NSDate *)date calendar:(NSCalendar *)calendar {
  return [self dateFromCalendar:calendar day:1 month:1 fromYearOfDate:date];
}

- (NSDate *)firstDayOfYearOfDate:(NSDate *)date {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  return [self firstDayOfYearOfDate:date calendar:calendar];
}

- (NSDate *)firstDayOfYear:(NSInteger)year month:(NSInteger)month calendar:(NSCalendar *)calendar {
  NSDateComponents *components = [[NSDateComponents alloc] init];
  [components setDay:1];
  [components setMonth:month];
  [components setYear:year];
  return [calendar dateFromComponents:components];
}

- (NSDate *)firstDayOfMonth:(NSInteger)month ofYearOfDate:(NSDate *)date calendar:(NSCalendar *)calendar {
  return [self dateFromCalendar:calendar day:1 month:month fromYearOfDate:date];
}

- (NSDate *)lastDayOfMonthForDate:(NSDate *)date month:(NSInteger)month calendar:(NSCalendar *)calendar {
  NSRange rng = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
  return [self dateFromCalendar:calendar day:rng.length month:month fromYearOfDate:date];
}

- (NSInteger)numMonthsInYear:(NSInteger)year calendar:(NSCalendar *)calendar {
  NSDate *firstDayOfYear = [self firstDayOfYear:year month:1 calendar:calendar];
  NSRange rng = [calendar rangeOfUnit:NSCalendarUnitMonth inUnit:NSCalendarUnitYear forDate:firstDayOfYear];
  return rng.length;
}

- (NSArray *)lastYearRangeFromDate:(NSDate *)date {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                             fromDate:date];
  [components setMonth:1];
  [components setDay:1];
  [components setYear:components.year - 1];
  NSDate *startOfLastYear = [calendar dateFromComponents:components];
  [components setMonth:12];
  [components setDay:31];
  return @[startOfLastYear, [calendar dateFromComponents:components]];
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

- (NSDate *)oneYearAgoFromDate:(NSDate *)fromDate {
  return [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:fromDate options:0];
}

- (NSDate *)oneYearAgoFromNow {
  return [self oneYearAgoFromDate:[NSDate date]];
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

- (NSDecimalNumber *)gasCostPerMileForVehicle:(FPVehicle *)vehicle
                               onOrBeforeDate:(NSDate *)onOrBeforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                              onOrBeforeDate:onOrBeforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  if (firstOdometerLog) {
    NSDecimalNumber *milesDriven = [self milesRecordedForVehicle:vehicle
                                                  onOrBeforeDate:onOrBeforeDate
                                                   onOrAfterDate:onOrAfterDate];
    NSDecimalNumber *totalSpentOnGas = [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                  onOrBeforeDate:onOrBeforeDate
                                                                                                   onOrAfterDate:onOrAfterDate
                                                                                                           error:_errorBlk]];
    return [self costPerMileForMilesDriven:milesDriven totalSpentOnGas:totalSpentOnGas];
  }
  return nil;
}

- (NSDecimalNumber *)gasCostPerMileForUser:(FPUser *)user
                            onOrBeforeDate:(NSDate *)onOrBeforeDate
                             onOrAfterDate:(NSDate *)onOrAfterDate {
  NSArray *vehicles = [_localDao vehiclesForUser:user error:_errorBlk];
  NSDecimalNumber *totalMilesDriven = [NSDecimalNumber zero];
  NSDecimalNumber *totalSpentOnGas = [NSDecimalNumber zero];
  for (FPVehicle *vehicle in vehicles) {
    FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                                onOrBeforeDate:onOrBeforeDate
                                                                 onOrAfterDate:onOrAfterDate
                                                                         error:_errorBlk];
    if (firstOdometerLog) {
      totalMilesDriven = [totalMilesDriven decimalNumberByAdding:[self milesRecordedForVehicle:vehicle
                                                                                onOrBeforeDate:onOrBeforeDate
                                                                                 onOrAfterDate:firstOdometerLog.logDate]];
      totalSpentOnGas = [totalSpentOnGas decimalNumberByAdding:[self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                                          onOrBeforeDate:onOrBeforeDate
                                                                                                                           onOrAfterDate:onOrAfterDate
                                                                                                                                   error:_errorBlk]]];
    }
  }
  return [self costPerMileForMilesDriven:totalMilesDriven totalSpentOnGas:totalSpentOnGas];
}

- (NSArray *)gasCostPerMileDataSetForUser:(FPUser *)user
                                     year:(NSInteger)year
                               startMonth:(NSInteger)startMonth
                                 endMonth:(NSInteger)endMonth
                                 calendar:(NSCalendar *)calendar {
  NSMutableArray *dataset = [NSMutableArray array];
  for (NSInteger i = startMonth; i <= endMonth; i++) {
    NSDate *firstDayOfMonth = [self firstDayOfYear:year month:i calendar:calendar];
    NSDate *lastDayOfMonth = [self lastDayOfMonthForDate:firstDayOfMonth month:i calendar:calendar];
    NSDecimalNumber *gasCostPerMile = [self gasCostPerMileForUser:user onOrBeforeDate:lastDayOfMonth onOrAfterDate:firstDayOfMonth];
    if (gasCostPerMile) {
      [dataset addObject:@[lastDayOfMonth, gasCostPerMile]];
    }
  }
  return dataset;
}

- (NSArray *)gasCostPerMileDataSetForUser:(FPUser *)user
                           onOrBeforeDate:(NSDate *)onOrBeforeDate
                            onOrAfterDate:(NSDate *)onOrAfterDate {
  NSMutableArray *dataset = [NSMutableArray array];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *onOrBeforeDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:onOrBeforeDate];
  NSDateComponents *onOrAfterDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:onOrAfterDate];
  NSInteger startYear = onOrAfterDateComps.year;
  NSInteger endYear = onOrBeforeDateComps.year;
  for (NSInteger i = startYear; i <= endYear; i++) {
    NSInteger startMonth;
    if (i == startYear) {
      startMonth = onOrAfterDateComps.month;
    } else {
      startMonth = 1;
    }
    NSInteger endMonth;
    if (i == endYear) {
      endMonth = onOrBeforeDateComps.month;
    } else {
      endMonth = 12;
    }
    [dataset addObjectsFromArray:[self gasCostPerMileDataSetForUser:user year:i startMonth:startMonth endMonth:endMonth calendar:calendar]];
  }
  return dataset;
}

#pragma mark - Gas Cost Per Mile

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
  return [self gasCostPerMileForUser:user onOrBeforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateGasCostPerMileDataSetForUser:(FPUser *)user {
  NSMutableArray *dataset = [NSMutableArray array];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSInteger currentMonth = [calendar component:NSCalendarUnitMonth fromDate:now];
  for (NSInteger i = 1; i <= currentMonth; i++) {
    NSDate *firstOfMonth = [self firstDayOfMonth:i ofYearOfDate:now calendar:calendar];
    NSDate *lastDayOfMonth = [self lastDayOfMonthForDate:firstOfMonth month:i calendar:calendar];
    NSDecimalNumber *gasCostPerMile = [self gasCostPerMileForUser:user onOrBeforeDate:lastDayOfMonth onOrAfterDate:firstOfMonth];
    if (gasCostPerMile) {
      [dataset addObject:@[lastDayOfMonth, gasCostPerMile]];
    }
  }
  return dataset;
}

- (NSDecimalNumber *)lastYearGasCostPerMileForUser:(FPUser *)user {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self gasCostPerMileForUser:user onOrBeforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user {
  NSArray *vehicles = [_localDao vehiclesForUser:user error:_errorBlk];
  NSDecimalNumber *totalMilesDriven = [NSDecimalNumber zero];
  NSDecimalNumber *totalSpentOnGas = [NSDecimalNumber zero];
  for (FPVehicle *vehicle in vehicles) {
    FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
    if (firstOdometerLog) {
      totalMilesDriven = [totalMilesDriven decimalNumberByAdding:[self milesRecordedForVehicle:vehicle]];
      totalSpentOnGas = [totalSpentOnGas decimalNumberByAdding:[self totalSpentOnGasForVehicle:vehicle since:firstOdometerLog.logDate]];
    }
  }
  return [self costPerMileForMilesDriven:totalMilesDriven totalSpentOnGas:totalSpentOnGas];
}

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [self firstDayOfYearOfDate:now];
  return [self gasCostPerMileForVehicle:vehicle onOrBeforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self gasCostPerMileForVehicle:vehicle onOrBeforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self gasCostPerMileForVehicle:vehicle onOrBeforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return nil;
}

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                 onOrBeforeDate:now
                                                                  onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                 onOrBeforeDate:lastYearRange[1]
                                                                  onOrAfterDate:lastYearRange[0]
                                                                          error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:now
                                                                     onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:now
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:lastYearRange[1]
                                                                     onOrAfterDate:lastYearRange[0]
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:lastYearRange[1]
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    onOrBeforeDate:[NSDate date]
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                        onOrBeforeDate:now
                                                                         onOrAfterDate:[self firstDayOfYearOfDate:now]
                                                                                 error:_errorBlk]];
}

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [self lastYearRangeFromDate:[NSDate date]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                        onOrBeforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
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

#pragma mark - Miles Recorded

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog && lastOdometerLog) {
    return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
  }
  return [NSDecimalNumber zero];
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
  if (firstOdometerLog && lastOdometerLog) {
    return [lastOdometerLog.odometer decimalNumberBySubtracting:firstOdometerLog.odometer];
  }
  return [NSDecimalNumber zero];
}

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                                   vehicle:(FPVehicle *)vehicle {
  NSDecimalNumber *odometer = [odometerLog odometer];
  if (![PEUtils isNil:odometer]) {
    NSArray *odometerLogs =
      [_localDao environmentLogsForVehicle:vehicle pageSize:1 beforeDateLogged:[odometerLog logDate] error:_errorBlk];
    if ([odometerLogs count] > 0) {
      NSDecimalNumber *lastOdometer = [odometerLogs[0] odometer];
      if (![PEUtils isNil:lastOdometer]) {
        return [odometer decimalNumberBySubtracting:lastOdometer];
      }
    }
  }
  return nil;
}

#pragma mark - Duration Between Odometer Logs

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog
                                     vehicle:(FPVehicle *)vehicle {
  NSArray *odometerLogs =
    [_localDao environmentLogsForVehicle:vehicle pageSize:1 beforeDateLogged:[odometerLog logDate] error:_errorBlk];
  if ([odometerLogs count] > 0) {
    NSDate *dateOfLastLog = [odometerLogs[0] logDate];
    if (dateOfLastLog) {
      return @([PEUtils daysFromDate:[odometerLog logDate] toDate:dateOfLastLog]);
    }
  }
  return nil;
}

#pragma mark - Outside Temperature

- (NSNumber *)temperatureLastYearForUser:(FPUser *)user
                      withinDaysVariance:(NSInteger)daysVariance {
  return [self temperatureForUser:user oneYearAgoFromDate:[NSDate date] withinDaysVariance:daysVariance];
}

- (NSNumber *)temperatureForUser:(FPUser *)user
              oneYearAgoFromDate:(NSDate *)oneYearAgoFromDate
              withinDaysVariance:(NSInteger)daysVariance {
  NSArray *nearestOdometerLog = [_localDao odometerLogNearestToDate:[self oneYearAgoFromDate:oneYearAgoFromDate]
                                                            forUser:user
                                                              error:_errorBlk];
  if (nearestOdometerLog) {
    if ([nearestOdometerLog[1] integerValue] <= daysVariance) {
      return [nearestOdometerLog[0] reportedOutsideTemp];
    }
  }
  return nil;
}

@end
