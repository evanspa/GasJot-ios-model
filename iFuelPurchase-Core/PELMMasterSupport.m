//
//  PELMMasterSupport.m
//  iFuelPurchase-Core
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
                     lastModified:(NSDate *)lastModified {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:mainEntityTable
                          masterEntityTable:masterEntityTable
                                  mediaType:mediaType
                                  relations:relations];
  if (self) {
    _deletedDate = deletedDate;
    _lastModified = lastModified;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMMasterSupport *)entity {
  [super overwrite:entity];
  [self setLastModified:[entity lastModified]];
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
      [PEUtils isDate:[self lastModified]
   msprecisionEqualTo:[masterSupport lastModified]];
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
    [[self lastModified] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, deleted date: [{%@}, {%f}], last modified: [{%@}, {%f}]",
          [super description],
          _deletedDate, [_deletedDate timeIntervalSince1970],
          _lastModified, [_lastModified timeIntervalSince1970]];
}

@end
