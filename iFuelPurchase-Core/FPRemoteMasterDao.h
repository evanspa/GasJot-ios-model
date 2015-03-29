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
         transactionId:(NSString *)transactionId
          asynchronous:(BOOL)asynchronous
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)saveExistingVehicle:(FPVehicle *)vehicle
              transactionId:(NSString *)transactionId
               asynchronous:(BOOL)asynchronous
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
  queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)deleteVehicle:(FPVehicle *)vehicle
        transactionId:(NSString *)transactionId
         asynchronous:(BOOL)asynchronous
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

#pragma mark - Fuel Station Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
             transactionId:(NSString *)transactionId
              asynchronous:(BOOL)asynchronous
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
 queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                  transactionId:(NSString *)transactionId
                   asynchronous:(BOOL)asynchronous
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
      queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
            transactionId:(NSString *)transactionId
             asynchronous:(BOOL)asynchronous
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                 transactionId:(NSString *)transactionId
                  asynchronous:(BOOL)asynchronous
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
     queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                      transactionId:(NSString *)transactionId
                       asynchronous:(BOOL)asynchronous
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
          queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                transactionId:(NSString *)transactionId
                 asynchronous:(BOOL)asynchronous
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
    queueForCompletionHandler:(dispatch_queue_t)queue;

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                      forUser:(FPUser *)user
                transactionId:(NSString *)transactionId
                 asynchronous:(BOOL)asynchronous
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
    queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
                     transactionId:(NSString *)transactionId
                      asynchronous:(BOOL)asynchronous
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
         queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)fuelPurchaseLog
               transactionId:(NSString *)transactionId
                asynchronous:(BOOL)asynchronous
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
   queueForCompletionHandler:(dispatch_queue_t)queue;

#pragma mark - User Operations

- (void)saveNewUser:(FPUser *)user
      transactionId:(NSString *)transactionId
       asynchronous:(BOOL)asynchronous
            timeout:(NSInteger)timeout
    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)saveExistingUser:(FPUser *)user
           transactionId:(NSString *)transactionId
            asynchronous:(BOOL)asynchronous
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                   transactionId:(NSString *)transactionId
                    asynchronous:(BOOL)asynchronous
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
       queueForCompletionHandler:(dispatch_queue_t)queue;

- (void)deleteUser:(FPUser *)user
     transactionId:(NSString *)transactionId
      asynchronous:(BOOL)asynchronous
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue;

@end
