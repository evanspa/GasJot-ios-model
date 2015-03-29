//
//  FPKnownMediaTypes.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/13/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCMediaType.h>

@interface FPKnownMediaTypes : NSObject

+ (HCMediaType *)apiMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)userMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)vehicleMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)fuelStationMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)fuelPurchaseLogMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)environmentLogMediaTypeWithVersion:(NSString *)version;

@end

