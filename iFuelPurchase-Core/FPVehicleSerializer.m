//
//  FPVehicleSerializer.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPVehicleSerializer.h"
#import "FPVehicle.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPVehicleNameKey           = @"fpvehicle/name";
NSString * const FPVehicleFuelCapacity      = @"fpvehicle/fuel-capacity";
NSString * const FPVehicleMinRequiredOctane = @"fpvehicle/min-redq-octane";
NSString * const FPVehicleDateAddedKey      = @"fpvehicle/date-added";

@implementation FPVehicleSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPVehicle *vehicle = (FPVehicle *)resourceModel;
  NSMutableDictionary *vehicleDict = [NSMutableDictionary dictionary];
  [vehicleDict setObjectIfNotNull:[vehicle name] forKey:FPVehicleNameKey];
  [vehicleDict setObjectIfNotNull:[HCUtils rfc7231StringFromDate:[vehicle dateAdded]]
                           forKey:FPVehicleDateAddedKey];
  return vehicleDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [FPVehicle vehicleWithName:[resDict objectForKey:FPVehicleNameKey]
                          dateAdded:[HCUtils rfc7231DateFromString:[resDict objectForKey:FPVehicleDateAddedKey]]
                   globalIdentifier:location
                          mediaType:mediaType
                          relations:relations
                       lastModified:lastModified];
}

@end
