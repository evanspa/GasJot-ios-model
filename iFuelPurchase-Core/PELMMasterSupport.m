//
//  PELMMasterSupport.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMasterSupport.h"
#import <PEObjc-Commons/PEUtils.h>

@implementation PELMMasterSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:mainEntityTable
                          masterEntityTable:masterEntityTable
                                  mediaType:mediaType
                                  relations:relations];
  if (self) {
    _deletedDate = deletedDate;
    _updatedAt = updatedAt;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMMasterSupport *)entity {
  [super overwrite:entity];
  [self setUpdatedAt:[entity updatedAt]];
  [self setDeletedDate:[entity deletedDate]];
}

#pragma mark - Equality

- (BOOL)isEqualToMasterSupport:(PELMMasterSupport *)masterSupport {
  if (!masterSupport) { return NO; }
  if ([super isEqualToModelSupport:masterSupport]) {
    BOOL hasEqualDeletedDates =
      [PEUtils isDate:[self deletedDate]
   msprecisionEqualTo:[masterSupport deletedDate]];
    BOOL hasEqualLastUpdateDates =
      [PEUtils isDate:[self updatedAt]
   msprecisionEqualTo:[masterSupport updatedAt]];
    return hasEqualDeletedDates && hasEqualLastUpdateDates;
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMMasterSupport class]]) { return NO; }
  return [self isEqualToMasterSupport:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self deletedDate] hash] ^
    [[self updatedAt] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, deleted date: [{%@}, {%f}], updated-at: [{%@}, {%f}]",
          [super description],
          _deletedDate, [_deletedDate timeIntervalSince1970],
          _updatedAt, [_updatedAt timeIntervalSince1970]];
}

@end
