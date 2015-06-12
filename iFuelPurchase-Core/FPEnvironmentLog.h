//
//  FPEnvironmentLog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

@interface FPEnvironmentLog : PELMMainSupport

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
          vehicleGlobalIdentifier:(NSString *)vehicleGlobalIdentifier
                         odometer:(NSDecimalNumber *)odometer
                   reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                   reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
              reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                          logDate:(NSDate *)logDate
                      reportedDte:(NSNumber *)reportedDte;

#pragma mark - Creation Functions

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                               mediaType:(HCMediaType *)mediaType;

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                        globalIdentifier:(NSString *)globalIdentifier
                               mediaType:(HCMediaType *)mediaType
                               relations:(NSDictionary *)relations
                               updatedAt:(NSDate *)updatedAt;

#pragma mark - Methods

- (void)overwrite:(FPEnvironmentLog *)envLog;

#pragma mark - Properties

@property (nonatomic) NSString *vehicleGlobalIdentifier;

@property (nonatomic) NSDecimalNumber *odometer;

@property (nonatomic) NSDecimalNumber *reportedAvgMpg;

@property (nonatomic) NSDecimalNumber *reportedAvgMph;

@property (nonatomic) NSNumber *reportedOutsideTemp;

@property (nonatomic) NSDate *logDate;

@property (nonatomic) NSNumber *reportedDte;

#pragma mark - Equality

- (BOOL)isEqualToEnvironmentLog:(FPEnvironmentLog *)envLog;

@end
