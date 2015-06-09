//
//  FPNotificationNames.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - User related notifications

// To be subscribed to by outsiders (e.g., GUI components)
FOUNDATION_EXPORT NSString * const FPUserSyncInitiated;
FOUNDATION_EXPORT NSString * const FPUserSynced;
FOUNDATION_EXPORT NSString * const FPUserSyncFailed;
FOUNDATION_EXPORT NSString * const FPUserDeleted;
FOUNDATION_EXPORT NSString * const FPUserRemotelyDeleted;
FOUNDATION_EXPORT NSString * const FPUserUpdated;
FOUNDATION_EXPORT NSString * const FPUserRemotelyUpdated;

#pragma mark - Vehicle related notifications

// FYI, 'remotely updated' notifications are raised when the application receives
// information from the remote master store that an entity has been updated (as
// opposed to regular 'updated' notifications which occur purely locally; usually
// by a user editing an entity using a GUI screen (or, a locally running BG job
// computing GEO coordinates and updating a fuel station entity).  Same goes for
// 'remotely deleted' and 'remotely added' notifications.  Why the distinction?
// So observers (usually GUI components) can tailor their messages/UX to the user
// accordingly.

// To be subscribed to by outsiders (e.g., GUI components)
FOUNDATION_EXPORT NSString * const FPVehicleSyncInitiated;
FOUNDATION_EXPORT NSString * const FPVehicleSynced;
FOUNDATION_EXPORT NSString * const FPVehicleSyncFailed;
FOUNDATION_EXPORT NSString * const FPVehicleDeleted;
FOUNDATION_EXPORT NSString * const FPVehicleRemotelyDeleted;
FOUNDATION_EXPORT NSString * const FPVehicleUpdated;
FOUNDATION_EXPORT NSString * const FPVehicleRemotelyUpdated;
FOUNDATION_EXPORT NSString * const FPVehicleAdded;
FOUNDATION_EXPORT NSString * const FPVehicleRemotelyAdded;

#pragma mark - Fuel Station related notifications

// To be subscribed to by outsiders (e.g., GUI components)
FOUNDATION_EXPORT NSString * const FPFuelStationCoordinateComputeInitiated;
FOUNDATION_EXPORT NSString * const FPFuelStationCoordinateComputeSuccess;
FOUNDATION_EXPORT NSString * const FPFuelStationCoordinateComputeFailed;
FOUNDATION_EXPORT NSString * const FPFuelStationSyncInitiated;
FOUNDATION_EXPORT NSString * const FPFuelStationSynced;
FOUNDATION_EXPORT NSString * const FPFuelStationSyncFailed;
FOUNDATION_EXPORT NSString * const FPFuelStationDeleted;
FOUNDATION_EXPORT NSString * const FPFuelStationRemotelyDeleted;
FOUNDATION_EXPORT NSString * const FPFuelStationUpdated;
FOUNDATION_EXPORT NSString * const FPFuelStationRemotelyUpdated;
FOUNDATION_EXPORT NSString * const FPFuelStationAdded;
FOUNDATION_EXPORT NSString * const FPFuelStationRemotelyAdded;

#pragma mark - Fuel Purchase Log related notifications

// To be subscribed to by outsiders (e.g., GUI components)
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogSyncInitiated;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogSynced;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogSyncFailed;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogDeleted;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogRemotelyDeleted;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogUpdated;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogRemotelyUpdated;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogAdded;
FOUNDATION_EXPORT NSString * const FPFuelPurchaseLogRemotelyAdded;

#pragma mark - Environment Log related notifications

// To be subscribed to by outsiders (e.g., GUI components)
FOUNDATION_EXPORT NSString * const FPEnvironmentLogSyncInitiated;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogSynced;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogSyncFailed;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogDeleted;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogRemotelyDeleted;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogUpdated;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogRemotelyUpdated;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogAdded;
FOUNDATION_EXPORT NSString * const FPEnvironmentLogRemotelyAdded;

#pragma mark - General Notifications

FOUNDATION_EXPORT NSString * const FPSystemPruningComplete;
FOUNDATION_EXPORT NSString * const FPAuthenticationRequired;
