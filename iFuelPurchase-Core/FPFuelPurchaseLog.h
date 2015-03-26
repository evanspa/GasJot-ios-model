//
//  FPFuelPurchaseLog.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

@interface FPFuelPurchaseLog : PELMMainSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                     lastModified:(NSDate *)lastModified
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                      editActorId:(NSNumber *)editActorId
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount
          vehicleGlobalIdentifier:(NSString *)vehicleGlobalIdentifier
      fuelStationGlobalIdentifier:(NSString *)fuelStationGlobalIdentifier
                       numGallons:(NSDecimalNumber *)numGallons
                           octane:(NSNumber *)octane
                      gallonPrice:(NSDecimalNumber *)gallonPrice
                       gotCarWash:(BOOL)gotCarWash
         carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                          logDate:(NSDate *)logDate;

#pragma mark - Creation Functions

+ (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate
                                           mediaType:(HCMediaType *)mediaType;

+ (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate
                                    globalIdentifier:(NSString *)globalIdentifier
                                           mediaType:(HCMediaType *)mediaType
                                           relations:(NSDictionary *)relations
                                        lastModified:(NSDate *)lastModified;

#pragma mark - Methods

- (void)overwrite:(FPFuelPurchaseLog *)fuelPurchaseLog;

#pragma mark - Properties

@property (nonatomic) NSString *vehicleGlobalIdentifier;

@property (nonatomic) NSString *fuelStationGlobalIdentifier;

@property (nonatomic) NSDecimalNumber *numGallons;

@property (nonatomic) NSNumber *octane;

@property (nonatomic) NSDecimalNumber *gallonPrice;

@property (nonatomic) BOOL gotCarWash;

@property (nonatomic) NSDecimalNumber *carWashPerGallonDiscount;

@property (nonatomic) NSDate *logDate;

#pragma mark - Equality

- (BOOL)isEqualToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog;

@end
