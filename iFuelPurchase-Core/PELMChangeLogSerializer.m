//
//  PELMChangeLogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMChangeLogSerializer.h"
#import "PELMChangeLog.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

//NSString * const FPVehicleNameKey = @"fpvehicle/name";
//NSString * const FPVehicleDateAddedKey = @"fpvehicle/dateAdded";

@implementation PELMChangeLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return nil;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                     httpResponse:(NSHTTPURLResponse *)httpResponse {
  /*return [FPVehicle vehicleWithName:[resDict objectForKey:FPVehicleNameKey]
                          dateAdded:[HCUtils rfc7231DateFromString:[resDict objectForKey:FPVehicleDateAddedKey]]
                   globalIdentifier:[HCUtils locationFromResponse:httpResponse]
                          mediaType:[HCUtils mediaTypeFromResponse:httpResponse]
                          relations:relations
                       lastModified:[HCUtils lastModifiedFromResponse:httpResponse]];*/
  return nil; // TODO
}

@end
