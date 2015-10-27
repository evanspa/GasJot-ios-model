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

#pragma mark - Gas Cost Per Mile

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

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user;

- (NSArray *)lastYearSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)overallSpentOnGasForUser:(FPUser *)user;

- (NSArray *)overallSpentOnGasDataSetForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)yearToDateSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)lastYearSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSArray *)spentOnGasDataSetForVehicle:(FPVehicle *)vehicle year:(NSInteger)year;

- (NSDecimalNumber *)overallSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSArray *)overallSpentOnGasDataSetForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)yearToDateSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)lastYearSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)overallSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSArray *)overallSpentOnGasDataSetForFuelstation:(FPFuelStation *)fuelstation;

#pragma mark - Average Price Per Gallon

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Max Price Per Gallon

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Min Price Per Gallon

- (NSDecimalNumber *)yearToDateMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMinPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMinPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

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
