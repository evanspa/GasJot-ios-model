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

- (NSDecimalNumber *)avgValueForDataset:(NSArray *)dataset
                            accumulator:(NSDecimalNumber *(^)(id))accumulator {
  NSInteger datasetCount = [dataset count];
  if (datasetCount > 0) {
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (NSArray *dp in dataset) {
      total = [total decimalNumberByAdding:accumulator(dp[1])];
    }
    return [total decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:datasetCount]];
  }
  return nil;
}

- (NSDecimalNumber *)avgValueForIntegerDataset:(NSArray *)dataset {
  return [self avgValueForDataset:dataset
                      accumulator:^(NSNumber *val) {return [[NSDecimalNumber alloc] initWithInteger:val.integerValue];}];
}

- (NSDecimalNumber *)avgValueForDecimalDataset:(NSArray *)dataset {
  return [self avgValueForDataset:dataset accumulator:^(NSDecimalNumber *val) {return val;}];
}

- (NSDecimalNumber *)minMaxValueForDataset:(NSArray *)dataset
                                comparator:(NSComparisonResult(^)(NSArray *, NSArray *))comparator {
  NSInteger count = [dataset count];
  if (count > 1) {
    NSArray *sortedDataset = [dataset sortedArrayUsingComparator:comparator];
    return sortedDataset[0][1];
  } else if (count == 1) {
    return dataset[0][1];
  }
  return nil;
}

- (NSDecimalNumber *)minValueForDataset:(NSArray *)dataset {
  return [self minMaxValueForDataset:dataset comparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
    return [dp1[1] compare:dp2[1]];
  }];
}

- (NSDecimalNumber *)maxValueForDataset:(NSArray *)dataset {
  return [self minMaxValueForDataset:dataset comparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
    return [dp2[1] compare:dp1[1]];
  }];
}

- (NSDecimalNumber *)totalSpentFromFplogs:(NSArray *)fplogs {
  if (fplogs.count > 0) {
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (FPFuelPurchaseLog *fplog in fplogs) {
      if (![PEUtils isNil:fplog.numGallons] && ![PEUtils isNil:fplog.gallonPrice]) {
        total = [total decimalNumberByAdding:[fplog.numGallons decimalNumberByMultiplyingBy:fplog.gallonPrice]];
      }
    }
    return total;
  }
  return nil;
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

- (NSDecimalNumber *)avgGasCostPerMileForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate {
  NSArray *vehicles = [_localDao vehiclesForUser:user error:_errorBlk];
  NSDecimalNumber *accumulatedAvgs = [NSDecimalNumber zero];
  NSInteger relevantVehicleCount = 0;
  for (FPVehicle *vehicle in vehicles) {
    NSDecimalNumber *avgGasCostPerMile = [self avgGasCostPerMileForVehicle:vehicle beforeDate:beforeDate onOrAfterDate:onOrAfterDate];
    if (avgGasCostPerMile) {
      relevantVehicleCount++;
      accumulatedAvgs = [accumulatedAvgs decimalNumberByAdding:avgGasCostPerMile];
    }
  }
  if (relevantVehicleCount > 0) {
    return [accumulatedAvgs decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:relevantVehicleCount]];
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

- (NSArray *)mergeDataSetsForUser:(FPUser *)user
                 childEntitiesBlk:(NSArray *(^)(void))childEntitiesBlk
         datasetForChildEntityBlk:(NSArray *(^)(id))datasetForChildEntityBlk
          entityDatapointValueBlk:(NSDecimalNumber *(^)(id))entityDatapointValueBlk {
  NSMutableDictionary *allEntitiesDatapointsDict = [NSMutableDictionary dictionary];
  NSArray *entities = childEntitiesBlk();
  if (entities.count > 0) {
    for (FPVehicle *entity in entities) {
      NSArray *entityDatapoints = datasetForChildEntityBlk(entity);
      for (NSArray *entityDatapoint in entityDatapoints) {
        NSDate *entityDatapointDate = entityDatapoint[0];
        NSDecimalNumber *allEntitiesDatapointVal = allEntitiesDatapointsDict[entityDatapointDate];
        if (allEntitiesDatapointVal != nil) {
          NSDecimalNumber *entityDatapointVal = entityDatapointValueBlk(entityDatapoint[1]);
          NSDecimalNumber *tmpTotalDatapointVal = [allEntitiesDatapointVal decimalNumberByAdding:entityDatapointVal];
          allEntitiesDatapointsDict[entityDatapointDate] = [tmpTotalDatapointVal decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:2]];
        } else {
          allEntitiesDatapointsDict[entityDatapointDate] = entityDatapointValueBlk(entityDatapoint[1]);
        }
      }
    }
    NSArray *keys = [allEntitiesDatapointsDict allKeys];
    NSMutableArray *allEntitiesDataSet = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSDate *entryDate in keys) {
      [allEntitiesDataSet addObject:@[entryDate, allEntitiesDatapointsDict[entryDate]]];
    }
    return [allEntitiesDataSet sortedArrayUsingComparator:^NSComparisonResult(NSArray *dp1, NSArray *dp2) {
      return [dp1[0] compare:dp2[0]];
    }];
  }
  return @[];
}

- (NSArray *)daysBetweenFillupsDataSetForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                     calendar:(NSCalendar *)calendar {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                                                                  beforeDate:beforeDate
                                                                                               onOrAfterDate:onOrAfterDate
                                                                                                    calendar:calendar]; }
            entityDatapointValueBlk:^(NSNumber *numDays) {return [[NSDecimalNumber alloc] initWithInteger:numDays.integerValue];}];
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

- (NSArray *)avgGasCostPerMileDataSetForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate {
  return [self mergeDataSetsForUser:user
                   childEntitiesBlk:^{ return [_localDao vehiclesForUser:user error:_errorBlk]; }
           datasetForChildEntityBlk:^(FPVehicle *vehicle) { return [self avgGasCostPerMileDataSetForVehicle:vehicle
                                                                                                 beforeDate:beforeDate
                                                                                              onOrAfterDate:onOrAfterDate]; }
            entityDatapointValueBlk:^(NSDecimalNumber *gasCostPerMile) {return gasCostPerMile;}];
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

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                   calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:now
                                              onOrAfterDate:firstDayOfCurrentYear
                                                   calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  return [self daysBetweenFillupsDataSetForUser:user
                                     beforeDate:now
                                  onOrAfterDate:firstDayOfCurrentYear
                                       calendar:calendar];
}

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                   calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)lastYearMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                 beforeDate:lastYearRange[1]
                                              onOrAfterDate:lastYearRange[0]
                                                   calendar:calendar];
  return [self maxValueForDataset:dataset];
}

- (NSArray *)lastYearDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  return [self daysBetweenFillupsDataSetForUser:user
                                     beforeDate:lastYearRange[1]
                                  onOrAfterDate:lastYearRange[0]
                                       calendar:calendar];
}

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                   beforeDate:now
                                                onOrAfterDate:firstGasLog.purchasedAt
                                                     calendar:calendar];
    return [self avgValueForIntegerDataset:dataset];
  }
  return nil;
}

- (NSNumber *)overallMaxDaysBetweenFillupsForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForUser:user
                                                   beforeDate:now
                                                onOrAfterDate:firstGasLog.purchasedAt
                                                     calendar:calendar];
    return [self maxValueForDataset:dataset];
  }
  return nil;
}

- (NSArray *)overallDaysBetweenFillupsDataSetForUser:(FPUser *)user {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForUser:user error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    return [self daysBetweenFillupsDataSetForUser:user
                                       beforeDate:now
                                    onOrAfterDate:firstGasLog.purchasedAt
                                         calendar:calendar];
  }
  return @[];
}

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                      calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:now
                                                 onOrAfterDate:firstDayOfCurrentYear
                                                      calendar:calendar];
  return [self maxValueForDataset:dataset];
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
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                      calendar:calendar];
  return [self avgValueForIntegerDataset:dataset];
}

- (NSNumber *)lastYearMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:calendar];
  NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                    beforeDate:lastYearRange[1]
                                                 onOrAfterDate:lastYearRange[0]
                                                      calendar:calendar];
  return [self maxValueForDataset:dataset];
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
    NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                      beforeDate:now
                                                   onOrAfterDate:firstGasLog.purchasedAt
                                                        calendar:calendar];
    return [self avgValueForIntegerDataset:dataset];
  }
  return nil;
}

- (NSNumber *)overallMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  FPFuelPurchaseLog *firstGasLog = [_localDao firstGasLogForVehicle:vehicle error:_errorBlk];
  if (firstGasLog) {
    NSDate *now = [NSDate date];
    NSArray *dataset = [self daysBetweenFillupsDataSetForVehicle:vehicle
                                                      beforeDate:now
                                                   onOrAfterDate:firstGasLog.purchasedAt
                                                        calendar:calendar];
    return [self maxValueForDataset:dataset];
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

- (NSDecimalNumber *)yearToDateGasCostPerMileForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSArray *)yearToDateGasCostPerMileDataSetForUser:(FPUser *)user {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self avgGasCostPerMileDataSetForUser:user beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)gasCostPerMileForUser:(FPUser *)user year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileForUser:user beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSArray *)gasCostPerMileDataSetForUser:(FPUser *)user year:(NSInteger)year {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDate *yearAsDate = [PEUtils firstDayOfYear:year month:1 calendar:calendar];
  NSDate *firstDayOfNextYear = [PEUtils firstDayOfYear:year + 1 month:1 calendar:calendar];
  return [self avgGasCostPerMileDataSetForUser:user beforeDate:firstDayOfNextYear onOrAfterDate:yearAsDate];
}

- (NSDecimalNumber *)lastYearGasCostPerMileForUser:(FPUser *)user {
  return [self gasCostPerMileForUser:user year:[PEUtils currentYear] - 1];
}

- (NSArray *)lastYearGasCostPerMileDataSetForUser:(FPUser *)user {
  return [self gasCostPerMileDataSetForUser:user year:[PEUtils currentYear] - 1];
}

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileForUser:user beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return nil;
}

- (NSArray *)overallGasCostPerMileDataSetForUser:(FPUser *)user {
  FPEnvironmentLog *firstOdometerLog = [_localDao firstOdometerLogForUser:user error:_errorBlk];
  if (firstOdometerLog) {
    NSDate *now = [NSDate date];
    return [self avgGasCostPerMileDataSetForUser:user beforeDate:now onOrAfterDate:firstOdometerLog.logDate];
  }
  return @[];
}

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
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForUser:user
                                                                     beforeDate:now
                                                                  onOrAfterDate:firstDayOfCurrentYear
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

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self yearToDateSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForUser:user]];
}

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user {
  NSArray *lastYearRange = [PEUtils lastYearRangeFromDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForUser:user beforeDate:lastYearRange[1] onOrAfterDate:lastYearRange[0]];
}

- (NSDecimalNumber *)lastYearAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForUser:user]];
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

- (NSDecimalNumber *)overallAvgSpentOnGasForUser:(FPUser *)user {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForUser:(FPUser *)user {
  return [self minValueForDataset:[self overallSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForUser:(FPUser *)user {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForUser:user]];
}

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self totalSpentFromFplogs:[_localDao unorderedFuelPurchaseLogsForVehicle:vehicle
                                                                        beforeDate:now
                                                                     onOrAfterDate:firstDayOfCurrentYear
                                                                             error:_errorBlk]];
}

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle {
  NSDate *now = [NSDate date];
  NSDate *firstDayOfCurrentYear = [PEUtils firstDayOfYearOfDate:now calendar:[NSCalendar currentCalendar]];
  return [self spentOnGasDataSetForVehicle:vehicle beforeDate:now onOrAfterDate:firstDayOfCurrentYear];
}

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self yearToDateSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForVehicle:vehicle]];
}

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

- (NSDecimalNumber *)lastYearAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForVehicle:vehicle]];
}

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

- (NSDecimalNumber *)overallAvgSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self minValueForDataset:[self overallSpentOnGasDataSetForVehicle:vehicle]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForVehicle:(FPVehicle *)vehicle {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForVehicle:vehicle]];
}

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

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self yearToDateSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)yearToDateMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self yearToDateSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self yearToDateSpentOnGasDataSetForFuelstation:fuelstation]];
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

- (NSDecimalNumber *)lastYearAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)lastYearMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)lastYearMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self lastYearSpentOnGasDataSetForFuelstation:fuelstation]];
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

- (NSDecimalNumber *)overallAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self avgValueForDecimalDataset:[self overallSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)overallMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self minValueForDataset:[self overallSpentOnGasDataSetForFuelstation:fuelstation]];
}

- (NSDecimalNumber *)overallMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation {
  return [self maxValueForDataset:[self overallSpentOnGasDataSetForFuelstation:fuelstation]];
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
