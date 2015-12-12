//
//  PELocalDao.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/11/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMUser.h"
#import "PELMUtils.h"
#import <FMDB/FMDatabaseQueue.h>

@interface PELocalDao : NSObject

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
               concreteUserClass:(Class)concreteUserClass;

#pragma mark - Properties

@property (nonatomic, readonly) PELMUtils *localModelUtils;

@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

#pragma mark - User Operations

- (PELMUser *)masterUserWithId:(NSNumber *)userId error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)mainUserWithError:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)mainUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewLocalUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareUserForEdit:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareUserForEdit:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)markUserAsSyncInProgressWithError:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForUser:(PELMUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
                    error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numUnsyncedEntitiesForUser:(PELMUser *)user mainEntityTable:(NSString *)entityTable;

- (NSInteger)numSyncNeededEntitiesForUser:(PELMUser *)user mainEntityTable:(NSString *)entityTable;

- (void)linkMainUser:(PELMUser *)mainUser
        toMasterUser:(PELMUser *)masterUser
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Persistence Helpers

- (NSString *)updateStmtForMasterUser;

- (NSArray *)updateArgsForMasterUser:(PELMUser *)user;

- (NSString *)updateStmtForMainUser;

- (NSArray *)updateArgsForMainUser:(PELMUser *)user;

- (void)insertIntoMainUser:(PELMUser *)user
                        db:(FMDatabase *)db
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)insertIntoMasterUser:(PELMUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Result Set -> User Helpers

- (PELMUser *)mainUserFromResultSet:(FMResultSet *)rs;

- (PELMUser *)masterUserFromResultSet:(FMResultSet *)rs;

@end
