//
//  FPLocalDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPLocalDao.h"
#import "FPDDLUtils.h"
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <CocoaLumberjack/DDLog.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEObjc-Commons/NSString+PEAdditions.h>
#import "PELMNotificationUtils.h"
#import "FPLogging.h"

uint32_t const FP_REQUIRED_SCHEMA_VERSION = 2;

@implementation FPLocalDao

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath {
  self = [super init];
  if (self) {
    _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:sqliteDataFilePath];
    _localModelUtils = [[PELMUtils alloc] initWithDatabaseQueue:_databaseQueue];
    [_databaseQueue inDatabase:^(FMDatabase *db) {
      // for some reason, this has to be done in a "inDatabase" block for it to
      // work.  I guess we'll just assume that FKs are enabled as a universal
      // truth of the system, regardless of 'required schema version' val.
      [db executeUpdate:@"PRAGMA foreign_keys = ON"];
    }];
  }
  return self;
}

#pragma mark - Initialize Database

- (void)initializeDatabaseWithError:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    uint32_t currentSchemaVersion = [db userVersion];
    DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, currentSchemaVersion: %d.  \
Required schema version: %d.", currentSchemaVersion, FP_REQUIRED_SCHEMA_VERSION);
    switch (currentSchemaVersion) {
      case 0: // will occur on very first startup of the app on user's device
        [self applyVersion0SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 0 (initial).");
        // fall-through to apply "next" schema updates
      case 1:
        [self applyVersion1SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in FPLocalDao/initializeDatabaseWithError:, applied schema updates for version 1.");
      case FP_REQUIRED_SCHEMA_VERSION:
        // great, nothing needed to do except update the db's schema version
        [db setUserVersion:FP_REQUIRED_SCHEMA_VERSION];
        break;
    }
  }];
}

#pragma mark - Schema version: FUTURE VERSION

#pragma mark - Schema version: version 1

- (void)applyVersion1SchemaEditsWithDb:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT", TBL_MAIN_FUEL_STATION, COL_FUELST_STREET]
                   db:db
                error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT", TBL_MASTER_FUEL_STATION, COL_FUELST_STREET]
                   db:db
                error:errorBlk];
}

#pragma mark - Schema edits, version: 0 (initial schema version)

- (void)applyVersion0SchemaEditsWithDb:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  void (^applyDDL)(NSString *) = ^ (NSString *ddl) {
    [PELMUtils doUpdate:ddl db:db error:errorBlk];
  };
  void (^makeRelTable)(NSString *) = ^ (NSString *table) {
    applyDDL([PELMDDL relDDLForEntityTable:table]);
  };
  void (^makeIndex)(NSString *, NSString *, NSString *) = ^(NSString *entity, NSString *col, NSString *name) {
    applyDDL([PELMDDL indexDDLForEntity:entity unique:NO column:col indexName:name]);
  };
  
  // ###########################################################################
  // User DDL
  // ###########################################################################
  // ------- master user -------------------------------------------------------
  applyDDL([FPDDLUtils masterUserDDL]);
  makeRelTable(TBL_MASTER_USER);
  // ------- main vehicle ------------------------------------------------------
  applyDDL([FPDDLUtils mainUserDDL]);
  applyDDL([FPDDLUtils mainUserUniqueIndex1]);
  makeRelTable(TBL_MAIN_USER);
  
  // ###########################################################################
  // Vehicle DDL
  // ###########################################################################
  // ------- master vehicle ----------------------------------------------------
  applyDDL([FPDDLUtils masterVehicleDDL]);
  applyDDL([FPDDLUtils masterVehicleUniqueIndex1]);
  makeIndex(TBL_MASTER_VEHICLE, COL_MST_UPDATED_AT, @"idx_mstr_veh_dt_updated");
  makeRelTable(TBL_MASTER_VEHICLE);
  // ------- main vehicle ------------------------------------------------------
  applyDDL([FPDDLUtils mainVehicleDDL]);
  applyDDL([FPDDLUtils mainVehicleUniqueIndex1]);
  makeRelTable(TBL_MAIN_VEHICLE);
  
  // ###########################################################################
  // Fuel Station DDL
  // ###########################################################################
  // ------- master fuel station -----------------------------------------------
  applyDDL([FPDDLUtils masterFuelStationDDL]);
  makeIndex(TBL_MASTER_FUEL_STATION, COL_MST_UPDATED_AT, @"idx_mstr_fs_dt_updated");
  makeRelTable(TBL_MASTER_FUEL_STATION);
  // ------- main fuel station -------------------------------------------------
  applyDDL([FPDDLUtils mainFuelStationDDL]);
  makeRelTable(TBL_MAIN_FUEL_STATION);
  
  // ###########################################################################
  // Fuel Purchase Log DDL
  // ###########################################################################
  // ------- master fuel purchase log ------------------------------------------
  applyDDL([FPDDLUtils masterFuelPurchaseLogDDL]);
  makeIndex(TBL_MASTER_FUELPURCHASE_LOG, COL_FUELPL_PURCHASED_AT, @"idx_mstr_fplog_log_dt");
  makeRelTable(TBL_MASTER_FUELPURCHASE_LOG);
  // ------- main fuel purchase log ------------------------------------------
  applyDDL([FPDDLUtils mainFuelPurchaseLogDDL]);
  makeIndex(TBL_MAIN_FUELPURCHASE_LOG, COL_FUELPL_PURCHASED_AT, @"idx_man_fplog_log_dt");
  makeRelTable(TBL_MAIN_FUELPURCHASE_LOG);
  
  // ###########################################################################
  // Environment Log DDL
  // ###########################################################################
  // ------- master environment log --------------------------------------------
  applyDDL([FPDDLUtils masterEnvironmentLogDDL]);
  makeIndex(TBL_MASTER_ENV_LOG, COL_ENVL_LOG_DT, @"idx_mstr_envlog_log_dt");
  makeRelTable(TBL_MASTER_ENV_LOG);
  // ------- main environment log ----------------------------------------------
  applyDDL([FPDDLUtils mainEnvironmentDDL]);
  makeIndex(TBL_MAIN_ENV_LOG, COL_ENVL_LOG_DT, @"idx_man_envlog_log_dt");
  makeRelTable(TBL_MAIN_ENV_LOG);
}

#pragma mark - System functions

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils pruneAllSyncedFromMainTables:@[TBL_MAIN_ENV_LOG,
                                                   TBL_MAIN_FUELPURCHASE_LOG,
                                                   TBL_MAIN_VEHICLE,
                                                   TBL_MAIN_FUEL_STATION,
                                                   TBL_MAIN_USER]
                                           error:errorBlk];
}

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils cancelSyncInProgressForEntityTable:TBL_MAIN_USER db:db error:error];
    [PELMUtils cancelSyncInProgressForEntityTable:TBL_MAIN_VEHICLE db:db error:error];
    [PELMUtils cancelSyncInProgressForEntityTable:TBL_MAIN_FUEL_STATION db:db error:error];
    [PELMUtils cancelSyncInProgressForEntityTable:TBL_MAIN_FUELPURCHASE_LOG db:db error:error];
    [PELMUtils cancelSyncInProgressForEntityTable:TBL_MAIN_ENV_LOG db:db error:error];
  }];
}

#pragma mark - User

- (NSDate *)mostRecentMasterUpdateForUser:(FPUser *)user
                                    error:(PELMDaoErrorBlk)errorBlk {
  __block NSDate *overallMostRecent = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    NSDate *(^mostRecentDate)(NSString *) = ^ NSDate * (NSString *table) {
      return [PELMUtils maxDateFromTable:table
                              dateColumn:COL_MST_UPDATED_AT
                             whereColumn:COL_MASTER_USER_ID
                              whereValue:user.localMasterIdentifier
                                      db:db
                                   error:errorBlk];
    };
    overallMostRecent = [PELMUtils maxDateFromTable:TBL_MASTER_USER
                                         dateColumn:COL_MST_UPDATED_AT
                                        whereColumn:COL_LOCAL_ID
                                         whereValue:user.localMasterIdentifier
                                                 db:db
                                              error:errorBlk];
    overallMostRecent = [PEUtils largerOfDate:overallMostRecent
                                      andDate:mostRecentDate(TBL_MASTER_VEHICLE)];
    overallMostRecent = [PEUtils largerOfDate:overallMostRecent
                                      andDate:mostRecentDate(TBL_MASTER_FUEL_STATION)];
    overallMostRecent = [PEUtils largerOfDate:overallMostRecent
                                      andDate:mostRecentDate(TBL_MASTER_FUELPURCHASE_LOG)];
    overallMostRecent = [PEUtils largerOfDate:overallMostRecent
                                      andDate:mostRecentDate(TBL_MASTER_ENV_LOG)];
  }];
  return overallMostRecent;
}

- (FPUser *)masterUserWithId:(NSNumber *)userId
                       error:(PELMDaoErrorBlk)errorBlk {
  NSString *userTable = TBL_MASTER_USER;
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", userTable, COL_LOCAL_ID]
                          entityTable:userTable
                        localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                            argsArray:@[userId]
                          rsConverter:^(FMResultSet *rs) { return [self masterUserFromResultSet:rs]; }
                                   db:db
                                error:errorBlk];
  }];
  return user;
}

- (FPUser *)masterUserWithGlobalId:(NSString *)globalId
                             error:(PELMDaoErrorBlk)errorBlk {
  NSString *userTable = TBL_MASTER_USER;
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", userTable, COL_GLOBAL_ID]
                          entityTable:userTable
                        localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                            argsArray:@[globalId]
                          rsConverter:^(FMResultSet *rs) { return [self masterUserFromResultSet:rs]; }
                                   db:db
                                error:errorBlk];
  }];
  return user;
}

- (void)deleteUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteUser:user db:db error:errorBlk];
  }];
}

- (void)deleteUser:(FPUser *)user
                db:(FMDatabase *)db
             error:(PELMDaoErrorBlk)errorBlk {
  [self deleteVehiclesOfUser:user db:db error:errorBlk];
  [self deleteFuelstationsOfUser:user db:db error:errorBlk];
  [PELMUtils deleteEntity:user
          entityMainTable:TBL_MAIN_USER
        entityMasterTable:TBL_MASTER_USER
                       db:db
                    error:errorBlk];
}

- (void)deleteVehiclesOfUser:(FPUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
  for (FPVehicle *vehicle in vehicles) {
    [self deleteVehicle:vehicle db:db error:errorBlk];
  }
}

- (void)deleteFuelstationsOfUser:(FPUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fuelstations = [self fuelStationsForUser:user db:db error:errorBlk];
  for (FPFuelStation *fuelstation in fuelstations) {
    [self deleteFuelstation:fuelstation db:db error:errorBlk];
  }
}

- (NSInteger)numUnsyncedEntitiesForUser:(FPUser *)user
                        mainEntityTable:(NSString *)entityTable {
  __block NSInteger numEntities = 0;
  if ([user localMainIdentifier]) {
    [_databaseQueue inDatabase:^(FMDatabase *db) {
      NSString *qry = [NSString stringWithFormat:@"select count(*) from %@ where \
                       %@ = ? and \
                       %@ = 0", entityTable,
                       COL_MAIN_USER_ID,
                       COL_MAN_SYNCED];
      FMResultSet *rs = [db executeQuery:qry
                    withArgumentsInArray:@[[user localMainIdentifier]]];
      [rs next];
      numEntities = [rs intForColumnIndex:0];
      [rs next]; // to not have 'open result set' warning
      [rs close];
    }];
  }
  return numEntities;
}

- (NSInteger)numSyncNeededEntitiesForUser:(FPUser *)user
                          mainEntityTable:(NSString *)entityTable {
  __block NSInteger numEntities = 0;
  if ([user localMainIdentifier]) {
    [_databaseQueue inDatabase:^(FMDatabase *db) {
      NSString *qry = [NSString stringWithFormat:@"select count(*) from %@ where \
%@ = ? and \
%@ = 0 and \
%@ = 0 and \
%@ = 0 and \
(%@ is null or %@ < 0)",
                       entityTable,
                       COL_MAIN_USER_ID,
                       COL_MAN_SYNCED,
                       COL_MAN_EDIT_IN_PROGRESS,
                       COL_MAN_SYNC_IN_PROGRESS,
                       COL_MAN_SYNC_ERR_MASK,
                       COL_MAN_SYNC_ERR_MASK];
      FMResultSet *rs = [db executeQuery:qry
                    withArgumentsInArray:@[[user localMainIdentifier]]];
      [rs next];
      numEntities = [rs intForColumnIndex:0];
      [rs next]; // to not have 'open result set' warning
      [rs close];
    }];
  }
  return numEntities;
}

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_VEHICLE];
}

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_FUEL_STATION];
}

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_FUELPURCHASE_LOG];
}

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user {
  return [self numUnsyncedEntitiesForUser:user mainEntityTable:TBL_MAIN_ENV_LOG];
}

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user {
  return [self numUnsyncedVehiclesForUser:user] +
    [self numUnsyncedFuelStationsForUser:user] +
    [self numUnsyncedFuelPurchaseLogsForUser:user] +
    [self numUnsyncedEnvironmentLogsForUser:user];
}

- (NSInteger)numSyncNeededVehiclesForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_VEHICLE];
}

- (NSInteger)numSyncNeededFuelStationsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_FUEL_STATION];
}

- (NSInteger)numSyncNeededFuelPurchaseLogsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_FUELPURCHASE_LOG];
}

- (NSInteger)numSyncNeededEnvironmentLogsForUser:(FPUser *)user {
  return [self numSyncNeededEntitiesForUser:user mainEntityTable:TBL_MAIN_ENV_LOG];
}

- (NSInteger)totalNumSyncNeededEntitiesForUser:(FPUser *)user {
  return [self numSyncNeededVehiclesForUser:user] +
    [self numSyncNeededFuelStationsForUser:user] +
    [self numSyncNeededFuelPurchaseLogsForUser:user] +
    [self numSyncNeededEnvironmentLogsForUser:user];
}

- (void)saveNewLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewLocalUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewLocalUser:(FPUser *)user
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMainUser:user db:db error:errorBlk];
}

- (void)linkMainUser:(FPUser *)mainUser
        toMasterUser:(FPUser *)masterUser
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  [mainUser overwrite:masterUser];
  [mainUser setLocalMasterIdentifier:[masterUser localMasterIdentifier]];
  [mainUser setSynced:YES];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set \
                       %@ = ?, \
                       %@ = 1, \
                       %@ = ?, \
                       %@ = ?, \
                       %@ = ?, \
                       %@ = ?, \
                       %@ = ? \
                       where %@ = ?", TBL_MAIN_USER,
                       COL_MASTER_USER_ID,
                       COL_MAN_SYNCED,
                       COL_GLOBAL_ID,
                       COL_MAN_MASTER_UPDATED_AT,
                       COL_USR_NAME,
                       COL_USR_EMAIL,
                       COL_USR_USERNAME,
                       COL_LOCAL_ID]
            argsArray:@[[masterUser localMasterIdentifier],
                        [masterUser globalIdentifier],
                        [PEUtils millisecondsFromDate:[masterUser updatedAt]],
                        orNil([masterUser name]),
                        orNil([masterUser email]),
                        orNil([masterUser username]),
                        [mainUser localMainIdentifier]]
                   db:db
                error:errorBlk];
  [PELMUtils deleteRelationsFromEntityTable:TBL_MAIN_USER
                            localIdentifier:[mainUser localMainIdentifier]
                                         db:db
                                      error:errorBlk];
  [PELMUtils insertRelations:[masterUser relations]
                   forEntity:mainUser
                 entityTable:TBL_MAIN_USER
             localIdentifier:[mainUser localMainIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewRemoteUser:(FPUser *)remoteUser
       andLinkToLocalUser:(FPUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                    error:(PELMDaoErrorBlk)errorBlk {
  // user is special in that, upon insertion, it should have a global-ID (this
  // is because as part of user-creation, we FIRST save to remote master, which
  // returns us back a global-ID, then we insert into local master, hence this
  // invariant check)
  NSAssert([remoteUser globalIdentifier] != nil, @"globalIdentifier is nil");
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewRemoteUser:remoteUser
         andLinkToLocalUser:localUser
preserveExistingLocalEntities:preserveExistingLocalEntities
                         db:db
                      error:errorBlk];
  }];
}

- (void)saveNewRemoteUser:(FPUser *)newRemoteUser
       andLinkToLocalUser:(FPUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterUser:newRemoteUser db:db error:errorBlk];
  [PELMUtils insertRelations:[newRemoteUser relations]
                   forEntity:newRemoteUser
                 entityTable:TBL_MASTER_USER
             localIdentifier:[newRemoteUser localMasterIdentifier]
                          db:db
                       error:errorBlk];
  [self linkMainUser:localUser toMasterUser:newRemoteUser db:db error:errorBlk];
  if (!preserveExistingLocalEntities) {
    [self deleteVehiclesOfUser:localUser db:db error:errorBlk];
    [self deleteFuelstationsOfUser:localUser db:db error:errorBlk];
  }
}

- (void)deepSaveNewRemoteUser:(FPUser *)remoteUser
           andLinkToLocalUser:(FPUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                        error:(PELMDaoErrorBlk)errorBlk {
  NSAssert([remoteUser globalIdentifier] != nil, @"globalIdentifier is nil");
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewRemoteUser:remoteUser
         andLinkToLocalUser:localUser
preserveExistingLocalEntities:preserveExistingLocalEntities
                         db:db
                      error:errorBlk];
    NSArray *vehicles = [remoteUser vehicles];
    if (vehicles) {
      for (FPVehicle *vehicle in vehicles) {
        [self persistDeepVehicleFromRemoteMaster:vehicle
                                         forUser:remoteUser
                                              db:db
                                           error:errorBlk];
      }
    }
    NSArray *fuelStations = [remoteUser fuelStations];
    if (fuelStations) {
      for (FPFuelStation *fuelStation in fuelStations) {
        [self persistDeepFuelStationFromRemoteMaster:fuelStation
                                             forUser:remoteUser
                                                  db:db
                                               error:errorBlk];
      }
    }
    NSArray *fpLogs = [remoteUser fuelPurchaseLogs];
    if (fpLogs) {
      for (FPFuelPurchaseLog *fpLog in fpLogs) {
        [self persistDeepFuelPurchaseLogFromRemoteMaster:fpLog
                                                 forUser:remoteUser
                                                      db:db
                                                   error:errorBlk];
      }
    }
    NSArray *envLogs = [remoteUser environmentLogs];
    if (envLogs) {
      for (FPEnvironmentLog *envLog in envLogs) {
        [self persistDeepEnvironmentLogFromRemoteMaster:envLog
                                                forUser:remoteUser
                                                     db:db
                                                  error:errorBlk];
      }
    }
  }];
}

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk {
  // we always go to main store first...(the end-user might be in the process
  // of editing their user entity, and therefore, the "latest" version of the
  // user entity will be residing in the main store).
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self mainUserWithDatabase:db error:errorBlk];
    if (!user) {
      user = [self masterUserWithDatabase:db error:errorBlk];
      if (user) {
        if ([user deletedAt]) {
          user = nil;
        }
      }
    }
  }];
  return user;
}

- (BOOL)prepareUserForEdit:(FPUser *)user
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils prepareEntityForEdit:user
                                      db:db
                               mainTable:TBL_MAIN_USER
                     entityFromResultSet:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];
                      }
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainUser]
                                   argsArray:[self updateArgsForMainUser:user]
                                          db:db
                                       error:errorBlk];
                         [PELMUtils deleteRelationsFromEntityTable:TBL_MAIN_USER
                                                   localIdentifier:[entity localMainIdentifier]
                                                                db:db
                                                             error:errorBlk];
                         [PELMUtils insertRelations:[user relations]
                                          forEntity:user
                                        entityTable:TBL_MAIN_USER
                                    localIdentifier:[user localMainIdentifier]
                                                 db:db
                                              error:errorBlk];
                       }
                                   error:errorBlk];
}

- (BOOL)prepareUserForEdit:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareUserForEdit:user db:db error:errorBlk];
  }];
  return returnVal;
}

- (void)saveUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveEntity:user
                     mainTable:TBL_MAIN_USER
                mainUpdateStmt:[self updateStmtForMainUser]
             mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:user
                                               mainTable:TBL_MAIN_USER
                                          mainUpdateStmt:[self updateStmtForMainUser]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                                                   error:errorBlk];
}

- (void)markAsDoneEditingUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:user
                                  mainTable:TBL_MAIN_USER
                             mainUpdateStmt:[self updateStmtForMainUser]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                                      error:errorBlk];
}

- (void)reloadUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils reloadEntity:user
                   fromMainTable:TBL_MAIN_USER
                     rsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                           error:errorBlk];
}

- (void)cancelEditOfUser:(FPUser *)user
                   error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelEditOfEntity:user
                             mainTable:TBL_MAIN_USER
                        mainUpdateStmt:[self updateStmtForMainUser]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                           masterTable:TBL_MASTER_USER
                           rsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
                                 error:errorBlk];
}

- (FPUser *)markUserAsSyncInProgressWithError:(PELMDaoErrorBlk)errorBlk {
  NSArray *userEntities =
  [_localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_USER
                                        entityFromResultSet:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                                                 updateStmt:[self updateStmtForMainUser]
                                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                                                      error:errorBlk];
  if ([userEntities count] > 1) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"There cannot be more than 1 user entity"
                                 userInfo:nil];
  } else if ([userEntities count] == 0) {
    return nil;
  } else {
    return [userEntities objectAtIndex:0];
  }
}

- (void)cancelSyncForUser:(FPUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
                    error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:user
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainUser]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                                  error:errorBlk];
}

- (BOOL)saveMasterUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils saveMasterEntity:user
                                masterTable:TBL_MASTER_USER
                           masterUpdateStmt:[self updateStmtForMasterUser]
                        masterUpdateArgsBlk:^NSArray * (FPUser *theUser) { return [self updateArgsForMasterUser:theUser]; }
                                  mainTable:TBL_MAIN_USER
                    mainEntityFromResultSet:^FPUser * (FMResultSet *rs) { return [self mainUserFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainUser]
                          mainUpdateArgsBlk:^NSArray * (FPUser *theUser) { return [self updateArgsForMainUser:theUser]; }
                                      error:errorBlk];
}

- (BOOL)saveMasterUser:(FPUser *)user
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveMasterEntity:user
                         masterTable:TBL_MASTER_USER
                    masterUpdateStmt:[self updateStmtForMasterUser]
                 masterUpdateArgsBlk:^NSArray * (FPUser *theUser) { return [self updateArgsForMasterUser:theUser]; }
                           mainTable:TBL_MAIN_USER
             mainEntityFromResultSet:^ FPUser * (FMResultSet *rs) { return [self mainUserFromResultSet:rs]; }
                      mainUpdateStmt:[self updateStmtForMainUser]
                   mainUpdateArgsBlk:^NSArray * (FPUser *theUser) { return [self updateArgsForMainUser:theUser]; }
                                  db:db
                               error:errorBlk];
}

- (void)markAsSyncCompleteForUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForUpdatedEntityInTxn:user
                                                  mainTable:TBL_MAIN_USER
                                                masterTable:TBL_MASTER_USER
                                             mainUpdateStmt:[self updateStmtForMainUser]
                                          mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainUser:(FPUser *)entity];}
                                           masterUpdateStmt:[self updateStmtForMasterUser]
                                        masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterUser:(FPUser *)entity];}
                                                      error:errorBlk];
}

- (NSArray *)saveChangelog:(FPChangelog *)changelog
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numDeletes = 0;
  __block NSInteger numUpdates = 0;
  __block NSInteger numInserts = 0;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    void (^processChangelogEntities)(NSArray *,
                                     NSString *,
                                     NSString *,
                                     void(^)(id),
                                     PELMSaveNewOrExistingCode(^)(id)) =
    ^ (NSArray *entities, NSString *masterTable, NSString *mainTable, void(^deleteBlk)(id), PELMSaveNewOrExistingCode(^saveNewOrExistingBlk)(id)) {
      for (PELMMainSupport *entity in entities) {
        if (![PEUtils isNil:entity.deletedAt]) {
          NSNumber *masterLocalId = [PELMUtils masterLocalIdFromEntityTable:masterTable
                                                           globalIdentifier:entity.globalIdentifier
                                                                         db:db
                                                                      error:errorBlk];
          if (![PEUtils isNil:masterLocalId]) {
            [entity setLocalMasterIdentifier:masterLocalId];
            NSNumber *mainLocalId = [PELMUtils localMainIdentifierForEntity:entity
                                                                  mainTable:mainTable
                                                                         db:db
                                                                      error:errorBlk];
            [entity setLocalMainIdentifier:mainLocalId];
            deleteBlk(entity);
            numDeletes++;
          } else {
            // the entity never existed on our device (i.e., it was created and deleted
            // before it could ever be downloaded to this device)
          }
        } else {
          PELMSaveNewOrExistingCode returnCode = saveNewOrExistingBlk(entity);
          switch (returnCode) {
            case PELMSaveNewOrExistingCodeDidUpdate:
              numUpdates++;
              break;
            case PELMSaveNewOrExistingCodeDidInsert:
              numInserts++;
              break;
            case PELMSaveNewOrExistingCodeDidNothing:
              // do nothing
              break;
          }
        }
      }
    };
    FPUser *updatedUser = [changelog user];
    if (![PEUtils isNil:updatedUser]) {
      if ([updatedUser.updatedAt compare:user.updatedAt] == NSOrderedDescending) {
        if ([self saveMasterUser:updatedUser db:db error:errorBlk]) {
          [user overwriteDomainProperties:updatedUser];
          numUpdates++;
        }
      }
    }
    processChangelogEntities([changelog vehicles],
                             TBL_MASTER_VEHICLE,
                             TBL_MAIN_VEHICLE,
                             ^(FPVehicle *vehicle) { [self deleteVehicle:vehicle db:db error:errorBlk]; },
                             ^(FPVehicle *vehicle) { return [self saveNewOrExistingMasterVehicle:vehicle forUser:user db:db error:errorBlk]; });
    processChangelogEntities([changelog fuelStations],
                             TBL_MASTER_FUEL_STATION,
                             TBL_MAIN_FUEL_STATION,
                             ^(FPFuelStation *fuelstation) { [self deleteFuelstation:fuelstation db:db error:errorBlk]; },
                             ^(FPFuelStation *fuelstation) { return [self saveNewOrExistingMasterFuelstation:fuelstation forUser:user db:db error:errorBlk]; });
    processChangelogEntities([changelog fuelPurchaseLogs],
                             TBL_MASTER_FUELPURCHASE_LOG,
                             TBL_MAIN_FUELPURCHASE_LOG,
                             ^(FPFuelPurchaseLog *fplog) { [self deleteFuelPurchaseLog:fplog db:db error:errorBlk]; },
                             ^(FPFuelPurchaseLog *fplog) { return [self saveNewOrExistingMasterFuelPurchaseLog:fplog forUser:user db:db error:errorBlk]; });
    processChangelogEntities([changelog environmentLogs],
                             TBL_MASTER_ENV_LOG,
                             TBL_MAIN_ENV_LOG,
                             ^(FPEnvironmentLog *envlog) { [self deleteEnvironmentLog:envlog db:db error:errorBlk]; },
                             ^(FPEnvironmentLog *envlog) { return [self saveNewOrExistingMasterEnvironmentLog:envlog forUser:user db:db error:errorBlk]; });
  }];
  return @[@(numDeletes), @(numUpdates), @(numInserts)];
}

#pragma mark - Vehicle

- (FPVehicle *)masterVehicleWithId:(NSNumber *)vehicleId
                             error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleTable = TBL_MASTER_VEHICLE;
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", vehicleTable, COL_LOCAL_ID]
                             entityTable:vehicleTable
                           localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                               argsArray:@[vehicleId]
                             rsConverter:^(FMResultSet *rs) { return [self masterVehicleFromResultSet:rs]; }
                                      db:db
                                   error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:vehicle mainTable:TBL_MAIN_VEHICLE db:db error:errorBlk];
    if (localMainId) {
      [vehicle setLocalMainIdentifier:localMainId];
    }
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleWithGlobalId:(NSString *)globalId
                                   error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleTable = TBL_MASTER_VEHICLE;
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", vehicleTable, COL_GLOBAL_ID]
                             entityTable:vehicleTable
                           localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                               argsArray:@[globalId]
                             rsConverter:^(FMResultSet *rs) { return [self masterVehicleFromResultSet:rs]; }
                                      db:db
                                   error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:vehicle mainTable:TBL_MAIN_VEHICLE db:db error:errorBlk];
    if (localMainId) {
      [vehicle setLocalMainIdentifier:localMainId];
    }
  }];
  return vehicle;
}

- (void)deleteVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteVehicle:vehicle db:db error:errorBlk];
  }];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fplogs = [self fuelPurchaseLogsForVehicle:vehicle db:db error:errorBlk];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }
  NSArray *envlogs = [self environmentLogsForVehicle:vehicle db:db error:errorBlk];
  for (FPEnvironmentLog *envlog in envlogs) {
    [self deleteEnvironmentLog:envlog db:db error:errorBlk];
  }
  [PELMUtils deleteEntity:vehicle
          entityMainTable:TBL_MAIN_VEHICLE
        entityMasterTable:TBL_MASTER_VEHICLE
                       db:db
                    error:errorBlk];
}

- (void)copyVehicleToMaster:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:nil
                             db:db
                          error:errorBlk];
  }];
}

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numVehicles = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numVehicles = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_VEHICLE
                                        entityMainTable:TBL_MAIN_VEHICLE
                                                     db:db
                                                  error:errorBlk];
  }];
  return numVehicles;
}

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *vehicles = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicles = [self vehiclesForUser:user db:db error:errorBlk];
  }];
  return vehicles;
}

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *vehicles = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicles = [self unsyncedVehiclesForUser:user db:db error:errorBlk];
  }];
  return vehicles;
}

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                  entityMasterTable:TBL_MASTER_VEHICLE
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_VEHICLE
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPVehicle *)o2 name] compare:[(FPVehicle *)o1 name]];}
                                orderByDomainColumn:COL_VEH_NAME
                       orderByDomainColumnDirection:@"ASC"
                                                 db:db
                                              error:errorBlk];
}

- (NSArray *)vehiclesForUser:(FPUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      where:nil
                                   whereArg:nil
                          entityMasterTable:TBL_MASTER_VEHICLE
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_VEHICLE
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPVehicle *)o2 name] compare:[(FPVehicle *)o1 name]];}
                        orderByDomainColumn:COL_VEH_NAME
               orderByDomainColumnDirection:@"ASC"
                                         db:db
                                      error:errorBlk];
}

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self userForVehicle:vehicle db:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  return (FPUser *)
  [PELMUtils parentForChildEntity:vehicle
            parentEntityMainTable:TBL_MAIN_USER
          parentEntityMasterTable:TBL_MASTER_USER
         parentEntityMainFkColumn:COL_MAIN_USER_ID
       parentEntityMasterFkColumn:COL_MASTER_USER_ID
      parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
    parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
             childEntityMainTable:TBL_MAIN_VEHICLE
       childEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
           childEntityMasterTable:TBL_MASTER_VEHICLE
                               db:db
                            error:errorBlk];
}

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepVehicleFromRemoteMaster:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterVehicle:vehicle forUser:user db:db error:errorBlk];
  [PELMUtils insertRelations:[vehicle relations]
                   forEntity:vehicle
                 entityTable:TBL_MASTER_VEHICLE
             localIdentifier:[vehicle localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewVehicle:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [vehicle setSyncInProgress:YES];
    [self saveNewVehicle:vehicle forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [vehicle setEditCount:1];
  [self insertIntoMainVehicle:vehicle forUser:user db:db error:errorBlk];
}

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    returnVal = [PELMUtils prepareEntityForEdit:vehicle
                                             db:db
                                      mainTable:TBL_MAIN_VEHICLE
                            entityFromResultSet:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                               [self insertIntoMainVehicle:vehicle forUser:user db:db error:errorBlk];}
                              mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                                [PELMUtils doUpdate:[self updateStmtForMainVehicle]
                                          argsArray:[self updateArgsForMainVehicle:vehicle]
                                                 db:db
                                              error:errorBlk];}
                                          error:errorBlk];
  }];
  return returnVal;
}

- (void)saveVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveEntity:vehicle
                     mainTable:TBL_MAIN_VEHICLE
                mainUpdateStmt:[self updateStmtForMainVehicle]
             mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:vehicle
                                  mainTable:TBL_MAIN_VEHICLE
                             mainUpdateStmt:[self updateStmtForMainVehicle]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncVehicle:(FPVehicle *)vehicle
                                        error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:vehicle
                                               mainTable:TBL_MAIN_VEHICLE
                                          mainUpdateStmt:[self updateStmtForMainVehicle]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                                   error:errorBlk];
}

- (void)reloadVehicle:(FPVehicle *)vehicle
                error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils reloadEntity:vehicle
                   fromMainTable:TBL_MAIN_VEHICLE
                     rsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                           error:errorBlk];
}

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelEditOfEntity:vehicle
                             mainTable:TBL_MAIN_VEHICLE
                        mainUpdateStmt:[self updateStmtForMainVehicle]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                           masterTable:TBL_MASTER_VEHICLE
                           rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markVehiclesAsSyncInProgressForUser:(FPUser *)user
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_VEHICLE
                                               entityFromResultSet:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                                                        updateStmt:[self updateStmtForMainVehicle]
                                                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                                             error:errorBlk];
}

- (void)cancelSyncForVehicle:(FPVehicle *)vehicle
                httpRespCode:(NSNumber *)httpRespCode
                   errorMask:(NSNumber *)errorMask
                     retryAt:(NSDate *)retryAt
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:vehicle
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainVehicle]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterVehicle:(FPVehicle *)vehicle
                                                    forUser:(FPUser *)user
                                                         db:(FMDatabase *)db
                                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:vehicle
                                      masterTable:TBL_MASTER_VEHICLE
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterVehicle]
                              masterUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMasterVehicle:theVehicle]; }
                                        mainTable:TBL_MAIN_VEHICLE
                          mainEntityFromResultSet:^FPVehicle * (FMResultSet *rs) { return [self mainVehicleFromResultSet:rs]; }
                                   mainUpdateStmt:[self updateStmtForMainVehicle]
                                mainUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMainVehicle:theVehicle]; }
                                               db:db
                                            error:errorBlk];
}

- (void)saveNewMasterVehicle:(FPVehicle *)vehicle
                     forUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveNewMasterEntity:vehicle
                            masterTable:TBL_MASTER_VEHICLE
                        masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                  error:errorBlk];
}

- (BOOL)saveMasterVehicle:(FPVehicle *)vehicle
                  forUser:(FPUser *)user
                    error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils saveMasterEntity:vehicle
                                masterTable:TBL_MASTER_VEHICLE
                           masterUpdateStmt:[self updateStmtForMasterVehicle]
                        masterUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMasterVehicle:theVehicle]; }
                                  mainTable:TBL_MAIN_VEHICLE
                    mainEntityFromResultSet:^FPVehicle * (FMResultSet *rs) { return [self mainVehicleFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainVehicle]
                          mainUpdateArgsBlk:^NSArray * (FPVehicle *theVehicle) { return [self updateArgsForMainVehicle:theVehicle]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewVehicle:(FPVehicle *)vehicle
                                forUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForNewEntity:vehicle
                                         mainTable:TBL_MAIN_VEHICLE
                                       masterTable:TBL_MASTER_VEHICLE
                                    mainUpdateStmt:[self updateStmtForMainVehicle]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)vehicle
                                      error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForUpdatedEntityInTxn:vehicle
                                                  mainTable:TBL_MAIN_VEHICLE
                                                masterTable:TBL_MASTER_VEHICLE
                                             mainUpdateStmt:[self updateStmtForMainVehicle]
                                          mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainVehicle:(FPVehicle *)entity];}
                                           masterUpdateStmt:[self updateStmtForMasterVehicle]
                                        masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterVehicle:(FPVehicle *)entity];}
                                                      error:errorBlk];
}

#pragma mark - Fuel Station

- (FPFuelStation *)masterFuelstationWithId:(NSNumber *)fuelstationId
                                     error:(PELMDaoErrorBlk)errorBlk {
  NSString *fuelstationTable = TBL_MASTER_FUEL_STATION;
  __block FPFuelStation *fuelstation = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstation = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fuelstationTable, COL_LOCAL_ID]
                                 entityTable:fuelstationTable
                               localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                                   argsArray:@[fuelstationId]
                                 rsConverter:^(FMResultSet *rs) { return [self masterFuelStationFromResultSet:rs]; }
                                          db:db
                                       error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fuelstation mainTable:TBL_MAIN_FUEL_STATION db:db error:errorBlk];
    if (localMainId) {
      [fuelstation setLocalMainIdentifier:localMainId];
    }
  }];
  return fuelstation;
}

- (FPFuelStation *)masterFuelstationWithGlobalId:(NSString *)globalId
                                           error:(PELMDaoErrorBlk)errorBlk {
  NSString *fuelstationTable = TBL_MASTER_FUEL_STATION;
  __block FPFuelStation *fuelstation = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstation = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fuelstationTable, COL_GLOBAL_ID]
                                 entityTable:fuelstationTable
                               localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                                   argsArray:@[globalId]
                                 rsConverter:^(FMResultSet *rs) { return [self masterFuelStationFromResultSet:rs]; }
                                          db:db
                                       error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fuelstation mainTable:TBL_MAIN_FUEL_STATION db:db error:errorBlk];
    if (localMainId) {
      [fuelstation setLocalMainIdentifier:localMainId];
    }
  }];
  return fuelstation;
}

- (void)deleteFuelstation:(FPFuelStation *)fuelstation error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteFuelstation:fuelstation db:db error:errorBlk];
  }];
}

- (void)deleteFuelstation:(FPFuelStation *)fuelstation
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fplogs = [self fuelPurchaseLogsForFuelStation:fuelstation db:db error:errorBlk];
  for (FPFuelPurchaseLog *fplog in fplogs) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }
  [PELMUtils deleteEntity:fuelstation
          entityMainTable:TBL_MAIN_FUEL_STATION
        entityMasterTable:TBL_MASTER_FUEL_STATION
                       db:db
                    error:errorBlk];
}

- (NSInteger)numFuelStationsForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numFuelStations = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numFuelStations = [PELMUtils numEntitiesForParentEntity:user
                                      parentEntityMainTable:TBL_MAIN_USER
                                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                          entityMasterTable:TBL_MASTER_FUEL_STATION
                                            entityMainTable:TBL_MAIN_FUEL_STATION
                                                         db:db
                                                      error:errorBlk];
  }];
  return numFuelStations;
}

- (NSArray *)fuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fuelStations = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelStations = [self fuelStationsForUser:user db:db error:errorBlk];
  }];
  return fuelStations;
}

- (NSArray *)fuelStationsForUser:(FPUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      where:nil
                                   whereArg:nil
                          entityMasterTable:TBL_MASTER_FUEL_STATION
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUEL_STATION
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelStation *)o2 name] compare:[(FPFuelStation *)o1 name]];}
                        orderByDomainColumn:COL_FUELST_NAME
               orderByDomainColumnDirection:@"ASC"
                                         db:db
                                      error:errorBlk];
}

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fuelstations = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstations = [self unsyncedFuelStationsForUser:user db:db error:errorBlk];
  }];
  return fuelstations;
}

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                  entityMasterTable:TBL_MASTER_FUEL_STATION
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_FUEL_STATION
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelStation *)o2 name] compare:[(FPFuelStation *)o1 name]];}
                                orderByDomainColumn:COL_FUELST_NAME
                       orderByDomainColumnDirection:@"ASC"
                                                 db:db
                                              error:errorBlk];
}

- (NSArray *)fuelStationsWithNonNilLocationForUser:(FPUser *)user
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:user
                      parentEntityMainTable:TBL_MAIN_USER
                parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                 parentEntityMasterIdColumn:COL_MASTER_USER_ID
                   parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      where:[NSString stringWithFormat:@"%@ IS NOT NULL AND %@ IS NOT NULL",
                                                      COL_FUELST_LATITUDE, COL_FUELST_LONGITUDE]
                                   whereArg:nil
                          entityMasterTable:TBL_MASTER_FUEL_STATION
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUEL_STATION
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                         db:db
                                      error:errorBlk];
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self userForFuelStation:fuelStation db:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  return (FPUser *)
  [PELMUtils parentForChildEntity:fuelStation
            parentEntityMainTable:TBL_MAIN_USER
          parentEntityMasterTable:TBL_MASTER_USER
         parentEntityMainFkColumn:COL_MAIN_USER_ID
       parentEntityMasterFkColumn:COL_MASTER_USER_ID
      parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
    parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
             childEntityMainTable:TBL_MAIN_FUEL_STATION
       childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
           childEntityMasterTable:TBL_MASTER_FUEL_STATION
                               db:db
                            error:errorBlk];
}

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepFuelStationFromRemoteMaster:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                            db:(FMDatabase *)db
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterFuelStation:fuelStation forUser:user db:db error:errorBlk];
  [PELMUtils insertRelations:[fuelStation relations]
                   forEntity:fuelStation
                 entityTable:TBL_MASTER_FUEL_STATION
             localIdentifier:[fuelStation localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewFuelStation:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [fuelStation setSyncInProgress:YES];
    [self saveNewFuelStation:fuelStation forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelStation setEditCount:1];
  [self insertIntoMainFuelStation:fuelStation forUser:user db:db error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  return [PELMUtils prepareEntityForEdit:fuelStation
                                      db:db
                               mainTable:TBL_MAIN_FUEL_STATION
                     entityFromResultSet:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainFuelStation:fuelStation forUser:user db:db error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainFuelStation]
                                   argsArray:[self updateArgsForMainFuelStation:fuelStation]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareFuelStationForEdit:fuelStation
                                        forUser:user
                                             db:db
                                          error:errorBlk];
  }];
  return returnVal;
}

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveEntity:fuelStation
                     mainTable:TBL_MAIN_FUEL_STATION
                mainUpdateStmt:[self updateStmtForMainFuelStation]
             mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:fuelStation
                                  mainTable:TBL_MAIN_FUEL_STATION
                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncFuelStation:(FPFuelStation *)fuelStation
                                            error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:fuelStation
                                                  mainTable:TBL_MAIN_FUEL_STATION
                                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                                      error:errorBlk];
}

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils reloadEntity:fuelStation
                   fromMainTable:TBL_MAIN_FUEL_STATION
                     rsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                           error:errorBlk];
}

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelEditOfEntity:fuelStation
                             mainTable:TBL_MAIN_FUEL_STATION
                        mainUpdateStmt:[self updateStmtForMainFuelStation]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                           masterTable:TBL_MASTER_FUEL_STATION
                           rsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markFuelStationsAsSyncInProgressForUser:(FPUser *)user
                                               error:(PELMDaoErrorBlk)errorBlk {
  return
    [_localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_FUEL_STATION
                                          entityFromResultSet:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                                                   updateStmt:[self updateStmtForMainFuelStation]
                                                updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                                        error:errorBlk];
}

- (void(^)(void))entityBeingSyncedLoggingBlkWithMsg:(NSString *)logMsg {
  return ^{
    DDLogDebug(@"Entity currently being synced.  Context specific message: [%@]", logMsg);
  };
}

- (void(^)(void))entityDeletedLoggingBlkWithMsg:(NSString *)logMsg {
  return ^{
    DDLogDebug(@"Entity currently deleted.  Context specific message: [%@]", logMsg);
  };
}

- (void(^)(void))entityInConflictLoggingBlkWithMsg:(NSString *)logMsg {
  return ^{
    DDLogDebug(@"Entity currently in conflict.  Context specific message: [%@]", logMsg);
  };
}

- (void)cancelSyncForFuelStation:(FPFuelStation *)fuelStation
                    httpRespCode:(NSNumber *)httpRespCode
                       errorMask:(NSNumber *)errorMask
                         retryAt:(NSDate *)retryAt
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:fuelStation
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainFuelStation]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterFuelstation:(FPFuelStation *)fuelstation
                                                        forUser:(FPUser *)user
                                                             db:(FMDatabase *)db
                                                          error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:fuelstation
                                      masterTable:TBL_MASTER_FUEL_STATION
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterFuelStation]
                              masterUpdateArgsBlk:^NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMasterFuelStation:theFuelstation]; }
                                        mainTable:TBL_MAIN_FUEL_STATION
                          mainEntityFromResultSet:^FPFuelStation * (FMResultSet *rs) { return [self mainFuelStationFromResultSet:rs]; }
                                   mainUpdateStmt:[self updateStmtForMainFuelStation]
                                mainUpdateArgsBlk:^NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMainFuelStation:theFuelstation]; }
                                               db:db
                                            error:errorBlk];
}

- (void)saveNewMasterFuelstation:(FPFuelStation *)fuelstation
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveNewMasterEntity:fuelstation
                            masterTable:TBL_MASTER_FUEL_STATION
                        masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                  error:errorBlk];
}

- (BOOL)saveMasterFuelstation:(FPFuelStation *)fuelstation
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils saveMasterEntity:fuelstation
                                masterTable:TBL_MASTER_FUEL_STATION
                           masterUpdateStmt:[self updateStmtForMasterFuelStation]
                        masterUpdateArgsBlk:^ NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMasterFuelStation:theFuelstation]; }
                                  mainTable:TBL_MAIN_FUEL_STATION
                    mainEntityFromResultSet:^ FPFuelStation * (FMResultSet *rs) { return [self mainFuelStationFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                          mainUpdateArgsBlk:^ NSArray * (FPFuelStation *theFuelstation) { return [self updateArgsForMainFuelStation:theFuelstation]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewFuelStation:(FPFuelStation *)fuelStation
                                    forUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForNewEntity:fuelStation
                                         mainTable:TBL_MAIN_FUEL_STATION
                                       masterTable:TBL_MASTER_FUEL_STATION
                                    mainUpdateStmt:[self updateStmtForMainFuelStation]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)fuelStation
                                          error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForUpdatedEntityInTxn:fuelStation
                                                  mainTable:TBL_MAIN_FUEL_STATION
                                                masterTable:TBL_MASTER_FUEL_STATION
                                             mainUpdateStmt:[self updateStmtForMainFuelStation]
                                          mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelStation:(FPFuelStation *)entity];}
                                           masterUpdateStmt:[self updateStmtForMasterFuelStation]
                                        masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterFuelStation:(FPFuelStation *)entity];}
                                                      error:errorBlk];
}

#pragma mark - Fuel Purchase Log

- (FPFuelPurchaseLog *)masterFplogWithId:(NSNumber *)fplogId error:(PELMDaoErrorBlk)errorBlk {
  NSString *fplogTable = TBL_MASTER_FUELPURCHASE_LOG;
  __block FPFuelPurchaseLog *fplog = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fplog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fplogTable, COL_LOCAL_ID]
                           entityTable:fplogTable
                         localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                             argsArray:@[fplogId]
                           rsConverter:^(FMResultSet *rs) { return [self masterFuelPurchaseLogFromResultSet:rs]; }
                                    db:db
                                 error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fplog mainTable:TBL_MAIN_FUELPURCHASE_LOG db:db error:errorBlk];
    if (localMainId) {
      [fplog setLocalMainIdentifier:localMainId];
    }
  }];
  return fplog;
}

- (FPFuelPurchaseLog *)masterFplogWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  NSString *fplogTable = TBL_MASTER_FUELPURCHASE_LOG;
  __block FPFuelPurchaseLog *fplog = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fplog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", fplogTable, COL_GLOBAL_ID]
                           entityTable:fplogTable
                         localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                             argsArray:@[globalId]
                           rsConverter:^(FMResultSet *rs) { return [self masterFuelPurchaseLogFromResultSet:rs]; }
                                    db:db
                                 error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:fplog mainTable:TBL_MAIN_FUELPURCHASE_LOG db:db error:errorBlk];
    if (localMainId) {
      [fplog setLocalMainIdentifier:localMainId];
    }
  }];
  return fplog;
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                        error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteFuelPurchaseLog:fplog db:db error:errorBlk];
  }];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:fplog
          entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
        entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                       db:db
                    error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:pageSize
                      beforeDateLogged:nil
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForUser:user
                                  pageSize:@(pageSize)
                          beforeDateLogged:beforeDateLogged
                                        db:db
                                     error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self unsyncedFuelPurchaseLogsForUser:user db:db error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                          db:(FMDatabase *)db
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                  entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                                orderByDomainColumn:COL_FUELPL_PURCHASED_AT
                       orderByDomainColumnDirection:@"DESC"
                                                 db:db
                                              error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:pageSize
                         beforeDateLogged:nil
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForVehicle:vehicle
                                     pageSize:@(pageSize)
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
  }];
  return fpLogs;
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:fuelStation
                                  parentEntityMainTable:TBL_MAIN_FUEL_STATION
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:fuelStation
                                  parentEntityMainTable:TBL_MAIN_FUEL_STATION
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                        entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_FUELPL_PURCHASED_AT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:pageSize
                             beforeDateLogged:nil
                                        error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *fpLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fpLogs = [self fuelPurchaseLogsForFuelStation:fuelStation
                                         pageSize:@(pageSize)
                                 beforeDateLogged:beforeDateLogged
                                               db:db
                                            error:errorBlk];
  }];
  return fpLogs;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:nil
                      beforeDateLogged:nil
                                    db:db
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:@(pageSize)
                      beforeDateLogged:nil
                                    db:db
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:@(pageSize)
                         beforeDateLogged:nil
                                       db:db
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:nil
                         beforeDateLogged:nil
                                       db:db
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:@(pageSize)
                             beforeDateLogged:nil
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:nil
                             beforeDateLogged:nil
                                           db:db
                                        error:errorBlk];
}

- (FPFuelPurchaseLog *)mostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                     db:(FMDatabase *)db
                                                  error:(PELMDaoErrorBlk)errorBlk {
  NSArray *fpLogs =
  [self fuelPurchaseLogsForUser:user pageSize:1 db:db error:errorBlk];
  if (fpLogs && ([fpLogs count] == 1)) {
    return fpLogs[0];
  }
  return nil;
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForFuelPurchaseLog:fpLog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelStation = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelStation = [self fuelStationForFuelPurchaseLog:fpLog db:db error:errorBlk];
  }];
  return fuelStation;
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *)[PELMUtils parentForChildEntity:fpLog
                                parentEntityMainTable:TBL_MAIN_VEHICLE
                              parentEntityMasterTable:TBL_MASTER_VEHICLE
                             parentEntityMainFkColumn:COL_MAIN_VEHICLE_ID
                           parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                          parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                        parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                 childEntityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                           childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                               childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                   db:db
                                                error:errorBlk];
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                              db:(FMDatabase *)db
                                           error:(PELMDaoErrorBlk)errorBlk {
  return (FPFuelStation *) [PELMUtils parentForChildEntity:fpLog
                                     parentEntityMainTable:TBL_MAIN_FUEL_STATION
                                   parentEntityMasterTable:TBL_MASTER_FUEL_STATION
                                  parentEntityMainFkColumn:COL_MAIN_FUELSTATION_ID
                                parentEntityMasterFkColumn:COL_MASTER_FUELSTATION_ID
                               parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                             parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                      childEntityMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                childEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                                    childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                        db:db
                                                     error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                       db:(FMDatabase *)db
                                                    error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *mostRecentFpLog =
  [self mostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self vehicleForFuelPurchaseLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPFuelStation *)fuelStationForMostRecentFuelPurchaseLogForUser:(FPUser *)user
                                                               db:(FMDatabase *)db
                                                            error:(PELMDaoErrorBlk)errorBlk {
  FPFuelPurchaseLog *mostRecentFpLog =
  [self mostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self fuelStationForFuelPurchaseLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self masterVehicleForMasterFpLog:fplog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils masterParentForMasterChildEntity:fplog
                                           parentEntityMasterTable:TBL_MASTER_VEHICLE
                                        parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                                     parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                            childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                                db:db
                                                             error:errorBlk];
}

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                             error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelstation = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    fuelstation = [self masterFuelstationForMasterFpLog:fplog db:db error:errorBlk];
  }];
  return fuelstation;
}

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  return (FPFuelStation *)[PELMUtils masterParentForMasterChildEntity:fplog
                                              parentEntityMasterTable:TBL_MASTER_FUEL_STATION
                                           parentEntityMasterFkColumn:COL_MASTER_FUELSTATION_ID
                                        parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                               childEntityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
                                                                   db:db
                                                                error:errorBlk];
}

- (FPVehicle *)defaultVehicleForNewFuelPurchaseLogForUser:(FPUser *)user
                                                    error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForMostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
    if (!vehicle) {
      NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
      if ([vehicles count] > 0) {
        vehicle = vehicles[0];
      }
    }
  }];
  return vehicle;
}

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk {
  __block FPFuelStation *fuelStation = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    FPFuelStation *(^fallbackIfNoLocation)(void) = ^ FPFuelStation * (void) {
      FPFuelStation *fs =
      [self fuelStationForMostRecentFuelPurchaseLogForUser:user db:db error:errorBlk];
      if (!fs) {
        NSArray *fuelStations =
        [self fuelStationsForUser:user db:db error:errorBlk];
        if ([fuelStations count] > 0) {
          fs = fuelStations[0];
        }
      }
      return fs;
    };
    if (currentLocation) {
      NSArray *fuelStations =
      [self fuelStationsWithNonNilLocationForUser:user db:db error:errorBlk];
      if (fuelStations && ([fuelStations count] > 0)) {
        fuelStation = fuelStations[0];
        CLLocationDistance closestDistance =
        [[fuelStation location] distanceFromLocation:currentLocation];
        for (FPFuelStation *loopfs in fuelStations) {
          CLLocationDistance distance =
          [[loopfs location] distanceFromLocation:currentLocation];
          if (distance < closestDistance) {
            closestDistance = distance;
            fuelStation = loopfs;
          }
        }
      }
    }
    if (!fuelStation) {
      fuelStation = fallbackIfNoLocation();
    }
  }];
  return fuelStation;
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSNumber *)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:user
                         parentEntityMainTable:TBL_MAIN_USER
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_USER_ID
                      parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSNumber *)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:vehicle
                         parentEntityMainTable:TBL_MAIN_VEHICLE
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                      parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSNumber *)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForParentEntity:fuelStation
                         parentEntityMainTable:TBL_MAIN_FUEL_STATION
                   parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainFuelStationFromResultSet:rs];}
                    parentEntityMasterIdColumn:COL_MASTER_FUELSTATION_ID
                      parentEntityMainIdColumn:COL_MAIN_FUELSTATION_ID
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                            db:db
                                         error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForParentEntity:(PELMModelSupport *)parentEntity
                       parentEntityMainTable:(NSString *)parentEntityMainTable
                 parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
                  parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdCol
                    parentEntityMainIdColumn:(NSString *)parentEntityMainIdCol
                                    pageSize:(NSNumber *)pageSize
                            beforeDateLogged:(NSDate *)beforeDateLogged
                                          db:(FMDatabase *)db
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdCol
                   parentEntityMainIdColumn:parentEntityMainIdCol
                                   pageSize:pageSize
                          pageBoundaryWhere:[NSString stringWithFormat:@"%@ < ?", COL_FUELPL_PURCHASED_AT]
                            pageBoundaryArg:[PEUtils millisecondsFromDate:beforeDateLogged]
                          entityMasterTable:TBL_MASTER_FUELPURCHASE_LOG
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_FUELPURCHASE_LOG
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPFuelPurchaseLog *)o2 purchasedAt] compare:[(FPFuelPurchaseLog *)o1 purchasedAt]];}
                        orderByDomainColumn:COL_FUELPL_PURCHASED_AT
               orderByDomainColumnDirection:@"DESC"
                                         db:db
                                      error:errorBlk];
}

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                             error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepFuelPurchaseLogFromRemoteMaster:fuelPurchaseLog
                                             forUser:user
                                                  db:db
                                               error:errorBlk];
  }];
}

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                                db:(FMDatabase *)db
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterFuelPurchaseLog:fuelPurchaseLog
                                forUser:user
                                     db:db
                                  error:errorBlk];
  [PELMUtils insertRelations:[fuelPurchaseLog relations]
                   forEntity:fuelPurchaseLog
                 entityTable:TBL_MASTER_FUELPURCHASE_LOG
             localIdentifier:[fuelPurchaseLog localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:vehicle
                   fuelStation:fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                              db:db
                           error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:vehicle
                                   fuelStation:fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [fuelPurchaseLog setSyncInProgress:YES];
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                              db:db
                           error:errorBlk];
  }];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                   fuelStation:(FPFuelStation *)fuelStation
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:fuelStation
                  toMainTable:TBL_MAIN_FUEL_STATION
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelPurchaseLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [fuelPurchaseLog setFuelStationMainIdentifier:[fuelStation localMainIdentifier]];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStation globalIdentifier]];
  [fuelPurchaseLog setEditCount:1];
  [self insertIntoMainFuelPurchaseLog:fuelPurchaseLog
                              forUser:user
                              vehicle:vehicle
                          fuelStation:fuelStation
                                   db:db
                                error:errorBlk];
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                   db:(FMDatabase *)db
                                error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self vehicleForFuelPurchaseLog:fuelPurchaseLog db:db error:errorBlk];
  FPFuelStation *fuelStation = [self fuelStationForFuelPurchaseLog:fuelPurchaseLog db:db error:errorBlk];
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:fuelStation
                  toMainTable:TBL_MAIN_FUEL_STATION
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [fuelPurchaseLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStation globalIdentifier]];
  [fuelPurchaseLog setFuelStationMainIdentifier:[fuelStation localMainIdentifier]];
  return [PELMUtils prepareEntityForEdit:fuelPurchaseLog
                                      db:db
                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                     entityFromResultSet:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainFuelPurchaseLog:fuelPurchaseLog
                                                    forUser:user
                                                    vehicle:vehicle
                                                fuelStation:fuelStation
                                                         db:db
                                                      error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                   argsArray:[self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                            forUser:user
                                                 db:db
                                              error:errorBlk];
  }];
  return returnVal;
}

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:fuelStation
                    toMainTable:TBL_MAIN_FUEL_STATION
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainFuelStation:(FPFuelStation *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils doUpdate:[self updateStmtForMainFuelPurchaseLog]
              argsArray:[self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog vehicle:vehicle fuelStation:fuelStation]
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:fuelPurchaseLog
                                  mainTable:TBL_MAIN_FUELPURCHASE_LOG
                             mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:fuelPurchaseLog
                                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                          mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                                   error:errorBlk];
}

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils reloadEntity:fuelPurchaseLog
                   fromMainTable:TBL_MAIN_FUELPURCHASE_LOG
                     rsConverter:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSet:rs];}
                           error:errorBlk];
}

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelEditOfEntity:fuelPurchaseLog
                             mainTable:TBL_MAIN_FUELPURCHASE_LOG
                        mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                           masterTable:TBL_MASTER_FUELPURCHASE_LOG
                           rsConverter:^(FMResultSet *rs){return [self masterFuelPurchaseLogFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markFuelPurchaseLogsAsSyncInProgressForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_FUELPURCHASE_LOG
                                               entityFromResultSet:^(FMResultSet *rs){return [self mainFuelPurchaseLogFromResultSetForSync:rs];}
                                                        updateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                                             error:errorBlk];
}

- (void)cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        httpRespCode:(NSNumber *)httpRespCode
                           errorMask:(NSNumber *)errorMask
                             retryAt:(NSDate *)retryAt
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:fuelPurchaseLog
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                                                            forUser:(FPUser *)user
                                                                 db:(FMDatabase *)db
                                                              error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:fplog
                                      masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                              masterUpdateArgsBlk:^NSArray * (FPFuelPurchaseLog *theFplog) {return [self updateArgsForMasterFuelPurchaseLog:theFplog];}
                                        mainTable:TBL_MAIN_FUELPURCHASE_LOG
                          mainEntityFromResultSet:^FPFuelPurchaseLog * (FMResultSet *rs) {return [self mainFuelPurchaseLogFromResultSet:rs];}
                                   mainUpdateStmt:[self updateStmtForMainFuelPurchaseLog]
                                mainUpdateArgsBlk:^NSArray * (FPFuelPurchaseLog *theFplog) {return [self updateArgsForMainFuelPurchaseLog:theFplog];}
                                               db:db
                                            error:errorBlk];
}

- (BOOL)saveMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                       forVehicle:(FPVehicle *)vehicle
                   forFuelstation:(FPFuelStation *)fuelstation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils saveMasterEntity:fplog
                                masterTable:TBL_MASTER_FUELPURCHASE_LOG
                           masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                        masterUpdateArgsBlk:^ NSArray * (FPFuelPurchaseLog *theFplog) { return [self updateArgsForMasterFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation]; }
                                  mainTable:TBL_MAIN_FUELPURCHASE_LOG
                    mainEntityFromResultSet:^ FPFuelPurchaseLog * (FMResultSet *rs) { return [self mainFuelPurchaseLogFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainFuelPurchaseLog]
                          mainUpdateArgsBlk:^ NSArray * (FPFuelPurchaseLog *theFplog) { return [self updateArgsForMainFuelPurchaseLog:theFplog vehicle:vehicle fuelStation:fuelstation]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        forUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForNewEntity:fuelPurchaseLog
                                         mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                       masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                    mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                              forUser:user
                                                                                                                   db:db
                                                                                                                error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                              error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    NSNumber *masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_VEHICLE
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[fuelPurchaseLog vehicleGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPVehicle *masterVehicle = [FPVehicle vehicleWithLocalMasterIdentifier:masterLocalIdentifier];
    masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_FUEL_STATION
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[fuelPurchaseLog fuelStationGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPFuelStation *masterFuelStation = [FPFuelStation fuelStationWithLocalMasterIdentifier:masterLocalIdentifier];
    [_localModelUtils markAsSyncCompleteForUpdatedEntity:fuelPurchaseLog
                                               mainTable:TBL_MAIN_FUELPURCHASE_LOG
                                             masterTable:TBL_MASTER_FUELPURCHASE_LOG
                                          mainUpdateStmt:[self updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks]
                                       mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)entity];}
                                        masterUpdateStmt:[self updateStmtForMasterFuelPurchaseLog]
                                     masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                              vehicle:masterVehicle
                                                                                                          fuelStation:masterFuelStation];}
                                                      db:db
                                                   error:errorBlk];
  }];
}

#pragma mark - Environment Log

- (FPEnvironmentLog *)masterEnvlogWithId:(NSNumber *)envlogId error:(PELMDaoErrorBlk)errorBlk {
  NSString *envlogTable = TBL_MASTER_ENV_LOG;
  __block FPEnvironmentLog *envlog = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    envlog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", envlogTable, COL_LOCAL_ID]
                            entityTable:envlogTable
                          localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                              argsArray:@[envlogId]
                            rsConverter:^(FMResultSet *rs) { return [self masterEnvironmentLogFromResultSet:rs]; }
                                     db:db
                                  error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:envlog mainTable:TBL_MAIN_ENV_LOG db:db error:errorBlk];
    if (localMainId) {
      [envlog setLocalMainIdentifier:localMainId];
    }
  }];
  return envlog;
}

- (FPEnvironmentLog *)masterEnvlogWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  NSString *envlogTable = TBL_MASTER_ENV_LOG;
  __block FPEnvironmentLog *envlog = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    envlog = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", envlogTable, COL_GLOBAL_ID]
                            entityTable:envlogTable
                          localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                              argsArray:@[globalId]
                            rsConverter:^(FMResultSet *rs) { return [self masterEnvironmentLogFromResultSet:rs]; }
                                     db:db
                                  error:errorBlk];
    NSNumber *localMainId = [PELMUtils localMainIdentifierForEntity:envlog mainTable:TBL_MAIN_ENV_LOG db:db error:errorBlk];
    if (localMainId) {
      [envlog setLocalMainIdentifier:localMainId];
    }
  }];
  return envlog;
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                       error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteEnvironmentLog:envlog db:db error:errorBlk];
  }];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:envlog
          entityMainTable:TBL_MAIN_ENV_LOG
        entityMasterTable:TBL_MASTER_ENV_LOG
                       db:db
                    error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                                        entityMainTable:TBL_MAIN_ENV_LOG
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:user
                                  parentEntityMainTable:TBL_MAIN_USER
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_USER_ID
                               parentEntityMainIdColumn:COL_MAIN_USER_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                                        entityMainTable:TBL_MAIN_ENV_LOG
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_ENVL_LOG_DT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:pageSize
                     beforeDateLogged:nil
                                error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self environmentLogsForUser:user
                                  pageSize:@(pageSize)
                          beforeDateLogged:beforeDateLogged
                                        db:db
                                     error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self unsyncedEnvironmentLogsForUser:user db:db error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils unsyncedEntitiesForParentEntity:user
                              parentEntityMainTable:TBL_MAIN_USER
                        parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                         parentEntityMasterIdColumn:COL_MASTER_USER_ID
                           parentEntityMainIdColumn:COL_MAIN_USER_ID
                                  entityMasterTable:TBL_MASTER_ENV_LOG
                     masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                    entityMainTable:TBL_MAIN_ENV_LOG
                       mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                  comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                                orderByDomainColumn:COL_ENVL_LOG_DT
                       orderByDomainColumnDirection:@"DESC"
                                                 db:db
                                              error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                                        entityMainTable:TBL_MAIN_ENV_LOG
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numEntitiesForParentEntity:vehicle
                                  parentEntityMainTable:TBL_MAIN_VEHICLE
                            parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                             parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                               parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                      entityMasterTable:TBL_MASTER_ENV_LOG
                                        entityMainTable:TBL_MAIN_ENV_LOG
                                                  where:[NSString stringWithFormat:@"%@ > ?", COL_ENVL_LOG_DT]
                                               whereArg:@([newerThan timeIntervalSince1970] * 1000)
                                                     db:db
                                                  error:errorBlk];
  }];
  return numEntities;
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:pageSize
                        beforeDateLogged:nil
                                   error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *envLogs = @[];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    envLogs = [self environmentLogsForVehicle:vehicle
                                     pageSize:@(pageSize)
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
  }];
  return envLogs;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:@(pageSize)
                     beforeDateLogged:nil
                                   db:db
                                error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:@(pageSize)
                        beforeDateLogged:nil
                                      db:db
                                   error:errorBlk];
}

- (FPEnvironmentLog *)mostRecentEnvironmentLogForUser:(FPUser *)user
                                                   db:(FMDatabase *)db
                                                error:(PELMDaoErrorBlk)errorBlk {
  NSArray *envLogs =
  [self environmentLogsForUser:user pageSize:1 db:db error:errorBlk];
  if (envLogs && ([envLogs count] == 1)) {
    return envLogs[0];
  }
  return nil;
}

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                      error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self masterVehicleForMasterEnvLog:envlog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils masterParentForMasterChildEntity:envlog
                                           parentEntityMasterTable:TBL_MASTER_VEHICLE
                                        parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                                     parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                            childEntityMasterTable:TBL_MASTER_ENV_LOG
                                                                db:db
                                                             error:errorBlk];
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForEnvironmentLog:envLog db:db error:errorBlk];
  }];
  return vehicle;
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envLog
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  return (FPVehicle *) [PELMUtils parentForChildEntity:envLog
                                 parentEntityMainTable:TBL_MAIN_VEHICLE
                               parentEntityMasterTable:TBL_MASTER_VEHICLE
                              parentEntityMainFkColumn:COL_MAIN_VEHICLE_ID
                            parentEntityMasterFkColumn:COL_MASTER_VEHICLE_ID
                           parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                         parentEntityMasterRsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                  childEntityMainTable:TBL_MAIN_ENV_LOG
                            childEntityMainRsConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                childEntityMasterTable:TBL_MASTER_ENV_LOG
                                                    db:db
                                                 error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentEnvironmentLogForUser:(FPUser *)user
                                                      db:(FMDatabase *)db
                                                   error:(PELMDaoErrorBlk)errorBlk {
  FPEnvironmentLog *mostRecentFpLog =
  [self mostRecentEnvironmentLogForUser:user db:db error:errorBlk];
  if (mostRecentFpLog) {
    return [self vehicleForEnvironmentLog:mostRecentFpLog db:db error:errorBlk];
  }
  return nil;
}

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  __block FPVehicle *vehicle = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    vehicle = [self vehicleForMostRecentEnvironmentLogForUser:user db:db error:errorBlk];
    if (!vehicle) {
      NSArray *vehicles = [self vehiclesForUser:user db:db error:errorBlk];
      if ([vehicles count] > 0) {
        vehicle = vehicles[0];
      }
    }
  }];
  return vehicle;
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:nil
                     beforeDateLogged:nil
                                   db:db
                                error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSNumber *)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForParentEntity:user
                        parentEntityMainTable:TBL_MAIN_USER
                  parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                   parentEntityMasterIdColumn:COL_MASTER_USER_ID
                     parentEntityMainIdColumn:COL_MAIN_USER_ID
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:nil
                        beforeDateLogged:nil
                                      db:db
                                   error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSNumber *)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForParentEntity:vehicle
                        parentEntityMainTable:TBL_MAIN_VEHICLE
                  parentEntityMainRsConverter:^(FMResultSet *rs){return [self mainVehicleFromResultSet:rs];}
                   parentEntityMasterIdColumn:COL_MASTER_VEHICLE_ID
                     parentEntityMainIdColumn:COL_MAIN_VEHICLE_ID
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                           db:db
                                        error:errorBlk];
}

- (NSArray *)environmentLogsForParentEntity:(PELMModelSupport *)parentEntity
                      parentEntityMainTable:(NSString *)parentEntityMainTable
                parentEntityMainRsConverter:(entityFromResultSetBlk)parentEntityMainRsConverter
                 parentEntityMasterIdColumn:(NSString *)parentEntityMasterIdCol
                   parentEntityMainIdColumn:(NSString *)parentEntityMainIdCol
                                   pageSize:(NSNumber *)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                         db:(FMDatabase *)db
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesForParentEntity:parentEntity
                      parentEntityMainTable:parentEntityMainTable
                parentEntityMainRsConverter:parentEntityMainRsConverter
                 parentEntityMasterIdColumn:parentEntityMasterIdCol
                   parentEntityMainIdColumn:parentEntityMainIdCol
                                   pageSize:pageSize
                          pageBoundaryWhere:[NSString stringWithFormat:@"%@ < ?", COL_ENVL_LOG_DT]
                            pageBoundaryArg:[PEUtils millisecondsFromDate:beforeDateLogged]
                          entityMasterTable:TBL_MASTER_ENV_LOG
             masterEntityResultSetConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                            entityMainTable:TBL_MAIN_ENV_LOG
               mainEntityResultSetConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                          comparatorForSort:^NSComparisonResult(id o1,id o2){return [[(FPEnvironmentLog *)o2 logDate] compare:[(FPEnvironmentLog *)o1 logDate]];}
                        orderByDomainColumn:COL_ENVL_LOG_DT
               orderByDomainColumnDirection:@"DESC"
                                         db:db
                                      error:errorBlk];
}

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                            error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self persistDeepEnvironmentLogFromRemoteMaster:environmentLog
                                            forUser:user
                                                 db:db
                                              error:errorBlk];
  }];
}

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                               db:(FMDatabase *)db
                                            error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterEnvironmentLog:environmentLog
                               forUser:user
                                    db:db
                                 error:errorBlk];
  [PELMUtils insertRelations:[environmentLog relations]
                   forEntity:environmentLog
                 entityTable:TBL_MASTER_ENV_LOG
             localIdentifier:[environmentLog localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:vehicle
                        error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                             db:db
                          error:errorBlk];
  }];
}

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                      forUser:(FPUser *)user
                                      vehicle:vehicle
                                        error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [environmentLog setSyncInProgress:YES];
    [self saveNewEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                             db:db
                          error:errorBlk];
  }];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:(FPVehicle *)vehicle
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [environmentLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  [environmentLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [environmentLog setEditCount:1];
  [self insertIntoMainEnvironmentLog:environmentLog
                             forUser:user
                             vehicle:vehicle
                                  db:db
                               error:errorBlk];
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicle = [self vehicleForEnvironmentLog:environmentLog db:db error:errorBlk];
  [PELMUtils copyMasterEntity:user
                  toMainTable:TBL_MAIN_USER
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [PELMUtils copyMasterEntity:vehicle
                  toMainTable:TBL_MAIN_VEHICLE
         mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                           db:db
                        error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicle globalIdentifier]];
  [environmentLog setVehicleMainIdentifier:[vehicle localMainIdentifier]];
  return [PELMUtils prepareEntityForEdit:environmentLog
                                      db:db
                               mainTable:TBL_MAIN_ENV_LOG
                     entityFromResultSet:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                      mainEntityInserter:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                        [self insertIntoMainEnvironmentLog:environmentLog
                                                   forUser:user
                                                   vehicle:vehicle
                                                        db:db
                                                     error:errorBlk];}
                       mainEntityUpdater:^(PELMMainSupport *entity, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
                         [PELMUtils doUpdate:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                   argsArray:[self updateArgsForMainEnvironmentLog:environmentLog]
                                          db:db
                                       error:errorBlk];}
                                   error:errorBlk];
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL returnVal;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self prepareEnvironmentLogForEdit:environmentLog
                                           forUser:user
                                                db:db
                                             error:errorBlk];
  }];
  return returnVal;
}

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils copyMasterEntity:user
                    toMainTable:TBL_MAIN_USER
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainUser:(FPUser *)entity db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils copyMasterEntity:vehicle
                    toMainTable:TBL_MAIN_VEHICLE
           mainTableInserterBlk:^(PELMMasterSupport *entity) {[self insertIntoMainVehicle:(FPVehicle *)entity forUser:user db:db error:errorBlk];}
                             db:db
                          error:errorBlk];
    [PELMUtils doUpdate:[self updateStmtForMainEnvironmentLog]
              argsArray:[self updateArgsForMainEnvironmentLog:environmentLog vehicle:vehicle]
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:environmentLog
                                  mainTable:TBL_MAIN_ENV_LOG
                             mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                          mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                      error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                               error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:environmentLog
                                               mainTable:TBL_MAIN_ENV_LOG
                                          mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                       mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                                   error:errorBlk];
}

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils reloadEntity:environmentLog
                   fromMainTable:TBL_MAIN_ENV_LOG
                     rsConverter:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                           error:errorBlk];
}

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelEditOfEntity:environmentLog
                             mainTable:TBL_MAIN_ENV_LOG
                        mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                     mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                           masterTable:TBL_MASTER_ENV_LOG
                           rsConverter:^(FMResultSet *rs){return [self masterEnvironmentLogFromResultSet:rs];}
                                 error:errorBlk];
}

- (NSArray *)markEnvironmentLogsAsSyncInProgressForUser:(FPUser *)user
                                                  error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils markEntitiesAsSyncInProgressInMainTable:TBL_MAIN_ENV_LOG
                                               entityFromResultSet:^(FMResultSet *rs){return [self mainEnvironmentLogFromResultSet:rs];}
                                                        updateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                                             error:errorBlk];
}

- (void)cancelSyncForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       httpRespCode:(NSNumber *)httpRespCode
                          errorMask:(NSNumber *)errorMask
                            retryAt:(NSDate *)retryAt
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:environmentLog
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                         mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                      mainUpdateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                  error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                                                           forUser:(FPUser *)user
                                                                db:(FMDatabase *)db
                                                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingMasterEntity:envlog
                                      masterTable:TBL_MASTER_ENV_LOG
                                  masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)entity forUser:user db:db error:errorBlk];}
                                 masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                              masterUpdateArgsBlk:^NSArray * (FPEnvironmentLog *theEnvlog) {return [self updateArgsForMasterEnvironmentLog:theEnvlog];}
                                        mainTable:TBL_MAIN_ENV_LOG
                          mainEntityFromResultSet:^FPEnvironmentLog * (FMResultSet *rs) {return [self mainEnvironmentLogFromResultSet:rs];}
                                   mainUpdateStmt:[self updateStmtForMainEnvironmentLog]
                                mainUpdateArgsBlk:^NSArray * (FPEnvironmentLog *theEnvlog) {return [self updateArgsForMainEnvironmentLog:theEnvlog];}
                                               db:db
                                            error:errorBlk];
}

- (BOOL)saveMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                      forVehicle:(FPVehicle *)vehicle
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  return [_localModelUtils saveMasterEntity:envlog
                                masterTable:TBL_MASTER_ENV_LOG
                           masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                        masterUpdateArgsBlk:^ NSArray * (FPEnvironmentLog *theEnvlog) { return [self updateArgsForMasterEnvironmentLog:theEnvlog vehicle:vehicle]; }
                                  mainTable:TBL_MAIN_ENV_LOG
                    mainEntityFromResultSet:^ FPEnvironmentLog * (FMResultSet *rs) { return [self mainEnvironmentLogFromResultSet:rs]; }
                             mainUpdateStmt:[self updateStmtForMainEnvironmentLog]
                          mainUpdateArgsBlk:^ NSArray * (FPEnvironmentLog *theEnvlog) { return [self updateArgsForMainEnvironmentLog:theEnvlog vehicle:vehicle]; }
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForNewEntity:environmentLog
                                         mainTable:TBL_MAIN_ENV_LOG
                                       masterTable:TBL_MASTER_ENV_LOG
                                    mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                 mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                   masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                             forUser:user
                                                                                                                  db:db
                                                                                                               error:errorBlk];}
                                             error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                             error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    NSNumber *masterLocalIdentifier =
    [PELMUtils numberFromTable:TBL_MASTER_VEHICLE
                  selectColumn:COL_LOCAL_ID
                   whereColumn:COL_GLOBAL_ID
                    whereValue:[environmentLog vehicleGlobalIdentifier]
                            db:db
                         error:errorBlk];
    FPVehicle *masterVehicle = [FPVehicle vehicleWithLocalMasterIdentifier:masterLocalIdentifier];
    [_localModelUtils markAsSyncCompleteForUpdatedEntity:environmentLog
                                               mainTable:TBL_MAIN_ENV_LOG
                                             masterTable:TBL_MASTER_ENV_LOG
                                          mainUpdateStmt:[self updateStmtForMainEnvironmentLogSansVehicleFks]
                                       mainUpdateArgsBlk:^(id entity){return [self updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)entity];}
                                        masterUpdateStmt:[self updateStmtForMasterEnvironmentLog]
                                     masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                             vehicle:masterVehicle];}
                                                      db:db
                                                   error:errorBlk];
  }];
}

#pragma mark - Result set -> Model helpers (private)

- (FPUser *)mainUserFromResultSet:(FMResultSet *)rs {
  return [[FPUser alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                               localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                    globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                           mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                           relations:nil
                                           deletedAt:nil // NA (this is a master store-only column)
                                           updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                      editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                      syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                              synced:[rs boolForColumn:COL_MAN_SYNCED]
                                           editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                    syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                         syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                         syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                                name:[rs stringForColumn:COL_USR_NAME]
                                               email:[rs stringForColumn:COL_USR_EMAIL]
                                            username:[rs stringForColumn:COL_USR_USERNAME]
                                            password:[rs stringForColumn:COL_USR_PASSWORD_HASH]];
}

- (FPUser *)masterUserFromResultSet:(FMResultSet *)rs {
  return [[FPUser alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                               localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                    globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                           mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                           relations:nil
                                           deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                           updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                      editInProgress:NO  // NA (this is a main store-only column)
                                      syncInProgress:NO  // NA (this is a main store-only column)
                                              synced:NO  // NA (this is a main store-only column)
                                           editCount:0   // NA (this is a main store-only column)
                                    syncHttpRespCode:nil // NA (this is a main store-only column)
                                         syncErrMask:nil // NA (this is a main store-only column)
                                         syncRetryAt:nil // NA (this is a main store-only column)
                                                name:[rs stringForColumn:COL_USR_NAME]
                                               email:[rs stringForColumn:COL_USR_EMAIL]
                                            username:[rs stringForColumn:COL_USR_USERNAME]
                                            password:[rs stringForColumn:COL_USR_PASSWORD_HASH]];
}

- (FPVehicle *)mainVehicleFromResultSet:(FMResultSet *)rs {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                  localMasterIdentifier:nil // NA (this is a master store-only column)
                                       globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                              relations:nil
                                            deletedAt:nil // NA (this is a master store-only column)
                                              updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                   dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                         editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                         syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                 synced:[rs boolForColumn:COL_MAN_SYNCED]
                                              editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                       syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                            syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                            syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                                   name:[rs stringForColumn:COL_VEH_NAME]
                                          defaultOctane:[PELMUtils numberFromResultSet:rs columnName:COL_VEH_DEFAULT_OCTANE]
                                           fuelCapacity:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_VEH_FUEL_CAPACITY]];
}

- (FPVehicle *)masterVehicleFromResultSet:(FMResultSet *)rs {
  return [[FPVehicle alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                  localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                       globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                              relations:nil
                                            deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                              updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                   dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                         editInProgress:NO  // NA (this is a main store-only column)
                                         syncInProgress:NO  // NA (this is a main store-only column)
                                                 synced:NO  // NA (this is a main store-only column)
                                              editCount:0   // NA (this is a main store-only column)
                                       syncHttpRespCode:nil // NA (this is a main store-only column)
                                            syncErrMask:nil // NA (this is a main store-only column)
                                            syncRetryAt:nil // NA (this is a main store-only column)
                                                   name:[rs stringForColumn:COL_VEH_NAME]
                                          defaultOctane:[PELMUtils numberFromResultSet:rs columnName:COL_VEH_DEFAULT_OCTANE]
                                           fuelCapacity:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_VEH_FUEL_CAPACITY]];
}

- (FPFuelStation *)mainFuelStationFromResultSet:(FMResultSet *)rs {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                      localMasterIdentifier:nil // NA (this is a master store-only column)
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                deletedAt:nil // NA (this is a master store-only column)
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                       dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                             editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                             syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                     synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                  editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                           syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                                       name:[rs stringForColumn:COL_FUELST_NAME]
                                                     street:[rs stringForColumn:COL_FUELST_STREET]
                                                       city:[rs stringForColumn:COL_FUELST_CITY]
                                                      state:[rs stringForColumn:COL_FUELST_STATE]
                                                        zip:[rs stringForColumn:COL_FUELST_ZIP]
                                                   latitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LATITUDE]
                                                  longitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LONGITUDE]];
}

- (FPFuelStation *)masterFuelStationFromResultSet:(FMResultSet *)rs {
  return [[FPFuelStation alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                      localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                       dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                             editInProgress:NO  // NA (this is a main store-only column)
                                             syncInProgress:NO  // NA (this is a main store-only column)
                                                     synced:NO  // NA (this is a main store-only column)
                                                  editCount:0   // NA (this is a main store-only column)
                                           syncHttpRespCode:nil // NA (this is a main store-only column)
                                                syncErrMask:nil // NA (this is a main store-only column)
                                                syncRetryAt:nil // NA (this is a main store-only column)
                                                       name:[rs stringForColumn:COL_FUELST_NAME]
                                                     street:[rs stringForColumn:COL_FUELST_STREET]
                                                       city:[rs stringForColumn:COL_FUELST_CITY]
                                                      state:[rs stringForColumn:COL_FUELST_STATE]
                                                        zip:[rs stringForColumn:COL_FUELST_ZIP]
                                                   latitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LATITUDE]
                                                  longitude:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELST_LONGITUDE]];
}

- (FPFuelPurchaseLog *)mainFuelPurchaseLogFromResultSetForSync:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                          localMasterIdentifier:nil // NA (this is a master store-only column)
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                    deletedAt:nil // NA (this is a master store-only column)
                                                   updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                           dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                 editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                 syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                         synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                      editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                               syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                    syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                    syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                          vehicleMainIdentifier:[rs objectForColumnName:COL_MAIN_VEHICLE_ID]
                                      fuelStationMainIdentifier:[rs objectForColumnName:COL_MAIN_FUELSTATION_ID]
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                        purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]];
}

- (FPFuelPurchaseLog *)mainFuelPurchaseLogFromResultSet:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                          localMasterIdentifier:nil // NA (this is a master store-only column)
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                      deletedAt:nil // NA (this is a master store-only column)
                                                      updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                           dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                 editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                 syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                         synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                      editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                               syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                    syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                    syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                        vehicleMainIdentifier:nil
                                    fuelStationMainIdentifier:nil
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                        purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]];
}

- (FPFuelPurchaseLog *)masterFuelPurchaseLogFromResultSet:(FMResultSet *)rs {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                          localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                               globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                      mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                      relations:nil
                                                      deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                      updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                           dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                                 editInProgress:NO  // NA (this is a main store-only column)
                                                 syncInProgress:NO  // NA (this is a main store-only column)
                                                         synced:NO  // NA (this is a main store-only column)
                                                      editCount:0   // NA (this is a main store-only column)
                                               syncHttpRespCode:nil // NA (this is a main store-only column)
                                                    syncErrMask:nil // NA (this is a main store-only column)
                                                    syncRetryAt:nil // NA (this is a main store-only column)
                                        vehicleMainIdentifier:nil
                                    fuelStationMainIdentifier:nil
                                                     numGallons:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_NUM_GALLONS]
                                                         octane:[PELMUtils numberFromResultSet:rs columnName:COL_FUELPL_OCTANE]
                                                    gallonPrice:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_PRICE_PER_GALLON]
                                                     gotCarWash:[rs boolForColumn:COL_FUELPL_GOT_CAR_WASH]
                                       carWashPerGallonDiscount:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT]
                                                        purchasedAt:[PELMUtils dateFromResultSet:rs columnName:COL_FUELPL_PURCHASED_AT]];
}

- (FPEnvironmentLog *)mainEnvironmentLogFromResultSet:(FMResultSet *)rs {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                         localMasterIdentifier:nil // NA (this is a master store-only column)
                                              globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                     mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                     relations:nil
                                                     deletedAt:nil // NA (this is a master store-only column)
                                                     updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                          dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                editInProgress:[rs boolForColumn:COL_MAN_EDIT_IN_PROGRESS]
                                                syncInProgress:[rs boolForColumn:COL_MAN_SYNC_IN_PROGRESS]
                                                        synced:[rs boolForColumn:COL_MAN_SYNCED]
                                                     editCount:[rs intForColumn:COL_MAN_EDIT_COUNT]
                                              syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_HTTP_RESP_CODE]
                                                   syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_MAN_SYNC_ERR_MASK]
                                                   syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_SYNC_RETRY_AT]
                                         vehicleMainIdentifier:[rs objectForColumnName:COL_MAIN_VEHICLE_ID]
                                                      odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_ODOMETER_READING]
                                                reportedAvgMpg:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPG_READING]
                                                reportedAvgMph:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPH_READING]
                                           reportedOutsideTemp:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_OUTSIDE_TEMP_READING]
                                                       logDate:[PELMUtils dateFromResultSet:rs columnName:COL_ENVL_LOG_DT]
                                                   reportedDte:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_DTE]];
}

- (FPEnvironmentLog *)masterEnvironmentLogFromResultSet:(FMResultSet *)rs {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                         localMasterIdentifier:[rs objectForColumnName:COL_LOCAL_ID]
                                              globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                     mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                     relations:nil
                                                     deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_DELETED_DT]
                                                     updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MST_UPDATED_AT]
                                          dateCopiedFromMaster:nil // NA (this is a main store-only column)
                                                editInProgress:NO  // NA (this is a main store-only column)
                                                syncInProgress:NO  // NA (this is a main store-only column)
                                                        synced:NO  // NA (this is a main store-only column)
                                                     editCount:0   // NA (this is a main store-only column)
                                              syncHttpRespCode:nil // NA (this is a main store-only column)
                                                   syncErrMask:nil // NA (this is a main store-only column)
                                                   syncRetryAt:nil // NA (this is a main store-only column)
                                       vehicleMainIdentifier:nil
                                                      odometer:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_ODOMETER_READING]
                                                reportedAvgMpg:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPG_READING]
                                                reportedAvgMph:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_MPH_READING]
                                           reportedOutsideTemp:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_OUTSIDE_TEMP_READING]
                                                       logDate:[PELMUtils dateFromResultSet:rs columnName:COL_ENVL_LOG_DT]
                                                   reportedDte:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_ENVL_DTE]];
}

#pragma mark - Fuel Station data access helpers (private)

- (void)insertIntoMasterFuelStation:(FPFuelStation *)fuelStation
                            forUser:(FPUser *)user
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
                    %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_FUEL_STATION,
                    COL_MASTER_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_FUELST_NAME,
                    COL_FUELST_STREET,
                    COL_FUELST_CITY,
                    COL_FUELST_STATE,
                    COL_FUELST_ZIP,
                    COL_FUELST_LATITUDE,
                    COL_FUELST_LONGITUDE];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([fuelStation globalIdentifier]),
                              orNil([[fuelStation mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[fuelStation deletedAt]]),
                              orNil([fuelStation name]),
                              orNil([fuelStation street]),
                              orNil([fuelStation city]),
                              orNil([fuelStation state]),
                              orNil([fuelStation zip]),
                              orNil([fuelStation latitude]),
                              orNil([fuelStation longitude])]
                     entity:fuelStation
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainFuelStation:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
                    (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
                    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_FUEL_STATION,
                    COL_MAIN_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_FUELST_NAME,
                    COL_FUELST_STREET,
                    COL_FUELST_CITY,
                    COL_FUELST_STATE,
                    COL_FUELST_ZIP,
                    COL_FUELST_LATITUDE,
                    COL_FUELST_LONGITUDE,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[orNil([user localMainIdentifier]),
                            orNil([fuelStation globalIdentifier]),
                            orNil([[fuelStation mediaType] description]),
                            orNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
                            orNil([PEUtils millisecondsFromDate:[fuelStation dateCopiedFromMaster]]),
                            orNil([fuelStation name]),
                            orNil([fuelStation street]),
                            orNil([fuelStation city]),
                            orNil([fuelStation state]),
                            orNil([fuelStation zip]),
                            orNil([fuelStation latitude]),
                            orNil([fuelStation longitude]),
                            [NSNumber numberWithBool:[fuelStation editInProgress]],
                            [NSNumber numberWithBool:[fuelStation syncInProgress]],
                            [NSNumber numberWithBool:[fuelStation synced]],
                            [NSNumber numberWithInteger:[fuelStation editCount]],
                            orNil([fuelStation syncHttpRespCode]),
                            orNil([fuelStation syncErrMask]),
                            orNil([PEUtils millisecondsFromDate:[fuelStation syncRetryAt]])]
                   entity:fuelStation
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterFuelStation {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_FUEL_STATION,// table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_FUELST_NAME,        // col5
          COL_FUELST_STREET,
          COL_FUELST_CITY,
          COL_FUELST_STATE,
          COL_FUELST_ZIP,
          COL_FUELST_LATITUDE,
          COL_FUELST_LONGITUDE,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterFuelStation:(FPFuelStation *)fuelStation {
  return @[orNil([fuelStation globalIdentifier]),
           orNil([[fuelStation mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[fuelStation deletedAt]]),
           orNil([fuelStation name]),
           orNil([fuelStation street]),
           orNil([fuelStation city]),
           orNil([fuelStation state]),
           orNil([fuelStation zip]),
           orNil([fuelStation latitude]),
           orNil([fuelStation longitude]),
           [fuelStation localMasterIdentifier]];
}

- (NSString *)updateStmtForMainFuelStation {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUEL_STATION,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELST_NAME,                       // col5
          COL_FUELST_STREET,
          COL_FUELST_CITY,
          COL_FUELST_STATE,
          COL_FUELST_ZIP,
          COL_FUELST_LATITUDE,
          COL_FUELST_LONGITUDE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainFuelStation:(FPFuelStation *)fuelStation {
  return @[orNil([fuelStation globalIdentifier]),
           orNil([[fuelStation mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[fuelStation updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[fuelStation dateCopiedFromMaster]]),
           orNil([fuelStation name]),
           orNil([fuelStation street]),
           orNil([fuelStation city]),
           orNil([fuelStation state]),
           orNil([fuelStation zip]),
           orNil([fuelStation latitude]),
           orNil([fuelStation longitude]),
           [NSNumber numberWithBool:[fuelStation editInProgress]],
           [NSNumber numberWithBool:[fuelStation syncInProgress]],
           [NSNumber numberWithBool:[fuelStation synced]],
           [NSNumber numberWithInteger:[fuelStation editCount]],
           orNil([fuelStation syncHttpRespCode]),
           orNil([fuelStation syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[fuelStation syncRetryAt]]),
           [fuelStation localMainIdentifier]];
}

#pragma mark - Vehicle data access helpers (private)

- (void)insertIntoMasterVehicle:(FPVehicle *)vehicle
                        forUser:(FPUser *)user
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
                    %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_VEHICLE,
                    COL_MASTER_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_VEH_NAME,
                    COL_VEH_DEFAULT_OCTANE,
                    COL_VEH_FUEL_CAPACITY];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([vehicle globalIdentifier]),
                              orNil([[vehicle mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[vehicle deletedAt]]),
                              orNil([vehicle name]),
                              orNil([vehicle defaultOctane]),
                              orNil([vehicle fuelCapacity])]
                     entity:vehicle
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainVehicle:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, \
                    %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_VEHICLE,
                    COL_MAIN_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_VEH_NAME,
                    COL_VEH_DEFAULT_OCTANE,
                    COL_VEH_FUEL_CAPACITY,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[orNil([user localMainIdentifier]),
                            orNil([vehicle globalIdentifier]),
                            orNil([[vehicle mediaType] description]),
                            orNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
                            orNil([PEUtils millisecondsFromDate:[vehicle dateCopiedFromMaster]]),
                            orNil([vehicle name]),
                            orNil([vehicle defaultOctane]),
                            orNil([vehicle fuelCapacity]),
                            [NSNumber numberWithBool:[vehicle editInProgress]],
                            [NSNumber numberWithBool:[vehicle syncInProgress]],
                            [NSNumber numberWithBool:[vehicle synced]],
                            [NSNumber numberWithInteger:[vehicle editCount]],
                            orNil([vehicle syncHttpRespCode]),
                            orNil([vehicle syncErrMask]),
                            orNil([PEUtils millisecondsFromDate:[vehicle syncRetryAt]])]
                   entity:vehicle
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterVehicle {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_VEHICLE,     // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_VEH_NAME,           // col5
          COL_VEH_DEFAULT_OCTANE,
          COL_VEH_FUEL_CAPACITY,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterVehicle:(FPVehicle *)vehicle {
  return @[orNil([vehicle globalIdentifier]),
           orNil([[vehicle mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[vehicle deletedAt]]),
           orNil([vehicle name]),
           orNil([vehicle defaultOctane]),
           orNil([vehicle fuelCapacity]),
           [vehicle localMasterIdentifier]];
}

- (NSString *)updateStmtForMainVehicle {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_VEHICLE,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_VEH_NAME,                       // col5
          COL_VEH_DEFAULT_OCTANE,
          COL_VEH_FUEL_CAPACITY,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainVehicle:(FPVehicle *)vehicle {
  return @[orNil([vehicle globalIdentifier]),
           orNil([[vehicle mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[vehicle updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[vehicle dateCopiedFromMaster]]),
           orNil([vehicle name]),
           orNil([vehicle defaultOctane]),
           orNil([vehicle fuelCapacity]),
           [NSNumber numberWithBool:[vehicle editInProgress]],
           [NSNumber numberWithBool:[vehicle syncInProgress]],
           [NSNumber numberWithBool:[vehicle synced]],
           [NSNumber numberWithInteger:[vehicle editCount]],
           orNil([vehicle syncHttpRespCode]),
           orNil([vehicle syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[vehicle syncRetryAt]]),
           [vehicle localMainIdentifier]];
}

#pragma mark - User data access helpers (quasi-private)

- (FPUser *)mainUserWithError:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self mainUserWithDatabase:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)mainUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSString *userTable = TBL_MAIN_USER;
  return [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", userTable]
                        entityTable:userTable
                      localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMainIdentifier]; }
                          argsArray:@[]
                        rsConverter:^(FMResultSet *rs){return [self mainUserFromResultSet:rs];}
                                 db:db
                              error:errorBlk];
}

- (FPUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk {
  __block FPUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self masterUserWithDatabase:db error:errorBlk];
  }];
  return user;
}

- (FPUser *)masterUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSString *userTable = TBL_MASTER_USER;
  return [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", userTable]
                        entityTable:userTable
                      localIdGetter:^NSNumber *(PELMModelSupport *entity) { return [entity localMasterIdentifier]; }
                          argsArray:@[]
                        rsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
                                 db:db
                              error:errorBlk];
}

#pragma mark - User data access helpers (private)

- (NSString *)updateStmtForMasterUser {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_USER,        // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT, // col3
          COL_MST_DELETED_DT,     // col4
          COL_USR_NAME,           // col5
          COL_USR_EMAIL,          // col6
          COL_USR_USERNAME,       // col7
          COL_USR_PASSWORD_HASH,  // col8
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterUser:(FPUser *)user {
  return @[orNil([user globalIdentifier]),
           orNil([[user mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[user deletedAt]]),
           orNil([user name]),
           orNil([user email]),
           orNil([user username]),
           orNil([user password]),
           [user localMasterIdentifier]];
}

- (NSString *)updateStmtForMainUser {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_USER,                      // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_USR_NAME,                       // col5
          COL_USR_EMAIL,                      // col6
          COL_USR_USERNAME,                   // col7
          COL_USR_PASSWORD_HASH,              // col8
          COL_MAN_EDIT_IN_PROGRESS,           // col10
          COL_MAN_SYNC_IN_PROGRESS,           // col11
          COL_MAN_SYNCED,                     // col12
          COL_MAN_EDIT_COUNT,                 // col15
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_MASTER_USER_ID];                // where, col1
}

- (NSArray *)updateArgsForMainUser:(FPUser *)user {
  return @[orNil([user globalIdentifier]),
           orNil([[user mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[user dateCopiedFromMaster]]),
           orNil([user name]),
           orNil([user email]),
           orNil([user username]),
           orNil([user password]),
           [NSNumber numberWithBool:[user editInProgress]],
           [NSNumber numberWithBool:[user syncInProgress]],
           [NSNumber numberWithBool:[user synced]],
           [NSNumber numberWithInteger:[user editCount]],
           orNil([user syncHttpRespCode]),
           orNil([user syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[user syncRetryAt]]),
           [user localMainIdentifier]];
}

- (void)insertIntoMainUser:(FPUser *)user
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \
?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_USER,
                    COL_LOCAL_ID,
                    COL_MASTER_USER_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_USR_NAME,
                    COL_USR_EMAIL,
                    COL_USR_USERNAME,
                    COL_USR_PASSWORD_HASH,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[orNil([user localMasterIdentifier]),
                            orNil([user localMasterIdentifier]),
                            orNil([user globalIdentifier]),
                            orNil([[user mediaType] description]),
                            orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
                            orNil([PEUtils millisecondsFromDate:[user dateCopiedFromMaster]]),
                            orNil([user name]),
                            orNil([user email]),
                            orNil([user username]),
                            orNil([user password]),
                            [NSNumber numberWithBool:[user editInProgress]],
                            [NSNumber numberWithBool:[user syncInProgress]],
                            [NSNumber numberWithBool:[user synced]],
                            [NSNumber numberWithInteger:[user editCount]],
                            orNil([user syncHttpRespCode]),
                            orNil([user syncErrMask]),
                            orNil([PEUtils millisecondsFromDate:[user syncRetryAt]])]
                   entity:user
                       db:db
                    error:errorBlk];
}

- (void)insertIntoMasterUser:(FPUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_USER,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_USR_NAME,
                    COL_USR_EMAIL,
                    COL_USR_USERNAME,
                    COL_USR_PASSWORD_HASH];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user globalIdentifier]),
                              orNil([[user mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[user deletedAt]]),
                              orNil([user name]),
                              orNil([user email]),
                              orNil([user username]),
                              orNil([user password])]
                     entity:user
                         db:db
                      error:errorBlk];
}

#pragma mark - Fuel Purchase Log data access helpers (private)

- (void)insertIntoMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                forUser:(FPUser *)user
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleGlobalId = [fuelPurchaseLog vehicleGlobalIdentifier];
  if (!vehicleGlobalId && [fuelPurchaseLog vehicleMainIdentifier]) {
    vehicleGlobalId = [PELMUtils stringFromTable:TBL_MAIN_VEHICLE
                                    selectColumn:COL_GLOBAL_ID
                                     whereColumn:COL_LOCAL_ID
                                      whereValue:[fuelPurchaseLog vehicleMainIdentifier]
                                              db:db
                                           error:errorBlk];
  }
  NSString *fuelStationGlobalId = [fuelPurchaseLog fuelStationGlobalIdentifier];
  if (!fuelStationGlobalId && [fuelPurchaseLog fuelStationMainIdentifier]) {
    fuelStationGlobalId = [PELMUtils stringFromTable:TBL_MAIN_FUEL_STATION
                                        selectColumn:COL_GLOBAL_ID
                                         whereColumn:COL_LOCAL_ID
                                          whereValue:[fuelPurchaseLog fuelStationMainIdentifier]
                                                  db:db
                                               error:errorBlk];
  }
  NSAssert(vehicleGlobalId, @"Fuel purchase log's vehicle global ID is nil");
  NSAssert(fuelStationGlobalId, @"Fuel purchase log's fuel station global ID is nil");
  FPVehicle *vehicle =
  (FPVehicle *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_VEHICLE, COL_GLOBAL_ID]
                              entityTable:TBL_MASTER_VEHICLE
                            localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                argsArray:@[vehicleGlobalId]
                              rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                       db:db
                                    error:errorBlk];
  FPFuelStation *fuelStation =
  (FPFuelStation *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_FUEL_STATION, COL_GLOBAL_ID]
                                  entityTable:TBL_MASTER_FUEL_STATION
                                localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                    argsArray:@[fuelStationGlobalId] //[fuelPurchaseLog fuelStationMainIdentifier]]
                                  rsConverter:^(FMResultSet *rs){return [self masterFuelStationFromResultSet:rs];}
                                           db:db
                                        error:errorBlk];
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_FUELPURCHASE_LOG,
                    COL_MASTER_USER_ID,
                    COL_MASTER_VEHICLE_ID,
                    COL_MASTER_FUELSTATION_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_FUELPL_NUM_GALLONS,
                    COL_FUELPL_OCTANE,
                    COL_FUELPL_PRICE_PER_GALLON,
                    COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
                    COL_FUELPL_GOT_CAR_WASH,
                    COL_FUELPL_PURCHASED_AT];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([vehicle localMasterIdentifier]),
                              orNil([fuelStation localMasterIdentifier]),
                              orNil([fuelPurchaseLog globalIdentifier]),
                              orNil([[fuelPurchaseLog mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog deletedAt]]),
                              orNil([fuelPurchaseLog numGallons]),
                              orNil([fuelPurchaseLog octane]),
                              orNil([fuelPurchaseLog gallonPrice]),
                              orNil([fuelPurchaseLog carWashPerGallonDiscount]),
                              [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
                              orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]])]
                     entity:fuelPurchaseLog
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                              vehicle:(FPVehicle *)vehicle
                          fuelStation:(FPFuelStation *)fuelStation
                                   db:(FMDatabase *)db
                                error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
(%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_FUELPURCHASE_LOG,
                    COL_MAIN_USER_ID,
                    COL_MAIN_VEHICLE_ID,
                    COL_MAIN_FUELSTATION_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_FUELPL_NUM_GALLONS,
                    COL_FUELPL_OCTANE,
                    COL_FUELPL_PRICE_PER_GALLON,
                    COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
                    COL_FUELPL_GOT_CAR_WASH,
                    COL_FUELPL_PURCHASED_AT,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[orNil([user localMainIdentifier]),
                            orNil([vehicle localMainIdentifier]),
                            orNil([fuelStation localMainIdentifier]),
                            orNil([fuelPurchaseLog globalIdentifier]),
                            orNil([[fuelPurchaseLog mediaType] description]),
                            orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
                            orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog dateCopiedFromMaster]]),
                            orNil([fuelPurchaseLog numGallons]),
                            orNil([fuelPurchaseLog octane]),
                            orNil([fuelPurchaseLog gallonPrice]),
                            orNil([fuelPurchaseLog carWashPerGallonDiscount]),
                            [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
                            orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
                            [NSNumber numberWithBool:[fuelPurchaseLog editInProgress]],
                            [NSNumber numberWithBool:[fuelPurchaseLog syncInProgress]],
                            [NSNumber numberWithBool:[fuelPurchaseLog synced]],
                            [NSNumber numberWithInteger:[fuelPurchaseLog editCount]],
                            orNil([fuelPurchaseLog syncHttpRespCode]),
                            orNil([fuelPurchaseLog syncErrMask]),
                            orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog syncRetryAt]])]
                   entity:fuelPurchaseLog
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterFuelPurchaseLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ? \
WHERE %@ = ?",
          TBL_MASTER_FUELPURCHASE_LOG, // table
          COL_MASTER_VEHICLE_ID,
          COL_MASTER_FUELSTATION_ID,
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,
          COL_LOCAL_ID];          // where, col1
}

- (NSString *)updateStmtForMasterFuelPurchaseLogSansVehicleFuelStationFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ?, \
%@ = ? \
WHERE %@ = ?",
          TBL_MASTER_FUELPURCHASE_LOG, // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  return [self updateArgsForMasterFuelPurchaseLog:fuelPurchaseLog vehicle:nil fuelStation:nil];
}

- (NSArray *)updateArgsForMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        vehicle:(FPVehicle *)vehicle
                                    fuelStation:(FPFuelStation *)fuelStation {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMasterIdentifier]];
  }
  if (fuelStation) {
    [args addObject:[fuelStation localMasterIdentifier]];
  }
  NSArray *reqdArgs =
  @[orNil([fuelPurchaseLog globalIdentifier]),
    orNil([[fuelPurchaseLog mediaType] description]),
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog deletedAt]]),
    orNil([fuelPurchaseLog numGallons]),
    orNil([fuelPurchaseLog octane]),
    orNil([fuelPurchaseLog gallonPrice]),
    orNil([fuelPurchaseLog carWashPerGallonDiscount]),
    [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
    [fuelPurchaseLog localMasterIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

- (NSString *)updateStmtForMainFuelPurchaseLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUELPURCHASE_LOG,                   // table
          COL_MAIN_VEHICLE_ID,
          COL_MAIN_FUELSTATION_ID,
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,                   // col6
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSString *)updateStmtForMainFuelPurchaseLogSansVehicleFuelStationFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_FUELPURCHASE_LOG,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_FUELPL_NUM_GALLONS,
          COL_FUELPL_OCTANE,
          COL_FUELPL_PRICE_PER_GALLON,
          COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT,
          COL_FUELPL_GOT_CAR_WASH,
          COL_FUELPL_PURCHASED_AT,                   // col6
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  return [self updateArgsForMainFuelPurchaseLog:fuelPurchaseLog
                                        vehicle:nil
                                    fuelStation:nil];
}

- (NSArray *)updateArgsForMainFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      vehicle:(FPVehicle *)vehicle
                                  fuelStation:(FPFuelStation *)fuelStation {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMainIdentifier]];
  }
  if (fuelStation) {
    [args addObject:[fuelStation localMainIdentifier]];
  }
  NSArray *reqdArgs =
  @[orNil([fuelPurchaseLog globalIdentifier]),
    orNil([[fuelPurchaseLog mediaType] description]),
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog updatedAt]]),
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog dateCopiedFromMaster]]),
    orNil([fuelPurchaseLog numGallons]),
    orNil([fuelPurchaseLog octane]),
    orNil([fuelPurchaseLog gallonPrice]),
    orNil([fuelPurchaseLog carWashPerGallonDiscount]),
    [NSNumber numberWithBool:[fuelPurchaseLog gotCarWash]],
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog purchasedAt]]),
    [NSNumber numberWithBool:[fuelPurchaseLog editInProgress]],
    [NSNumber numberWithBool:[fuelPurchaseLog syncInProgress]],
    [NSNumber numberWithBool:[fuelPurchaseLog synced]],
    [NSNumber numberWithInteger:[fuelPurchaseLog editCount]],
    orNil([fuelPurchaseLog syncHttpRespCode]),
    orNil([fuelPurchaseLog syncErrMask]),
    orNil([PEUtils millisecondsFromDate:[fuelPurchaseLog syncRetryAt]]),
    [fuelPurchaseLog localMainIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

#pragma mark - Environment Log data access helpers (private)

- (void)insertIntoMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog
                               forUser:(FPUser *)user
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  NSString *vehicleGlobalId = [environmentLog vehicleGlobalIdentifier];
  if (!vehicleGlobalId && [environmentLog vehicleMainIdentifier]) {
    vehicleGlobalId = [PELMUtils stringFromTable:TBL_MAIN_VEHICLE
                                    selectColumn:COL_GLOBAL_ID
                                     whereColumn:COL_LOCAL_ID
                                      whereValue:[environmentLog vehicleMainIdentifier]
                                              db:db
                                           error:errorBlk];
  }
  NSAssert(vehicleGlobalId, @"Environment log's vehicle global ID is nil");
  FPVehicle *vehicle =
  (FPVehicle *)[PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_VEHICLE, COL_GLOBAL_ID]
                              entityTable:TBL_MASTER_VEHICLE
                            localIdGetter:^NSNumber *(PELMModelSupport *entity){return [entity localMasterIdentifier];}
                                argsArray:@[vehicleGlobalId]
                              rsConverter:^(FMResultSet *rs){return [self masterVehicleFromResultSet:rs];}
                                       db:db
                                    error:errorBlk];
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, \
                    %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_ENV_LOG,
                    COL_MASTER_USER_ID,
                    COL_MASTER_VEHICLE_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MST_UPDATED_AT,
                    COL_MST_DELETED_DT,
                    COL_ENVL_ODOMETER_READING,
                    COL_ENVL_MPG_READING,
                    COL_ENVL_MPH_READING,
                    COL_ENVL_OUTSIDE_TEMP_READING,
                    COL_ENVL_LOG_DT,
                    COL_ENVL_DTE];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([vehicle localMasterIdentifier]),
                              orNil([environmentLog globalIdentifier]),
                              orNil([[environmentLog mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[environmentLog deletedAt]]),
                              orNil([environmentLog odometer]),
                              orNil([environmentLog reportedAvgMpg]),
                              orNil([environmentLog reportedAvgMph]),
                              orNil([environmentLog reportedOutsideTemp]),
                              orNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
                              orNil([environmentLog reportedDte])]
                     entity:environmentLog
                         db:db
                      error:errorBlk];
}

- (void)insertIntoMainEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                             vehicle:(FPVehicle *)vehicle
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ \
                    (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES \
                    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MAIN_ENV_LOG,
                    COL_MAIN_USER_ID,
                    COL_MAIN_VEHICLE_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_MAN_MASTER_UPDATED_AT,
                    COL_MAN_DT_COPIED_DOWN_FROM_MASTER,
                    COL_ENVL_ODOMETER_READING,
                    COL_ENVL_MPG_READING,
                    COL_ENVL_MPH_READING,
                    COL_ENVL_OUTSIDE_TEMP_READING,
                    COL_ENVL_LOG_DT,
                    COL_ENVL_DTE,
                    COL_MAN_EDIT_IN_PROGRESS,
                    COL_MAN_SYNC_IN_PROGRESS,
                    COL_MAN_SYNCED,
                    COL_MAN_EDIT_COUNT,
                    COL_MAN_SYNC_HTTP_RESP_CODE,
                    COL_MAN_SYNC_ERR_MASK,
                    COL_MAN_SYNC_RETRY_AT];
  [PELMUtils doMainInsert:stmt
                argsArray:@[orNil([user localMainIdentifier]),
                            orNil([vehicle localMainIdentifier]),
                            orNil([environmentLog globalIdentifier]),
                            orNil([[environmentLog mediaType] description]),
                            orNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
                            orNil([PEUtils millisecondsFromDate:[environmentLog dateCopiedFromMaster]]),
                            orNil([environmentLog odometer]),
                            orNil([environmentLog reportedAvgMpg]),
                            orNil([environmentLog reportedAvgMph]),
                            orNil([environmentLog reportedOutsideTemp]),
                            orNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
                            orNil([environmentLog reportedDte]),
                            [NSNumber numberWithBool:[environmentLog editInProgress]],
                            [NSNumber numberWithBool:[environmentLog syncInProgress]],
                            [NSNumber numberWithBool:[environmentLog synced]],
                            [NSNumber numberWithInteger:[environmentLog editCount]],
                            orNil([environmentLog syncHttpRespCode]),
                            orNil([environmentLog syncErrMask]),
                            orNil([PEUtils millisecondsFromDate:[environmentLog syncRetryAt]])]
                   entity:environmentLog
                       db:db
                    error:errorBlk];
}

- (NSString *)updateStmtForMasterEnvironmentLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_ENV_LOG, // table
          COL_MASTER_VEHICLE_ID,
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_LOCAL_ID];          // where, col1
}

- (NSString *)updateStmtForMasterEnvironmentLogSansVehicleFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_ENV_LOG, // table
          COL_GLOBAL_ID,          // col1
          COL_MEDIA_TYPE,         // col2
          COL_MST_UPDATED_AT,  // col3
          COL_MST_DELETED_DT,     // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_LOCAL_ID];          // where, col1
}

- (NSArray *)updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  return [self updateArgsForMasterEnvironmentLog:environmentLog vehicle:nil];
}

- (NSArray *)updateArgsForMasterEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       vehicle:(FPVehicle *)vehicle {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMasterIdentifier]];
  }
  NSArray *reqdArgs =
  @[orNil([environmentLog globalIdentifier]),
    orNil([[environmentLog mediaType] description]),
    orNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
    orNil([PEUtils millisecondsFromDate:[environmentLog deletedAt]]),
    orNil([environmentLog odometer]),
    orNil([environmentLog reportedAvgMpg]),
    orNil([environmentLog reportedAvgMph]),
    orNil([environmentLog reportedOutsideTemp]),
    orNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
    orNil([environmentLog reportedDte]),
    [environmentLog localMasterIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

- (NSString *)updateStmtForMainEnvironmentLog {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_ENV_LOG,                   // table
          COL_MAIN_VEHICLE_ID,
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,
          COL_ENVL_DTE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSString *)updateStmtForMainEnvironmentLogSansVehicleFks {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MAIN_ENV_LOG,                   // table
          COL_GLOBAL_ID,                      // col1
          COL_MEDIA_TYPE,                     // col2
          COL_MAN_MASTER_UPDATED_AT,      // col3
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col4
          COL_ENVL_ODOMETER_READING,
          COL_ENVL_MPG_READING,
          COL_ENVL_MPH_READING,
          COL_ENVL_OUTSIDE_TEMP_READING,
          COL_ENVL_LOG_DT,                  // col6
          COL_ENVL_DTE,
          COL_MAN_EDIT_IN_PROGRESS,           // col7
          COL_MAN_SYNC_IN_PROGRESS,           // col8
          COL_MAN_SYNCED,                     // col9
          COL_MAN_EDIT_COUNT,                 // col12
          COL_MAN_SYNC_HTTP_RESP_CODE,
          COL_MAN_SYNC_ERR_MASK,
          COL_MAN_SYNC_RETRY_AT,
          COL_LOCAL_ID];                      // where, col1
}

- (NSArray *)updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)environmentLog {
  return [self updateArgsForMainEnvironmentLog:environmentLog
                                       vehicle:nil];
}

- (NSArray *)updateArgsForMainEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     vehicle:(FPVehicle *)vehicle {
  NSMutableArray *args = [NSMutableArray array];
  if (vehicle) {
    [args addObject:[vehicle localMainIdentifier]];
  }
  NSArray *reqdArgs =
  @[orNil([environmentLog globalIdentifier]),
    orNil([[environmentLog mediaType] description]),
    orNil([PEUtils millisecondsFromDate:[environmentLog updatedAt]]),
    orNil([PEUtils millisecondsFromDate:[environmentLog dateCopiedFromMaster]]),
    orNil([environmentLog odometer]),
    orNil([environmentLog reportedAvgMpg]),
    orNil([environmentLog reportedAvgMph]),
    orNil([environmentLog reportedOutsideTemp]),
    orNil([PEUtils millisecondsFromDate:[environmentLog logDate]]),
    orNil([environmentLog reportedDte]),
    [NSNumber numberWithBool:[environmentLog editInProgress]],
    [NSNumber numberWithBool:[environmentLog syncInProgress]],
    [NSNumber numberWithBool:[environmentLog synced]],
    [NSNumber numberWithInteger:[environmentLog editCount]],
    orNil([environmentLog syncHttpRespCode]),
    orNil([environmentLog syncErrMask]),
    orNil([PEUtils millisecondsFromDate:[environmentLog syncRetryAt]]),
    [environmentLog localMainIdentifier]];
  [args addObjectsFromArray:reqdArgs];
  return args;
}

@end
