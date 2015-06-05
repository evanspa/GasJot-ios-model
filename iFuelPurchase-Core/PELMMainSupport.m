//
//  PELMMainSupport.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMainSupport.h"
#import <PEObjc-Commons/PEUtils.h>

@implementation PELMMainSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                      editActorId:(NSNumber *)editActorId
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:mainEntityTable
                          masterEntityTable:masterEntityTable
                                  mediaType:mediaType
                                  relations:relations
                                deletedDate:deletedDate
                                  updatedAt:updatedAt];
  if (self) {
    _dateCopiedFromMaster = dateCopiedFromMaster;
    _editInProgress = editInProgress;
    _editActorId = editActorId;
    _syncInProgress = syncInProgress;
    _synced = synced;
    _inConflict = inConflict;
    _deleted = deleted;
    _editCount = editCount;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMMainSupport *)entity {
  [super overwrite:entity];
  [self setDateCopiedFromMaster:[entity dateCopiedFromMaster]];
  [self setEditInProgress:[entity editInProgress]];
  [self setEditActorId:[entity editActorId]];
  [self setSyncInProgress:[entity syncInProgress]];
  [self setSynced:[entity synced]];
  [self setInConflict:[entity inConflict]];
  [self setDeleted:[entity deleted]];
  [self setEditCount:[entity editCount]];
}

- (NSUInteger)incrementEditCount {
  _editCount++;
  return _editCount;
}

- (NSUInteger)decrementEditCount {
  _editCount--;
  return _editCount;
}

#pragma mark - Equality

- (BOOL)isEqualToMainSupport:(PELMMainSupport *)mainSupport {
  if (!mainSupport) { return NO; }
  if ([super isEqualToMasterSupport:mainSupport]) {
    BOOL hasEqualCopyFromMasterDates =
      [PEUtils isDate:[self dateCopiedFromMaster]
   msprecisionEqualTo:[mainSupport dateCopiedFromMaster]];
    return hasEqualCopyFromMasterDates &&
      ([self editInProgress] == [mainSupport editInProgress]) &&
      ([self syncInProgress] == [mainSupport syncInProgress]) &&
      ([self synced] == [mainSupport synced]) &&
      ([self inConflict] == [mainSupport inConflict]) &&
      ([self deleted] == [mainSupport deleted]);
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMMainSupport class]]) { return NO; }
  return [self isEqualToMainSupport:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self dateCopiedFromMaster] hash] ^
    [[NSNumber numberWithBool:[self editInProgress]] hash] ^
    [_editActorId hash] ^
    [[NSNumber numberWithBool:[self syncInProgress]] hash] ^
    [[NSNumber numberWithBool:[self synced]] hash] ^
    [[NSNumber numberWithBool:[self inConflict]] hash] ^
    [[NSNumber numberWithBool:[self deleted]] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, date copied from master: [{%@}, {%f}], \
edit in progress: [%@], edit actor id: [%@], sync in progress: [%@], \
synced: [%@], in conflict: [%@], deleted: [%@], edit count: [%lu]",
          [super description],
          _dateCopiedFromMaster,
          [_dateCopiedFromMaster timeIntervalSince1970],
          [PEUtils trueFalseFromBool:_editInProgress],
          _editActorId,
          [PEUtils trueFalseFromBool:_syncInProgress],
          [PEUtils trueFalseFromBool:_synced],
          [PEUtils trueFalseFromBool:_inConflict],
          [PEUtils trueFalseFromBool:_deleted],
          (unsigned long)_editCount];
}

@end
