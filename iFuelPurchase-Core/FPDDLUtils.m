//
//  FPDDLUtils.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPDDLUtils.h"

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
NSString * const COL_MAIN_USER_ID = @"main_user_id";
NSString * const COL_MASTER_USER_ID = @"master_user_id";
NSString * const COL_MAIN_VEHICLE_ID = @"main_vehicle_id";
NSString * const COL_MASTER_VEHICLE_ID = @"master_vehicle_id";
NSString * const COL_MAIN_FUELSTATION_ID = @"main_fuelstation_id";
NSString * const COL_MASTER_FUELSTATION_ID = @"master_fuelstation_id";

//##############################################################################
// User Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_USER = @"master_user";
NSString * const TBL_MAIN_USER = @"main_user";
// ----Columns------------------------------------------------------------------
NSString * const COL_USR_NAME = @"name";
NSString * const COL_USR_EMAIL = @"email";
NSString * const COL_USR_USERNAME = @"username";
NSString * const COL_USR_PASSWORD_HASH = @"password_hash";
NSString * const COL_USR_CREATION_DT = @"creation_date";

//##############################################################################
// Vehicle Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_VEHICLE = @"master_vehicle";
NSString * const TBL_MAIN_VEHICLE = @"main_vehicle";
// ----Columns------------------------------------------------------------------
NSString * const COL_VEH_NAME = @"name";
NSString * const COL_VEH_DT_ADDED = @"date_added";

//##############################################################################
// Fuel Station Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_FUEL_STATION = @"master_fuelstation";
NSString * const TBL_MAIN_FUEL_STATION = @"main_fuelstation";
// ----Columns------------------------------------------------------------------
NSString * const COL_FUELST_NAME = @"name";
NSString * const COL_FUELST_STREET = @"street";
NSString * const COL_FUELST_CITY = @"city";
NSString * const COL_FUELST_STATE = @"state";
NSString * const COL_FUELST_ZIP = @"zip";
NSString * const COL_FUELST_LATITUDE = @"latitude";
NSString * const COL_FUELST_LONGITUDE = @"longitude";
NSString * const COL_FUELST_DT_ADDED = @"date_added";

//##############################################################################
// Fuel Purchase Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_FUELPURCHASE_LOG = @"master_fuelpurchase_log";
NSString * const TBL_MAIN_FUELPURCHASE_LOG = @"main_fuelpurchase_log";
// ----Columns------------------------------------------------------------------
NSString * const COL_FUELPL_NUM_GALLONS = @"num_gallons";
NSString * const COL_FUELPL_PRICE_PER_GALLON = @"price_per_gallon";
NSString * const COL_FUELPL_OCTANE = @"octane";
NSString * const COL_FUELPL_GOT_CAR_WASH = @"got_car_wash";
NSString * const COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT = @"car_wash_discount";
NSString * const COL_FUELPL_LOG_DT = @"log_date";
// ----Aliases used in SELECT statements----------------------------------------
NSString * const FUELPL_ALIAS_VEHICLE_GLOBAL_ID = @"fuelpl_vehicle_global_id";
NSString * const FUELPL_ALIAS_FUELSTATION_GLOBAL_ID = @"fuelpl_fuelstatoin_global_id";


//##############################################################################
// Environment Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_ENV_LOG = @"master_environment_log";
NSString * const TBL_MAIN_ENV_LOG = @"main_environment_log";
// ----Columns------------------------------------------------------------------
NSString * const COL_ENVL_ODOMETER_READING = @"odometer_reading";
NSString * const COL_ENVL_MPG_READING = @"mpg_reading";
NSString * const COL_ENVL_MPH_READING = @"mph_reading";
NSString * const COL_ENVL_OUTSIDE_TEMP_READING = @"outside_temp_reading";
NSString * const COL_ENVL_LOG_DT = @"log_date";
NSString * const COL_ENVL_DTE = @"dte";
// ----Aliases used in SELECT statements----------------------------------------
NSString * const ENVL_ALIAS_VEHICLE_GLOBAL_ID = @"fuelpl_vehicle_global_id";

@implementation FPDDLUtils

#pragma mark - Master and Main Environment Log entities

+ (NSString *)masterEnvironmentLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ REAL, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_ENV_LOG,
                   COL_LOCAL_ID,                  // col1
                   COL_MASTER_USER_ID,            // col2
                   COL_MASTER_VEHICLE_ID,         // col3
                   COL_GLOBAL_ID,                 // col4
                   COL_MEDIA_TYPE,                // col5
                   COL_MST_LAST_MODIFIED,         // col6
                   COL_MST_DELETED_DT,            // col7
                   COL_ENVL_ODOMETER_READING,     // col8
                   COL_ENVL_MPG_READING,          // col9
                   COL_ENVL_MPH_READING,          // col10
                   COL_ENVL_OUTSIDE_TEMP_READING, // col11
                   COL_ENVL_LOG_DT,               // col12
                   COL_ENVL_DTE,                  // col13
                   COL_MASTER_USER_ID,            // fk1, col1
                   TBL_MASTER_USER,               // fk1, tbl-ref
                   COL_LOCAL_ID,                  // fk1, tbl-ref col1
                   COL_MASTER_VEHICLE_ID,         // fk2, col1
                   TBL_MASTER_VEHICLE,            // fk2, tbl-ref
                   COL_LOCAL_ID];                 // fk2, tbl-ref col1
}

+ (NSString *)mainEnvironmentDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ REAL, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_ENV_LOG,
                   COL_LOCAL_ID,                       // col1
                   COL_MAIN_USER_ID,                   // col2
                   COL_MAIN_VEHICLE_ID,                // col3
                   COL_GLOBAL_ID,                      // col4
                   COL_MEDIA_TYPE,                     // col5
                   COL_MAN_MASTER_LAST_MODIFIED,       // col6
                   COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col7
                   COL_ENVL_ODOMETER_READING,          // col8
                   COL_ENVL_MPG_READING,               // col9
                   COL_ENVL_MPH_READING,               // col10
                   COL_ENVL_OUTSIDE_TEMP_READING,      // col11
                   COL_ENVL_LOG_DT,                    // col12
                   COL_ENVL_DTE,                       // col12.5
                   COL_MAN_EDIT_IN_PROGRESS,           // col13
                   COL_MAN_SYNC_IN_PROGRESS,           // col14
                   COL_MAN_SYNCED,                     // col15
                   COL_MAN_IN_CONFLICT,                // col16
                   COL_MAN_DELETED,                    // col16
                   COL_MAN_EDIT_COUNT,                 // col18
                   COL_MAN_EDIT_ACTOR_ID,              // col19
                   COL_MAIN_USER_ID,                   // fk1, col1
                   TBL_MAIN_USER,                      // fk1, tbl-ref
                   COL_LOCAL_ID,                       // fk1, tbl-ref col1
                   COL_MAIN_VEHICLE_ID,                // fk2, col1
                   TBL_MAIN_VEHICLE,                   // fk2, tbl-ref
                   COL_LOCAL_ID];                      // fk2, tbl-ref col1
}

#pragma mark - Master and Main Fuel Purchase Log entities

+ (NSString *)masterFuelPurchaseLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_FUELPURCHASE_LOG,
                   COL_LOCAL_ID,                            // col1
                   COL_MASTER_USER_ID,                      // col2
                   COL_MASTER_VEHICLE_ID,                   // col3
                   COL_MASTER_FUELSTATION_ID,               // col4
                   COL_GLOBAL_ID,                           // col5
                   COL_MEDIA_TYPE,                          // col6
                   COL_MST_LAST_MODIFIED,                   // col7
                   COL_MST_DELETED_DT,                      // col8
                   COL_FUELPL_NUM_GALLONS,                  // col9
                   COL_FUELPL_PRICE_PER_GALLON,             // col10
                   COL_FUELPL_OCTANE,                       // col11
                   COL_FUELPL_GOT_CAR_WASH,                 // col12
                   COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT, // col13
                   COL_FUELPL_LOG_DT,                       // col14
                   COL_MASTER_USER_ID,                      // fk1, col1
                   TBL_MASTER_USER,                         // fk1, tbl-ref
                   COL_LOCAL_ID,                            // fk1, tbl-ref col1
                   COL_MASTER_VEHICLE_ID,                   // fk2, col1
                   TBL_MASTER_VEHICLE,                      // fk2, tbl-ref
                   COL_LOCAL_ID,                            // fk2, tbl-ref col1
                   COL_MASTER_FUELSTATION_ID,               // fk3, col1
                   TBL_MASTER_FUEL_STATION,                 // fk3, tbl-ref
                   COL_LOCAL_ID];                           // fk3, tbl-ref col1
}

+ (NSString *)mainFuelPurchaseLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_FUELPURCHASE_LOG,
                   COL_LOCAL_ID,                            // col1
                   COL_MAIN_USER_ID,                        // col2
                   COL_MAIN_VEHICLE_ID,                     // col3
                   COL_MAIN_FUELSTATION_ID,                 // col4
                   COL_GLOBAL_ID,                           // col5
                   COL_MEDIA_TYPE,                          // col6
                   COL_MAN_MASTER_LAST_MODIFIED,            // col7
                   COL_MAN_DT_COPIED_DOWN_FROM_MASTER,      // col8
                   COL_FUELPL_NUM_GALLONS,                  // col9
                   COL_FUELPL_PRICE_PER_GALLON,             // col10
                   COL_FUELPL_OCTANE,                       // col11
                   COL_FUELPL_GOT_CAR_WASH,                 // col12
                   COL_FUELPL_CAR_WASH_PER_GALLON_DISCOUNT, // col13
                   COL_FUELPL_LOG_DT,                       // col14
                   COL_MAN_EDIT_IN_PROGRESS,                // col15
                   COL_MAN_SYNC_IN_PROGRESS,                // col16
                   COL_MAN_SYNCED,                          // col17
                   COL_MAN_IN_CONFLICT,                     // col18
                   COL_MAN_DELETED,                         // col19
                   COL_MAN_EDIT_COUNT,                      // col20
                   COL_MAN_EDIT_ACTOR_ID,                   // col21
                   COL_MAIN_USER_ID,                        // fk1, col1
                   TBL_MAIN_USER,                           // fk1, tbl-ref
                   COL_LOCAL_ID,                            // fk1, tbl-ref col1
                   COL_MAIN_VEHICLE_ID,                     // fk2, col1
                   TBL_MAIN_VEHICLE,                        // fk2, tbl-ref
                   COL_LOCAL_ID,                            // fk2, tbl-ref col1
                   COL_MAIN_FUELSTATION_ID,                 // fk3, col1
                   TBL_MAIN_FUEL_STATION,                   // fk3, tbl-ref
                   COL_LOCAL_ID];                           // fk3, tbl-ref col1
}

#pragma mark - Master and Main Fuel Station entities

+ (NSString *)masterFuelStationDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ REAL, \
%@ REAL, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_FUEL_STATION,
                   COL_LOCAL_ID,           // col1
                   COL_MASTER_USER_ID,     // col2
                   COL_GLOBAL_ID,          // col3
                   COL_MEDIA_TYPE,         // col4
                   COL_MST_LAST_MODIFIED,  // col5
                   COL_MST_DELETED_DT,     // col6
                   COL_FUELST_NAME,        // col7
                   COL_FUELST_CITY,        // col8
                   COL_FUELST_STATE,       // col9
                   COL_FUELST_ZIP,         // col10
                   COL_FUELST_LATITUDE,    // col11
                   COL_FUELST_LONGITUDE,   // col12
                   COL_FUELST_DT_ADDED,    // col13
                   COL_MASTER_USER_ID,     // fk1, col1
                   TBL_MASTER_USER,        // fk1, tbl-ref
                   COL_LOCAL_ID];          // fk1, tbl-ref col1
}

+ (NSString *)mainFuelStationDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ REAL, \
%@ REAL, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_FUEL_STATION,
                   COL_LOCAL_ID,                       // col1
                   COL_MAIN_USER_ID,                   // col2
                   COL_GLOBAL_ID,                      // col3
                   COL_MEDIA_TYPE,                     // col4
                   COL_MAN_MASTER_LAST_MODIFIED,       // col5
                   COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col6
                   COL_FUELST_NAME,                    // col7
                   COL_FUELST_CITY,                    // col8
                   COL_FUELST_STATE,                   // col9
                   COL_FUELST_ZIP,                     // col10
                   COL_FUELST_LATITUDE,                // col11
                   COL_FUELST_LONGITUDE,               // col12
                   COL_FUELST_DT_ADDED,                // col13
                   COL_MAN_EDIT_IN_PROGRESS,           // col14
                   COL_MAN_SYNC_IN_PROGRESS,           // col15
                   COL_MAN_SYNCED,                     // col16
                   COL_MAN_IN_CONFLICT,                // col17
                   COL_MAN_DELETED,                    // col18
                   COL_MAN_EDIT_COUNT,                 // col19
                   COL_MAN_EDIT_ACTOR_ID,              // col20
                   COL_MAIN_USER_ID,                   // fk1, col1
                   TBL_MAIN_USER,                      // fk1, tbl-ref
                   COL_LOCAL_ID];                      // fk1, tbl-ref col1
}

#pragma mark - Master and Main Vehicle entities

+ (NSString *)masterVehicleDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_VEHICLE,
                   COL_LOCAL_ID,           // col1
                   COL_MASTER_USER_ID,     // col2
                   COL_GLOBAL_ID,          // col3
                   COL_MEDIA_TYPE,         // col4
                   COL_MST_LAST_MODIFIED,  // col5
                   COL_MST_DELETED_DT,     // col6
                   COL_VEH_NAME,           // col7
                   COL_VEH_DT_ADDED,       // col8
                   COL_MASTER_USER_ID,     // fk1, col1
                   TBL_MASTER_USER,        // fk1, tbl-ref
                   COL_LOCAL_ID];          // fk1, tbl-ref col1
}

+ (NSString *)masterVehicleUniqueIndex1 {
  return [PELMDDL indexDDLForEntity:TBL_MASTER_VEHICLE
                             unique:YES
                            columns:@[COL_LOCAL_ID, COL_MASTER_USER_ID]
                          indexName:@"uidx_master_veh"];
}

+ (NSString *)mainVehicleDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_VEHICLE,
                   COL_LOCAL_ID,                       // col1
                   COL_MAIN_USER_ID,                   // col2
                   COL_GLOBAL_ID,                      // col3
                   COL_MEDIA_TYPE,                     // col4
                   COL_MAN_MASTER_LAST_MODIFIED,       // col5
                   COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col6
                   COL_VEH_NAME,                       // col7
                   COL_VEH_DT_ADDED,                   // col8
                   COL_MAN_EDIT_IN_PROGRESS,           // col9
                   COL_MAN_SYNC_IN_PROGRESS,           // col10
                   COL_MAN_SYNCED,                     // col11
                   COL_MAN_IN_CONFLICT,                // col12
                   COL_MAN_DELETED,                    // col13
                   COL_MAN_EDIT_COUNT,                 // col14
                   COL_MAN_EDIT_ACTOR_ID,              // col15
                   COL_MAIN_USER_ID,                   // fk1, col1
                   TBL_MAIN_USER,                      // fk1, tbl-ref
                   COL_LOCAL_ID];                      // fk1, tbl-ref col1
}

+ (NSString *)mainVehicleUniqueIndex1 {
  return [PELMDDL indexDDLForEntity:TBL_MAIN_VEHICLE
                             unique:YES
                            columns:@[COL_LOCAL_ID, COL_MAIN_USER_ID]
                          indexName:@"uidx_main_veh"];
}

#pragma mark - Master and Main User entities

+ (NSString *)masterUserDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT)", TBL_MASTER_USER,
                   COL_LOCAL_ID,           // col1
                   COL_GLOBAL_ID,          // col2
                   COL_MEDIA_TYPE,         // col3
                   COL_MST_LAST_MODIFIED,  // col4
                   COL_MST_DELETED_DT,     // col5
                   COL_USR_NAME,           // col6
                   COL_USR_EMAIL,          // col7
                   COL_USR_USERNAME,       // col8
                   COL_USR_PASSWORD_HASH,  // col9
                   COL_USR_CREATION_DT];   // col10
}

+ (NSString *)mainUserDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@))",
                   TBL_MAIN_USER,                      // table
                   COL_LOCAL_ID,                       // col1
                   COL_MASTER_USER_ID,                 // col2
                   COL_GLOBAL_ID,                      // col3
                   COL_MEDIA_TYPE,                     // col4
                   COL_MAN_MASTER_LAST_MODIFIED,       // col5
                   COL_MAN_DT_COPIED_DOWN_FROM_MASTER, // col6
                   COL_USR_NAME,                       // col7
                   COL_USR_EMAIL,                      // col8
                   COL_USR_USERNAME,                   // col9
                   COL_USR_PASSWORD_HASH,              // col10
                   COL_USR_CREATION_DT,                // col11
                   COL_MAN_EDIT_IN_PROGRESS,           // col12
                   COL_MAN_SYNC_IN_PROGRESS,           // col13
                   COL_MAN_SYNCED,                     // col14
                   COL_MAN_IN_CONFLICT,                // col15
                   COL_MAN_DELETED,                    // col16
                   COL_MAN_EDIT_COUNT,                 // col17
                   COL_MAN_EDIT_ACTOR_ID,              // col18
                   COL_MASTER_USER_ID,                 // fk1, col1
                   TBL_MASTER_USER,                    // fk1, ref-tab
                   COL_LOCAL_ID];                      // fk1, ref-tab col1
}

+ (NSString *)mainUserUniqueIndex1 {
  return [PELMDDL indexDDLForEntity:TBL_MAIN_USER
                             unique:YES
                             column:COL_MASTER_USER_ID
                          indexName:@"uidx_main_user"];
}

@end
