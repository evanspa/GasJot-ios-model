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

- (NSDecimalNumber *)yearToDateGasCostPerMileForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearGasCostPerMileForUser:(FPUser *)user;

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle;

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)lastYearSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)lastYearSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle since:(NSDate *)since;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)lastYearSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

- (NSDecimalNumber *)totalSpentOnGasForFuelstation:(FPFuelStation *)fuelstation;

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
                              onOrBeforeDate:(NSDate *)onOrBeforeDate
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
