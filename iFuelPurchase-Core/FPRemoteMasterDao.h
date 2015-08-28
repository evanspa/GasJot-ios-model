//
//  FPRemoteMasterDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCAuthentication.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPFuelPurchaseLog.h"
#import "FPEnvironmentLog.h"
#import "PELMUtils.h"

@protocol FPRemoteMasterDao <NSObject>

#pragma mark - General Operations

- (void)setAuthToken:(NSString *)authToken;

#pragma mark - Vehicle Operations

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingVehicle:(FPVehicle *)vehicle
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteVehicle:(FPVehicle *)vehicle
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchVehicleWithGlobalId:(NSString *)globalId
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Fuel Station Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchFuelstationWithGlobalId:(NSString *)globalId
                             timeout:(NSInteger)timeout
                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                        authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalId
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                      forUser:(FPUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalId
                                timeout:(NSInteger)timeout
                        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - User Operations

- (void)logoutUser:(FPUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)establishAccountForUser:(FPUser *)user
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingUser:(FPUser *)user
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)lightLoginForUser:(FPUser *)user
                 password:(NSString *)password
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteUser:(FPUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

@end
