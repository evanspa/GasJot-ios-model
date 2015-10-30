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

- (NSArray *)dataSetForEntity:(id)entity
                     valueBlk:(id(^)(NSDate *, NSDate *))valueBlk
                         year:(NSInteger)year
                   startMonth:(NSInteger)startMonth
                     endMonth:(NSInteger)endMonth
                     calendar:(NSCalendar *)calendar {
  NSMutableArray *dataset = [NSMutableArray array];
  for (NSInteger i = startMonth; i <= endMonth; i++) {
    NSDate *firstDayOfMonth = [PEUtils firstDayOfYear:year month:i calendar:calendar];
    NSDate *firstDateOfNextMonth = [calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:firstDayOfMonth options:0];
    id value = valueBlk(firstDateOfNextMonth, firstDayOfMonth);
    if (value) {
      [dataset addObject:@[firstDayOfMonth, value]];
    }
  }
  return dataset;
}

- (NSArray *)dataSetForEntity:(id)entity
               monthOfDataBlk:(NSArray *(^)(NSInteger, NSInteger, NSInteger, NSCalendar *))monthOfDataBlk
                   beforeDate:(NSDate *)beforeDate
                onOrAfterDate:(NSDate *)onOrAfterDate {
  NSMutableArray *dataset = [NSMutableArray array];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *beforeDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:beforeDate];
  NSDateComponents *onOrAfterDateComps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:onOrAfterDate];
  NSInteger startYear = onOrAfterDateComps.year;
  NSInteger endYear = beforeDateComps.year;
  for (NSInteger i = startYear; i <= endYear; i++) {
    NSInteger startMonth;
    if (i == startYear) {
      startMonth = onOrAfterDateComps.month;
    } else {
      startMonth = 1;
    }
    NSInteger endMonth;
    if (i == endYear) {
      endMonth = beforeDateComps.month;
    } else {
      endMonth = 12;
    }
    NSDate *startMonthDate = [PEUtils dateFromCalendar:calendar day:1 month:startMonth year:i];
    if ([startMonthDate compare:beforeDate] == NSOrderedAscending) {
      [dataset addObjectsFromArray:monthOfDataBlk(i, startMonth, endMonth, calendar)];
    }
  }
  return dataset;
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
    if (numRelevantLogs > 0) {
      return [gallonPriceSum decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:numRelevantLogs]];
    }
  }
  return nil;
}

- (NSDecimalNumber *)avgGasCostPerMileForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                                  beforeDate:beforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  if (firstOdometerLog) {
    NSDecimalNumber *milesDriven = [self milesRecordedForVehicle:vehicle
                                                      beforeDate:beforeDate
                                                   onOrAfterDate:onOrAfterDate];
    NSDecimalNumber *totalSpentOnGas = [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                      beforeDate:beforeDate
                                                                                                       afterDate:firstOdometerLog.logDate
                                                                                                           error:_errorBlk]];
    return [self costPerMileForMilesDriven:milesDriven totalSpentOnGas:totalSpentOnGas];
  }
  return nil;
}

- (NSArray *)daysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                        calendar:(NSCalendar *)calendar {
  NSArray *fplogs = [_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                        beforeDate:beforeDate
                                                     onOrAfterDate:onOrAfterDate
                                                             error:_errorBlk];
  fplogs = [fplogs sortedArrayUsingComparator:^NSComparisonResult(FPFuelPurchaseLog *fplog1, FPFuelPurchaseLog *fplog2) {
    return [fplog1.purchasedAt compare:fplog2.purchasedAt];
  }];
  NSMutableArray *dataset = [NSMutableArray array];
  NSInteger numFplogs = [fplogs count];
  if (numFplogs > 0) {
    for (NSInteger i = 0; i < numFplogs; i++) {
      if (i + 1 < numFplogs) {
        FPFuelPurchaseLog *log1 = fplogs[i];
        FPFuelPurchaseLog *log2 = fplogs[i+1];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:log1.purchasedAt toDate:log2.purchasedAt options:0];
        [dataset addObject:@[log2.purchasedAt, @([components day])]];
      }
    }
  }
  return dataset;
}

- (NSDecimalNumber *)avgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                            calendar:(NSCalendar *)calendar {
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:beforeDate
                                                 onOrAfterDate:onOrAfterDate
                                                      calendar:calendar];
  NSInteger numItems = [dataset count];
  if (numItems > 0) {
    NSInteger totalNumDays = 0;
    for (NSArray *entry in dataset) {
      totalNumDays += [entry[1] integerValue];
    }
    return [[[NSDecimalNumber alloc] initWithInteger:totalNumDays] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:numItems]];
  }
  return nil;
}

- (NSNumber *)maxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                     calendar:(NSCalendar *)calendar {
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:beforeDate
                                                 onOrAfterDate:onOrAfterDate
                                                      calendar:calendar];
  NSInteger numItems = [dataset count];
  if (numItems > 0) {
    // sort descending by num-days
    dataset = [dataset sortedArrayUsingComparator:^NSComparisonResult(NSArray *o1, NSArray *o2) {
      NSNumber *numDays1 = o1[1];
      NSNumber *numDays2 = o2[1];
      return [numDays2 compare:numDays1];
    }];
    return dataset[0][1];
  }
  return nil;
}

- (NSArray *)avgGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGasCostPerMileForVehicle:vehicle beforeDate:firstDateOfNextMonth onOrAfterDate:firstDayOfMonth];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForUser:(FPUser *)user
                           beforeDate:(NSDate *)beforeDate
                        onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:user
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:user
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                                                             beforeDate:firstDateOfNextMonth
                                                                                                          onOrAfterDate:firstDayOfMonth
                                                                                                                  error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle
                              beforeDate:(NSDate *)beforeDate
                           onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                                beforeDate:firstDateOfNextMonth
                                                                                                             onOrAfterDate:firstDayOfMonth
                                                                                                                     error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)spentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self dataSetForEntity:fuelstation
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:fuelstation
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                                                    beforeDate:firstDateOfNextMonth
                                                                                                                 onOrAfterDate:firstDayOfMonth
                                                                                                                         error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgPricePerGallonDataSetForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                      octane:(NSNumber *)octane {
  return [self dataSetForEntity:user
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:user
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                                                                 beforeDate:firstDateOfNextMonth
                                                                                                              onOrAfterDate:firstDayOfMonth
                                                                                                                     octane:octane
                                                                                                                      error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                         octane:(NSNumber *)octane {
  return [self dataSetForEntity:vehicle
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:vehicle
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                                                    beforeDate:firstDateOfNextMonth
                                                                                                                 onOrAfterDate:firstDayOfMonth
                                                                                                                        octane:octane
                                                                                                                         error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
}

- (NSArray *)avgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation
                                         beforeDate:(NSDate *)beforeDate
                                      onOrAfterDate:(NSDate *)onOrAfterDate
                                             octane:(NSNumber *)octane {
  return [self dataSetForEntity:fuelstation
                 monthOfDataBlk:^NSArray *(NSInteger year, NSInteger startMonth, NSInteger endMonth, NSCalendar *cal) {
                   return [self dataSetForEntity:fuelstation
                                        valueBlk:^id(NSDate *firstDateOfNextMonth, NSDate *firstDayOfMonth) {
                                          return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                                                        beforeDate:firstDateOfNextMonth
                                                                                                                     onOrAfterDate:firstDayOfMonth
                                                                                                                            octane:octane
                                                                                                                             error:_errorBlk]];
                                        }
                                            year:year
                                      startMonth:startMonth
                                        endMonth:endMonth
                                        calendar:cal];
                 }
                     beforeDate:beforeDate
                  onOrAfterDate:onOrAfterDate];
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

#pragma mark - Days Between Fill-ups

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self avgDaysBetweenFillupsForVehicle:vehicle
                                    beforeDate:now
                                 onOrAfterDate:firstDayOfCurrentYear
                                      calendar:calendar];
}

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self maxDaysBetweenFillupsForVehicle:vehicle
                                    beforeDate:now
                                 onOrAfterDate:firstDayOfCurrentYear
                                      calendar:calendar];
}

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                        beforeDate:now
                                     onOrAfterDate:firstDayOfCurrentYear
                                          calendar:calendar];
}

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self avgDaysBetweenFillupsForVehicle:vehicle
                                    beforeDate:lastYearRange[1]
                                 onOrAfterDate:lastYearRange[0]
                                      calendar:calendar];
}

- (NSNumber *)lastYearMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self maxDaysBetweenFillupsForVehicle:vehicle
                                    beforeDate:lastYearRange[1]
                                 onOrAfterDate:lastYearRange[0]
                                      calendar:calendar];
}

- (NSArray *)lastYearDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                        beforeDate:lastYearRange[1]
                                     onOrAfterDate:lastYearRange[0]
                                          calendar:calendar];
}

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self avgDaysBetweenFillupsForVehicle:vehicle
                                      beforeDate:now
                                   onOrAfterDate:firstGasLog.purchasedAt
                                        calendar:calendar];
  }
  return nil;
}

- (NSNumber *)overallMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self maxDaysBetweenFillupsForVehicle:vehicle
                                      beforeDate:now
                                   onOrAfterDate:firstGasLog.purchasedAt
                                        calendar:calendar];
  }
  return nil;
}

- (NSArray *)overallDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                          beforeDate:now
                                       onOrAfterDate:firstGasLog.purchasedAt
                                            calendar:calendar];
  }
  return @[];
}

#pragma mark - Gas Cost Per Mile

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)gasCostPerMileForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSArray *)gasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSDecimalNumber *)lastYearGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  return [self gasCostPerMileForVehicle:vehicle year:[PEUtils currentYear] - 1];
}

- (NSArray *)lastYearGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  return [self gasCostPerMileDataSetForVehicle:vehicle year:[PEUtils currentYear] - 1];
}

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileForVehicle:vehicle beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return nil;
}

- (NSArray *)overallGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:now
                                                                  onOrAfterDate:[PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]]
                                                                          error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:lastYearRange[1]
                                                                  onOrAfterDate:lastYearRange[0]
                                                                          error:_errorBlk]];
}

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallSpentOnGasForUser:(FPUser *)user {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForUser:(FPUser *)user {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForUser:user
                               beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                            onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                    beforeDate:now
                                                                     onOrAfterDate:[PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]]
                                                                             error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}



/*- (NSDecimalNumber *)yearToDateSpentOnGa_sForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:now
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}*/

/*- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  NSDate *now = [NSDate date];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:since];
}*/

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:lastYearRange[1]
                                                                     onOrAfterDate:lastYearRange[0]
                                                                             error:_errorBlk]];
}

- (NSArray *)lastYearSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

/*- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:lastYearRange[1]
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}*/

- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForVehicle:vehicle error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForVehicle:vehicle
                                  beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                               onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

/*- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:[NSDate date]
                                                                     onOrAfterDate:since
                                                                             error:_errorBlk]];
}*/

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:now
                                                                         onOrAfterDate:[PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]]
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForFuelstation:fuelstation beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)overallSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation error:_errorBlk]];
}

- (NSArray *)overallSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForFuelstation:fuelstation error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self spentOnGasDataSetForFuelstation:fuelstation
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                   onOrAfterDate:firstGasLog.purchasedAt];
  }
  return @[];
}

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:now
                                                                      onOrAfterDate:firstDayOfCurrentYear
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                         beforeDate:lastYearRange[1]
                                                                      onOrAfterDate:lastYearRange[0]
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0] octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                             octane:octane
                                                                              error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForUser:user octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForUser:user
                                      beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                   onOrAfterDate:firstGasLog.purchasedAt
                                          octane:octane];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:now
                                                                         onOrAfterDate:firstDayOfCurrentYear
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:now
                                    onOrAfterDate:firstDayOfCurrentYear
                                           octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                            beforeDate:lastYearRange[1]
                                                                         onOrAfterDate:lastYearRange[0]
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForVehicle:vehicle
                                       beforeDate:lastYearRange[1]
                                    onOrAfterDate:lastYearRange[0]
                                           octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                                octane:octane
                                                                                 error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForVehicle:vehicle octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForVehicle:vehicle
                                         beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                      onOrAfterDate:firstGasLog.purchasedAt
                                             octane:octane];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:now
                                                                             onOrAfterDate:firstDayOfCurrentYear
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation beforeDate:now onOrAfterDate:firstDayOfCurrentYear octane:octane];
}

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                beforeDate:lastYearRange[1]
                                                                             onOrAfterDate:lastYearRange[0]
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                           beforeDate:lastYearRange[1]
                                        onOrAfterDate:lastYearRange[0]
                                               octane:octane];
}

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  return [self avgGallonPriceFromFplogs:[_localDao unorderedFuelPurchaseLogsForFuelstation:fuelstation
                                                                                    octane:octane
                                                                                     error:_errorBlk]];
}

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForFuelstation:fuelstation octane:octane error:_errorBlk];
  if (firstGasLog) {
    FPFuelPurchaseLog *lastGasLog = [_localDao lastGasLogForFuelstation:fuelstation octane:octane error:_errorBlk];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self avgPricePerGallonDataSetForFuelstation:fuelstation
                                             beforeDate:[calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:lastGasLog.purchasedAt options:0]
                                          onOrAfterDate:firstGasLog.purchasedAt
                                                 octane:octane];
  }
  return @[];
}

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [_localDao maxGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao maxGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
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
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:now
                                           onOrAfterDate:firstDayOfCurrentYear
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                              beforeDate:lastYearRange[1]
                                           onOrAfterDate:lastYearRange[0]
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForUser:user
                                                  octane:octane
                                                   error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane {
  return [_localDao minGallonPriceFuelPurchaseLogForVehicle:vehicle
                                                     octane:octane
                                                      error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:now
                                                  onOrAfterDate:firstDayOfCurrentYear
                                                         octane:octane
                                                          error:_errorBlk].gallonPrice;
}

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [_localDao minGallonPriceFuelPurchaseLogForFuelstation:fuelstation
                                                     beforeDate:lastYearRange[1]
                                                  onOrAfterDate:lastYearRange[0]
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
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForVehicle:vehicle
                                                                  beforeDate:beforeDate
                                                               onOrAfterDate:onOrAfterDate
                                                                       error:_errorBlk];
  FPEnvironmentLog *lastOdometerLog = [_localDao lastOdometerLogForVehicle:vehicle
                                                                beforeDate:beforeDate
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
