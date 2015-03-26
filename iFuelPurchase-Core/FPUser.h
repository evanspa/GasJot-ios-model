//
//  FPUser.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPEnvironmentLog.h"

FOUNDATION_EXPORT NSString * const FPUsersRelation;
FOUNDATION_EXPORT NSString * const FPLoginRelation;
FOUNDATION_EXPORT NSString * const FPVehiclesRelation;
FOUNDATION_EXPORT NSString * const FPFuelStationsRelation;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogsRelation;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogsRelation;
FOUNDATION_EXPORT NSString * const FPAppTransactionSetRelation;

@interface FPUser : PELMMainSupport

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
                            email:(NSString *)email
                         username:(NSString *)username
                         password:(NSString *)password
                     creationDate:(NSDate *)creationDate;

#pragma mark - Creation Functions

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
            creationDate:(NSDate *)creationDate
               mediaType:(HCMediaType *)mediaType;

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
            creationDate:(NSDate *)creationDate
        globalIdentifier:(NSString *)globalIdentifier
               mediaType:(HCMediaType *)mediaType
               relations:(NSDictionary *)relations
            lastModified:(NSDate *)lastModified;

#pragma mark - Methods

- (void)overwrite:(FPUser *)user;

- (void)addVehicle:(FPVehicle *)vehicle;

- (void)addFuelStation:(FPFuelStation *)fuelStation;

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog;

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog;

- (NSArray *)vehicles;

- (NSArray *)fuelStations;

- (NSString *)usernameOrEmail;

- (NSArray *)fuelPurchaseLogs;

- (NSArray *)environmentLogs;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *email;

@property (nonatomic) NSString *username;

@property (nonatomic) NSString *password;

@property (nonatomic) NSDate *creationDate;

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation;

+ (NSString *)fuelStationsRelation;

#pragma mark - Equality

- (BOOL)isEqualToUser:(FPUser *)user;

@end
