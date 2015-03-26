//
//  FPFuelPurchaseLogSerializer.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/3/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPFuelPurchaseLogSerializer.h"
#import "FPFuelPurchaseLog.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>

NSString * const FPFuelPurchaseLogVehicleGlobalIdKey          = @"fpfuelpurchaselog/vehicle";
NSString * const FPFuelPurchaseLogFuelStationGlobalIdKey      = @"fpfuelpurchaselog/fuelstation";
NSString * const FPFuelPurchaseLogNumGallonsKey               = @"fpfuelpurchaselog/num-gallons";
NSString * const FPFuelPurchaseLogOctaneKey                   = @"fpfuelpurchaselog/octane";
NSString * const FPFuelPurchaseLogGallonPriceKey              = @"fpfuelpurchaselog/gallon-price";
NSString * const FPFuelPurchaseLogGotCarWashKey               = @"fpfuelpurchaselog/got-car-wash";
NSString * const FPFuelPurchaseLogCarWashPerGallonDiscountKey = @"fpfuelpurchaselog/carwash-per-gal-discount";
NSString * const FPFuelPurchaseLogLogDateKey                  = @"fpfuelpurchaselog/purchase-date";

@implementation FPFuelPurchaseLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPFuelPurchaseLog *fuelPurchaseLog = (FPFuelPurchaseLog *)resourceModel;
  NSMutableDictionary *fuelPurchaseLogDict = [NSMutableDictionary dictionary];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog vehicleGlobalIdentifier] forKey:FPFuelPurchaseLogVehicleGlobalIdKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog fuelStationGlobalIdentifier] forKey:FPFuelPurchaseLogFuelStationGlobalIdKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog numGallons] forKey:FPFuelPurchaseLogNumGallonsKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog octane] forKey:FPFuelPurchaseLogOctaneKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog gallonPrice] forKey:FPFuelPurchaseLogGallonPriceKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]] forKey:FPFuelPurchaseLogGotCarWashKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[fuelPurchaseLog carWashPerGallonDiscount] forKey:FPFuelPurchaseLogCarWashPerGallonDiscountKey];
  [fuelPurchaseLogDict setObjectIfNotNull:[HCUtils rfc7231StringFromDate:[fuelPurchaseLog logDate]]
                               forKey:FPFuelPurchaseLogLogDateKey];
  return fuelPurchaseLogDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPFuelPurchaseLog *fplog =
    [FPFuelPurchaseLog
      fuelPurchaseLogWithNumGallons:resDict[FPFuelPurchaseLogNumGallonsKey]
                             octane:resDict[FPFuelPurchaseLogOctaneKey]
                        gallonPrice:resDict[FPFuelPurchaseLogGallonPriceKey]
                         gotCarWash:[resDict[FPFuelPurchaseLogGotCarWashKey] boolValue]
           carWashPerGallonDiscount:resDict[FPFuelPurchaseLogCarWashPerGallonDiscountKey]
                            logDate:[HCUtils rfc7231DateFromString:resDict[FPFuelPurchaseLogLogDateKey]]
                   globalIdentifier:location
                          mediaType:mediaType
                          relations:relations
                       lastModified:lastModified];
  [fplog setVehicleGlobalIdentifier:resDict[FPFuelPurchaseLogVehicleGlobalIdKey]];
  [fplog setFuelStationGlobalIdentifier:resDict[FPFuelPurchaseLogFuelStationGlobalIdKey]];
  return fplog;
}

@end
