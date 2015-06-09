//
//  FPNotificationNames.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPNotificationNames.h"
#import "PELMNotificationUtils.h"

#pragma mark - User related notifications

// To be subscribed to by outsiders (e.g., GUI components)
NSString * const FPUserSyncInitiated = @"FPUserSyncInitiated";
NSString * const FPUserSynced = @"FPUserSynced";
NSString * const FPUserSyncFailed = @"FPUserSyncFailed";
NSString * const FPUserDeleted = @"FPUserDeleted";
NSString * const FPUserRemotelyDeleted = @"FPUserRemotelyDeleted";
NSString * const FPUserUpdated = @"FPUserUpdated";
NSString * const FPUserRemotelyUpdated = @"FPUserRemotelyUpdated";

#pragma mark - Vehicle related notifications

// To be subscribed to by outsiders (e.g., GUI components)
NSString * const FPVehicleSyncInitiated = @"FPVehicleSyncInitiated";
NSString * const FPVehicleSynced = @"FPVehicleSynced";
NSString * const FPVehicleSyncFailed = @"FPVehicleSyncFailed";
NSString * const FPVehicleDeleted = @"FPVehicleDeleted";
NSString * const FPVehicleRemotelyDeleted = @"FPVehicleRemotelyDeleted";
NSString * const FPVehicleUpdated = @"FPVehicleUpdated";
NSString * const FPVehicleRemotelyUpdated = @"FPVehicleRemotelyUpdated";
NSString * const FPVehicleAdded = @"FPVehicleAdded";
NSString * const FPVehicleRemotelyAdded = @"FPVehicleRemotelyAdded";

#pragma mark - Fuel Station related notifications

// To be subscribed to by outsiders (e.g., GUI components)
NSString * const FPFuelStationCoordinateComputeInitiated = @"FPFuelStationCoordComputeInitiated";
NSString * const FPFuelStationCoordinateComputeSuccess = @"FPFuelStationCoordComputeSuccess";
NSString * const FPFuelStationCoordinateComputeFailed = @"FPFuelStationCoordComputeFailed";
NSString * const FPFuelStationSyncInitiated = @"FPFuelStationSyncInitiated";
NSString * const FPFuelStationSynced = @"FPFuelStationSynced";
NSString * const FPFuelStationSyncFailed = @"FPFuelStationSyncFailed";
NSString * const FPFuelStationDeleted = @"FPFuelStationDeleted";
NSString * const FPFuelStationRemotelyDeleted = @"FPFuelStationRemotelyDeleted";
NSString * const FPFuelStationUpdated = @"FPFuelStationUpdated";
NSString * const FPFuelStationRemotelyUpdated = @"FPFuelStationRemotelyUpdated";
NSString * const FPFuelStationAdded = @"FPFuelStationAdded";
NSString * const FPFuelStationRemotelyAdded = @"FPFuelStationRemotelyAdded";

#pragma mark - Fuel Purchase Log related notifications

// To be subscribed to by outsiders (e.g., GUI components)
NSString * const FPFuelPurchaseLogSyncInitiated = @"FPFuelPurchaseLogSyncInitiated";
NSString * const FPFuelPurchaseLogSynced = @"FPFuelPurchaseLogSynced";
NSString * const FPFuelPurchaseLogSyncFailed = @"FPFuelPurchaseLogSyncFailed";
NSString * const FPFuelPurchaseLogGone = @"FPFuelPurchaseLogGone";
NSString * const FPFuelPurchaseLogDeleted = @"FPFuelPurchaseLogDeleted";
NSString * const FPFuelPurchaseLogRemotelyDeleted = @"FPFuelPurchaseLogRemotelyDeleted";
NSString * const FPFuelPurchaseLogUpdated = @"FPFuelPurchaseLogUpdated";
NSString * const FPFuelPurchaseLogRemotelyUpdated = @"FPFuelPurchaseLogRemotelyUpdated";
NSString * const FPFuelPurchaseLogAdded = @"FPFuelPurchaseLogAdded";
NSString * const FPFuelPurchaseLogRemotelyAdded = @"FPFuelPurchaseLogRemotelyAdded";

#pragma mark - Environment Log related notifications

// To be subscribed to by outsiders (e.g., GUI components)
NSString * const FPEnvironmentLogSyncInitiated = @"FPEnvironmentLogSyncInitiated";
NSString * const FPEnvironmentLogSynced = @"FPEnvironmentLogSynced";
NSString * const FPEnvironmentLogSyncFailed = @"FPEnvironmentLogSyncFailed";
NSString * const FPEnvironmentLogDeleted = @"FPEnvironmentLogDeleted";
NSString * const FPEnvironmentLogRemotelyDeleted = @"FPEnvironmentLogRemotelyDeleted";
NSString * const FPEnvironmentLogUpdated = @"FPEnvironmentLogUpdated";
NSString * const FPEnvironmentLogRemotelyUpdated = @"FPEnvironmentLogRemotelyUpdated";
NSString * const FPEnvironmentLogAdded = @"FPEnvironmentLogAdded";
NSString * const FPEnvironmentLogRemotelyAdded = @"FPEnvironmentLogRemotelyAdded";

#pragma mark - General Notifications

NSString * const FPSystemPruningComplete = @"FPSystemPruningComplete";
NSString * const FPAuthenticationRequired = @"FPAuthenticationRequired";
