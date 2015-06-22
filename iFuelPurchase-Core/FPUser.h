//
//  FPUser.h
//  PEFuelPurchase-Model
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

@interface FPUser : PELMMainSupport <NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                      editActorId:(NSNumber *)editActorId
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                             name:(NSString *)name
                            email:(NSString *)email
                         username:(NSString *)username
                         password:(NSString *)password;

#pragma mark - Creation Functions

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
               mediaType:(HCMediaType *)mediaType;

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
        globalIdentifier:(NSString *)globalIdentifier
               mediaType:(HCMediaType *)mediaType
               relations:(NSDictionary *)relations
               updatedAt:(NSDate *)updatedAt;

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

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation;

+ (NSString *)fuelStationsRelation;

#pragma mark - Equality

- (BOOL)isEqualToUser:(FPUser *)user;

@end
