//
//  FPLocalDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PELMUtils.h"
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPFuelStation.h"
#import "FPEnvironmentLog.h"
#import "FPFuelPurchaseLog.h"

@interface FPLocalDao : NSObject

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath;

#pragma mark - Initialize Database

- (void)initializeDatabaseWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (nonatomic, readonly) PELMUtils *localModelUtils;

@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

#pragma mark - System related

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk
                       systemPruneCount:(NSInteger)systemFlushCount;

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error;

- (void)deleteAllUsers:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User

- (void)saveNewLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewRemoteUser:(FPUser *)remoteUser
       andLinkToLocalUser:(FPUser *)localUser
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)deepSaveNewRemoteUser:(FPUser *)remoteUser
           andLinkToLocalUser:(FPUser *)localUser
                        error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

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

- (void)markAsDoneEditingImmediateSyncUser:(FPUser *)user
                               editActorId:(NSNumber *)editActorId
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

- (FPUser *)markUserAsSyncInProgressWithEditActorId:(NSNumber *)editActorId
                                              error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForUser:(FPUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
              editActorId:(NSNumber *)editActorId
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsInConflictForUser:(FPUser *)user
                    editActorId:(NSNumber *)editActorId
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUser:(FPUser *)user
                      editActorId:(NSNumber *)editActorId
                            error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Vehicle

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
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

- (void)markAsDoneEditingImmediateSyncVehicle:(FPVehicle *)vehicle
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

- (NSArray *)markVehiclesAsSyncInProgressForUser:(FPUser *)user
                                     editActorId:(NSNumber *)editActorId
                                           error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForVehicle:(FPVehicle *)vehicle
                httpRespCode:(NSNumber *)httpRespCode
                   errorMask:(NSNumber *)errorMask
                     retryAt:(NSDate *)retryAt
                 editActorId:(NSNumber *)editActorId
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsInConflictForVehicle:(FPVehicle *)vehicle
                       editActorId:(NSNumber *)editActorId
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewVehicle:(FPVehicle *)vehicle
                                forUser:(FPUser *)user
                            editActorId:(NSNumber *)editActorId
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)vehicle
                                editActorId:(NSNumber *)editActorId
                                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Station

- (NSInteger)numFuelStationsForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelStationsForUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepFuelStationFromRemoteMaster:(FPFuelStation *)fuelStation
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
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

- (void)markAsDoneEditingImmediateSyncFuelStation:(FPFuelStation *)fuelStation
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

- (NSArray *)markFuelStationsAsSyncInProgressForUser:(FPUser *)user
                                         editActorId:(NSNumber *)editActorId
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markFuelStationsAsCoordinateComputeForUser:(FPUser *)user
                                            editActorId:(NSNumber *)editActorId                                      
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelStation:(FPFuelStation *)fuelStation
                    httpRespCode:(NSNumber *)httpRespCode
                       errorMask:(NSNumber *)errorMask
                         retryAt:(NSDate *)retryAt
                     editActorId:(NSNumber *)editActorId
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsInConflictForFuelStation:(FPFuelStation *)fuelStation
                           editActorId:(NSNumber *)editActorId
                                 error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelStation:(FPFuelStation *)fuelStation
                                    forUser:(FPUser *)user
                                editActorId:(NSNumber *)editActorId
                                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)fuelStation
                                    editActorId:(NSNumber *)editActorId
                                          error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Purchase Log

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk;

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

- (void)persistDeepFuelPurchaseLogFromRemoteMaster:(FPFuelPurchaseLog *)fuelPurchaseLog
                                           forUser:(FPUser *)user
                                             error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:vehicle
                   fuelStation:fuelStation
                         error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:vehicle
                                   fuelStation:fuelStation
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

- (void)markAsDoneEditingImmediateSyncFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
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

- (NSArray *)markFuelPurchaseLogsAsSyncInProgressForUser:(FPUser *)user
                                             editActorId:(NSNumber *)editActorId
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        httpRespCode:(NSNumber *)httpRespCode
                           errorMask:(NSNumber *)errorMask
                             retryAt:(NSDate *)retryAt
                         editActorId:(NSNumber *)editActorId
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsInConflictForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                               editActorId:(NSNumber *)editActorId
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        forUser:(FPUser *)user
                                    editActorId:(NSNumber *)editActorId
                                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        editActorId:(NSNumber *)editActorId
                                              error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Environment Log

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

- (void)persistDeepEnvironmentLogFromRemoteMaster:(FPEnvironmentLog *)environmentLog
                                          forUser:(FPUser *)user
                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:vehicle
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                      forUser:(FPUser *)user
                                      vehicle:vehicle
                                        error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                         editActorId:(NSNumber *)editActorId
                   entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                       entityDeleted:(void(^)(void))entityDeletedBlk
                    entityInConflict:(void(^)(void))entityInConflictBlk
       entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
               editActorId:(NSNumber *)editActorId
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                            editActorId:(NSNumber *)editActorId
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                         editActorId:(NSNumber *)editActorId
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       editActorId:(NSNumber *)editActorId
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDeletedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEnvironmentLogsAsSyncInProgressForUser:(FPUser *)user
                                            editActorId:(NSNumber *)editActorId
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       httpRespCode:(NSNumber *)httpRespCode
                          errorMask:(NSNumber *)errorMask
                            retryAt:(NSDate *)retryAt
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsInConflictForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                              editActorId:(NSNumber *)editActorId
                                    error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       forUser:(FPUser *)user
                                   editActorId:(NSNumber *)editActorId
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       editActorId:(NSNumber *)editActorId
                                             error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Cascade Deletion

- (void)cascadeDeleteEnvironmentLog:(FPEnvironmentLog *)environmentLog
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)cascadeDeleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)cascadeDeleteFuelStation:(FPFuelStation *)fuelStation
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)cascadeDeleteVehicle:(FPVehicle *)vehicle
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cascadeDeleteUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User data access helpers (quasi-private)

- (FPUser *)mainUserWithError:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk;

@end
