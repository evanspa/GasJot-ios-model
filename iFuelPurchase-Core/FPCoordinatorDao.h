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
 errorBlkForBackgroundProcessing:(PELMDaoErrorBlk)bgProcessingErrorBlk
                   bgEditActorId:(NSNumber *)bgEditActorId
        allowInvalidCertificates:(BOOL)allowInvalidCertifications;

#pragma mark - Initialize Local Database

- (void)initializeLocalDatabaseWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic) NSString *authToken;

@property (nonatomic, readonly) FPLocalDao *localDao;

@property (nonatomic) NSUInteger flushToRemoteMasterCount;

@property (nonatomic) NSUInteger systemPruneCount;

@property (nonatomic) BOOL includeUserInBackgroundFlush;

#pragma mark - Flushing to Remote Master and other Background Work

// by definition, this can only be invoked by the 'background' edit actor ID
// (supplied to coordDao's initializer)
- (void)asynchronousWork:(NSTimer *)timer;

- (void)flushToRemoteMasterWithEditActorId:(NSNumber *)editActorId
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)computeOfFuelStationCoordsWithEditActorId:(NSNumber *)editActorId
                                            error:(PELMDaoErrorBlk)error;

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - System

- (void)logoutUser:(FPUser *)user error:(PELMDaoErrorBlk)error;

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error;

#pragma mark - User

- (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password;

- (void)immediateRemoteSyncSaveNewUser:(FPUser *)user
                       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                     completionHandler:(FPSavedNewEntityCompletionHandler)complHandler
                 localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler;

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               completionHandler:(FPFetchedEntityCompletionHandler)complHandler
           localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler;

- (BOOL)prepareUserForEdit:(FPUser *)user
               editActorId:(NSNumber *)editActorId
         entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
             entityDeleted:(void(^)(void))entityDeletedBlk
          entityInConflict:(void(^)(void))entityInConflictBlk
entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUser:(FPUser *)user
     editActorId:(NSNumber *)editActorId
           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                                  editActorId:(NSNumber *)editActorId
                                   successBlk:(void(^)(void))successBlk
                               remoteErrorBlk:(void(^)(NSError *))remoteErrBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                        error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingUser:(FPUser *)user
                  editActorId:(NSNumber *)editActorId
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfUser:(FPUser *)user
             editActorId:(NSNumber *)editActorId
                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedUser:(FPUser *)user
              editActorId:(NSNumber *)editActorId
                    error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Vehicle

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity;

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                  editActorId:(NSNumber *)editActorId
            entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                entityDeleted:(void(^)(void))entityDeletedBlk
             entityInConflict:(void(^)(void))entityInConflictBlk
entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveVehicle:(FPVehicle *)vehicle
        editActorId:(NSNumber *)editActorId
              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                     editActorId:(NSNumber *)editActorId
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadVehicle:(FPVehicle *)vehicle
                error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle
                editActorId:(NSNumber *)editActorId
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedVehicle:(FPVehicle *)vehicle
                 editActorId:(NSNumber *)editActorId
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

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                      editActorId:(NSNumber *)editActorId
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                    entityDeleted:(void(^)(void))entityDeletedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
    entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelStation:(FPFuelStation *)fuelStation
            editActorId:(NSNumber *)editActorId
                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                         editActorId:(NSNumber *)editActorId
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                    editActorId:(NSNumber *)editActorId
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedFuelStation:(FPFuelStation *)fuelStation
                     editActorId:(NSNumber *)editActorId
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

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                          editActorId:(NSNumber *)editActorId
                    entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                        entityDeleted:(void(^)(void))entityDeletedBlk
                     entityInConflict:(void(^)(void))entityInConflictBlk
        entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                editActorId:(NSNumber *)editActorId
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                             editActorId:(NSNumber *)editActorId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                         editActorId:(NSNumber *)editActorId
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

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)envLog
                             forUser:(FPUser *)user
                         editActorId:(NSNumber *)editActorId
                   entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                       entityDeleted:(void(^)(void))entityDeletedBlk
                    entityInConflict:(void(^)(void))entityInConflictBlk
       entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEnvironmentLog:(FPEnvironmentLog *)envLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
               editActorId:(NSNumber *)editActorId
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)envLog
                            editActorId:(NSNumber *)editActorId
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)envLog
                       editActorId:(NSNumber *)editActorId
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedEnvironmentLog:(FPEnvironmentLog *)envLog
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk;

@end
