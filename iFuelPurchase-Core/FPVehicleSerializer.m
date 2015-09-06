//
//  FPVehicleSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPVehicleSerializer.h"
#import "FPVehicle.h"
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPVehicleNameKey          = @"fpvehicle/name";
NSString * const FPVehicleDefaultOctaneKey = @"fpvehicle/default-octane";
NSString * const FPVehicleFuelCapacityKey  = @"fpvehicle/fuel-capacity";
NSString * const FPVehicleUpdatedAtKey     = @"fpvehicle/updated-at";
NSString * const FPVehicleDeletedAtKey     = @"fpvehicle/deleted-at";

@implementation FPVehicleSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPVehicle *vehicle = (FPVehicle *)resourceModel;
  NSMutableDictionary *vehicleDict = [NSMutableDictionary dictionary];
  [vehicleDict nullSafeSetObject:[vehicle name] forKey:FPVehicleNameKey];
  [vehicleDict nullSafeSetObject:[vehicle defaultOctane] forKey:FPVehicleDefaultOctaneKey];
  [vehicleDict nullSafeSetObject:[vehicle fuelCapacity] forKey:FPVehicleFuelCapacityKey];
  return vehicleDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPVehicle *vehicle = [FPVehicle vehicleWithName:[resDict objectForKey:FPVehicleNameKey]
                                    defaultOctane:resDict[FPVehicleDefaultOctaneKey]
                                     fuelCapacity:resDict[FPVehicleFuelCapacityKey]
                                 globalIdentifier:location
                                        mediaType:mediaType
                                        relations:relations
                                        updatedAt:[resDict dateSince1970ForKey:FPVehicleUpdatedAtKey]];
  [vehicle setDeletedAt:resDict[FPVehicleDeletedAtKey]];
  return vehicle;
}

@end
