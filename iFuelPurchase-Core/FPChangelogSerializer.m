//
//  FPChangelogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPChangelogSerializer.h"
#import "FPChangelog.h"
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>

NSString * const FPChangelogUpdatedAtKey = @"changelog/updated-at";

@implementation FPChangelogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return nil;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                     httpResponse:(NSHTTPURLResponse *)httpResponse {
  return [[FPChangelog alloc] initWithUpdatedAt:[resDict dateSince1970ForKey:FPChangelogUpdatedAtKey]];
}

@end
