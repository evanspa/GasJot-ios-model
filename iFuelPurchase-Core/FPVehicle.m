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

@implementation FPVehicle

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
                    defaultOctane:(NSNumber *)defaultOctane
                     fuelCapacity:(NSDecimalNumber *)fuelCapacity {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_VEHICLE
                          masterEntityTable:TBL_MASTER_VEHICLE
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
                                syncRetryAt:syncRetryAt];
  if (self) {
    _name = name;
    _defaultOctane = defaultOctane;
    _fuelCapacity = fuelCapacity;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPVehicle *copy = [[FPVehicle alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                              name:_name
                                                     defaultOctane:_defaultOctane
                                                      fuelCapacity:_fuelCapacity];
  return copy;
}

#pragma mark - Creation Functions

+ (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
                     mediaType:(HCMediaType *)mediaType {
  return [FPVehicle vehicleWithName:name
                      defaultOctane:defaultOctane
                       fuelCapacity:fuelCapacity
                   globalIdentifier:nil
                          mediaType:mediaType
                          relations:nil
                          updatedAt:nil];
}

+ (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
              globalIdentifier:(NSString *)globalIdentifier
                     mediaType:(HCMediaType *)mediaType
                     relations:(NSDictionary *)relations
                     updatedAt:(NSDate *)updatedAt {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
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
                                          defaultOctane:defaultOctane
                                           fuelCapacity:fuelCapacity];
}

+ (FPVehicle *)vehicleWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil
                                  localMasterIdentifier:localMasterIdentifier
                                       globalIdentifier:nil
                                              mediaType:nil
                                              relations:nil
                                              deletedAt:nil
                                              updatedAt:nil
                                   dateCopiedFromMaster:nil
                                         editInProgress:NO
                                         syncInProgress:NO
                                                 synced:NO
                                              editCount:0
                                       syncHttpRespCode:nil
                                            syncErrMask:nil
                                            syncRetryAt:nil
                                                   name:nil
                                          defaultOctane:nil
                                           fuelCapacity:nil];
}

#pragma mark - Merging

+ (BOOL)mergeRemoteVehicle:(FPVehicle *)remoteVehicle
          withLocalVehicle:(FPVehicle *)localVehicle
        localMasterVehicle:(FPVehicle *)localMasterVehicle {
  return [PEUtils mergeRemoteObject:remoteVehicle
                    withLocalObject:localVehicle
                previousLocalObject:localMasterVehicle
            getterSetterComparators:@[@[[NSValue valueWithPointer:@selector(name)],
                                        [NSValue valueWithPointer:@selector(setName:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isStringProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setName:[remoteObject name]];},
                                        ^(id localObject, id remoteObject) {}],
                                      @[[NSValue valueWithPointer:@selector(defaultOctane)],
                                        [NSValue valueWithPointer:@selector(setDefaultOctane:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {[localObject setDefaultOctane:[remoteObject defaultOctane]];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) {}],
                                      @[[NSValue valueWithPointer:@selector(fuelCapacity)],
                                        [NSValue valueWithPointer:@selector(setFuelCapacity:)],
                                        ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                        ^(FPVehicle * localObject, FPVehicle * remoteObject) { [localObject setFuelCapacity:[remoteObject fuelCapacity]];},
                                        ^(id localObject, id remoteObject) {}]]];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPVehicle *)vehicle {
  [super overwriteDomainProperties:vehicle];
  [self setName:[vehicle name]];
  [self setDefaultOctane:[vehicle defaultOctane]];
  [self setFuelCapacity:[vehicle fuelCapacity]];
}

- (void)overwrite:(FPVehicle *)vehicle {
  [super overwrite:vehicle];
  [self overwriteDomainProperties:vehicle];
}

#pragma mark - Equality

- (BOOL)isEqualToVehicle:(FPVehicle *)vehicle {
  if (!vehicle) { return NO; }
  if ([super isEqualToMainSupport:vehicle]) {
    return [PEUtils isString:[self name] equalTo:[vehicle name]] &&
      [PEUtils isNumProperty:@selector(defaultOctane) equalFor:self and:vehicle] &&
      [PEUtils isNumProperty:@selector(fuelCapacity) equalFor:self and:vehicle];
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
  [[self defaultOctane] hash] ^
  [[self fuelCapacity] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], default octane: [%@], fuel capacity: [%@]",
          [super description], _name,
          _defaultOctane, _fuelCapacity];
}

@end
