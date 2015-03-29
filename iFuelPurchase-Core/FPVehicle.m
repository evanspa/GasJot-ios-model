//
//  FPVehicle.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/29/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPVehicle.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"
#import "FPNotificationNames.h"

@implementation FPVehicle

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
                        dateAdded:(NSDate *)dateAdded {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_VEHICLE
                          masterEntityTable:TBL_MASTER_VEHICLE
                                  mediaType:mediaType
                                  relations:relations
                                deletedDate:deletedDate
                               lastModified:lastModified
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                                editActorId:editActorId
                             syncInProgress:syncInProgress
                                     synced:synced
                                 inConflict:inConflict
                                    deleted:deleted
                                  editCount:editCount];
  if (self) {
    _name = name;
    _dateAdded = dateAdded;
  }
  return self;
}

#pragma mark - Creation Functions

+ (FPVehicle *)vehicleWithName:(NSString *)name
                     dateAdded:(NSDate *)dateAdded
                     mediaType:(HCMediaType *)mediaType {
  return [FPVehicle vehicleWithName:name
                          dateAdded:dateAdded
                   globalIdentifier:nil
                          mediaType:mediaType
                          relations:nil
                       lastModified:nil];
}

+ (FPVehicle *)vehicleWithName:(NSString *)name
                     dateAdded:(NSDate *)dateAdded
              globalIdentifier:(NSString *)globalIdentifier
                     mediaType:(HCMediaType *)mediaType
                     relations:(NSDictionary *)relations
                  lastModified:(NSDate *)lastModified {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
                                  localMasterIdentifier:nil
                                       globalIdentifier:globalIdentifier
                                              mediaType:mediaType
                                              relations:relations
                                            deletedDate:nil
                                           lastModified:lastModified
                                   dateCopiedFromMaster:nil
                                         editInProgress:NO
                                            editActorId:nil
                                         syncInProgress:NO
                                                 synced:NO
                                             inConflict:NO
                                                deleted:NO
                                              editCount:0
                                                   name:name
                                              dateAdded:dateAdded];
}

+ (FPVehicle *)vehicleWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
                                  localMasterIdentifier:localMasterIdentifier
                                       globalIdentifier:nil
                                              mediaType:nil
                                              relations:nil
                                            deletedDate:nil
                                           lastModified:nil
                                   dateCopiedFromMaster:nil
                                         editInProgress:NO
                                            editActorId:nil
                                         syncInProgress:NO
                                                 synced:NO
                                             inConflict:NO
                                                deleted:NO
                                              editCount:0
                                                   name:nil
                                              dateAdded:nil];
}

#pragma mark - Methods

- (void)overwrite:(FPVehicle *)vehicle {
  [super overwrite:vehicle];
  [self setName:[vehicle name]];
  [self setDateAdded:[vehicle dateAdded]];
}

#pragma mark - Equality

- (BOOL)isEqualToVehicle:(FPVehicle *)vehicle {
  if (!vehicle) { return NO; }
  if ([super isEqualToMainSupport:vehicle]) {
    return [PEUtils isString:[self name] equalTo:[vehicle name]] &&
      [PEUtils isDate:[self dateAdded] msprecisionEqualTo:[vehicle dateAdded]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPVehicle class]]) { return NO; }
  return [self isEqualToVehicle:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self name] hash] ^
  [[self dateAdded] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], date added: [{%@}, {%f}]",
          [super description], _name,
          _dateAdded, [_dateAdded timeIntervalSince1970]];
}

@end
