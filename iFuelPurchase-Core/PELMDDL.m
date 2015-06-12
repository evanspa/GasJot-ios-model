//
//  PELMDDL.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMDDL.h"

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
NSString * const COL_LOCAL_ID = @"id";
NSString * const COL_GLOBAL_ID = @"global_identifier";
NSString * const COL_MEDIA_TYPE = @"media_type";
NSString * const COL_REL_NAME = @"name";
NSString * const COL_REL_URI = @"uri";
NSString * const COL_REL_MEDIA_TYPE = @"media_type";
// ----Common master columns----------------------------------------------------
NSString * const COL_MST_UPDATED_AT = @"updated_at";
NSString * const COL_MST_DELETED_DT = @"deleted_date";
// ----Common main columns------------------------------------------------------
NSString * const COL_MAN_MASTER_UPDATED_AT = @"master_updated_at";
NSString * const COL_MAN_DT_COPIED_DOWN_FROM_MASTER = @"date_copied_down_from_master";
NSString * const COL_MAN_EDIT_IN_PROGRESS = @"edit_in_progress";
NSString * const COL_MAN_EDIT_ACTOR_ID = @"edit_actor_id";
NSString * const COL_MAN_SYNC_IN_PROGRESS = @"sync_in_progress";
NSString * const COL_MAN_SYNCED = @"synced";
NSString * const COL_MAN_IN_CONFLICT = @"in_conflict";
NSString * const COL_MAN_DELETED = @"deleted";
NSString * const COL_MAN_EDIT_COUNT = @"edit_count";
NSString * const COL_MAN_SYNC_HTTP_RESP_CODE = @"sync_http_resp_code";
NSString * const COL_MAN_SYNC_ERR_MASK = @"sync_http_resp_err_mask";
NSString * const COL_MAN_SYNC_RETRY_AT = @"sync_http_resp_retry_at";
// ----Common table names-------------------------------------------------------
NSString * const TBLSUFFIX_RELATION_ENTITY = @"_rel";

@implementation PELMDDL

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                         column:(NSString *)column
                      indexName:(NSString *)indexName {
  return [PELMDDL indexDDLForEntity:entity
                             unique:unique
                            columns:@[column]
                          indexName:indexName];
}

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                        columns:(NSArray *)columns
                      indexName:(NSString *)indexName {
  NSMutableString *idxDdl =
    [NSMutableString stringWithFormat:@"CREATE %@INDEX IF NOT EXISTS %@ ON %@ (",
     (unique ? @"UNIQUE " : @""),
     indexName,
     entity];
  NSUInteger numColumns = [columns count];
  for (int i = 0; i < numColumns; i++) {
    [idxDdl appendFormat:@"%@", [columns objectAtIndex:i]];
    if ((i + 1) < numColumns) {
      [idxDdl appendString:@", "];
    }
  }
  [idxDdl appendString:@")"];
  return idxDdl;
}

+ (NSString *)relTableForEntityTable:(NSString *)entityTable {
  return [NSString stringWithFormat:@"%@_rel", entityTable];
}

+ (NSString *)relFkColumnForEntityTable:(NSString *)entityTable
                         entityPkColumn:(NSString *)entityPkColumn {
  return [NSString stringWithFormat:@"%@_%@", entityTable, entityPkColumn];
}

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable
               entityPkColumn:(NSString *)entityPkColumn {
  NSString *relTableName = [PELMDDL relTableForEntityTable:entityTable];
  NSString *fkColumn = [PELMDDL relFkColumnForEntityTable:entityTable
                                           entityPkColumn:entityPkColumn];
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@))", relTableName,
          COL_LOCAL_ID,       // col1
          fkColumn,           // col2
          COL_REL_NAME,       // col3
          COL_REL_URI,        // col4
          COL_REL_MEDIA_TYPE, // col5
          fkColumn,           // fk1, col1
          entityTable,             // fk1, tbl-ref
          entityPkColumn];    // fk1, tbl-ref col1
}

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable {
  return [PELMDDL relDDLForEntityTable:entityTable entityPkColumn:COL_LOCAL_ID];
}

@end
