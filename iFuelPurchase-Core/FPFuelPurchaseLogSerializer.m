//
//  FPFuelPurchaseLogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelPurchaseLogSerializer.h"
#import "FPFuelPurchaseLog.h"
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>

NSString * const FPFuelPurchaseLogVehicleGlobalIdKey          = @"fplog/vehicle";
NSString * const FPFuelPurchaseLogFuelStationGlobalIdKey      = @"fplog/fuelstation";
NSString * const FPFuelPurchaseLogNumGallonsKey               = @"fplog/num-gallons";
NSString * const FPFuelPurchaseLogOctaneKey                   = @"fplog/octane";
NSString * const FPFuelPurchaseLogGallonPriceKey              = @"fplog/gallon-price";
NSString * const FPFuelPurchaseLogGotCarWashKey               = @"fplog/got-car-wash";
NSString * const FPFuelPurchaseLogCarWashPerGallonDiscountKey = @"fplog/car-wash-per-gal-discount";
NSString * const FPFuelPurchaseLogPurchasedAtKey              = @"fplog/purchased-at";
NSString * const FPFuelPurchaseLogCreatedAtKey                = @"fplog/created-at";
NSString * const FPFuelPurchaseLogUpdatedAtKey                = @"fplog/updated-at";
NSString * const FPFuelPurchaseLogDeletedAtKey                = @"fplog/deleted-at";

@implementation FPFuelPurchaseLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPFuelPurchaseLog *fuelPurchaseLog = (FPFuelPurchaseLog *)resourceModel;
  NSMutableDictionary *fuelPurchaseLogDict = [NSMutableDictionary dictionary];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog vehicleGlobalIdentifier]
                                  forKey:FPFuelPurchaseLogVehicleGlobalIdKey];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog fuelStationGlobalIdentifier]
                                  forKey:FPFuelPurchaseLogFuelStationGlobalIdKey];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog numGallons]
                                  forKey:FPFuelPurchaseLogNumGallonsKey];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog octane]
                                  forKey:FPFuelPurchaseLogOctaneKey];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog gallonPrice]
                                  forKey:FPFuelPurchaseLogGallonPriceKey];
  [fuelPurchaseLogDict nullSafeSetObject:[NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]]
                                  forKey:FPFuelPurchaseLogGotCarWashKey];
  [fuelPurchaseLogDict nullSafeSetObject:[fuelPurchaseLog carWashPerGallonDiscount]
                                  forKey:FPFuelPurchaseLogCarWashPerGallonDiscountKey];
  [fuelPurchaseLogDict setMillisecondsSince1970FromDate:[fuelPurchaseLog purchasedAt]
                                                 forKey:FPFuelPurchaseLogPurchasedAtKey];
  return fuelPurchaseLogDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPFuelPurchaseLog *fplog =
  [FPFuelPurchaseLog fuelPurchaseLogWithNumGallons:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPFuelPurchaseLogNumGallonsKey] description]]
                                            octane:resDict[FPFuelPurchaseLogOctaneKey]
                                       gallonPrice:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPFuelPurchaseLogGallonPriceKey] description]]
                                        gotCarWash:[resDict[FPFuelPurchaseLogGotCarWashKey] boolValue]
                          carWashPerGallonDiscount:[PEUtils nullSafeDecimalNumberFromString:[resDict[FPFuelPurchaseLogCarWashPerGallonDiscountKey] description]]
                                       purchasedAt:[resDict dateSince1970ForKey:FPFuelPurchaseLogPurchasedAtKey]
                                  globalIdentifier:location
                                         mediaType:mediaType
                                         relations:relations
                                         createdAt:[resDict dateSince1970ForKey:FPFuelPurchaseLogCreatedAtKey]
                                         deletedAt:[resDict dateSince1970ForKey:FPFuelPurchaseLogDeletedAtKey]
                                         updatedAt:[resDict dateSince1970ForKey:FPFuelPurchaseLogUpdatedAtKey]];
  [fplog setVehicleGlobalIdentifier:resDict[FPFuelPurchaseLogVehicleGlobalIdKey]];
  [fplog setFuelStationGlobalIdentifier:resDict[FPFuelPurchaseLogFuelStationGlobalIdKey]];
  return fplog;
}

@end
