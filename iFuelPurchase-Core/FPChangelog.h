//
//  FPChangelog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPEnvironmentLog.h"

@interface FPChangelog : NSObject

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Properties

@property (nonatomic) NSString *globalIdentifier;

@property (nonatomic) HCMediaType *mediaType;

@property (nonatomic) NSDictionary *relations;

#pragma mark - Methods

- (void)setUser:(FPUser *)user;

- (void)addVehicle:(FPVehicle *)vehicle;

- (void)addFuelStation:(FPFuelStation *)fuelStation;

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog;

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog;

- (FPUser *)user;

- (NSArray *)vehicles;

- (NSArray *)fuelStations;

- (NSArray *)fuelPurchaseLogs;

- (NSArray *)environmentLogs;

@end
