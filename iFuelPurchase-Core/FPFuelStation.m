//
//  FPFuelStation.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStation.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"

@implementation FPFuelStation

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
                       inConflict:(BOOL)inConflict
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                             name:(NSString *)name
                           street:(NSString *)street
                             city:(NSString *)city
                            state:(NSString *)state
                              zip:(NSString *)zip
                         latitude:(NSDecimalNumber *)latitude
                        longitude:(NSDecimalNumber *)longitude {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_FUEL_STATION
                          masterEntityTable:TBL_MASTER_FUEL_STATION
                                  mediaType:mediaType
                                  relations:relations
                                deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                 inConflict:inConflict
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _name = name;
    _street = street;
    _city = city;
    _state = state;
    _zip = zip;
    _latitude = latitude;
    _longitude = longitude;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPFuelStation *copy = [[FPFuelStation alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                                inConflict:[self inConflict]
                                                                 editCount:[self editCount]
                                                          syncHttpRespCode:[self syncHttpRespCode]
                                                               syncErrMask:[self syncErrMask]
                                                               syncRetryAt:[self syncRetryAt]
                                                                      name:_name
                                                                    street:_street
                                                                      city:_city
                                                                     state:_state
                                                                       zip:_zip
                                                                  latitude:_latitude
                                                                 longitude:_longitude];
  return copy;
}

#pragma mark - Creation Functions

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             mediaType:(HCMediaType *)mediaType {
  return [FPFuelStation fuelStationWithName:name
                                     street:street
                                       city:city
                                      state:state
                                        zip:zip
                                   latitude:latitude
                                  longitude:longitude
                           globalIdentifier:nil
                                  mediaType:mediaType
                                  relations:nil
                               updatedAt:nil];
}

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                      globalIdentifier:(NSString *)globalIdentifier
                             mediaType:(HCMediaType *)mediaType
                             relations:(NSDictionary *)relations
                          updatedAt:(NSDate *)updatedAt {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                 inConflict:NO
                                                  editCount:0
                                           syncHttpRespCode:nil
                                                syncErrMask:nil
                                                syncRetryAt:nil
                                                       name:name
                                                     street:street
                                                       city:city
                                                      state:state
                                                        zip:zip
                                                   latitude:latitude
                                                  longitude:longitude];
}

+ (FPFuelStation *)fuelStationWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                 inConflict:NO
                                                  editCount:0
                                           syncHttpRespCode:nil
                                                syncErrMask:nil
                                                syncRetryAt:nil
                                                       name:nil
                                                     street:nil
                                                       city:nil
                                                      state:nil
                                                        zip:nil
                                                   latitude:nil
                                                  longitude:nil];
}

#pragma mark - Methods

- (void)overwrite:(FPFuelStation *)fuelStation {
  [super overwrite:fuelStation];
  [self setName:[fuelStation name]];
  [self setStreet:[fuelStation street]];
  [self setCity:[fuelStation city]];
  [self setState:[fuelStation state]];
  [self setZip:[fuelStation zip]];
  [self setLatitude:[fuelStation latitude]];
  [self setLongitude:[fuelStation longitude]];
}

- (CLLocation *)location {
  if ((_latitude && ![_latitude isEqual:[NSNull null]]) &&
      (_longitude && ![_longitude isEqual:[NSNull null]])) {
    return [[CLLocation alloc] initWithLatitude:[_latitude doubleValue]
                                      longitude:[_longitude doubleValue]];
  }
  return nil;
}

#pragma mark - Equality

- (BOOL)isEqualToFuelStation:(FPFuelStation *)fuelStation {
  if (!fuelStation) { return NO; }
  if ([super isEqualToMainSupport:fuelStation]) {
    return [PEUtils isString:[self name] equalTo:[fuelStation name]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPFuelStation class]]) { return NO; }
  return [self isEqualToFuelStation:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self name] hash] ^
  [[self street] hash] ^
  [[self city] hash] ^
  [[self state] hash] ^
  [[self zip] hash] ^
  [[self latitude] hash] ^
  [[self longitude] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], street: [%@], city: [%@], state: [%@], zip: [%@], latitude: [%@], \
longitude: [%@]]",
          [super description], _name, _street, _city, _state, _zip, _latitude, _longitude];
}

@end
