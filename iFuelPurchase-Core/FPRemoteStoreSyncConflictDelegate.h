//
//  FPRemoteStoreSyncConflictDelegate.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPFuelPurchaseLog.h"
#import "FPEnvironmentLog.h"

@protocol FPRemoteStoreSyncConflictDelegate <NSObject>

- (void)remoteStoreVersionOfUser:(FPUser *)remoteStoreUser
         isNewerThanLocalVersion:(FPUser *)localUser;

- (void)remoteStoreVersionOfVehicle:(FPVehicle *)remoteStoreVehicle
            isNewerThanLocalVersion:(FPVehicle *)localVehicle;

- (void)remoteStoreVersionOfFuelStation:(FPFuelStation *)remoteStoreFuelStation
                isNewerThanLocalVersion:(FPFuelStation *)localFuelStation;

- (void)remoteStoreVersionOfFuelPurchaseLog:(FPFuelPurchaseLog *)remoteStoreFuelPurchaseLog
                    isNewerThanLocalVersion:(FPFuelPurchaseLog *)localFuelPurchaseLog;

- (void)remoteStoreVersionOfEnvironmentLog:(FPEnvironmentLog *)remoteStoreEnvironmentLog
                   isNewerThanLocalVersion:(FPEnvironmentLog *)localEnvironmentLog;

@end
