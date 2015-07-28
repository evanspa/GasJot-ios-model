//
//  PELMUtils.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMResultSet.h>
#import <PEHateoas-Client/HCAuthentication.h>
#import "PELMMainSupport.h"

/**
 Param 1 (NSString *): New authentication token.
 Param 2 (NSString *): The global identifier of the newly created resource, in
 the event the request was a POST to create a resource.  If the request was not
 a POST to create a resource, this parameter may be nil.
 Param 3 (id): Resource returned in the response (in the case of a GET or a
 PUT).  This parameter may be nil.
 Param 4 (NSDictionary *): The relations associated with the subject-resource
 Param 5 (NSDate *): The last-modified date of the subject-resource of the HTTP request (this response-header should be present on ALL 2XX responses)
 Param 6 (BOOL): Whether or not the subject-resource is gone (existed at one point, but has since been deleted).
 Param 7 (BOOL): Whether or not the subject-resource is not-found (i.e., never exists).
 Param 8 (BOOL): Whether or not the subject-resource has permanently moved
 Param 9 (BOOL): Whether or not the subject-resource has not been modified based on conditional-fetch criteria
 Param 10 (NSError *): Encapsulates error information in the event of an error.
 Param 11 (NSHTTPURLResponse *): The raw HTTP response.
 */
typedef void (^PELMRemoteMasterCompletionHandler)(NSString *, // auth token
                                                NSString *, // global URI (location) (in case of moved-permenantly, will be new location of resource)
                                                id,         // resource returned in response (in case of 409, will be master's copy of subject-resource)
                                                NSDictionary *, // resource relations
                                                NSDate *,   // last modified date
                                                BOOL,       // is conflict (if YES, then id param will be latest version of result)
                                                BOOL,       // gone
                                                BOOL,       // not found
                                                BOOL,       // moved permanently
                                                BOOL,       // not modified
                                                NSError *,  // error
                                                NSHTTPURLResponse *); // raw HTTP response

typedef void (^PELMRemoteMasterBusyBlk)(NSDate *);

typedef void (^PELMRemoteMasterAuthReqdBlk)(HCAuthentication *);

typedef void (^PELMRemoteMasterDeletionBlk)(PELMRemoteMasterBusyBlk,
                                            PELMRemoteMasterAuthReqdBlk,
                                            PELMRemoteMasterCompletionHandler);

typedef void (^PELMRemoteMasterSaveBlk)(PELMRemoteMasterBusyBlk,
                                        PELMRemoteMasterAuthReqdBlk,
                                        PELMRemoteMasterCompletionHandler);

typedef void (^PELMDaoErrorBlk)(NSError *, int, NSString *);

typedef NSDictionary * (^relationsFromResultSetBlk)(FMResultSet *);

typedef id (^entityFromResultSetBlk)(FMResultSet *);

typedef void (^editPrepInvariantChecksBlk)(PELMMainSupport *, PELMMainSupport *);

typedef void (^mainEntityInserterBlk)(PELMMainSupport *, FMDatabase *, PELMDaoErrorBlk);

typedef void (^mainEntityUpdaterBlk)(PELMMainSupport *, FMDatabase *, PELMDaoErrorBlk);

void (^cannotBe)(BOOL, NSString *);

id (^orNil)(id);

void (^LogSyncRemoteMaster)(NSString *, NSInteger);

void (^LogSystemPrune)(NSString *, NSInteger);

void (^LogSyncLocal)(NSString *, NSInteger);

@interface PELMUtils : NSObject

#pragma mark - Initializers

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue;

#pragma mark - Syncing and Deleting

+ (void)flushUnsyncedChangesToEntity:(PELMMainSupport *)entity
                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                 remoteStoreErrorBlk:(void(^)(PELMMainSupport *, NSError *, NSNumber *))remoteStoreErrorBlk
                   markAsConflictBlk:(void(^)(id))markAsConflictBlk
   markAsSyncCompleteForNewEntityBlk:(void(^)(PELMMainSupport *))markAsSyncCompleteForNewEntityBlk
markAsSyncCompleteForExistingEntityBlk:(void(^)(PELMMainSupport *))markAsSyncCompleteForExistingEntityBlk
                 authRequiredHandler:(PELMRemoteMasterAuthReqdBlk)authRequiredHandler
                     newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk
              remoteMasterSaveNewBlk:(PELMRemoteMasterSaveBlk)remoteMasterSaveNewBlk
         remoteMasterSaveExistingBlk:(PELMRemoteMasterSaveBlk)remoteMasterSaveExistingBlk
               localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrHandler;

+ (void)deleteEntity:(PELMMainSupport *)entity
  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
 remoteStoreErrorBlk:(void(^)(PELMMainSupport *, NSError *, NSNumber *))remoteStoreErrorBlk
   markAsConflictBlk:(void(^)(id))markAsConflictBlk
   deleteCompleteBlk:(void(^)(void))markAsSyncCompleteForNewEntityBlk
 authRequiredHandler:(PELMRemoteMasterAuthReqdBlk)authRequiredHandler
     newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk
remoteMasterDeleteBlk:(PELMRemoteMasterDeletionBlk)remoteMasterDeleteBlk
localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrHandler;

+ (void)cancelSyncInProgressForEntityTable:(NSString *)mainEntityTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)error;

#pragma mark - Result Set Helpers

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs
                       columnName:(NSString *)columnName;

+ (NSDecimalNumber *)decimalNumberFromResultSet:(FMResultSet *)rs
                                     columnName:(NSString *)columnName;

+ (NSDate *)dateFromResultSet:(FMResultSet *)rs
                   columnName:(NSString *)columnName;

#pragma mark - Properties

@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

#pragma mark - Utils

- (void)cancelSyncForEntity:(PELMMainSupport *)entity
               httpRespCode:(NSNumber *)httpRespCode
                  errorMask:(NSNumber *)errorMask
                    retryAt:(NSDate *)retryAt
             mainUpdateStmt:(NSString *)mainUpdateStmt
          mainUpdateArgsBlk:(NSArray *(^)(PELMMainSupport *))mainUpdateArgsBlk
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEntity:(PELMMainSupport *)entity
                 mainTable:(NSString *)mainTable
               masterTable:(NSString *)masterTable
               rsConverter:(entityFromResultSetBlk)rsConverter
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEntity:(PELMMainSupport *)entity
         mainTable:(NSString *)mainTable
    mainUpdateStmt:(NSString *)mainUpdateStmt
 mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEntity:(PELMMainSupport *)entity
                      mainTable:(NSString *)mainTable
                 mainUpdateStmt:(NSString *)mainUpdateStmt
              mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncEntity:(PELMMainSupport *)entity
                                   mainTable:(NSString *)mainTable
                              mainUpdateStmt:(NSString *)mainUpdateStmt
                           mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                                       error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewEntity:(PELMMainSupport *)entity
                             mainTable:(NSString *)mainTable
                           masterTable:(NSString *)masterTable
                        mainUpdateStmt:(NSString *)mainUpdateStmt
                     mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                 error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedEntityInTxn:(PELMMainSupport *)entity
                                      mainTable:(NSString *)mainTable
                                    masterTable:(NSString *)masterTable
                                 mainUpdateStmt:(NSString *)mainUpdateStmt
                              mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                               masterUpdateStmt:(NSString *)masterUpdateStmt
                            masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedEntity:(PELMMainSupport *)entity
                                 mainTable:(NSString *)mainTable
                               masterTable:(NSString *)masterTable
                            mainUpdateStmt:(NSString *)mainUpdateStmt
                         mainUpdateArgsBlk:(NSArray *(^)(id))mainUpdateArgsBlk
                          masterUpdateStmt:(NSString *)masterUpdateStmt
                       masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)entitiesForParentEntity:(PELMModelSupport *)parentEntity
               parentEntityMainTable:(NSString *)parentEntityMainTable
         parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
          parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
            parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                            pageSize:(NSNumber *)pageSize
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
                               error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)unsyncedEntitiesForParentEntity:(PELMModelSupport *)parentEntity
                       parentEntityMainTable:(NSString *)parentEntityMainTable
                 parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
                  parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
                    parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                           entityMasterTable:(NSString *)entityMasterTable
              masterEntityResultSetConverter:(entityFromResultSetBlk)masterEntityResultSetConverter
                             entityMainTable:(NSString *)entityMainTable
                mainEntityResultSetConverter:(entityFromResultSetBlk)mainEntityResultSetConverter
                           comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                         orderByDomainColumn:(NSString *)orderByDomainColumn
                orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                          db:(FMDatabase *)db
                                       error:(PELMDaoErrorBlk)errorBlk;

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
                   comparatorForSort:(NSComparisonResult(^)(id, id))comparatorForSort
                 orderByDomainColumn:(NSString *)orderByDomainColumn
        orderByDomainColumnDirection:(NSString *)orderByDomainColumnDirection
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk;

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
                               error:(PELMDaoErrorBlk)errorBlk;

+ (NSInteger)numEntitiesForParentEntity:(PELMModelSupport *)parentEntity
                  parentEntityMainTable:(NSString *)parentEntityMainTable
            parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
             parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdColumn
               parentEntityMainIdColumn:(NSString *)parentEntityMainIdColumn
                      entityMasterTable:(NSString *)entityMasterTable
                        entityMainTable:(NSString *)entityMainTable
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk;

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
                                  error:(PELMDaoErrorBlk)errorBlk;

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
                                    error:(PELMDaoErrorBlk)errorBlk;

+ (NSNumber *)localMainIdentifierForEntity:(PELMModelSupport *)entity
                                 mainTable:(NSString *)mainTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEntity:(PELMModelSupport *)entity
       fromMainTable:(NSString *)mainTable
         rsConverter:(entityFromResultSetBlk)rsConverter
               error:(PELMDaoErrorBlk)errorBlk;

+ (void)copyMasterEntity:(PELMMainSupport *)entity
             toMainTable:(NSString *)mainTable
    mainTableInserterBlk:(void(^)(PELMMasterSupport *))mainTableInserter
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk;

+ (NSNumber *)masterLocalIdFromEntityTable:(NSString *)masterEntityTable
                          globalIdentifier:(NSString *)globalIdentifier
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk;

+ (NSDictionary *)relationsForEntity:(PELMModelSupport *)entity
                         entityTable:(NSString *)entityTable
                     localIdentifier:(NSNumber *)localIdentifier
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk;

+ (void)setRelationsForEntity:(PELMModelSupport *)entity
                  entityTable:(NSString *)entityTable
              localIdentifier:(NSNumber *)localIdentifier
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

+ (void)updateRelationsForEntity:(PELMModelSupport *)entity
                     entityTable:(NSString *)entityTable
                 localIdentifier:(NSNumber *)localIdentifier
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk;

+ (void)insertRelations:(NSDictionary *)relations
              forEntity:(PELMModelSupport *)entity
            entityTable:(NSString *)entityTable
        localIdentifier:(NSNumber *)localIdentifier
                     db:(FMDatabase *)db
                  error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEntitiesAsSyncInProgressInMainTable:(NSString *)mainTable
                                          usingQuery:(NSString *)query
                                 entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
                                          updateStmt:(NSString *)updateStmt
                                       updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                                           filterBlk:(BOOL(^)(PELMMainSupport *))filterBlk
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEntitiesAsSyncInProgressInMainTable:(NSString *)mainTable
                                 entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
                                          updateStmt:(NSString *)updateStmt
                                       updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                                               error:(PELMDaoErrorBlk)errorBlk;

+ (BOOL)prepareEntityForEdit:(PELMMainSupport *)entity
                          db:(FMDatabase *)db
                   mainTable:(NSString *)mainTable
         entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
          mainEntityInserter:(mainEntityInserterBlk)mainEntityInserter
     editPrepInvariantChecks:(editPrepInvariantChecksBlk)editPrepInvariantChecks
           mainEntityUpdater:(mainEntityUpdaterBlk)mainEntityUpdater
           entityBeingSynced:(void(^)(void))entityBeingSynced
            entityInConflict:(void(^)(void))entityInConflict
                       error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareEntityForEditInTxn:(PELMMainSupport *)entity
                        mainTable:(NSString *)mainTable
              entityFromResultSet:(entityFromResultSetBlk)entityFromResultSet
               mainEntityInserter:(mainEntityInserterBlk)mainEntityInserter
          editPrepInvariantChecks:(editPrepInvariantChecksBlk)editPrepInvariantChecks
                mainEntityUpdater:(mainEntityUpdaterBlk)mainEntityUpdater
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
                            error:(PELMDaoErrorBlk)errorBlk;

+ (void)invokeError:(PELMDaoErrorBlk)errorBlk db:(FMDatabase *)db;

+ (void)deleteEntity:(PELMModelSupport *)entity
     entityMainTable:(NSString *)entityMainTable
   entityMasterTable:(NSString *)entityMasterTable
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk;

+ (void)deleteRelationsFromEntityTable:(NSString *)entityTable
                       localIdentifier:(NSNumber *)localIdentifier
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk;

- (void)pruneAllSyncedFromMainTables:(NSArray *)tableNames
                               error:(PELMDaoErrorBlk)errorBlk;

+ (void)doMainInsert:(NSString *)stmt
           argsArray:(NSArray *)argsArray
              entity:(PELMMainSupport *)entity
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk;

+ (void)doMasterInsert:(NSString *)stmt
             argsArray:(NSArray *)argsArray
                entity:(PELMModelSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk;

+ (void)doUpdate:(NSString *)stmt
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk;

+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk;

- (void)doUpdateInTxn:(NSString *)stmt
            argsArray:(NSArray *)argsArray
                error:(PELMDaoErrorBlk)errorBlk;

+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk;

+ (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
          rsConverter:(entityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk;

+ (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
            argsArray:(NSArray *)argsArray
          rsConverter:(entityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk;

- (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
          rsConverter:(entityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk;

- (id)entityFromQuery:(NSString *)query
          entityTable:(NSString *)entityTable
        localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
            argsArray:(NSArray *)argsArray
          rsConverter:(entityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)mainEntitiesFromQuery:(NSString *)query
                       entityTable:(NSString *)entityTable
                         argsArray:(NSArray *)argsArray
                       rsConverter:(entityFromResultSetBlk)rsConverter
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)masterEntitiesFromQuery:(NSString *)query
                         entityTable:(NSString *)entityTable
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)mainEntitiesFromQuery:(NSString *)query
                        numAllowed:(NSNumber *)numAllowed
                       entityTable:(NSString *)entityTable
                         argsArray:(NSArray *)argsArray
                       rsConverter:(entityFromResultSetBlk)rsConverter
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)masterEntitiesFromQuery:(NSString *)query
                          numAllowed:(NSNumber *)numAllowed
                         entityTable:(NSString *)entityTable
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)entitiesFromQuery:(NSString *)query
                    numAllowed:(NSNumber *)numAllowed
                   entityTable:(NSString *)entityTable
                 localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
                     argsArray:(NSArray *)argsArray
                   rsConverter:(entityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)entitiesFromEntityTable:(NSString *)entityTable
                         whereClause:(NSString *)whereClause
                       localIdGetter:(NSNumber *(^)(PELMModelSupport *))localIdGetter
                           argsArray:(NSArray *)argsArray
                         rsConverter:(entityFromResultSetBlk)rsConverter
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Helpers

- (NSInteger)numEntitiesFromTable:(NSString *)table
                            error:(PELMDaoErrorBlk)errorBlk;

+ (NSInteger)numEntitiesFromTable:(NSString *)table
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Invariant-violation checkers (private)

+ (void)readyForSyncEntityInvariantChecks:(PELMMainSupport *)mainEntity;

+ (void)saveEntityInvariantChecks:(PELMMainSupport *)mainEntity;

//+ (void)prepareEntityForEditInvariantChecks:(PELMMainSupport *)mainEntity;

+ (void)newEntityInsertionInvariantChecks:(PELMMainSupport *)mainEntity;

+ (void)forEditPreparationFoundMainModelSupport:(PELMModelSupport *)mainModelSupport
                          mustMatchModelSupport:(PELMModelSupport *)modelSupport;

+ (void)forEditPreparationFoundMainMainSupport:(PELMMainSupport *)mainMainSupport
                      mustMatchMainMainSupport:(PELMMainSupport *)mainSupport;

@end
