//
//  PELogoutSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 7/28/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "PELogoutSerializer.h"

@implementation PELogoutSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return @{};
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [[NSObject alloc] init];
}

@end
