//
//  FPFuelStation.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStation.h"
#import <PEObjc-Commons/PEUtils.h>
#import "FPDDLUtils.h"
#import "FPNotificationNames.h"

@implementation FPFuelStation

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
                        dateAdded:(NSDate *)dateAdded {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_FUEL_STATION
                          masterEntityTable:TBL_MASTER_FUEL_STATION
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
    _street = street;
    _city = city;
    _state = state;
    _zip = zip;
    _latitude = latitude;
    _longitude = longitude;
    _dateAdded = dateAdded;
  }
  return self;
}

#pragma mark - Creation Functions

+ (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude
                             dateAdded:(NSDate *)dateAdded
                             mediaType:(HCMediaType *)mediaType {
  return [FPFuelStation fuelStationWithName:name
                                     street:street
                                       city:city
                                      state:state
                                        zip:zip
                                   latitude:latitude
                                  longitude:longitude
                                  dateAdded:dateAdded
                           globalIdentifier:nil
                                  mediaType:mediaType
                                  relations:nil
                               lastModified:nil];
}

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
                          lastModified:(NSDate *)lastModified {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                     street:street
                                                       city:city
                                                      state:state
                                                        zip:zip
                                                   latitude:latitude
                                                  longitude:longitude
                                                  dateAdded:dateAdded];
}

+ (FPFuelStation *)fuelStationWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil
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
                                                     street:nil
                                                       city:nil
                                                      state:nil
                                                        zip:nil
                                                   latitude:nil
                                                  longitude:nil
                                                  dateAdded:nil];
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
  [self setDateAdded:[fuelStation dateAdded]];
}

- (CLLocation *)location {
  if (_latitude && _longitude) {
    return [[CLLocation alloc] initWithLatitude:[_latitude doubleValue]
                                      longitude:[_longitude doubleValue]];
  }
  return nil;
}

#pragma mark - Equality

- (BOOL)isEqualToFuelStation:(FPFuelStation *)fuelStation {
  if (!fuelStation) { return NO; }
  if ([super isEqualToMainSupport:fuelStation]) {
    return [PEUtils isString:[self name] equalTo:[fuelStation name]] &&
      [PEUtils isDate:[self dateAdded] msprecisionEqualTo:[fuelStation dateAdded]];
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
  [[self longitude] hash] ^
  [[self dateAdded] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], street: [%@], city: [%@], state: [%@], zip: [%@], latitude: [%@], \
longitude: [%@], date added: [{%@}, {%f}]",
          [super description], _name, _street, _city, _state, _zip, _latitude, _longitude, _dateAdded,
          [_dateAdded timeIntervalSince1970]];
}

@end
