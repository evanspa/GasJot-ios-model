//
//  PELocalModelDDL.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
FOUNDATION_EXPORT NSString * const COL_LOCAL_ID;
FOUNDATION_EXPORT NSString * const COL_GLOBAL_ID;
FOUNDATION_EXPORT NSString * const COL_MEDIA_TYPE;
FOUNDATION_EXPORT NSString * const COL_REL_NAME;
FOUNDATION_EXPORT NSString * const COL_REL_URI;
FOUNDATION_EXPORT NSString * const COL_REL_MEDIA_TYPE;
// ----Common master columns----------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MST_LAST_MODIFIED;
FOUNDATION_EXPORT NSString * const COL_MST_DELETED_DT;
// ----Common main columns------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MAN_MASTER_LAST_MODIFIED;
FOUNDATION_EXPORT NSString * const COL_MAN_DT_COPIED_DOWN_FROM_MASTER;
FOUNDATION_EXPORT NSString * const COL_MAN_EDIT_IN_PROGRESS;
FOUNDATION_EXPORT NSString * const COL_MAN_EDIT_ACTOR_ID;
FOUNDATION_EXPORT NSString * const COL_MAN_SYNC_IN_PROGRESS;
FOUNDATION_EXPORT NSString * const COL_MAN_SYNCED;
FOUNDATION_EXPORT NSString * const COL_MAN_IN_CONFLICT;
FOUNDATION_EXPORT NSString * const COL_MAN_DELETED;
FOUNDATION_EXPORT NSString * const COL_MAN_EDIT_COUNT;
// ----Common table names-------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBLSUFFIX_RELATION_ENTITY;

@interface PELMDDL : NSObject

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                         column:(NSString *)column
                      indexName:(NSString *)indexName;

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                        columns:(NSArray *)columns
                      indexName:(NSString *)indexName;

+ (NSString *)relTableForEntityTable:(NSString *)entityTable;

+ (NSString *)relFkColumnForEntityTable:(NSString *)entityTable
                         entityPkColumn:(NSString *)entityPkColumn;

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable
                    entityPkColumn:(NSString *)entityPkColumn;

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable;

@end
