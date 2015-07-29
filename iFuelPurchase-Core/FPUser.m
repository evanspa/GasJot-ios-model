//
//  FPUser.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPUser.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"

NSString * const FPVehiclesRelation = @"vehicles";
NSString * const FPFuelStationsRelation = @"fuelstations";
NSString * const FPFuelPurchaseLogsRelation = @"fuelpurchase-logs";
NSString * const FPEnvironmentLogsRelation = @"environment-logs";

@implementation FPUser {
  NSMutableArray *_vehicles;
  NSMutableArray *_fuelStations;
  NSMutableArray *_fuelPurchaseLogs;
  NSMutableArray *_environmentLogs;
}

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                             name:(NSString *)name
                            email:(NSString *)email
                         username:(NSString *)username
                         password:(NSString *)password {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt
                                       name:name
                                      email:email
                                   username:username
                                   password:password];
  if (self) {
    _vehicles = [NSMutableArray array];
    _fuelStations = [NSMutableArray array];
    _fuelPurchaseLogs = [NSMutableArray array];
    _environmentLogs = [NSMutableArray array];
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPUser *copy = [[FPUser alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                                       localMasterIdentifier:[self localMasterIdentifier]
                                            globalIdentifier:[self globalIdentifier]
                                                   mediaType:[self mediaType]
                                                   relations:[self relations]
                                                 deletedAt:[self deletedAt]
                                                   updatedAt:[self updatedAt]
                                        dateCopiedFromMaster:[self dateCopiedFromMaster]
                                              editInProgress:[self editInProgress]
                                              syncInProgress:[self syncInProgress]
                                                      synced:[self synced]
                                                   editCount:[self editCount]
                                            syncHttpRespCode:[self syncHttpRespCode]
                                                 syncErrMask:[self syncErrMask]
                                                 syncRetryAt:[self syncRetryAt]
                                                        name:[self name]
                                                       email:[self email]
                                                    username:[self username]
                                                    password:[self password]];
  return copy;
}

#pragma mark - Creation Functions

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
               mediaType:(HCMediaType *)mediaType {
  return [FPUser userWithName:name
                        email:email
                     username:username
                     password:password
             globalIdentifier:nil
                    mediaType:mediaType
                    relations:nil
                    updatedAt:nil];
}

+ (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password
        globalIdentifier:(NSString *)globalIdentifier
               mediaType:(HCMediaType *)mediaType
               relations:(NSDictionary *)relations
               updatedAt:(NSDate *)updatedAt {
  return [[FPUser alloc] initWithLocalMainIdentifier:nil
                               localMasterIdentifier:nil
                                    globalIdentifier:globalIdentifier
                                           mediaType:mediaType
                                           relations:relations
                                         deletedAt:nil
                                           updatedAt:updatedAt
                                dateCopiedFromMaster:nil
                                      editInProgress:NO
                                      syncInProgress:NO
                                              synced:NO
                                           editCount:0
                                    syncHttpRespCode:nil
                                         syncErrMask:nil
                                         syncRetryAt:nil
                                                name:name
                                               email:email
                                            username:username
                                            password:password];
}

#pragma mark - Methods

- (void)addVehicle:(FPVehicle *)vehicle {
  [_vehicles addObject:vehicle];
}

- (void)addFuelStation:(FPFuelStation *)fuelStation {
  [_fuelStations addObject:fuelStation];
}

- (void)addFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  [_fuelPurchaseLogs addObject:fuelPurchaseLog];
}

- (void)addEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  [_environmentLogs addObject:environmentLog];
}

- (NSArray *)vehicles {
  return _vehicles;
}

- (NSArray *)fuelStations {
  return _fuelStations;
}

- (NSArray *)fuelPurchaseLogs {
  return _fuelPurchaseLogs;
}

- (NSArray *)environmentLogs {
  return _environmentLogs;
}

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation {
  return FPVehiclesRelation;
}

+ (NSString *)fuelStationsRelation {
  return FPFuelStationsRelation;
}

@end
