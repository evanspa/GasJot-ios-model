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

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)milesRecordedForVehicle:(FPVehicle *)vehicle
                              onOrBeforeDate:(NSDate *)onOrBeforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate;

- (NSDecimalNumber *)yearToDateGasCostPerMileForUser:(FPUser *)user;

- (NSDecimalNumber *)overallGasCostPerMileForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateGasCostPerMileForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)overallGasCostPerMileForVehicle:(FPVehicle *)vehicle;

#pragma mark - Amount Spent on Gas

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForFuelstation:(FPFuelStation *)vehicle;

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

#pragma mark - Odometer Log Reports

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

- (NSNumber *)temperatureLastYearFromLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

@end
