//
//  FPReport.h
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 10/10/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPLocalDao.h"

@interface FPReports : NSObject

#pragma mark - Initializers

- (id)initWithLocalDao:(FPLocalDao *)localDao errorBlk:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Gas Log Fun Fact Definitions

- (NSDecimalNumber *)yearToDateSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)yearToDateSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)yearToDateSpentOnGasForFuelstation:(FPFuelStation *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForUser:(FPUser *)user;

- (NSDecimalNumber *)totalSpentOnGasForVehicle:(FPVehicle *)vehicle;

- (NSDecimalNumber *)totalSpentOnGasForFuelstation:(FPFuelStation *)vehicle;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallAvgPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)yearToDateMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForUser:(FPUser *)user octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForVehicle:(FPVehicle *)vehicle octane:(NSNumber *)octane;

- (NSDecimalNumber *)overallMaxPricePerGallonForFuelstation:(FPFuelStation *)fuelstation octane:(NSNumber *)octane;

#pragma mark - Odometer Log Fun Facts

- (NSDecimalNumber *)milesDrivenSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

- (NSNumber *)daysSinceLastOdometerLogAndLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

- (NSNumber *)temperatureLastYearFromLog:(FPEnvironmentLog *)odometerLog user:(FPUser *)user;

@end
