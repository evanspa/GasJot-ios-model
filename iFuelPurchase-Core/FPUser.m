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
#import "FPNotificationNames.h"

NSString * const FPUsersRelation = @"users";
NSString * const FPLoginRelation = @"login";
NSString * const FPVehiclesRelation = @"vehicles";
NSString * const FPFuelStationsRelation = @"fuelstations";
NSString * const FPFuelPurchaseLogsRelation = @"fuelpurchase-logs";
NSString * const FPEnvironmentLogsRelation = @"environment-logs";
NSString * const FPAppTransactionSetRelation = @"apptxnset";

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
                         password:(NSString *)password {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_USER
                          masterEntityTable:TBL_MASTER_USER
                                  mediaType:mediaType
                                  relations:relations
                                deletedDate:deletedDate
                               updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                                editActorId:editActorId
                             syncInProgress:syncInProgress
                                     synced:synced
                                 inConflict:inConflict
                                    deleted:deleted
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _name = name;
    _email = email;
    _username = username;
    _password = password;
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
                                                 deletedDate:[self deletedDate]
                                                   updatedAt:[self updatedAt]
                                        dateCopiedFromMaster:[self dateCopiedFromMaster]
                                              editInProgress:[self editInProgress]
                                                 editActorId:[self editActorId]
                                              syncInProgress:[self syncInProgress]
                                                      synced:[self synced]
                                                  inConflict:[self inConflict]
                                                     deleted:[self deleted]
                                                   editCount:[self editCount]
                                            syncHttpRespCode:[self syncHttpRespCode]
                                                 syncErrMask:[self syncErrMask]
                                                 syncRetryAt:[self syncRetryAt]
                                                        name:_name
                                                       email:_email
                                                    username:_username
                                                    password:_password];
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
                                         deletedDate:nil
                                           updatedAt:updatedAt
                                dateCopiedFromMaster:nil
                                      editInProgress:NO
                                         editActorId:nil
                                      syncInProgress:NO
                                              synced:NO
                                          inConflict:NO
                                             deleted:NO
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

- (void)overwrite:(FPUser *)user {
  [super overwrite:user];
  [self setName:[user name]];
  [self setEmail:[user email]];
  [self setPassword:[user password]];
  [self setUsername:[user username]];
}

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

- (NSString *)usernameOrEmail {
  if (!([self username] == (id)[NSNull null] || [self username].length == 0)) {
    return [self username];
  }
  return [self email];
}

#pragma mark - Known Relation Names

+ (NSString *)vehiclesRelation {
  return FPVehiclesRelation;
}

+ (NSString *)fuelStationsRelation {
  return FPFuelStationsRelation;
}

#pragma mark - Equality

- (BOOL)isEqualToUser:(FPUser *)user {
  if (!user) { return NO; }
  if ([super isEqualToMainSupport:user]) {
    return [PEUtils isString:[self name] equalTo:[user name]] &&
      [PEUtils isString:[self email] equalTo:[user email]] &&
      [PEUtils isString:[self username] equalTo:[user username]] &&
      [PEUtils isString:[self password] equalTo:[user password]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPUser class]]) { return NO; }
  return [self isEqualToUser:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self name] hash] ^
    [[self email] hash] ^
    [[self username] hash] ^
    [[self password] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], email: [%@], \
username: [%@], password: [%@]",
          [super description],
          _name, _email, _username, _password];
}

@end
