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
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPFuelStationNameKey      = @"fpfuelstation/name";
NSString * const FPFuelStationStreetKey    = @"fpfuelstation/street";
NSString * const FPFuelStationCityKey      = @"fpfuelstation/city";
NSString * const FPFuelStationStateKey     = @"fpfuelstation/state";
NSString * const FPFuelStationZipKey       = @"fpfuelstation/zip";
NSString * const FPFuelStationLatitudeKey  = @"fpfuelstation/latitude";
NSString * const FPFuelStationLongitudeKey = @"fpfuelstation/longitude";
NSString * const FPFuelStationDateAddedKey = @"fpfuelstation/date-added";

@implementation FPFuelStationSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPFuelStation *fuelStation = (FPFuelStation *)resourceModel;
  NSMutableDictionary *fuelStationDict = [NSMutableDictionary dictionary];
  [fuelStationDict setObjectIfNotNull:[fuelStation name] forKey:FPFuelStationNameKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation street] forKey:FPFuelStationStreetKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation city] forKey:FPFuelStationCityKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation state] forKey:FPFuelStationStateKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation zip] forKey:FPFuelStationZipKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation latitude] forKey:FPFuelStationLatitudeKey];
  [fuelStationDict setObjectIfNotNull:[fuelStation longitude] forKey:FPFuelStationLongitudeKey];
  [fuelStationDict setObjectIfNotNull:[HCUtils rfc7231StringFromDate:[fuelStation dateAdded]]
                               forKey:FPFuelStationDateAddedKey];
  return fuelStationDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [FPFuelStation fuelStationWithName:[resDict objectForKey:FPFuelStationNameKey]
                                     street:[resDict objectForKey:FPFuelStationStreetKey]
                                       city:[resDict objectForKey:FPFuelStationCityKey]
                                      state:[resDict objectForKey:FPFuelStationStateKey]
                                        zip:[resDict objectForKey:FPFuelStationZipKey]
                                   latitude:[resDict objectForKey:FPFuelStationLatitudeKey]
                                  longitude:[resDict objectForKey:FPFuelStationLongitudeKey]
                                  dateAdded:[HCUtils rfc7231DateFromString:[resDict objectForKey:FPFuelStationDateAddedKey]]
                           globalIdentifier:location
                                  mediaType:mediaType
                                  relations:relations
                               lastModified:lastModified];
}

@end
