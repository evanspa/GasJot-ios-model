//
//  FPStats.h
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPLocalDao.h"

@interface FPStats : NSObject

#pragma mark - Initializers

- (id)initWithLocalDao:(FPLocalDao *)localDao errorBlk:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Days Between Fill-ups

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)lastYearMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)lastYearDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForUser:(FPUser *)user;

- (NSNumber *)overallMaxDaysBetweenFillupsForUser:(FPUser *)user;

- (NSArray *)overallDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)yearToDateMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)lastYearMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSNumber *)overallMaxDaysBetweenFillupsForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallAvgDaysBetweenFillupsDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Gas Cost Per Mile

- (NSDecimalNumber *)yearToDateGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)yearToDateGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)gasCostPerMileForUser:(FPUser *)user year:(NSInteger)year;

- (NSArray *)gasCostPerMileDataSetForUser:(FPUser *)user year:(NSInteger)year;

- (NSDecimalNumber *)lastYearGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)lastYearGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user;

- (NSArray *)overallGasCostPerMileDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)gasCostPerMileForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSArray *)gasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSDecimalNumber *)lastYearGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallGasCostPerMileDataSetForVehicle:(FPVehicle *)vehicle;

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;

- (NSArray *)yearToDateSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user;

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallSpentOnGasForUser:(FPUser *)user;

- (NSArray *)overallSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallAvgSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMinSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)overallMaxSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallAvgSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMinSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallMaxSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)yearToDateSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)yearToDateMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)lastYearSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)overallSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallAvgSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMinSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallMaxSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)yearToDateAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)lastYearAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSArray *)overallAvgPricePerGallonDataSetForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Min Price Per Gallon

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)lastYearMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Miles Recorded

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate;

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog vehicle:(FPVehicle *)vehicle;

#pragma mark - Duration Between Odometer Logs

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog vehicle:(FPVehicle *)vehicle;

#pragma mark - Outside Temperature

- (NSNumber *)temperatureLastYearForUser:(FPUser *)user
                      withinDaysVariance:(NSInteger)daysVariance;

- (NSNumber *)temperatureForUser:(FPUser *)user
              oneYearAgoFromDate:(NSDate *)oneYearAgoFromDate
              withinDaysVariance:(NSInteger)daysVariance;

@end
