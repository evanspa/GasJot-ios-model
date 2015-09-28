//
//  FPFuelStationSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelStationSerializer.h"
#import "FPFuelStation.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPFuelStationNameKey      = @"fpfuelstation/name";
NSString * const FPFuelStationStreetKey    = @"fpfuelstation/street";
NSString * const FPFuelStationCityKey      = @"fpfuelstation/city";
NSString * const FPFuelStationStateKey     = @"fpfuelstation/state";
NSString * const FPFuelStationZipKey       = @"fpfuelstation/zip";
NSString * const FPFuelStationLatitudeKey  = @"fpfuelstation/latitude";
NSString * const FPFuelStationLongitudeKey = @"fpfuelstation/longitude";
NSString * const FPFuelStationCreatedAtKey = @"fpfuelstation/created-at";
NSString * const FPFuelStationUpdatedAtKey = @"fpfuelstation/updated-at";
NSString * const FPFuelStationDeletedAtKey = @"fpfuelstation/deleted-at";

@implementation FPFuelStationSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPFuelStation *fuelStation = (FPFuelStation *)resourceModel;
  NSMutableDictionary *fuelStationDict = [NSMutableDictionary dictionary];
  [fuelStationDict nullSafeSetObject:[fuelStation name] forKey:FPFuelStationNameKey];
  [fuelStationDict nullSafeSetObject:[fuelStation street] forKey:FPFuelStationStreetKey];
  [fuelStationDict nullSafeSetObject:[fuelStation city] forKey:FPFuelStationCityKey];
  [fuelStationDict nullSafeSetObject:[fuelStation state] forKey:FPFuelStationStateKey];
  [fuelStationDict nullSafeSetObject:[fuelStation zip] forKey:FPFuelStationZipKey];
  [fuelStationDict nullSafeSetObject:[fuelStation latitude] forKey:FPFuelStationLatitudeKey];
  [fuelStationDict nullSafeSetObject:[fuelStation longitude] forKey:FPFuelStationLongitudeKey];
  return fuelStationDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPFuelStation *fuelstation =
  [FPFuelStation fuelStationWithName:[resDict objectForKey:FPFuelStationNameKey]
                              street:[resDict objectForKey:FPFuelStationStreetKey]
                                city:[resDict objectForKey:FPFuelStationCityKey]
                               state:[resDict objectForKey:FPFuelStationStateKey]
                                 zip:[resDict objectForKey:FPFuelStationZipKey]
                            latitude:[resDict objectForKey:FPFuelStationLatitudeKey]
                           longitude:[resDict objectForKey:FPFuelStationLongitudeKey]
                    globalIdentifier:location
                           mediaType:mediaType
                           relations:relations
                           createdAt:[resDict dateSince1970ForKey:FPFuelStationCreatedAtKey]
                           deletedAt:[resDict dateSince1970ForKey:FPFuelStationDeletedAtKey]
                           updatedAt:[resDict dateSince1970ForKey:FPFuelStationUpdatedAtKey]];
  return fuelstation;
}

@end
