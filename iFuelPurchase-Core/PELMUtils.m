//
//  PELMUtils.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMUtils.h"
#import "PELMDDL.h"
#import <FMDB/FMDatabase.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEAppTransaction-Logger/TLTransaction.h>
#import <PEHateoas-Client/HCRelation.h>
#import "PELMNotificationUtils.h"
#import <CocoaLumberjack/DDLog.h>
#import "FPLogging.h"

void (^cannotBe)(BOOL, NSString *) = ^(BOOL invariantViolation, NSString *msg) {
  if (invariantViolation) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:msg
                                 userInfo:nil];
  }
};

id (^orNil)(id) = ^ id (id someObj) {
  if (!someObj) {
    return [NSNull null];
  }
  return someObj;
};

void (^LogSyncRemoteMaster)(NSString *, NSInteger) = ^(NSString *msg, NSInteger syncCount) {
  DDLogCDebug(@"[%lu] --- SyncRemoteMaster --- %@", (long)syncCount, msg);
};

void (^LogSystemPrune)(NSString *, NSInteger) = ^(NSString *msg, NSInteger pruneCount) {
  DDLogCDebug(@"[%lu] --- SystemPrune --- %@", (long)pruneCount, msg);
};

void (^LogSyncLocal)(NSString *, NSInteger) = ^(NSString *msg, NSInteger syncCount) {
  DDLogCDebug(@"[%lu] --- SyncLocal --- %@", (long)syncCount, msg);
};

PELMMainSupport * (^toMainSupport)(FMResultSet *, NSString *, NSDictionary *) = ^PELMMainSupport *(FMResultSet *rs, NSString *mainTable, NSDictionary *relations) {
  return [[PELMMainSupport alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                        localMasterIdentifier:nil // NA (this is a master entity-only column)
                                             globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mainEntityTable:mainTable
                                            masterEntityTable:nil
                                                    mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                    relations:relations
                                                  deletedDate:nil // NA (this is a master entity-only column)
                                                 lastModified:[rs dateForColumn:COL_MAN_MASTER_LAST_MODIFIED]
                                         dateCopiedFromMaster:[rs dateForColumn:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                               editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                  editActorId:[rs objectForColumnName:COL_MAN_EDIT_ACTOR_ID]
                                               syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                       synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                   inConflict:[rs boolForColumn:COL_MAN_IN_CONFLICT]
                                                      deleted:[rs boolForColumn:COL_MAN_DELETED]
                                                    editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]];
};

@implementation PELMUtils

#pragma mark - Initializers

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
  self = [super init];
  if (self) {
    _databaseQueue = databaseQueue;
  }
  return self;
}

#pragma mark - Syncing

+ (void)flushUnsyncedChangesToEntity:(PELMMainSupport *)unsyncedEntity
                    systemFlushCount:(NSInteger)systemFlushCount
             contextForNotifications:(NSObject *)contextForNotifications
                  transactionManager:(TLTransactionManager *)txnManager
                      syncTxnUsecase:(NSInteger)syncTxnUsecase
        syncInitiatedTxnUsecaseEvent:(NSInteger)syncInitiatedTxnUsecaseEvent
                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                       cancelSyncBlk:(void(^)(PELMMainSupport *))cancelSyncBlk
                   markAsConflictBlk:(void(^)(id, PELMMainSupport *))markAsConflictBlk
     syncRespReceivedTxnUsecaseEvent:(NSInteger)syncRespReceivedUsecaseEvent
   markAsSyncCompleteForNewEntityBlk:(void(^)(PELMMainSupport *))markAsSyncCompleteForNewEntityBlk
markAsSyncCompleteForExistingEntityBlk:(void(^)(PELMMainSupport *))markAsSyncCompleteForExistingEntityBlk
        syncCompleteNotificationName:(NSString *)syncCompleteNotificationName
          syncFailedNotificationName:(NSString *)syncFailedNotificationName
          entityGoneNotificationName:(NSString *)entityGoneNotificationName
           physicallyDeleteEntityBlk:(void(^)(PELMMainSupport *))physicallyDeleteEntityBlk
        syncAttemptedTxnUsecaseEvent:(NSInteger)syncAttemptedTxnUsecaseEvent
                 authRequiredHandler:(PELMRemoteMasterAuthReqdBlk)authRequiredHandler
                     newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk
           backgroundProcessingQueue:(dispatch_queue_t)backgroundProcessingQueue
               remoteMasterDeleteBlk:(PELMRemoteMasterDeletionBlk)remoteMasterDeleteBlk
              remoteMasterSaveNewBlk:(PELMRemoteMasterSaveBlk)remoteMasterSaveNewBlk
         remoteMasterSaveExistingBlk:(PELMRemoteMasterSaveBlk)remoteMasterSaveExistingBlk
               localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrHandler {
  TLTransaction *txn = [txnManager transactionWithUsecase:@(syncTxnUsecase) error:localSaveErrHandler];
  [txn logWithUsecaseEvent:@(syncInitiatedTxnUsecaseEvent) error:localSaveErrHandler];
  if (unsyncedEntity) {
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler = ^(NSDate *retryAfter) {
      [txn logWithUsecaseEvent:@(syncRespReceivedUsecaseEvent) error:localSaveErrHandler];
      remoteStoreBusyBlk(retryAfter);
      cancelSyncBlk(unsyncedEntity);
    };
    void (^processConflict)(id) = ^ (id latestResourceModel) {
      markAsConflictBlk(latestResourceModel, unsyncedEntity);
    };
    void (^notifySuccessfulSync)(PELMMainSupport *, BOOL, BOOL) = ^(PELMMainSupport *respEntity, BOOL wasDeletion, BOOL wasPut) {
      if (!wasDeletion) {
        if (respEntity) {
          NSString *unsyncedEntityGlobalId = [unsyncedEntity globalIdentifier];
          [unsyncedEntity overwrite:respEntity];
          if (wasPut) {
            // we do this because, in an HTTP PUT, the typical response is 200,
            // and, with 200, the "location" header is usually absent; this means
            // that the entity parsed from the response will have its 'globalIdentifier'
            // property empty.  Well, we want to keep our existing global identity
            // property, so, we have to re-set it onto unsyncedEntity after doing
            // the "overwrite" step above
            [unsyncedEntity setGlobalIdentifier:unsyncedEntityGlobalId];
          }
        }
        if (wasPut) {
          markAsSyncCompleteForExistingEntityBlk(unsyncedEntity);
        } else {
          markAsSyncCompleteForNewEntityBlk(unsyncedEntity);
        }
      }
      [PELMNotificationUtils postNotificationWithName:syncCompleteNotificationName
                                               entity:unsyncedEntity];
    };
    void (^notifyUnsuccessfulSync)(NSError *) = ^(NSError *error) {
      cancelSyncBlk(unsyncedEntity);
      [PELMNotificationUtils postNotificationWithName:syncFailedNotificationName
                                               entity:unsyncedEntity];
    };
    void (^processGone)(void) = ^{
      physicallyDeleteEntityBlk(unsyncedEntity);
      [PELMNotificationUtils postNotificationWithName:entityGoneNotificationName
                                               entity:unsyncedEntity];
    };
    PELMRemoteMasterAuthReqdBlk authReqdWithNotification = ^(HCAuthentication *auth) {
      [txn logWithUsecaseEvent:@(syncRespReceivedUsecaseEvent) error:localSaveErrHandler];
      notifyUnsuccessfulSync(nil);
      authRequiredHandler(auth);
    };
    if ([unsyncedEntity deleted]) {
      PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
      ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
        NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
        BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
        [txn logWithUsecaseEvent:@(syncRespReceivedUsecaseEvent) error:localSaveErrHandler];
        LogSyncLocal([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                      STARTED to process response from remote master delete request for entity: [%@].",
                      unsyncedEntity], systemFlushCount);
        newAuthTokenBlk(newAuthTkn);
        if (lastModified) {
          [unsyncedEntity setLastModified:lastModified];
        }
        if (movedPermanently) {
          [unsyncedEntity setGlobalIdentifier:globalId];
        } else if (isConflict) {
          processConflict(resourceModel);
        } else if (gone) {
          processGone();
        } else if (notFound) {
          // weird - this should not happen
        } else if (notModified) {
          // should not happen since we're doing a PUT
        } else if (err) {
          notifyUnsuccessfulSync(err);
        } else {
          physicallyDeleteEntityBlk(unsyncedEntity);
          notifySuccessfulSync(nil, YES, NO);
        }
        LogSyncLocal(@"(PELMRemoteMasterCompletionHandler) COMPLETED to process \
                     response from remote master delete request", systemFlushCount);
      };
      [txn logWithUsecaseEvent:@(syncAttemptedTxnUsecaseEvent) error:localSaveErrHandler];
      LogSyncRemoteMaster(@"(PELMRemoteMasterCompletionHandler) START invoke \
                          'remoteMasterDeleteBlk'", systemFlushCount);
      remoteMasterDeleteBlk(unsyncedEntity,
                            [txn guid],
                            remoteStoreBusyHandler,
                            authReqdWithNotification,
                            remoteStoreComplHandler,
                            backgroundProcessingQueue);
      LogSyncRemoteMaster(@"(PELMRemoteMasterCompletionHandler) COMPLETE \
                          'remoteMasterDeleteBlk' invocation", systemFlushCount);
    } else {
      if ([unsyncedEntity globalIdentifier]) {
        PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
        ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
          NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
          BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
          [txn logWithUsecaseEvent:@(syncRespReceivedUsecaseEvent) error:localSaveErrHandler];
          LogSyncLocal([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                        STARTED to process response from remote master update request for entity: [%@].",
                        unsyncedEntity],systemFlushCount);
          newAuthTokenBlk(newAuthTkn);
          if (lastModified) {
            [unsyncedEntity setLastModified:lastModified];
          }
          if (movedPermanently) { // this block will get executed again
            [unsyncedEntity setGlobalIdentifier:globalId];
          } else if (isConflict) {
            processConflict(resourceModel);
          } else if (gone) {
            processGone();
          } else if (notFound) {
            // weird - this should not happen
          } else if (notModified) {
            // should not happen since we're doing a PUT
          } else if (err) {
            notifyUnsuccessfulSync(err);
          } else {
            notifySuccessfulSync(resourceModel, NO, YES);
          }
          LogSyncLocal([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                        COMPLETED to process response from remote master update request for entity: [%@].",
                        unsyncedEntity],systemFlushCount);
        };
        [txn logWithUsecaseEvent:@(syncAttemptedTxnUsecaseEvent) error:localSaveErrHandler];
        LogSyncRemoteMaster(@"(PELMRemoteMasterCompletionHandler) START invoke\
                            'remoteMasterSaveExistingBlk'", systemFlushCount);
        remoteMasterSaveExistingBlk(unsyncedEntity,
                                    [txn guid],
                                    remoteStoreBusyHandler,
                                    authReqdWithNotification,
                                    remoteStoreComplHandler,
                                    backgroundProcessingQueue);
        LogSyncRemoteMaster(@"(PELMRemoteMasterCompletionHandler) COMPLETE \
                            'remoteMasterSaveExistingBlk' invocation", systemFlushCount);
      } else {
        PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
        ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
          NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
          BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
          [txn logWithUsecaseEvent:@(syncRespReceivedUsecaseEvent) error:localSaveErrHandler];
          LogSyncLocal([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                        STARTED to process response from remote master creation request for entity: [%@].",
                        unsyncedEntity],systemFlushCount);
          newAuthTokenBlk(newAuthTkn);
          if (lastModified) {
            [unsyncedEntity setLastModified:lastModified];
          }
          if (movedPermanently) { // this block will get executed again
            [unsyncedEntity setGlobalIdentifier:globalId];
          } else if (isConflict) {
            // weird - this should not happen
          } else if (gone) {
            processGone();
          } else if (notFound) {
            // weird - this should not happen
          } else if (notModified) {
            // should not happen since we're doing a POST
          } else if (err) {
            notifyUnsuccessfulSync(err);
          } else {
            notifySuccessfulSync(resourceModel, NO, NO);
          }
          LogSyncLocal([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                        COMPLETED to process response from remote master creation request for entity: [%@].",
                        unsyncedEntity],systemFlushCount);
        };
        [txn logWithUsecaseEvent:@(syncAttemptedTxnUsecaseEvent) error:localSaveErrHandler];
        if (remoteMasterSaveNewBlk) {
          LogSyncRemoteMaster([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                               START invoke 'remoteMasterSaveNewBlk'"], systemFlushCount);
          remoteMasterSaveNewBlk(unsyncedEntity,
                                 [txn guid],
                                 remoteStoreBusyHandler,
                                 authReqdWithNotification,
                                 remoteStoreComplHandler,
                                 backgroundProcessingQueue);
          LogSyncRemoteMaster([NSString stringWithFormat:@"(PELMRemoteMasterCompletionHandler) \
                               COMPLETE 'remoteMasterSaveNewBlk' invocation"], systemFlushCount);
        }
      }
    }
  } else {
    // I dunno - do I really need to log this?  Seems like this is a good way to
    // fill up my transaction database with useless data.
    //[txn logWithEventType:FPTxnSyncUserEvtSaveToRemoteStoreSkippedDueToNoEdits];
  }
}

+ (void)cancelSyncInProgressForEntityTable:(NSString *)mainEntityTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)error {
  [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET %@ = 0",
                     mainEntityTable,
                     COL_MAN_SYNC_IN_PROGRESS]];
}

#pragma mark - Result Set Helpers

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs
                       columnName:(NSString *)columnName {
  return [PEUtils nullSafeNumberFromString:[rs stringForColumn:columnName]];
}

+ (NSDecimalNumber *)decimalNumberFromResultSet:(FMResultSet *)rs
                                     columnName:(NSString *)columnName {
  return [PEUtils nullSafeDecimalNumberFromString:[rs stringForColumn:columnName]];
}

#pragma mark - Utils

- (void)cancelEditOfEntity:(PELMMainSupport *)entity
                 mainTable:(NSString *)mainTable
               editActorId:(NSNumber *)editActorId
               masterTable:(NSString *)masterTable
               rsConverter:(entityFromResultSetBlk)rsConverter
                     error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils saveEntityInvariantChecks:entity];
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils assertActualEditActorIdOfEntity:entity
                            matchesEditActorId:editActorId
                                     mainTable:mainTable
                                            db:db
                                         error:errorBlk];
    [entity setEditInProgress:NO];
    if ([entity decrementEditCount] == 0) {
      [PELMUtils deleteRelationsForEntity:entity
                              entityTable:mainTable
                          localIdentifier:[entity localMainIdentifier]
                                       db:db
                                    error:errorBlk];
      [PELMUtils deleteFromTable:mainTable
                    whereColumns:@[COL_LOCAL_ID]
                     whereValues:@[[entity localMainIdentifier]]
                              db:db
                           error:errorBlk];
      [entity setLocalMainIdentifier:nil];
      if ([entity globalIdentifier]) {
        DDLogDebug(@"In PELMUtils/cancelEditOfEntity..., canceled edit of entity resulted in it being pruned \
from its main table.  However its global ID is not nil.  Proceeding to load the entity \
from its master table and overwrite in-memory entity with it.  In-memory entity before master-load: %@", entity);
        PELMMainSupport *fetchedMasterEntity = (PELMMainSupport *)
          [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", masterTable, COL_GLOBAL_ID]
                         entityTable:masterTable
                       localIdGetter:^NSNumber *(PELMModelSupport *entity) {return [entity localMasterIdentifier];}
                           argsArray:@[[entity globalIdentifier]]
                         rsConverter:rsConverter
                                  db:db
                               error:errorBlk];
        if (fetchedMasterEntity) {
          [entity setLocalMasterIdentifier:[fetchedMasterEntity localMasterIdentifier]];
          [entity overwrite:fetchedMasterEntity];
          DDLogDebug(@"In PELMUtils/cancelEditOfEntity..., entity after \
overwrite with master-copy: %@", entity);
        } else {
          DDLogDebug(@"In PELMUtils/cancelEditOfEntity..., ouch!  Master \
version of entity not found!  It's global ID is: [%@]", [entity globalIdentifier]);
        }
      }
    } else {
      [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET %@ = 0 \
WHERE %@ = ?", mainTable, COL_MAN_EDIT_IN_PROGRESS, COL_LOCAL_ID]
   withArgumentsInArray:@[[entity localMainIdentifier]]];
    }
  }];
}

- (void)saveEntity:(PELMMainSupport *)entity
         mainTable:(NSString *)mainTable
    mainUpdateStmt:(NSString *)mainUpdateStmt
 mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
       editActorId:(NSNumber *)editActorId
             error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils saveEntityInvariantChecks:entity];
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils assertActualEditActorIdOfEntity:entity
                            matchesEditActorId:editActorId
                                     mainTable:mainTable
                                            db:db
                                         error:errorBlk];
    [PELMUtils doUpdate:mainUpdateStmt
              argsArray:mainUpdateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingEntity:(PELMMainSupport *)entity
                      mainTable:(NSString *)mainTable
                 mainUpdateStmt:(NSString *)mainUpdateStmt
              mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                    editActorId:(NSNumber *)editActorId
                          error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils saveEntityInvariantChecks:entity];
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils assertActualEditActorIdOfEntity:entity
                            matchesEditActorId:editActorId
                                     mainTable:mainTable
                                            db:db
                                         error:errorBlk];
    [entity setEditInProgress:NO];
    [PELMUtils doUpdate:mainUpdateStmt
              argsArray:mainUpdateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsSyncCompleteForNewEntity:(PELMMainSupport *)entity
                             mainTable:(NSString *)mainTable
                           masterTable:(NSString *)masterTable
                        mainUpdateStmt:(NSString *)mainUpdateStmt
                     mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [entity setSyncInProgress:NO];
    [entity setSynced:YES];
    [PELMUtils updateRelationsForEntity:entity
                            entityTable:mainTable
                        localIdentifier:[entity localMainIdentifier]
                                     db:db
                                  error:errorBlk];
    [PELMUtils doUpdate:mainUpdateStmt
              argsArray:mainUpdateArgsBlk(entity)
                     db:db
                  error:errorBlk];
    masterInsertBlk(entity, db);
    [PELMUtils insertRelations:[entity relations]
                     forEntity:entity
                   entityTable:masterTable
               localIdentifier:[entity localMasterIdentifier]
                            db:db
                         error:errorBlk];
  }];
}

- (void)markAsSyncCompleteForUpdatedEntityInTxn:(PELMMainSupport *)entity
                                      mainTable:(NSString *)mainTable
                                    masterTable:(NSString *)masterTable
                                 mainUpdateStmt:(NSString *)mainUpdateStmt
                              mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                               masterUpdateStmt:(NSString *)masterUpdateStmt
                            masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                          error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self markAsSyncCompleteForUpdatedEntity:entity
                                   mainTable:mainTable
                                 masterTable:masterTable
                              mainUpdateStmt:mainUpdateStmt
                           mainUpdateArgsBlk:mainUpdateArgsBlk
                            masterUpdateStmt:masterUpdateStmt
                         masterUpdateArgsBlk:masterUpdateArgsBlk
                                          db:db
                                       error:errorBlk];
  }];
}

- (void)markAsSyncCompleteForUpdatedEntity:(PELMMainSupport *)entity
                                 mainTable:(NSString *)mainTable
                               masterTable:(NSString *)masterTable
                            mainUpdateStmt:(NSString *)mainUpdateStmt
                         mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                          masterUpdateStmt:(NSString *)masterUpdateStmt
                       masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  [entity setSyncInProgress:NO];
  [entity setSynced:YES];
  [PELMUtils updateRelationsForEntity:entity
                          entityTable:mainTable
                      localIdentifier:[entity localMainIdentifier]
                                   db:db
                                error:errorBlk];
  [PELMUtils doUpdate:mainUpdateStmt
            argsArray:mainUpdateArgsBlk(entity)
                   db:db
                error:errorBlk];
  [entity setLocalMasterIdentifier:[PELMUtils masterLocalIdFromEntityTable:masterTable
                                                          globalIdentifier:[entity globalIdentifier]
                                                                        db:db
                                                                     error:errorBlk]];
  [PELMUtils updateRelationsForEntity:entity
                          entityTable:masterTable
                      localIdentifier:[entity localMasterIdentifier]
                                   db:db
                                error:errorBlk];
  [PELMUtils doUpdate:masterUpdateStmt
            argsArray:masterUpdateArgsBlk(entity)
                   db:db
                error:errorBlk];
}

+ (NSArray *)entitiesForParentEntity:(PELMModelSupport *)parentEntity
               parentEntityMainTable:(NSString *)parentEntityMainTable
         parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
          parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
            parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                            pageSize:(NSInteger)pageSize
                   pageBoundaryWhere:(NSString *)pageBoundaryWhere
                     pageBoundaryArg:(id)pageBoundaryArg
                   entityMasterTable:(NSString *)entityMasterTable
      masterEntityResultSetConverter:(entityFromResultSetBlk)masterEntityResultSetConverter
                     entityMainTable:(NSString *)entityMainTable
        mainEntityResultSetConverter:(entityFromResultSetBlk)mainEntityResultSetConverter
                   comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                 orderByDomainColumn:(NSString *)orderByDomainColumn
        orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *(^masterQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (pageBoundaryArg) {
      qry = [qry stringByAppendingFormat:@" AND mstr.%@ ", pageBoundaryWhere];
    }
    return [qry stringByAppendingFormat:@" ORDER BY mstr.%@ %@", orderByDomainColumn, orderByDomainColumnDirection];
  };
  NSArray *(^argsArrayTransformer)(NSArray *) = ^ NSArray *(NSArray *argsArray) {
    if (pageBoundaryArg) {
      return [argsArray arrayByAddingObject:pageBoundaryArg];
    }
    return argsArray;
  };
  NSString *(^mainQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (pageBoundaryArg) {
      qry = [qry stringByAppendingFormat:@" AND %@ ", pageBoundaryWhere];
    }
    return [qry stringByAppendingFormat:@" ORDER BY %@ %@", orderByDomainColumn, orderByDomainColumnDirection];
  };
  NSArray *(^entitiesFilter)(NSArray *) = ^ NSArray *(NSArray *entities) {
    NSArray *sortedEntities = [entities sortedArrayUsingComparator:comparatorForSort];
    if ([sortedEntities count] > pageSize) {
      NSMutableArray *truncatedEntities = [NSMutableArray arrayWithCapacity:pageSize];
      for (int i = 0; i < pageSize; i++) {
        [truncatedEntities addObject:sortedEntities[i]];
      }
      sortedEntities = truncatedEntities;
    }
    return sortedEntities;
  };
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdColumn
                   parentEntityMainIdColumn:parentEntityMainIdColumn
                                   pageSize:@(pageSize)
                          entityMasterTable:entityMasterTable
             masterEntityResultSetConverter:masterEntityResultSetConverter
                            entityMainTable:entityMainTable
               mainEntityResultSetConverter:mainEntityResultSetConverter
                     masterQueryTransformer:masterQueryTransformer
                 masterArgsArrayTransformer:argsArrayTransformer
                       mainQueryTransformer:mainQueryTransformer
                   mainArgsArrayTransformer:argsArrayTransformer
                             entitiesFilter:entitiesFilter
                                         db:db
                                      error:errorBlk];
}

+ (NSArray *)entitiesForParentEntity:(PELMModelSupport *)parentEntity
               parentEntityMainTable:(NSString *)parentEntityMainTable
         parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
          parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
            parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                               where:(NSString *)where
                            whereArg:(id)whereArg
                   entityMasterTable:(NSString *)entityMasterTable
      masterEntityResultSetConverter:(entityFromResultSetBlk)masterEntityResultSetConverter
                     entityMainTable:(NSString *)entityMainTable
        mainEntityResultSetConverter:(entityFromResultSetBlk)mainEntityResultSetConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *(^masterQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (where) {
      return [qry stringByAppendingFormat:@" AND mstr.%@ ", where];
    }
    return qry;
  };
  NSArray *(^argsArrayTransformer)(NSArray *) = ^ NSArray *(NSArray *argsArray) {
    if (whereArg) {
      return [argsArray arrayByAddingObject:whereArg];
    }
    return argsArray;
  };
  NSString *(^mainQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (where) {
      return [qry stringByAppendingFormat:@" AND %@ ", where];
    }
    return qry;
  };
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdColumn
                   parentEntityMainIdColumn:parentEntityMainIdColumn
                                   pageSize:nil
                          entityMasterTable:entityMasterTable
             masterEntityResultSetConverter:masterEntityResultSetConverter
                            entityMainTable:entityMainTable
               mainEntityResultSetConverter:mainEntityResultSetConverter
                     masterQueryTransformer:masterQueryTransformer
                 masterArgsArrayTransformer:argsArrayTransformer
                       mainQueryTransformer:mainQueryTransformer
                   mainArgsArrayTransformer:argsArrayTransformer
                             entitiesFilter:nil
                                         db:db
                                      error:errorBlk];
}

+ (NSArray *)entitiesForParentEntity:(PELMModelSupport *)parentEntity
               parentEntityMainTable:(NSString *)parentEntityMainTable
         parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
          parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
            parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                            pageSize:(NSNumber *)pageSize
                   entityMasterTable:(NSString *)entityMasterTable
      masterEntityResultSetConverter:(entityFromResultSetBlk)masterEntityResultSetConverter
                     entityMainTable:(NSString *)entityMainTable
        mainEntityResultSetConverter:(entityFromResultSetBlk)mainEntityResultSetConverter
              masterQueryTransformer:(NSString *(^)(NSString *))masterQueryTransformer
          masterArgsArrayTransformer:(NSArray *(^)(NSArray *))masterArgsArrayTransformer
                mainQueryTransformer:(NSString *(^)(NSString *))mainQueryTransformer
            mainArgsArrayTransformer:(NSArray *(^)(NSArray *))mainArgsArrayTransformer
                      entitiesFilter:(NSArray *(^)(NSArray *))entitiesFilter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils reloadEntity:parentEntity
            fromMainTable:parentEntityMainTable
              rsConverter:parentEntityMainRsConverter
                       db:db
                    error:errorBlk];
  NSMutableArray *entities = [NSMutableArray array];
  if ([parentEntity localMasterIdentifier]) {
    NSArray *argsArray = @[[parentEntity localMasterIdentifier]];
    NSString *qry = [NSString stringWithFormat:@"\
                     SELECT mstr.* FROM %@ mstr WHERE mstr.%@ = ? AND mstr.%@ IS NULL",
                     entityMasterTable,
                     parentEntityMasterIdColumn,
                     COL_MST_DELETED_DT];
    if ([parentEntity localMainIdentifier]) {
      qry = [NSString stringWithFormat:@"\
             SELECT mstr.* \
             FROM %@ mstr \
             WHERE mstr.%@ = ? AND \
                   mstr.%@ NOT IN (SELECT man.%@ \
                                   FROM %@ man \
                                   WHERE man.%@ = ? AND \
                                         man.%@ = 0 AND \
                                         man.%@ = 0 AND \
                                         man.%@ IS NOT NULL) AND \
                   mstr.%@ IS NULL",
             entityMasterTable,
             parentEntityMasterIdColumn,
             COL_GLOBAL_ID,
             COL_GLOBAL_ID,
             entityMainTable,
             parentEntityMainIdColumn,
             COL_MAN_DELETED,
             COL_MAN_IN_CONFLICT,
             COL_GLOBAL_ID,
             COL_MST_DELETED_DT];
      argsArray = @[[parentEntity localMasterIdentifier], [parentEntity localMainIdentifier]];
    }
    qry = masterQueryTransformer(qry);
    argsArray = masterArgsArrayTransformer(argsArray);
    NSArray *masterEntities =
    [PELMUtils masterEntitiesFromQuery:qry
                            numAllowed:pageSize
                           entityTable:entityMasterTable
                             argsArray:argsArray
                           rsConverter:masterEntityResultSetConverter
                                    db:db
                                 error:errorBlk];
    /*
     The following is needed to filter the result set.  Although we have our sub-select
     in the SQL query to filter out master entities that are sitting in main, this
     sub-select won't catch them all.  I.e., it won't catch those entities that have been
     edited to be associated with a different parent entity.  I.e., imagine the following:
     1. FPLog-1 belongs to V-1.  They are both in master, and neither are in main.
     2. FPLog-1 is marked for edit.  This brings FPLog-1 and V-1 into their main tables.
     3. FPLog-1 is edited to be associated to V-2 and saved.
     4. Remote sync has not ocurred.
     5. Prune has not ocurred.
     6. FPLog-1 has a row in master, and a row in main.  Its row in main is linked
     to V-2.  Its row in master however is still linked to V-1 (because remote sync
     has not ocurred yet).
     7. In this situation, the query above would include FPLog-1 when V-1's fplogs are
     asked for.  This would be incorrect because FPLog-1 REALLY belongs to V-2, it's
     just that this fact is only reflected in FPLog-1 main.  The following code
     rectifies this by checking to see if FPLog-1 exists in main (by looking it
     up via its global identifier), and if it does, it will not be included in
     the array.
     */
    NSInteger numMasterEntities = [masterEntities count];
    int count = 0;
    for (int i = 0; i < numMasterEntities; i++) {
      PELMModelSupport *masterEntity = masterEntities[i];
      if ([masterEntity globalIdentifier]) {
        NSNumber *localMainIdentifier =
        [PELMUtils numberFromTable:entityMainTable
                      selectColumn:COL_LOCAL_ID
                       whereColumn:COL_GLOBAL_ID
                        whereValue:[masterEntity globalIdentifier]
                                db:db
                             error:errorBlk];
        if (!localMainIdentifier) {
          count++;
          [entities addObject:masterEntity];
        }
      }
    }
  }
  if ([parentEntity localMainIdentifier]) {
    NSString *qry = [NSString stringWithFormat:@"\
                     SELECT * \
                     FROM %@ \
                     WHERE %@ = ? AND \
                           %@ = 0 AND \
                           %@ = 0", entityMainTable,
                     parentEntityMainIdColumn,
                     COL_MAN_DELETED,
                     COL_MAN_IN_CONFLICT];
    NSArray *argsArray = @[[parentEntity localMainIdentifier]];
    qry = mainQueryTransformer(qry);
    argsArray = mainArgsArrayTransformer(argsArray);
    NSArray *mainEntities = [PELMUtils mainEntitiesFromQuery:qry
                                                  numAllowed:pageSize
                                                 entityTable:entityMainTable
                                                   argsArray:argsArray
                                                 rsConverter:mainEntityResultSetConverter
                                                          db:db
                                                       error:errorBlk];
    NSInteger numMainEntities = [mainEntities count];
    for (int i = 0; i < numMainEntities; i++) {
      PELMMainSupport *mainEntity = mainEntities[i];
      if ([mainEntity globalIdentifier]) {
        NSNumber *masterLocalIdentifier =
        [PELMUtils numberFromTable:entityMasterTable
                      selectColumn:COL_LOCAL_ID
                       whereColumn:COL_GLOBAL_ID
                        whereValue:[mainEntity globalIdentifier]
                                db:db
                             error:errorBlk];
        if (masterLocalIdentifier) {
          [mainEntity setLocalMasterIdentifier:masterLocalIdentifier];
        }
      }
    }
    [entities addObjectsFromArray:mainEntities];
  }
  if (entitiesFilter) {
    return entitiesFilter(entities);
  } else {
    return entities;
  }
}

+ (NSInteger)numEntitiesForParentEntity:(PELMModelSupport *)parentEntity
                  parentEntityMainTable:(NSString *)parentEntityMainTable
            parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
             parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
               parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                      entityMasterTable:(NSString *)entityMasterTable
                        entityMainTable:(NSString *)entityMainTable
                                  where:(NSString *)where
                               whereArg:(id)whereArg
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  NSString *(^masterQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (where) {
      return [qry stringByAppendingFormat:@" AND mstr.%@ ", where];
    }
    return qry;
  };
  NSArray *(^argsArrayTransformer)(NSArray *) = ^ NSArray *(NSArray *argsArray) {
    if (whereArg) {
      return [argsArray arrayByAddingObject:whereArg];
    }
    return argsArray;
  };
  NSString *(^mainQueryTransformer)(NSString *) = ^ NSString *(NSString *qry) {
    if (where) {
      return [qry stringByAppendingFormat:@" AND %@ ", where];
    }
    return qry;
  };
  return [PELMUtils numEntitiesForParentEntity:parentEntity
                         parentEntityMainTable:parentEntityMainTable
                   parentEntityMainRsConverter:parentEntityMainRsConverter
                    parentEntityMasterIdColumn:parentEntityMasterIdColumn
                      parentEntityMainIdColumn:parentEntityMainIdColumn
                             entityMasterTable:entityMasterTable
                               entityMainTable:entityMainTable
                        masterQueryTransformer:masterQueryTransformer
                    masterArgsArrayTransformer:argsArrayTransformer
                          mainQueryTransformer:mainQueryTransformer
                      mainArgsArrayTransformer:argsArrayTransformer
                                            db:db
                                         error:errorBlk];
}

+ (NSInteger)numEntitiesForParentEntity:(PELMModelSupport *)parentEntity
                  parentEntityMainTable:(NSString *)parentEntityMainTable
            parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
             parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
               parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                      entityMasterTable:(NSString *)entityMasterTable
                        entityMainTable:(NSString *)entityMainTable
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils numEntitiesForParentEntity:parentEntity
                         parentEntityMainTable:parentEntityMainTable
                   parentEntityMainRsConverter:parentEntityMainRsConverter
                    parentEntityMasterIdColumn:parentEntityMasterIdColumn
                      parentEntityMainIdColumn:parentEntityMainIdColumn
                             entityMasterTable:entityMasterTable
                               entityMainTable:entityMainTable
                        masterQueryTransformer:^NSString *(NSString *qry){return qry;}
                    masterArgsArrayTransformer:^NSArray *(NSArray *args){return args;}
                          mainQueryTransformer:^NSString *(NSString *qry){return qry;}
                      mainArgsArrayTransformer:^NSArray *(NSArray *args){return args;}
                                            db:db
                                         error:errorBlk];
}

+ (NSInteger)numEntitiesForParentEntity:(PELMModelSupport *)parentEntity
                  parentEntityMainTable:(NSString *)parentEntityMainTable
            parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
             parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
               parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                      entityMasterTable:(NSString *)entityMasterTable
                        entityMainTable:(NSString *)entityMainTable
                 masterQueryTransformer:(NSString *(^)(NSString *))masterQueryTransformer
             masterArgsArrayTransformer:(NSArray *(^)(NSArray *))masterArgsArrayTransformer
                   mainQueryTransformer:(NSString *(^)(NSString *))mainQueryTransformer
               mainArgsArrayTransformer:(NSArray *(^)(NSArray *))mainArgsArrayTransformer
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils reloadEntity:parentEntity
            fromMainTable:parentEntityMainTable
              rsConverter:parentEntityMainRsConverter
                       db:db
                    error:errorBlk];
  NSInteger numEntities = 0;
  if ([parentEntity localMasterIdentifier]) {
    NSArray *argsArray = @[[parentEntity localMasterIdentifier]];
    NSString *qry = [NSString stringWithFormat:@"\
                     SELECT count(mstr.%@) FROM %@ mstr WHERE mstr.%@ = ? AND mstr.%@ IS NULL",
                     COL_LOCAL_ID,
                     entityMasterTable,
                     parentEntityMasterIdColumn,
                     COL_MST_DELETED_DT];
    qry = masterQueryTransformer(qry);
    BOOL didJoinWithMain = NO;
    NSString *mainMasterQrySansSelectClause =
    [NSString stringWithFormat:@"\
     FROM %@ mstr \
     WHERE mstr.%@ = ? AND \
           mstr.%@ NOT IN (SELECT innerman.%@ \
                           FROM %@ innerman \
                           WHERE innerman.%@ = ? AND \
                                 innerman.%@ = 0 AND \
                                 innerman.%@ = 0 AND \
                                 innerman.%@ IS NOT NULL) AND \
           mstr.%@ IS NULL",
     entityMasterTable,
     parentEntityMasterIdColumn,
     COL_GLOBAL_ID,
     COL_GLOBAL_ID,
     entityMainTable,
     parentEntityMainIdColumn,
     COL_MAN_DELETED,
     COL_MAN_IN_CONFLICT,
     COL_GLOBAL_ID,
     COL_MST_DELETED_DT];
    mainMasterQrySansSelectClause = masterQueryTransformer(mainMasterQrySansSelectClause);
    if ([parentEntity localMainIdentifier]) {
      didJoinWithMain = YES;
      qry = [NSString stringWithFormat:@"SELECT count(mstr.%@) %@",
             COL_GLOBAL_ID,
             mainMasterQrySansSelectClause];
      argsArray = @[[parentEntity localMasterIdentifier], [parentEntity localMainIdentifier]];
    }
    argsArray = masterArgsArrayTransformer(argsArray);
    numEntities += [PELMUtils intFromQuery:qry args:argsArray db:db];
    if (didJoinWithMain) {
      qry = [NSString stringWithFormat:@"SELECT count(outman.%@) from %@ outman WHERE outman.%@ IN (SELECT mstr.%@ %@)",
             COL_LOCAL_ID,
             entityMainTable,
             COL_GLOBAL_ID,
             COL_GLOBAL_ID,
             mainMasterQrySansSelectClause];
      NSInteger numMainMasterEntities = [PELMUtils intFromQuery:qry args:argsArray db:db];
      numEntities -= numMainMasterEntities;
    }
  }
  if ([parentEntity localMainIdentifier]) {
    NSString *qry = [NSString stringWithFormat:@"\
                     SELECT count(%@) \
                     FROM %@ \
                     WHERE %@ = ? AND \
                     %@ = 0 AND \
                     %@ = 0",
                     COL_LOCAL_ID,
                     entityMainTable,
                     parentEntityMainIdColumn,
                     COL_MAN_DELETED,
                     COL_MAN_IN_CONFLICT];
    qry = mainQueryTransformer(qry);
    NSArray *argsArray = @[[parentEntity localMainIdentifier]];
    argsArray = mainArgsArrayTransformer(argsArray);
    numEntities += [PELMUtils intFromQuery:qry args:argsArray db:db];
  }
  return numEntities;
}

+ (PELMMainSupport *)parentForChildEntity:(PELMMainSupport *)childEntity
                    parentEntityMainTable:(NSString *)parentEntityMainTable
                  parentEntityMasterTable:(NSString *)parentEntityMasterTable
                 parentEntityMainFkColumn:(NSString *)parentEntityMainFkColumn
               parentEntityMasterFkColumn:(NSString *)parentEntityMasterFkColumn
              parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
            parentEntityMasterRsConverter:(entityFromResultSetBlk)parentEntityMasterRsConverter
                     childEntityMainTable:(NSString *)childEntityMainTable
               childEntityMainRsConverter:(entityFromResultSetBlk)childEntityMainRsConverter
                   childEntityMasterTable:(NSString *)childEntityMasterTable
                                       db:(FMDatabase *)db
                                    error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils reloadEntity:childEntity
            fromMainTable:childEntityMainTable
              rsConverter:childEntityMainRsConverter
                       db:db
                    error:errorBlk];
  if ([childEntity localMainIdentifier]) {
    NSString *qry = [NSString stringWithFormat:@"\
SELECT manparent.* \
FROM %@ manparent \
WHERE manparent.%@ IN (SELECT child.%@ \
                       FROM %@ child \
                       WHERE child.%@ = ?)",
                     parentEntityMainTable,
                     COL_LOCAL_ID,
                     parentEntityMainFkColumn,
                     childEntityMainTable,
                     COL_LOCAL_ID];
    PELMMainSupport *mainEntity = [PELMUtils entityFromQuery:qry
                                                 entityTable:parentEntityMainTable
                                               localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMainIdentifier];}
                                                   argsArray:@[[childEntity localMainIdentifier]]
                                                 rsConverter:parentEntityMainRsConverter
                                                          db:db
                                                       error:errorBlk];
    if (mainEntity) {
      if ([mainEntity globalIdentifier]) {
        NSNumber *localMasterIdentifier =
        [PELMUtils numberFromTable:parentEntityMasterTable
                      selectColumn:COL_LOCAL_ID
                       whereColumn:COL_GLOBAL_ID
                        whereValue:[mainEntity globalIdentifier]
                                db:db
                             error:errorBlk];
        if (localMasterIdentifier) {
          [mainEntity setLocalMasterIdentifier:localMasterIdentifier];
        }
      }
    }
    return mainEntity;
  } else if ([childEntity localMasterIdentifier]) {
    NSString *qry = [NSString stringWithFormat:@"\
SELECT masparent.* \
FROM %@ masparent \
WHERE masparent.%@ IN (SELECT child.%@ \
                       FROM %@ child \
                       WHERE child.%@ = ?)",
                     parentEntityMasterTable,
                     COL_LOCAL_ID,
                     parentEntityMasterFkColumn,
                     childEntityMasterTable,
                     COL_LOCAL_ID];
    PELMMainSupport *masterEntity = [PELMUtils entityFromQuery:qry
                                                   entityTable:parentEntityMasterTable
                                                 localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                                     argsArray:@[[childEntity localMasterIdentifier]]
                                                   rsConverter:parentEntityMasterRsConverter
                                                            db:db
                                                         error:errorBlk];
    if (masterEntity) {
      if ([masterEntity globalIdentifier]) {
        NSNumber *localMainIdentifier =
        [PELMUtils numberFromTable:parentEntityMainTable
                      selectColumn:COL_LOCAL_ID
                       whereColumn:COL_GLOBAL_ID
                        whereValue:[masterEntity globalIdentifier]
                                db:db
                             error:errorBlk];
        if (localMainIdentifier) {
          [masterEntity setLocalMainIdentifier:localMainIdentifier];
        }
      }
    }
    return masterEntity;
  } else {
    return nil;
  }
}

+ (NSNumber *)localMainIdentifierForEntity:(PELMModelSupport *)entity
                                 mainTable:(NSString *)mainTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  void (^consistencyCheck)(NSNumber *, NSNumber *) = ^(NSNumber *foundLocalId, NSNumber *localId) {
    if (localId && foundLocalId) {
      if (![foundLocalId isEqualToNumber:localId]) {
        @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:[NSString stringWithFormat:@"Inside \
                        localMainIdentifierForEntity:mainTable:db:error: - found local main ID [%@] is \
                        different from the local main ID [%@] on the in-memory entity with global \
                        ID: [%@].", foundLocalId, localId, [entity globalIdentifier]]
                userInfo:nil];
      }
    }
  };
  NSNumber *foundMainLocalIdentifier = nil;
  if ([entity globalIdentifier]) {
    // our first choice is to lookup the entity by global ID
    foundMainLocalIdentifier = [PELMUtils numberFromTable:mainTable
                                             selectColumn:COL_LOCAL_ID
                                              whereColumn:COL_GLOBAL_ID
                                               whereValue:[entity globalIdentifier]
                                                       db:db
                                                    error:errorBlk];
    // we do this to help weed-out bugs in the design
    consistencyCheck(foundMainLocalIdentifier, [entity localMainIdentifier]);
  }
  if (!foundMainLocalIdentifier) {
    if ([entity localMainIdentifier]) {
      // our second choice is to lookup the entity using its in-memory local main id
      foundMainLocalIdentifier = [PELMUtils numberFromTable:mainTable
                                               selectColumn:COL_LOCAL_ID
                                                whereColumn:COL_LOCAL_ID
                                                 whereValue:[entity localMainIdentifier]
                                                         db:db
                                                      error:errorBlk];
      // we do this to help weed-out bugs in the design
      consistencyCheck(foundMainLocalIdentifier, [entity localMainIdentifier]);
    }
  }
  return foundMainLocalIdentifier;
}

- (void)reloadEntity:(PELMModelSupport *)entity
       fromMainTable:(NSString *)mainTable
         rsConverter:(entityFromResultSetBlk)rsConverter
               error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    [PELMUtils reloadEntity:entity
              fromMainTable:mainTable
                rsConverter:rsConverter
                         db:db
                      error:errorBlk];
  }];
}

+ (void)reloadEntity:(PELMModelSupport *)entity
       fromMainTable:(NSString *)mainTable
         rsConverter:(entityFromResultSetBlk)rsConverter
                  db:db
               error:(PELMDaoErrorBlk)errorBlk {
  NSString *globalIdentifier = [entity globalIdentifier];
  if (globalIdentifier) {
    NSNumber *foundMainLocalIdentifier = [PELMUtils numberFromTable:mainTable
                                                       selectColumn:COL_LOCAL_ID
                                                        whereColumn:COL_GLOBAL_ID
                                                         whereValue:globalIdentifier
                                                                 db:db
                                                              error:errorBlk];
    if (foundMainLocalIdentifier) {
      NSString *qry = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", mainTable, COL_LOCAL_ID];
      PELMModelSupport *foundEntity = [PELMUtils entityFromQuery:qry
                                                     entityTable:mainTable
                                                   localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMainIdentifier];}
                                                       argsArray:@[foundMainLocalIdentifier]
                                                     rsConverter:rsConverter
                                                              db:db
                                                           error:errorBlk];
      if (foundEntity) {
        [entity overwrite:foundEntity];
        [entity setLocalMainIdentifier:[foundEntity localMainIdentifier]];
      }
    }
  }
}

+ (void)copyMasterEntity:(PELMMainSupport *)entity
             toMainTable:(NSString *)mainTable
    mainTableInserterBlk:(void(^)(PELMMasterSupport *))mainTableInserter
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  void (^copyToMainAction)(void) = ^{
    [entity setSynced:YES];
    mainTableInserter(entity);
    [PELMUtils insertRelations:[entity relations]
                     forEntity:entity
                   entityTable:mainTable
               localIdentifier:[entity localMainIdentifier]
                            db:db
                         error:errorBlk];
  };
  NSNumber *foundLocalMainId = [PELMUtils localMainIdentifierForEntity:entity
                                                             mainTable:mainTable
                                                                    db:db
                                                                 error:errorBlk];
  if (!foundLocalMainId) {
    if (![entity globalIdentifier]) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:[NSString stringWithFormat:@"Inside \
copyMasterEntity:toMainTable:..., we couldn't find the main entity associated \
with the in-memory localMainIdentifier in the main table, so the assumption is \
that 'entity' is a master entity, and that we need to copy it into its main \
table.  The problem is, it doesn't have a global ID, so this is bad (i.e., we \
have a consistency violation; our database is in an inconsistent state).  \
Entity: %@", entity]
                                   userInfo:nil];
    }
    copyToMainAction();
  }
}

+ (NSNumber *)masterLocalIdFromEntityTable:(NSString *)masterEntityTable
                          globalIdentifier:(NSString *)globalIdentifier
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils numberFromTable:masterEntityTable
                       selectColumn:COL_LOCAL_ID
                        whereColumn:COL_GLOBAL_ID
                         whereValue:globalIdentifier
                                 db:db
                              error:errorBlk];
}

+ (NSDictionary *)relationsForEntity:(PELMModelSupport *)entity
                         entityTable:(NSString *)entityTable
                     localIdentifier:(NSNumber *)localIdentifier
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *relsTable = [PELMDDL relTableForEntityTable:entityTable];
  NSString *whereColumn = [PELMDDL relFkColumnForEntityTable:entityTable
                                              entityPkColumn:COL_LOCAL_ID];
  NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                     relsTable, whereColumn];
  FMResultSet *rs = [db executeQuery:query
                withArgumentsInArray:@[localIdentifier]];
  NSMutableDictionary *relations = [NSMutableDictionary dictionary];
  while ([rs next]) {
    HCRelation *relation = [PELMUtils relationFromResultSet:rs
                                       subjectResourceModel:entity];
    [relations setObject:relation forKey:[relation name]];
  }
  return relations;
}

+ (void)setRelationsForEntity:(PELMModelSupport *)entity
                  entityTable:(NSString *)entityTable
              localIdentifier:(NSNumber *)localIdentifier
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  [entity setRelations:[PELMUtils relationsForEntity:entity
                                         entityTable:entityTable
                                     localIdentifier:localIdentifier
                                                  db:db
                                               error:errorBlk]];
}

+ (void)updateRelationsForEntity:(PELMModelSupport *)entity
                     entityTable:(NSString *)entityTable
                 localIdentifier:(NSNumber *)localIdentifier
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteRelationsForEntity:entity
                          entityTable:entityTable
                      localIdentifier:localIdentifier
                                   db:db
                                error:errorBlk];
  [PELMUtils insertRelations:[entity relations]
                   forEntity:entity
                 entityTable:entityTable
             localIdentifier:localIdentifier
                          db:db
                       error:errorBlk];
}

+ (void)insertRelations:(NSDictionary *)relations
              forEntity:(PELMModelSupport *)entity
            entityTable:(NSString *)entityTable
        localIdentifier:(NSNumber *)localIdentifier
                     db:(FMDatabase *)db
                  error:(PELMDaoErrorBlk)errorBlk {
  NSString *relsTable = [PELMDDL relTableForEntityTable:entityTable];
  NSString *fkColumn = [PELMDDL relFkColumnForEntityTable:entityTable
                                           entityPkColumn:COL_LOCAL_ID];
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@(%@, %@, %@, %@) \
                    VALUES (?, ?, ?, ?)", relsTable, fkColumn, COL_REL_NAME, COL_REL_URI,
                    COL_REL_MEDIA_TYPE];
  [relations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    HCRelation *relation = (HCRelation *)obj;
    [PELMUtils doUpdate:stmt
              argsArray:@[localIdentifier,
                          [relation name],
                          [[[relation target] uri] absoluteString],
                          [[[relation target] mediaType] description]]
                     db:db
                  error:errorBlk];
  }];
}

- (NSArray *)markEntitiesAsSyncInProgressInMainTable:(NSString *)mainTable
                                          usingQuery:(NSString *)query
                                 entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
                                          updateStmt:(NSString *)updateStmt
                                       updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                                           filterBlk:(BOOL(^)(PELMMainSupport *))filterBlk
                       syncInitiatedNotificationName:(NSString *)syncInitiatedNotificationName
                                               error:(PELMDaoErrorBlk)errorBlk {
  void (^markSyncInProgressAction)(PELMMainSupport *, FMDatabase *) = ^ (PELMMainSupport *entity, FMDatabase *db) {
    [entity setSyncInProgress:YES];
    [PELMUtils doUpdate:updateStmt
              argsArray:updateArgsBlk(entity)
                     db:db
                  error:errorBlk];
    [PELMNotificationUtils postNotificationWithName:syncInitiatedNotificationName
                                             entity:entity];
  };
  __block NSArray *entities = nil;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    entities =
    [PELMUtils mainEntitiesFromQuery:query
                         entityTable:mainTable
                           argsArray:@[]
                         rsConverter:entityFromResultSet
                                  db:db
                               error:errorBlk];
    for (PELMMainSupport *entity in entities) {
      if (![entity editInProgress] && ![entity syncInProgress] && ![entity inConflict] && ![entity synced]) {
        if (filterBlk) {
          if (filterBlk(entity)) {
            markSyncInProgressAction(entity, db);
          }
        } else {
          markSyncInProgressAction(entity, db); // no filter provided, therefore we do action
        }
      }
    }
  }];
  return entities;
}

- (NSArray *)markEntitiesAsSyncInProgressInMainTable:(NSString *)mainTable
                                 entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
                                          updateStmt:(NSString *)updateStmt
                                       updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                       syncInitiatedNotificationName:(NSString *)syncInitiatedNotificationName
                                               error:(PELMDaoErrorBlk)errorBlk {
  return [self markEntitiesAsSyncInProgressInMainTable:mainTable
                                            usingQuery:[NSString stringWithFormat:@"SELECT * FROM %@", mainTable]
                                   entityFromResultSet:entityFromResultSet
                                            updateStmt:updateStmt
                                         updateArgsBlk:updateArgsBlk
                                             filterBlk:nil
                         syncInitiatedNotificationName:syncInitiatedNotificationName
                                                 error:errorBlk];
}

+ (void)assertActualEditActorIdOfEntity:(PELMMainSupport *)entity
                     matchesEditActorId:(NSNumber *)editActorId
                              mainTable:(NSString *)mainTable
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  NSNumber *actualEditActorId = [PELMUtils numberFromTable:mainTable
                                              selectColumn:COL_MAN_EDIT_ACTOR_ID
                                               whereColumn:COL_LOCAL_ID
                                                whereValue:[entity localMainIdentifier]
                                                        db:db
                                                     error:errorBlk];
  if (actualEditActorId) {
    if (![actualEditActorId isEqualToNumber:editActorId]) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:@"The edit actor currently associated with the main entity does not match the edit actor parameter."
                                   userInfo:nil];
    }
  }
}

+ (BOOL)prepareEntityForEdit:(PELMMainSupport *)entity
                          db:(FMDatabase *)db
                   mainTable:(NSString *)mainTable
         entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
          mainEntityInserter:(mainEntityInserterBlk)mainEntityInserter
     editPrepInvariantChecks:(editPrepInvariantChecksBlk)editPrepInvariantChecks
           mainEntityUpdater:(mainEntityUpdaterBlk)mainEntityUpdater
                 editActorId:(NSNumber *)editActorId
           entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
               entityDeleted:(void(^)(void))entityDeletedBlk
            entityInConflict:(void(^)(void))entityInConflictBlk
entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                       error:(PELMDaoErrorBlk)errorBlk {
  void (^actionIfEntityNotInMain)(void) = ^{
    [entity setEditInProgress:YES];
    [entity setSynced:NO];
    [entity setDateCopiedFromMaster:[NSDate date]];
    [entity setEditCount:1];
    [entity setEditActorId:editActorId];
    mainEntityInserter(entity, db, errorBlk);
    [PELMUtils insertRelations:[entity relations]
                     forEntity:entity
                   entityTable:mainTable
               localIdentifier:[entity localMainIdentifier]
                            db:db
                         error:errorBlk];
  };
  void (^actionIfEntityAlreadyInMain)(void) = ^{
    [entity setEditInProgress:YES];
    [entity setSynced:NO];
    [entity setEditActorId:editActorId];
    [entity incrementEditCount];
    mainEntityUpdater(entity, db, errorBlk);
  };
  NSString *(^mainEntityFetchQueryBlk)(NSString *) = ^NSString *(NSString *whereCol) {
    return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", mainTable, whereCol];
  };
  NSString *mainEntityFetchQuery;
  NSArray *mainEntityFetchQueryArgs;
  if ([entity globalIdentifier]) {
    mainEntityFetchQuery = mainEntityFetchQueryBlk(COL_GLOBAL_ID);
    mainEntityFetchQueryArgs = @[[entity globalIdentifier]];
  } else {
    mainEntityFetchQuery = mainEntityFetchQueryBlk(COL_LOCAL_ID);
    mainEntityFetchQueryArgs = @[[entity localMainIdentifier]];
  }
  PELMMainSupport *fetchedEntity = (PELMMainSupport *)
    [PELMUtils entityFromQuery:mainEntityFetchQuery
                   entityTable:mainTable
                 localIdGetter:^NSNumber *(PELMModelSupport *entity) {return [entity localMainIdentifier];}
                     argsArray:mainEntityFetchQueryArgs
                   rsConverter:entityFromResultSet
                            db:db
                         error:errorBlk];
  if (!fetchedEntity) {
    actionIfEntityNotInMain();
  } else {
    [entity setLocalMainIdentifier:[fetchedEntity localMainIdentifier]];
    [entity overwrite:fetchedEntity];
    if ([fetchedEntity syncInProgress]) {
      entityBeingSyncedBlk();
      return NO;
    }
    if ([fetchedEntity editInProgress]) {
      if (![[fetchedEntity editActorId] isEqualToNumber:editActorId]) {
        entityBeingEditedByOtherActorBlk([fetchedEntity editActorId]);
        return NO;
      }
    }
    if ([fetchedEntity deleted]) {
      entityDeletedBlk();
      return NO;
    }
    if ([fetchedEntity inConflict]) {
      entityInConflictBlk();
      return NO;
    }
    actionIfEntityAlreadyInMain();
  }
  return YES;
}

- (BOOL)prepareEntityForEditInTxn:(PELMMainSupport *)entity
                        mainTable:(NSString *)mainTable
              entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
               mainEntityInserter:(mainEntityInserterBlk)mainEntityInserter
          editPrepInvariantChecks:(editPrepInvariantChecksBlk)editPrepInvariantChecks
                mainEntityUpdater:(mainEntityUpdaterBlk)mainEntityUpdater
                      editActorId:(NSNumber *)editActorId
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                    entityDeleted:(void(^)(void))entityDeletedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
    entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                            error:(PELMDaoErrorBlk)errorBlk {
  NSAssert([entity localMainIdentifier], @"Entity does not have a localMainIdentifier.");
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [PELMUtils prepareEntityForEdit:entity
                                 db:db
                          mainTable:mainTable
                entityFromResultSet:entityFromResultSet
                 mainEntityInserter:mainEntityInserter
            editPrepInvariantChecks:editPrepInvariantChecks
                  mainEntityUpdater:mainEntityUpdater
                        editActorId:editActorId
                  entityBeingSynced:entityBeingSyncedBlk
                      entityDeleted:entityDeletedBlk
                   entityInConflict:entityInConflictBlk
      entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                              error:errorBlk];
  }];
  return returnVal;
}

+ (void)invokeError:(PELMDaoErrorBlk)errorBlk db:(FMDatabase *)db {
  errorBlk([db lastError], [db lastErrorCode], [db lastErrorMessage]);
}

+ (void)deleteEntity:(PELMModelSupport *)entity
         entityTable:(NSString *)entityTable
     localIdentifier:(NSNumber *)localIdentifier
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteRelationsForEntity:entity
                          entityTable:entityTable
                      localIdentifier:localIdentifier
                                   db:db
                                error:errorBlk];
  [self deleteFromTable:entityTable
           whereColumns:@[COL_LOCAL_ID]
            whereValues:@[localIdentifier]
                     db:db
                  error:errorBlk];
}

+ (void)deleteRelationsForEntity:(PELMModelSupport *)entity
                     entityTable:(NSString *)entityTable
                 localIdentifier:(NSNumber *)localIdentifier
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  NSString *relsTable = [PELMDDL relTableForEntityTable:entityTable];
  NSString *delWhereColumn = [PELMDDL relFkColumnForEntityTable:entityTable
                                                 entityPkColumn:COL_LOCAL_ID];
  [self deleteFromTable:relsTable
           whereColumns:@[delWhereColumn]
            whereValues:@[localIdentifier]
                     db:db
                  error:errorBlk];
}

+ (void)deleteFromTable:(NSString *)table
           whereColumns:(NSArray *)whereColumns
            whereValues:(NSArray *)whereValues
                     db:(FMDatabase *)db
                  error:(PELMDaoErrorBlk)errorBlk {
  NSMutableString *stmt = [NSMutableString stringWithFormat:@"DELETE FROM %@", table];
  NSUInteger numColumns = [whereColumns count];
  if (numColumns > 0) {
    [stmt appendString:@" WHERE "];
  }
  for (int i = 0; i < numColumns; i++) {
    [stmt appendFormat:@"%@ = ?", [whereColumns objectAtIndex:i]];
    if ((i + 1) < numColumns) {
      [stmt appendString:@" AND "];
    }
  }
  [self doUpdate:stmt argsArray:whereValues db:db error:errorBlk];
}

- (void)deleteFromTableInTxn:(NSString *)table
                whereColumns:(NSArray *)whereColumns
                 whereValues:(NSArray *)whereValues
                       error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils deleteFromTable:table
                  whereColumns:whereColumns
                   whereValues:whereValues
                            db:db
                         error:errorBlk];
  }];
}

+ (void)deleteFromTables:(NSArray *)tables
            whereColumns:(NSArray *)whereColumns
             whereValues:(NSArray *)whereValues
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  for (NSString *table in tables) {
    [self deleteFromTable:table
             whereColumns:whereColumns
              whereValues:whereValues
                       db:db
                    error:errorBlk];
  }
}

- (void)deleteFromTablesInTxn:(NSArray *)tables
                 whereColumns:(NSArray *)whereColumns
                  whereValues:(NSArray *)whereValues
                        error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils deleteFromTables:tables
                   whereColumns:whereColumns
                    whereValues:whereValues
                             db:db
                          error:errorBlk];
  }];
}

+ (void)deleteAllEntities:(NSString *)table
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteFromTable:[PELMDDL relTableForEntityTable:table]
                whereColumns:@[]
                 whereValues:@[]
                          db:db
                       error:errorBlk];
  [PELMUtils deleteFromTable:table
                whereColumns:@[]
                 whereValues:@[]
                          db:db
                       error:errorBlk];
}

- (void)deleteAllEntitiesInTxn:(NSString *)table
                         error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils deleteAllEntities:table db:db error:errorBlk];
  }];
}

- (void)pruneAllSyncedFromMainTables:(NSArray *)tableNames
                    systemPruneCount:(NSInteger)systemPruneCount
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *entityKey = @"entity";
  NSString *tableKey = @"table";
  NSMutableArray *syncedEntitiesDicts = [NSMutableArray array];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    for (NSString *table in tableNames) {
      FMResultSet *rs =
      [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = 1", table, COL_MAN_SYNCED]
               argsArray:@[]
                      db:db
                   error:errorBlk];
      while ([rs next]) {
        [syncedEntitiesDicts addObject:[NSDictionary dictionaryWithObjects:@[toMainSupport(rs, table, nil), table] forKeys:@[entityKey, tableKey]]];
      }
    }
  }];
  for (NSDictionary *syncedEntityDict in syncedEntitiesDicts) {
    PELMMainSupport *syncedEntity = [syncedEntityDict objectForKey:entityKey];
    if ([syncedEntity localMainIdentifier]) { // it shouldn't be possible for localMainIdentifier to be nil here, but, just 'cause
      NSString *table = [syncedEntityDict objectForKey:tableKey];
      [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [PELMUtils deleteRelationsForEntity:syncedEntity
                                entityTable:table
                            localIdentifier:[syncedEntity localMainIdentifier]
                                         db:db
                                      error:errorBlk];
        [PELMUtils doUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", table, COL_LOCAL_ID]
                  argsArray:@[[syncedEntity localMainIdentifier]]
                         db:db
                      error:^ (NSError *err, int code, NSString *msg) {
                        *rollback = YES;
                        LogSystemPrune([NSString stringWithFormat:@"DB error in pruneAllSyncedFromMainTables:error:, received error: [%@] attempting to prune entity: [%@] for main table: [%@].  Rolling back the trasaction (which essentially includes deletion of its relations).", err, syncedEntity, table], systemPruneCount);
                      }];
      }];
    }
  }
}

+ (void)doMainInsert:(NSString *)stmt
           argsArray:(NSArray *)argsArray
              entity:(PELMMainSupport *)entity
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  [self doInsert:stmt
       argsArray:argsArray
          entity:entity
      idAssigner:^(PELMModelSupport *entity, NSNumber *newId) { [entity setLocalMainIdentifier:newId]; }
              db:db
           error:errorBlk];
}

+ (void)doMasterInsert:(NSString *)stmt
             argsArray:(NSArray *)argsArray
                entity:(PELMModelSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  [self doInsert:stmt
       argsArray:argsArray
          entity:entity
      idAssigner:^(PELMModelSupport *entity, NSNumber *newId) { [entity setLocalMasterIdentifier:newId]; }
              db:db
           error:errorBlk];
}

+ (void)doInsert:(NSString *)stmt
       argsArray:(NSArray *)argsArray
          entity:(PELMModelSupport *)entity
      idAssigner:(void(^)(PELMModelSupport *, NSNumber *))idAssigner
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk {
  if ([db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    idAssigner(entity, [NSNumber numberWithLongLong:[db lastInsertRowId]]);
  } else {
    [self invokeError:errorBlk db:db];
  }
}

+(void)doUpdate:(NSString *)stmt
             db:(FMDatabase *)db
          error:(PELMDaoErrorBlk)errorBlk {
  [self doUpdate:stmt argsArray:nil db:db error:errorBlk];
}

+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk {
  if (![db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    [self invokeError:errorBlk db:db];
  }
}

- (void)doUpdateInTxn:(NSString *)stmt
            argsArray:(NSArray *)argsArray
                error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:stmt argsArray:argsArray db:db error:errorBlk];
  }];
}

+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:argsArray];
  if (!rs) {
    [self invokeError:errorBlk db:db];
  }
  return rs;
}

+ (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
          rsConverter:(entityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  return [self entityFromQuery:query
                   entityTable:entityTable
                 localIdGetter:localIdGetter
                     argsArray:@[]
                   rsConverter:rsConverter
                            db:db
                         error:errorBlk];
}

+ (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
            argsArray:(NSArray *)argsArray
          rsConverter:(entityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  id entity = nil;
  FMResultSet *rs = [self doQuery:query
                        argsArray:argsArray
                               db:db
                            error:errorBlk];
  if (rs) { while ([rs next]) { entity = rsConverter(rs); } }
  if (entity) {
    [PELMUtils setRelationsForEntity:entity
                         entityTable:entityTable
                     localIdentifier:localIdGetter(entity)
                                  db:db
                               error:errorBlk];
  }
  return entity;
}

- (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
          rsConverter:(entityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk {
  return [self entityFromQuery:query
                   entityTable:entityTable
                 localIdGetter:localIdGetter
                     argsArray:@[]
                   rsConverter:rsConverter
                         error:errorBlk];
}

- (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
            argsArray:(NSArray *)argsArray
          rsConverter:(entityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk {
  __block id entity = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    entity = [PELMUtils entityFromQuery:query
                            entityTable:entityTable
                          localIdGetter:localIdGetter
                              argsArray:argsArray
                            rsConverter:rsConverter
                                     db:db
                                  error:errorBlk];
  }];
  return entity;
}

+ (NSArray *)mainEntitiesFromQuery:(NSString *)query
                       entityTable:(NSString *)entityTable
                         argsArray:(NSArray *)argsArray
                       rsConverter:(entityFromResultSetBlk)rsConverter
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils mainEntitiesFromQuery:query
                               numAllowed:nil
                              entityTable:entityTable
                                argsArray:argsArray
                              rsConverter:rsConverter
                                       db:db
                                    error:errorBlk];
}

+ (NSArray *)masterEntitiesFromQuery:(NSString *)query
                         entityTable:(NSString *)entityTable
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils masterEntitiesFromQuery:query
                                 numAllowed:nil
                                entityTable:entityTable
                                  argsArray:argsArray
                                rsConverter:rsConverter
                                         db:db
                                      error:errorBlk];
}

+ (NSArray *)mainEntitiesFromQuery:(NSString *)query
                        numAllowed:(NSNumber *)numAllowed
                       entityTable:(NSString *)entityTable
                         argsArray:(NSArray *)argsArray
                       rsConverter:(entityFromResultSetBlk)rsConverter
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:query
                           numAllowed:numAllowed
                          entityTable:entityTable
                        localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMainIdentifier]; }
                            argsArray:argsArray
                          rsConverter:rsConverter
                                   db:db
                                error:errorBlk];
}

+ (NSArray *)masterEntitiesFromQuery:(NSString *)query
                          numAllowed:(NSNumber *)numAllowed
                         entityTable:(NSString *)entityTable
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:query
                           numAllowed:numAllowed
                          entityTable:entityTable
                        localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                            argsArray:argsArray
                          rsConverter:rsConverter
                                   db:db
                                error:errorBlk];
}

+ (NSArray *)entitiesFromQuery:(NSString *)query
                    numAllowed:(NSNumber *)numAllowed
                   entityTable:(NSString *)entityTable
                 localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
                     argsArray:(NSArray *)argsArray
                   rsConverter:(entityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *entities = [NSMutableArray array];
  FMResultSet *rs = [self doQuery:query argsArray:argsArray db:db error:errorBlk];
  if (rs) {
    int count = 0;
    while ([rs next]) {
      if (numAllowed && (count == [numAllowed intValue])) {
        [rs close];
        break;
      }
      [entities addObject:rsConverter(rs)];
      count++;
    }
  }
  for (PELMModelSupport *entity in entities) {
    [PELMUtils setRelationsForEntity:entity
                         entityTable:entityTable
                     localIdentifier:localIdGetter(entity)
                                  db:db
                               error:errorBlk];
  }
  return entities;
}

+ (NSArray *)entitiesFromEntityTable:(NSString *)entityTable
                         whereClause:(NSString *)whereClause
                       localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",
                     entityTable, whereClause];
  return [PELMUtils entitiesFromQuery:query
                           numAllowed:nil
                          entityTable:entityTable
                        localIdGetter:localIdGetter
                            argsArray:argsArray
                          rsConverter:rsConverter
                                   db:db
                                error:errorBlk];
}

#pragma mark - Result set -> Model helpers (private)

+ (HCRelation *)relationFromResultSet:(FMResultSet *)rs
                 subjectResourceModel:(PELMModelSupport *)subjectResourceModel {
  HCResource *subjectResource =
  [[HCResource alloc]
   initWithMediaType:[subjectResourceModel mediaType]
   uri:[NSURL URLWithString:[subjectResourceModel globalIdentifier]]];
  HCResource *targetResource =
  [[HCResource alloc]
   initWithMediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_REL_MEDIA_TYPE]]
   uri:[NSURL URLWithString:[rs stringForColumn:COL_REL_URI]]];
  return [[HCRelation alloc]
          initWithName:[rs stringForColumn:COL_REL_NAME]
          subjectResource:subjectResource
          targetResource:targetResource];
}

#pragma mark - Helpers

+ (NSDateFormatter *)sqliteDateFormatter {
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy/MM/dd hh:mm:ss"];
  return dateFormat;
}

+ (NSString *)sqliteTextFromDate:(NSDate *)date {
  if (date) {
    return [[PELMUtils sqliteDateFormatter] stringFromDate:date];
  }
  return nil;
}

+ (NSDate *)dateFromSqliteText:(NSString *)dateText {
  if (dateText) {
    return [[PELMUtils sqliteDateFormatter] dateFromString:dateText];
  }
  return nil;
}

+ (NSInteger)intFromQuery:(NSString *)query args:(NSArray *)args db:(FMDatabase *)db {
  NSInteger num = 0;
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:args];
  while ([rs next]) {
    num = [rs intForColumnIndex:0];
  }
  return num;
}

- (NSNumber *)numEntitiesFromTable:(NSString *)table
                             error:(PELMDaoErrorBlk)errorBlk {
  __block NSNumber *numEntities = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", table]];
    while ([rs next]) {
      numEntities = [NSNumber numberWithInt:[rs intForColumnIndex:0]];
    }
  }];
  return numEntities;
}

- (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils numberFromTable:table
                           selectColumn:selectColumn
                            whereColumn:whereColumn
                             whereValue:whereValue
                                     db:db
                                  error:errorBlk];
  }];
  return value;
}

+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils valueFromTable:table
                      selectColumn:selectColumn
                       whereColumn:whereColumn
                        whereValue:whereValue
                       rsExtractor:^id(FMResultSet *rs, NSString *selectColum){return [NSNumber numberWithInt:[rs intForColumn:selectColumn]];}
                                db:db
                             error:errorBlk];
}

- (NSNumber *)boolFromTable:(NSString *)table
               selectColumn:(NSString *)selectColumn
                whereColumn:(NSString *)whereColumn
                 whereValue:(id)whereValue
                      error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils boolFromTable:table
                         selectColumn:selectColumn
                          whereColumn:whereColumn
                           whereValue:whereValue
                                   db:db
                                error:errorBlk];
  }];
  return value;
}

+ (NSNumber *)boolFromTable:(NSString *)table
               selectColumn:(NSString *)selectColumn
                whereColumn:(NSString *)whereColumn
                 whereValue:(id)whereValue
                         db:(FMDatabase *)db
                      error:(PELMDaoErrorBlk)errorBlk {
  id (^rsExtractor)(FMResultSet *, NSString *) = ^ id (FMResultSet *rs, NSString *selectColum) {
    return [NSNumber numberWithBool:[rs boolForColumn:selectColum]];
  };
  return [self valueFromTable:table
                 selectColumn:selectColumn
                  whereColumn:whereColumn
                   whereValue:whereValue
                  rsExtractor:rsExtractor
                           db:db
                        error:errorBlk];
}



- (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils stringFromTable:table
                           selectColumn:selectColumn
                            whereColumn:whereColumn
                             whereValue:whereValue
                                     db:db
                                  error:errorBlk];
  }];
  return value;
}

+ (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [self valueFromTable:table
                 selectColumn:selectColumn
                  whereColumn:whereColumn
                   whereValue:whereValue
                  rsExtractor:^id(FMResultSet *rs,NSString *selectColum){return [rs stringForColumn:selectColumn];}
                           db:db
                        error:errorBlk];
}

+ (id)valueFromTable:(NSString *)table
        selectColumn:(NSString *)selectColumn
         whereColumn:(NSString *)whereColumn
          whereValue:(id)whereValue
         rsExtractor:(id(^)(FMResultSet *, NSString *))rsExtractor
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  id value = nil;
  FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", selectColumn, table, whereColumn]
                withArgumentsInArray:@[whereValue]];
  while ([rs next]) {
    value = rsExtractor(rs, selectColumn);
  }
  return value;
}

#pragma mark - Invariant-violation checkers (private)

+ (void)readyForSyncEntityInvariantChecks:(PELMMainSupport *)mainEntity {
  NSAssert(![mainEntity editInProgress], @"Entity is currently in edit-in-progress mode.");
  NSAssert(![mainEntity synced], @"Entity is currently marked as 'synced.'");
  NSAssert(![mainEntity syncInProgress], @"Entity is currently already marked as 'sync-in-progress.'");
}

+ (void)saveEntityInvariantChecks:(PELMMainSupport *)mainEntity {
  NSAssert([mainEntity localMainIdentifier], @"Entity does not currently have a localMainIdentifier value.");
  NSAssert([mainEntity editInProgress], @"Entity is not currently in edit-in-progress mode.");
  NSAssert(![mainEntity synced], @"Entity is currently marked as 'synced.'");
  NSAssert(![mainEntity syncInProgress], @"Entity is currently marked as 'sync-in-progress.'");
  NSAssert(![mainEntity deleted], @"Entity is currently marked as 'deleted.'");
}

/*+ (void)prepareEntityForEditInvariantChecks:(PELMMainSupport *)mainEntity {
  NSAssert(![mainEntity syncInProgress], @"Entity sync is in progress.");
  NSAssert(![mainEntity deleted], @"Entity is marked as deleted.");
  NSAssert(![mainEntity inConflict], @"Entity is marked as in-conflict.");
}*/

+ (void)newEntityInsertionInvariantChecks:(PELMMainSupport *)mainEntity {
  NSAssert(![mainEntity editInProgress], @"editInProgress is YES");
  NSAssert(![mainEntity synced], @"synced is YES");
  NSAssert([mainEntity localMainIdentifier] == nil, @"localMainIdentifier is not nil");
  NSAssert(![mainEntity syncInProgress], @"syncInProgress is YES");
}

+ (void)forEditPreparationFoundMainModelSupport:(PELMModelSupport *)mainModelSupport
                          mustMatchModelSupport:(PELMModelSupport *)modelSupport {
  /*  cannotBe(![PEUtils isNumber:[mainModelSupport localIdentifier]
   equalTo:[modelSupport localIdentifier]],
   @"Cannot prepare instance for edit if its 'localIdentifier' propery differs \
   from the instance found in main store");
   cannotBe(![PEUtils isString:[mainModelSupport globalIdentifier]
   equalTo:[modelSupport globalIdentifier]],
   @"Cannot prepare instance for edit if its 'globalIdentifier' propery differs \
   from the instance found in main store");*/
}

+ (void)forEditPreparationFoundMainMainSupport:(PELMMainSupport *)mainMainSupport
                      mustMatchMainMainSupport:(PELMMainSupport *)mainSupport {
  [self forEditPreparationFoundMainModelSupport:mainMainSupport
                          mustMatchModelSupport:mainSupport];
  cannotBe([mainMainSupport syncInProgress], @"Cannot prepare user for edit if sync is in progress.");
  cannotBe([mainMainSupport inConflict], @"Cannot prepare user for edit if marked as in-conflict.");
  cannotBe([mainMainSupport deleted], @"Cannot prepare user for edit if marked as deleted.");
}

@end