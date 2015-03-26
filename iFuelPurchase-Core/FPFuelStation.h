//
//  FPFuelStation.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMainSupport.h"
#import <CoreLocation/CoreLocation.h>

@interface FPFuelStation : PELMMainSupport

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
                           street:(NSString *)street
                             city:(NSString *)city
                            state:(NSString *)state
                              zip:(NSString *)zip
                         latitude:(NSDecimalNumber *)latitude
                        longitude:(NSDecimalNumber *)longitude
                        dateAdded:(NSDate *)dateAdded;

#pragma mark - Creation Functions

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             dateAdded:(NSDate *)dateAdded
                             mediaType:(HCMediaType *)mediaType;

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             dateAdded:(NSDate *)dateAdded
                      globalIdentifier:(NSString *)globalIdentifier
                             mediaType:(HCMediaType *)mediaType
                             relations:(NSDictionary *)relations
                          lastModified:(NSDate *)lastModified;

+ (FPFuelStation *)fuelStationWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier;

#pragma mark - Methods

- (void)overwrite:(FPFuelStation *)fuelStation;

- (CLLocation *)location;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *street;

@property (nonatomic) NSString *city;

@property (nonatomic) NSString *state;

@property (nonatomic) NSString *zip;

@property (nonatomic) NSDecimalNumber *latitude;

@property (nonatomic) NSDecimalNumber *longitude;

@property (nonatomic) NSDate *dateAdded;

#pragma mark - Equality

- (BOOL)isEqualToFuelStation:(FPFuelStation *)fuelStation;

@end
