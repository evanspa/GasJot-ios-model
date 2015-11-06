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
#import "FPChangelog.h"
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

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk;

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error;

#pragma mark - User

- (NSDate *)mostRecentMasterUpdateForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)masterUserWithId:(NSNumber *)userId error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)masterUserWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteUser:(FPUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user;

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user;

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user;

- (NSInteger)numSyncNeededVehiclesForUser:(FPUser *)user;

- (NSInteger)numSyncNeededFuelStationsForUser:(FPUser *)user;

- (NSInteger)numSyncNeededFuelPurchaseLogsForUser:(FPUser *)user;

- (NSInteger)numSyncNeededEnvironmentLogsForUser:(FPUser *)user;

- (NSInteger)totalNumSyncNeededEntitiesForUser:(FPUser *)user;

- (void)saveNewLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewRemoteUser:(FPUser *)remoteUser
       andLinkToLocalUser:(FPUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)deepSaveNewRemoteUser:(FPUser *)remoteUser
           andLinkToLocalUser:(FPUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                        error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareUserForEdit:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)markUserAsSyncInProgressWithError:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForUser:(FPUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
                    error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)saveChangelog:(FPChangelog *)changelog
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Vehicle

- (FPVehicle *)masterVehicleWithId:(NSNumber *)vehicleId error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)masterVehicleWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)copyVehicleToMaster:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)vehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)persistDeepVehicleFromRemoteMaster:(FPVehicle *)vehicle
                                   forUser:(FPUser *)user
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewVehicle:(FPVehicle *)vehicle forUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)saveVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markVehiclesAsSyncInProgressForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForVehicle:(FPVehicle *)vehicle
                httpRespCode:(NSNumber *)httpRespCode
                   errorMask:(NSNumber *)errorMask
                     retryAt:(NSDate *)retryAt
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterVehicle:(FPVehicle *)vehicle
                     forUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterVehicle:(FPVehicle *)vehicle
                  forUser:(FPUser *)user
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewVehicle:(FPVehicle *)vehicle
                                forUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Station

- (FPFuelStation *)masterFuelstationWithId:(NSNumber *)fuelstationId error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)masterFuelstationWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelstation:(FPFuelStation *)fuelstation error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)fuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk;

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
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncFuelStation:(FPFuelStation *)fuelStation
                                            error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markFuelStationsAsSyncInProgressForUser:(FPUser *)user
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelStation:(FPFuelStation *)fuelStation
                    httpRespCode:(NSNumber *)httpRespCode
                       errorMask:(NSNumber *)errorMask
                         retryAt:(NSDate *)retryAt
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterFuelstation:(FPFuelStation *)fuelstation
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterFuelstation:(FPFuelStation *)fuelstation
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelStation:(FPFuelStation *)fuelStation
                                    forUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)fuelStation
                                          error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Fuel Purchase Log

- (NSArray *)distinctOctanesForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)distinctOctanesForVehicle:(FPVehicle *)vehicle
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)distinctOctanesForFuelstation:(FPFuelStation *)fuelstation
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                          beforeDate:(NSDate *)beforeDate
                                       onOrAfterDate:(NSDate *)onOrAfterDate
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForFuelstation:(FPFuelStation *)fuelstation
                                              octane:(NSNumber *)octane
                                               error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                    beforeDate:(NSDate *)beforeDate
                                                 onOrAfterDate:(NSDate *)onOrAfterDate
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForVehicle:(FPVehicle *)vehicle
                                                        octane:(NSNumber *)octane
                                                         error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                        beforeDate:(NSDate *)beforeDate
                                                     onOrAfterDate:(NSDate *)onOrAfterDate
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForFuelstation:(FPFuelStation *)fuelstation
                                                            octane:(NSNumber *)octane
                                                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)beforeDate
                                       afterDate:(NSDate *)afterDate
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                   beforeDate:(NSDate *)beforeDate
                                onOrAfterDate:(NSDate *)onOrAfterDate
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedFuelPurchaseLogsForUser:(FPUser *)user
                                       octane:(NSNumber *)octane
                                        error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForUser:(FPUser *)user
                                   octane:(NSNumber *)octane
                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                      octane:(NSNumber *)octane
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForVehicle:(FPVehicle *)vehicle
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)firstGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          octane:(NSNumber *)octane
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForUser:(FPUser *)user
                                  octane:(NSNumber *)octane
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                     octane:(NSNumber *)octane
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForVehicle:(FPVehicle *)vehicle
                                 beforeDate:(NSDate *)beforeDate
                              onOrAfterDate:(NSDate *)onOrAfterDate
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)lastGasLogForFuelstation:(FPFuelStation *)fuelstation
                                         octane:(NSNumber *)octane
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                      forVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)gasLogNearestToDate:(NSDate *)date
                         forUser:(FPUser *)user
                          octane:(NSNumber *)octane
                           error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                 beforeDate:(NSDate *)beforeDate
                                              onOrAfterDate:(NSDate *)onOrAfterDate
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)maxGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)minGallonPriceFuelPurchaseLogForUser:(FPUser *)user
                                                     octane:(NSNumber *)octane
                                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)masterFplogWithId:(NSNumber *)fplogId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelPurchaseLog *)masterFplogWithGlobalId:(NSString *)globalId
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk;

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


- (FPVehicle *)masterVehicleForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                     error:(PELMDaoErrorBlk)errorBlk;

- (FPFuelStation *)masterFuelstationForMasterFpLog:(FPFuelPurchaseLog *)fplog
                                             error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk;

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
                                error:(PELMDaoErrorBlk)errorBlk;

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markFuelPurchaseLogsAsSyncInProgressForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        httpRespCode:(NSNumber *)httpRespCode
                           errorMask:(NSNumber *)errorMask
                             retryAt:(NSDate *)retryAt
                               error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                       forVehicle:(FPVehicle *)vehicle
                   forFuelstation:(FPFuelStation *)fuelstation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                        forUser:(FPUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                              error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Environment Log

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                            beforeDate:(NSDate *)beforeDate
                                         onOrAfterDate:(NSDate *)onOrAfterDate
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                               beforeDate:(NSDate *)beforeDate
                                            onOrAfterDate:(NSDate *)onOrAfterDate
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)maxReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForUser:(FPUser *)user
                                                 error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)minReportedMpgOdometerLogForVehicle:(FPVehicle *)vehicle
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                      afterDate:(NSDate *)afterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unorderedEnvironmentLogsForUser:(FPUser *)user
                                  beforeDate:(NSDate *)beforeDate
                               onOrAfterDate:(NSDate *)onOrAfterDate
                                       error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                           forVehicle:(FPVehicle *)vehicle
                                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogNearestToDate:(NSDate *)date
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)odometerLogWithNonNilTemperatureNearestToDate:(NSDate *)date
                                                   forUser:(FPUser *)user
                                                     error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                      beforeDate:(NSDate *)onOrBeforeDate
                                   onOrAfterDate:(NSDate *)onOrAfterDate
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                     beforeDate:(NSDate *)beforeDate
                                  onOrAfterDate:(NSDate *)onOrAfterDate
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForUser:(FPUser *)user
                                        error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)firstOdometerLogForVehicle:(FPVehicle *)vehicle
                                           error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)lastOdometerLogForVehicle:(FPVehicle *)vehicle
                                          error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)masterEnvlogWithId:(NSNumber *)envlogId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (FPEnvironmentLog *)masterEnvlogWithGlobalId:(NSString *)globalId
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                       error:(PELMDaoErrorBlk)errorBlk;

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

- (FPVehicle *)masterVehicleForMasterEnvLog:(FPEnvironmentLog *)envlog
                                      error:(PELMDaoErrorBlk)errorBlk;

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)envlog
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
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEnvironmentLogsAsSyncInProgressForUser:(FPUser *)user
                                                  error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       httpRespCode:(NSNumber *)httpRespCode
                          errorMask:(NSNumber *)errorMask
                            retryAt:(NSDate *)retryAt
                              error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterEnvironmentLog:(FPEnvironmentLog *)envlog
                      forVehicle:(FPVehicle *)vehicle
                         forUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                       forUser:(FPUser *)user
                                         error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                             error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User data access helpers (quasi-private)

- (FPUser *)mainUserWithError:(PELMDaoErrorBlk)errorBlk;

- (FPUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk;

@end
