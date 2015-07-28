//
//  FPCoordinatorDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCCharset.h>
#import <PEFuelPurchase-Common/FPAuthTokenDelegate.h>
#import "FPRemoteStoreSyncConflictDelegate.h"
#import "FPRemoteMasterDao.h"
#import "FPLocalDao.h"

typedef void (^FPSavedNewEntityCompletionHandler)(FPUser *, NSError *);

typedef void (^FPFetchedEntityCompletionHandler)(id, NSError *);

@interface FPCoordinatorDao : NSObject

#pragma mark - Initializers

/**
 @param authScheme When interacting with the remote master store, in an
 authenticated context, the user's authentication material (an auth token), is
 communicated via the standard "Authorization" HTTP request header.  The value
 of this header will be of the form: "SCHEME PARAM=VALUE".  This parameter serves
 as the "SCHEME" part.
 @param authTokenParamName As per the explanation on the authScheme param, this
 param serves as the "PARAM" part.
 @param authToken As per the explanation on the authScheme param, this param
 serves as the "VALUE" part.  If the user of this class happens to have their
 hands on an existing authentication token (perhaps they yanked one from the
 app's keychain), then they would provide it on this param; otherwise, nil can
 be passed.
 @param authTokenResponseHeaderName Upon establishing an authenticated session,
 the authentication token value will travel back to the client as a custom
 HTTP response header.  This param serves as the name of the header.
 @param authTokenDelegate
 */
- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
      localDatabaseCreationError:(PELMDaoErrorBlk)errorBlk
  timeoutForMainThreadOperations:(NSInteger)timeout
                   acceptCharset:(HCCharset *)acceptCharset
                  acceptLanguage:(NSString *)acceptLanguage
              contentTypeCharset:(HCCharset *)contentTypeCharset
                      authScheme:(NSString *)authScheme
              authTokenParamName:(NSString *)authTokenParamName
                       authToken:(NSString *)authToken
             errorMaskHeaderName:(NSString *)errorMaskHeaderName
      establishSessionHeaderName:(NSString *)establishHeaderSessionName
     authTokenResponseHeaderName:(NSString *)authTokenHeaderName
    bundleHoldingApiJsonResource:(NSBundle *)bundle
       nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
                 apiResMtVersion:(NSString *)apiResourceMediaTypeVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
      remoteSyncConflictDelegate:(id<FPRemoteStoreSyncConflictDelegate>)conflictDelegate
               authTokenDelegate:(id<FPAuthTokenDelegate>)authTokenDelegate
        allowInvalidCertificates:(BOOL)allowInvalidCertifications;

#pragma mark - Initialize Local Database

- (void)initializeLocalDatabaseWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) NSString *authToken;

@property (nonatomic, readonly) FPLocalDao *localDao;

#pragma mark - Pruning

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - System

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error;

#pragma mark - Flushing to Remote Master

- (void)flushUnsyncedChangesToUser:(FPUser *)user
                    addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                       addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                           addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      forUser:(FPUser *)user
                               addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     forUser:(FPUser *)user
                              addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(FPUser *)user
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                          allDone:(void(^)(void))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User

- (void)deleteUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user;

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user;

- (BOOL)doesUserHaveAnyUnsyncedEntities:(FPUser *)user;

- (void)deleteRemoteAuthenticationTokenWithRemoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                     addlCompletionHandler:(void(^)(void))addlCompletionHandler;

- (void)resetAsLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)error;

- (FPUser *)newLocalUserWithError:(PELMDaoErrorBlk)errorBlk;

- (void)establishRemoteAccountForLocalUser:(FPUser *)localUser
             preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                         completionHandler:(FPSavedNewEntityCompletionHandler)complHandler
                     localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler;

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
    andLinkRemoteUserToLocalUser:(FPUser *)localUser
   preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               completionHandler:(FPFetchedEntityCompletionHandler)complHandler
           localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler;

- (void)lightLoginForUser:(FPUser *)user
                 password:(NSString *)password
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
        completionHandler:(void(^)(NSError *))complHandler
    localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler;

- (BOOL)prepareUserForEdit:(FPUser *)user
         entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
             entityDeleted:(void(^)(void))entityDeletedBlk
          entityInConflict:(void(^)(void))entityInConflictBlk
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUser:(FPUser *)user
           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfUser:(FPUser *)user
                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedAndSyncUserImmediate:(FPUser *)user
                               successBlk:(void(^)(void))successBlk
                       remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                       tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                           remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                          authRequiredBlk:(void(^)(void))authRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Vehicle

- (void)copyVehicleToMaster:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity;

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                            successBlk:(void(^)(void))successBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                        remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                       authRequiredBlk:(void(^)(void))authRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
            entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                entityDeleted:(void(^)(void))entityDeletedBlk
             entityInConflict:(void(^)(void))entityInConflictBlk
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveVehicle:(FPVehicle *)vehicle
              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                                      successBlk:(void(^)(void))successBlk
                              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                 authRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadVehicle:(FPVehicle *)vehicle
                error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedVehicle:(FPVehicle *)vehicle
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Station

- (NSInteger)numFuelStationsForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude;

- (NSArray *)fuelStationsForUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                                successBlk:(void(^)(void))successBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                           authRequiredBlk:(void(^)(void))authRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                    entityDeleted:(void(^)(void))entityDeletedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                          successBlk:(void(^)(void))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                      remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     authRequiredBlk:(void(^)(void))authRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedFuelStation:(FPFuelStation *)fuelStation
                           error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Purchase Log

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate;

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                     newerThan:(NSDate *)newerThan
                                         error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                      error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)defaultVehicleForNewFuelPurchaseLogForUser:(FPUser *)user
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                   fuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:(FPVehicle *)vehicle
                                   fuelStation:(FPFuelStation *)fuelStation
                                    successBlk:(void(^)(void))successBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                               authRequiredBlk:(void(^)(void))authRequiredBlk
                  skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
              skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                         error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                    entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                        entityDeleted:(void(^)(void))entityDeletedBlk
                     entityInConflict:(void(^)(void))entityInConflictBlk
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                 forUser:(FPUser *)user
                                              successBlk:(void(^)(void))successBlk
                                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                          remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                         authRequiredBlk:(void(^)(void))authRequiredBlk
                            skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                        skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                               error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Environment Log

- (FPEnvironmentLog *)environmentLogWithOdometer:(NSDecimalNumber *)odometer
                                  reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                                  reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                             reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                         logDate:(NSDate *)logDate
                                     reportedDte:(NSNumber *)reportedDte;

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                newerThan:(NSDate *)newerThan
                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)fpLog
                                  error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)envLog
                      forUser:(FPUser *)user
                      vehicle:(FPVehicle *)vehicle
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)envLog
                                      forUser:(FPUser *)user
                                      vehicle:(FPVehicle *)vehicle
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)envLog
                             forUser:(FPUser *)user
                   entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                       entityDeleted:(void(^)(void))entityDeletedBlk
                    entityInConflict:(void(^)(void))entityInConflictBlk
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEnvironmentLog:(FPEnvironmentLog *)envLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)envLog
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
                                                forUser:(FPUser *)user
                                             successBlk:(void(^)(void))successBlk
                                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                         remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                        authRequiredBlk:(void(^)(void))authRequiredBlk
                           skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)envLog
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedEnvironmentLog:(FPEnvironmentLog *)envLog
                              error:(PELMDaoErrorBlk)errorBlk;

@end
