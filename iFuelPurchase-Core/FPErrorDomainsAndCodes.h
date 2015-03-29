//
//  FPErrorDomainsAndCodes.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Error domain for errors that are fundamentally the fault of the user (e.g.,
 providing invalid input).
 */
FOUNDATION_EXPORT NSString * const FPUserFaultedErrorDomain;

/**
 Error domain for errors that are fundamentally connection-related (neither the
 fault of the user, or the backend system.  The error codes used for this
 domain are listed here:
 https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
 This error domain effectively mirrors the NSURLErrorDomain domain.
 */
FOUNDATION_EXPORT NSString * const FPConnFaultedErrorDomain;

/**
 Error domain for errors that are fundamentally the fault of the system (e.g.,
 the database is down).
 */
FOUNDATION_EXPORT NSString * const FPSystemFaultedErrorDomain;

/**
 Error codes for the 'Save User' use cases of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSaveUserMsg) {
  FPSaveUsrAnyIssues              = 1 << 0,
  FPSaveUsrNameNotProvided        = 1 << 1,
  FPSaveUsrInvalidName            = 1 << 2,
  FPSaveUsrInvalidEmail           = 1 << 3,
  FPSaveUsrInvalidUsername        = 1 << 4,
  FPSaveUsrIdentifierNotProvided  = 1 << 5,
  FPSaveUsrPasswordNotProvided    = 1 << 6,
  FPSaveUsrEmailAlreadyRegistered = 1 << 7
};

/**
 Error codes for the 'Save Environment Log' use cases of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSaveEnvironmentLogMsg) {
  FPSaveEnvironmentLogAnyIssues                 = 1 << 0,
  FPSaveEnvironmentLogDateNotProvided           = 1 << 1,
  FPSaveEnvironmentLogOdometerNotProvided       = 1 << 2
};

/**
 Error codes for the 'Save Fuel Purchase Log' use cases of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSaveFuelPurchaseLogMsg) {
  FPSaveFuelPurchaseLogAnyIssues                 = 1 << 0,
  FPSaveFuelPurchaseLogPurchaseDateNotProvided   = 1 << 1,
  FPSaveFuelPurchaseLogNumGallonsNotProvided     = 1 << 2,
  FPSaveFuelPurchaseLogOctaneNotProvided         = 1 << 3,
  FPSaveFuelPurchaseLogGallonPriceNotProvided    = 1 << 4
};

/**
 Error codes for the 'Save Fuel Station' use cases of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSaveFuelStationMsg) {
  FPSaveFuelStationAnyIssues                 = 1 << 0,
  FPSaveFuelStationNameNotProvided           = 1 << 1, // ctx: Create/Edit fuel station
};

/**
 Error codes for the 'Save Vehicle' use cases of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSaveVehicleMsg) {
  FPSaveVehicleAnyIssues              = 1 << 0,
  FPSaveVehicleNameNotProvided        = 1 << 1, // ctx: Create/Edit vehicle
  FPSaveVehicleVehicleAlreadyExists   = 1 << 2, // ctx: Create vehicle
};

/**
 General (screen-agnostic) error codes of the FPSystemFaultedErrorDomain domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSysErrorMsg) {
  FPSysAnyIssues    = 1 << 0,
  FPSysDatabaseDown = 1 << 1
};

/**
 Error codes for the 'Sign In' use case of the FPUserFaultedErrorDomain
 domain.
 */
typedef NS_OPTIONS(NSUInteger, FPSignInMsg) {
  FPSignInAnyIssues                  = 1 << 0,
  FPSignInUsernameOrEmailNotProvided = 1 << 1,
  FPSignInPasswordNotProvided        = 1 << 2,
  FPSignInInvalidCredentials         = 1 << 3
};

