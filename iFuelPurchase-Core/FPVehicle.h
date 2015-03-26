//
//  FPVehicle.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 7/29/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMainSupport.h"
#import "FPFuelPurchaseLog.h"

@interface FPVehicle : PELMMainSupport

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
                             name:(NSString *)name
                        dateAdded:(NSDate *)dateAdded;

#pragma mark - Creation Functions

+ (FPVehicle *)vehicleWithName:(NSString *)name
                     dateAdded:(NSDate *)dateAdded
                     mediaType:(HCMediaType *)mediaType;

+ (FPVehicle *)vehicleWithName:(NSString *)name
                     dateAdded:(NSDate *)dateAdded
              globalIdentifier:(NSString *)globalIdentifier
                     mediaType:(HCMediaType *)mediaType
                     relations:(NSDictionary *)relations
                  lastModified:(NSDate *)lastModified;

+ (FPVehicle *)vehicleWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier;

#pragma mark - Methods

- (void)overwrite:(FPVehicle *)vehicle;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSDate *dateAdded;

#pragma mark - Equality

- (BOOL)isEqualToVehicle:(FPVehicle *)vehicle;

@end
