//
//  PELocalDao.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/11/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDao.h"

typedef void (^PEUserDbOpBlk)(PELMUser *, FMDatabase *, PELMDaoErrorBlk);

@interface PELocalDaoImpl : NSObject <PELocalDao>

#pragma mark - Master Entity Table Names

- (NSArray *)masterEntityTableNames;

#pragma mark - Pre-Delete User Hook 

- (PEUserDbOpBlk)preDeleteUserHook;

#pragma mark - Post-Deep Save User Hook

- (PEUserDbOpBlk)postDeepSaveUserHook;

#pragma mark - Main Entity Table Names (child -> parent order)

- (NSArray *)mainEntityTableNamesChildToParentOrder;

#pragma mark - Change Log Processors

- (NSArray *)changelogProcessorsWithUser:(PELMUser *)user
                               changelog:(PEChangelog *)changelog
                                      db:(FMDatabase *)db
                         processingBlock:(PELMProcessChangelogEntitiesBlk)processingBlk
                                errorBlk:(PELMDaoErrorBlk)errorBlk;

@end
