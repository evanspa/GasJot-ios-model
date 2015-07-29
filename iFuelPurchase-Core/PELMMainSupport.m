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
                      deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:mainEntityTable
                          masterEntityTable:masterEntityTable
                                  mediaType:mediaType
                                  relations:relations
                                deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _dateCopiedFromMaster = dateCopiedFromMaster;
    _editInProgress = editInProgress;
    _syncInProgress = syncInProgress;
    _synced = synced;
    _inConflict = inConflict;
    _editCount = editCount;
    _syncHttpRespCode = syncHttpRespCode;
    _syncErrMask = syncErrMask;
    _syncRetryAt = syncRetryAt;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMMainSupport *)entity {
  [super overwrite:entity];
  [self setDateCopiedFromMaster:[entity dateCopiedFromMaster]];
  [self setEditInProgress:[entity editInProgress]];
  [self setSyncInProgress:[entity syncInProgress]];
  [self setSynced:[entity synced]];
  [self setInConflict:[entity inConflict]];
  [self setEditCount:[entity editCount]];
  [self setSyncHttpRespCode:[entity syncHttpRespCode]];
  [self setSyncErrMask:[entity syncErrMask]];
  [self setSyncRetryAt:[entity syncRetryAt]];
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
    BOOL hasEqualSyncRetryAtDates = [PEUtils isDate:[self syncRetryAt]
                                 msprecisionEqualTo:[mainSupport syncRetryAt]];
    return hasEqualCopyFromMasterDates &&
      ([self editInProgress] == [mainSupport editInProgress]) &&
      ([self syncInProgress] == [mainSupport syncInProgress]) &&
      ([self synced] == [mainSupport synced]) &&
      ([self inConflict] == [mainSupport inConflict]) &&
      [PEUtils isNumber:[self syncHttpRespCode] equalTo:[mainSupport syncHttpRespCode]] &&
      [PEUtils isNumber:[self syncErrMask] equalTo:[mainSupport syncErrMask]] &&
      hasEqualSyncRetryAtDates;
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
    [[NSNumber numberWithBool:[self syncInProgress]] hash] ^
    [[NSNumber numberWithBool:[self synced]] hash] ^
    [[NSNumber numberWithBool:[self inConflict]] hash] ^
    [_syncHttpRespCode hash] ^
    [_syncErrMask hash] ^
    [_syncRetryAt hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, date copied from master: [{%@}, {%f}], \
edit in progress: [%@], sync in progress: [%@], \
synced: [%@], in conflict: [%@], edit count: [%lu], \
sync HTTP resp code: [%@], sync err mask: [%@], sync retry at: [%@]",
          [super description],
          _dateCopiedFromMaster,
          [_dateCopiedFromMaster timeIntervalSince1970],
          [PEUtils trueFalseFromBool:_editInProgress],
          [PEUtils trueFalseFromBool:_syncInProgress],
          [PEUtils trueFalseFromBool:_synced],
          [PEUtils trueFalseFromBool:_inConflict],
          (unsigned long)_editCount,
          _syncHttpRespCode,
          _syncErrMask,
          _syncRetryAt];
}

@end
