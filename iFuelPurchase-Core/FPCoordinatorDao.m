//
//  FPCoordinatorDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CocoaLumberjack/DDLog.h>
#import "FPCoordinatorDao.h"
#import "FPErrorDomainsAndCodes.h"
#import "FPLocalDao.h"
#import "FPRestRemoteMasterDao.h"
#import "FPRemoteDaoErrorDomains.h"
#import "FPNotificationNames.h"
#import "PELMUtils.h"
#import "FPKnownMediaTypes.h"
#import <PEObjc-Commons/PEUtils.h>
#import "PELMNotificationUtils.h"
#import "FPLogging.h"

@implementation FPCoordinatorDao {
  id<FPRemoteMasterDao> _remoteMasterDao;
  NSInteger _timeout;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  NSString *_apiResMtVersion;
  NSString *_userResMtVersion;
  NSString *_vehicleResMtVersion;
  NSString *_fuelStationResMtVersion;
  NSString *_fuelPurchaseLogResMtVersion;
  NSString *_environmentLogResMtVersion;
  id<FPRemoteStoreSyncConflictDelegate> _conflictDelegate;
  id<FPAuthTokenDelegate> _authTokenDelegate;
  dispatch_queue_t _serialQueue;
  PELMDaoErrorBlk _bgProcessingErrorBlk;
  NSNumber *_bgEditActorId;
}

#pragma mark - Initializers

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
                 apiResMtVersion:(NSString *)apiResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
      remoteSyncConflictDelegate:(id<FPRemoteStoreSyncConflictDelegate>)conflictDelegate
               authTokenDelegate:(id<FPAuthTokenDelegate>)authTokenDelegate
 errorBlkForBackgroundProcessing:(PELMDaoErrorBlk)bgProcessingErrorBlk
                   bgEditActorId:(NSNumber *)bgEditActorId
        allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super init];
  if (self) {
    _serialQueue = dispatch_queue_create("name.paulevans.fuelpurchase.bgprocessing",
                                         DISPATCH_QUEUE_SERIAL);
    _flushToRemoteMasterCount = 0;
    _systemPruneCount = 0;
    _timeout = timeout;
    _localDao = [[FPLocalDao alloc] initWithSqliteDataFilePath:sqliteDataFilePath];
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _authToken = authToken;
    _apiResMtVersion = apiResMtVersion;
    _userResMtVersion = userResMtVersion;
    _vehicleResMtVersion = vehicleResMtVersion;
    _fuelStationResMtVersion = fuelStationResMtVersion;
    _fuelPurchaseLogResMtVersion = fuelPurchaseLogResMtVersion;
    _environmentLogResMtVersion = environmentLogResMtVersion;

    FPEnvironmentLogSerializer *environmentLogSerializer =
      [self environmentLogSerializerForCharset:acceptCharset];
    FPFuelPurchaseLogSerializer *fuelPurchaseLogSerializer =
      [self fuelPurchaseLogSerializerForCharset:acceptCharset];
    FPVehicleSerializer *vehicleSerializer =
      [self vehicleSerializerForCharset:acceptCharset];
    FPFuelStationSerializer *fuelStationSerializer =
      [self fuelStationSerializerForCharset:acceptCharset];
    FPUserSerializer *userSerializer =
      [self userSerializerForCharset:acceptCharset
                   vehicleSerializer:vehicleSerializer
               fuelStationSerializer:fuelStationSerializer
           fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
            environmentLogSerializer:environmentLogSerializer];
    FPLoginSerializer *loginSerializer =
      [[FPLoginSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                           charset:acceptCharset
                                    userSerializer:userSerializer];
    _remoteMasterDao =
      [[FPRestRemoteMasterDao alloc]
        initWithAcceptCharset:acceptCharset
               acceptLanguage:acceptLanguage
           contentTypeCharset:contentTypeCharset
                   authScheme:authScheme
           authTokenParamName:authTokenParamName
                    authToken:authToken
          errorMaskHeaderName:errorMaskHeaderName
   establishSessionHeaderName:establishHeaderSessionName
          authTokenHeaderName:authTokenHeaderName
 bundleHoldingApiJsonResource:bundle
    nameOfApiJsonResourceFile:apiResourceFileName
              apiResMtVersion:apiResMtVersion
               userSerializer:userSerializer
              loginSerializer:loginSerializer
            vehicleSerializer:vehicleSerializer
        fuelStationSerializer:fuelStationSerializer
    fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
     environmentLogSerializer:environmentLogSerializer
     allowInvalidCertificates:allowInvalidCertificates];
    _conflictDelegate = conflictDelegate;
    _authTokenDelegate = authTokenDelegate;
    _bgProcessingErrorBlk = bgProcessingErrorBlk;
    _bgEditActorId = bgEditActorId;

    _includeUserInBackgroundFlush = YES;
  }
  return self;
}

#pragma mark - Initialize Local Database

- (void)initializeLocalDatabaseWithError:(PELMDaoErrorBlk)errorBlk {
  [_localDao initializeDatabaseWithError:errorBlk];
}

#pragma mark - Setters

- (void)setAuthToken:(NSString *)authToken {
  _authToken = authToken;
  [_remoteMasterDao setAuthToken:authToken];
}

#pragma mark - Initializer Helpers

- (FPEnvironmentLogSerializer *)environmentLogSerializerForCharset:(HCCharset *)charset {
  return [[FPEnvironmentLogSerializer alloc] initWithMediaType:[FPKnownMediaTypes environmentLogMediaTypeWithVersion:_environmentLogResMtVersion]
                                                       charset:charset
                               serializersForEmbeddedResources:@{}
                                   actionsForEmbeddedResources:@{}];
}

- (FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializerForCharset:(HCCharset *)charset {
  return [[FPFuelPurchaseLogSerializer alloc] initWithMediaType:[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:_fuelPurchaseLogResMtVersion]
                                                        charset:charset
                                serializersForEmbeddedResources:@{}
                                    actionsForEmbeddedResources:@{}];
}

- (FPFuelStationSerializer *)fuelStationSerializerForCharset:(HCCharset *)charset {
  return [[FPFuelStationSerializer alloc] initWithMediaType:[FPKnownMediaTypes fuelStationMediaTypeWithVersion:_fuelStationResMtVersion]
                                                    charset:charset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}];
}

- (FPVehicleSerializer *)vehicleSerializerForCharset:(HCCharset *)charset {
  return [[FPVehicleSerializer alloc] initWithMediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:_vehicleResMtVersion]
                                                charset:charset
                        serializersForEmbeddedResources:@{}
                            actionsForEmbeddedResources:@{}];
}

- (FPUserSerializer *)userSerializerForCharset:(HCCharset *)charset
                             vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
                         fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
                     fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
                      environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer {
  HCActionForEmbeddedResource actionForEmbeddedVehicle = ^(id user, id embeddedVehicle) {
    [(FPUser *)user addVehicle:embeddedVehicle];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelStation = ^(id user, id embeddedFuelStation) {
    [(FPUser *)user addFuelStation:embeddedFuelStation];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelPurchaseLog = ^(id user, id embeddedFuelPurchaseLog) {
    [(FPUser *)user addFuelPurchaseLog:embeddedFuelPurchaseLog];
  };
  HCActionForEmbeddedResource actionForEmbeddedEnvironmentLog = ^(id user, id embeddedEnvironmentLog) {
    [(FPUser *)user addEnvironmentLog:embeddedEnvironmentLog];
  };
  return [[FPUserSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                             charset:charset
                     serializersForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : vehicleSerializer,
                                                       [[fuelStationSerializer mediaType] description] : fuelStationSerializer,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : fuelPurchaseLogSerializer,
                                                       [[environmentLogSerializer mediaType] description] : environmentLogSerializer}
                         actionsForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle,
                                                       [[fuelStationSerializer mediaType] description] : actionForEmbeddedFuelStation,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : actionForEmbeddedFuelPurchaseLog,
                                                       [[environmentLogSerializer mediaType] description] : actionForEmbeddedEnvironmentLog}];
}

#pragma mark - Flushing to Remote Master and other Background Work

- (void)asynchronousWork:(NSTimer *)timer {
  if (_authToken) {
    PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAfter) {
      [timer setFireDate:[[timer fireDate] laterDate:retryAfter]];
    };
    dispatch_async(_serialQueue, ^{
      [self computeOfFuelStationCoordsWithEditActorId:_bgEditActorId
                                                error:_bgProcessingErrorBlk];
    });
    dispatch_async(_serialQueue, ^{
        [self flushToRemoteMasterWithEditActorId:_bgEditActorId
                              remoteStoreBusyBlk:remoteStoreBusyBlk
                                           error:_bgProcessingErrorBlk];
      });
  } else {
    DDLogDebug(@"Skipping asynchronous work due to having a nil authentication token.");
  }
}

- (void)flushToRemoteMasterWithEditActorId:(NSNumber *)editActorId
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  _flushToRemoteMasterCount++;
  LogSyncRemoteMaster(@"Syncing remote master starting.", _flushToRemoteMasterCount);
  [self flushUnsyncedChangesToAllEntityTypes:remoteStoreBusyBlk
                                 editActorId:editActorId
                                       error:errorBlk];
  LogSyncRemoteMaster(@"Remote master syncing COMPLETE for all entity types.", _flushToRemoteMasterCount);
}

- (void)computeOfFuelStationCoordsWithEditActorId:(NSNumber *)editActorId
                                            error:(PELMDaoErrorBlk)errorBlk {
  FPUser *user = [self userWithError:_bgProcessingErrorBlk];
  if (user) { // need to check in case user was "deleted" / "logged-out"
    NSArray *fuelStationsToComputeCoords =
      [_localDao markFuelStationsAsCoordinateComputeForUser:user
                                                editActorId:editActorId
                                                      error:errorBlk];
    DDLogDebug(@"Marked [%lu] fuel stations for edit in order to compute and set their geo coordinates.", (unsigned long)[fuelStationsToComputeCoords count]);
    for (FPFuelStation *fuelStation in fuelStationsToComputeCoords) {
      DDLogDebug(@"Proceeding to compute geo coordinates for fuel station: [%@]", fuelStation);
      CLGeocoder *geocoder = [[CLGeocoder alloc] init];
      [geocoder geocodeAddressString:[PEUtils addressStringFromStreet:[fuelStation street]
                                                                 city:[fuelStation city]
                                                                state:[fuelStation state]
                                                                  zip:[fuelStation zip]]
                   completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks && ([placemarks count] > 0)) {
          CLPlacemark *placemark = placemarks[0];
          CLLocation *location = [placemark location];
          CLLocationCoordinate2D coordinate = [location coordinate];
          [fuelStation setLatitude:[PEUtils decimalNumberFromDouble:coordinate.latitude]];
          [fuelStation setLongitude:[PEUtils decimalNumberFromDouble:coordinate.longitude]];
          [_localDao saveFuelStation:fuelStation
                         editActorId:editActorId
                               error:errorBlk];
          DDLogDebug(@"Geo coordinates computed successfully for fuel station: [%@]", fuelStation);
          [PELMNotificationUtils postNotificationWithName:FPFuelStationCoordinateComputeSuccess
                                       entity:fuelStation];
          [_localDao markAsDoneEditingFuelStation:fuelStation
                                      editActorId:editActorId
                                            error:errorBlk];
        } else if (error) {
          DDLogDebug(@"Geo coordinates NOT computed successfully for fuel station: [%@]", fuelStation);
          [PELMNotificationUtils postNotificationWithName:FPFuelStationCoordinateComputeFailed
                                                   entity:fuelStation];
          [_localDao cancelEditOfFuelStation:fuelStation
                                 editActorId:editActorId
                                       error:errorBlk];
        }
      }];
      [NSThread sleepForTimeInterval:1.0]; // throttle myself
    }
  }
}

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk {
  _systemPruneCount++;
  LogSystemPrune(@"About to prune system.", _systemPruneCount);
  [_localDao pruneAllSyncedEntitiesWithError:errorBlk
                            systemPruneCount:_systemPruneCount];
  [PELMNotificationUtils postNotificationWithName:FPSystemPruningComplete];
  LogSystemPrune(@"System pruning complete and notification sent.", _systemPruneCount);
}

#pragma mark - Flush to Remote Master Helpers

+ (void)invokeErrorBlocksForHttpStatusCode:(NSNumber *)httpStatusCode
                                     error:(NSError *)err
                    addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk {
  if (httpStatusCode) {
    if ([[err domain] isEqualToString:FPUserFaultedErrorDomain]) {
      if ([err code] > 0) {
        if (addlRemoteErrorBlk) addlRemoteErrorBlk([err code]);
      } else {
        if (addlTempRemoteErrorBlk) addlTempRemoteErrorBlk();
      }
    } else {
      if (addlTempRemoteErrorBlk) addlTempRemoteErrorBlk();
    }
  } else {
    // if no http status code, then it was a connection failure, and that by nature is temporary
    if (addlTempRemoteErrorBlk) addlTempRemoteErrorBlk();
  }
}

- (void)flushUnsyncedChangesToUser:(FPUser *)user
                       editActorId:(NSNumber *)editActorId
                    addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                             error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedUser) {
    [_localDao markAsInConflictForUser:(FPUser *)unsyncedUser
                           editActorId:editActorId
                                 error:_bgProcessingErrorBlk];
    [_conflictDelegate remoteStoreVersionOfUser:latestResourceModel isNewerThanLocalVersion:(FPUser *)unsyncedUser];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
      ^(PELMMainSupport *unsyncedUser,
        PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
        PELMRemoteMasterAuthReqdBlk authReqdHandler,
        PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
        dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao deleteUser:(FPUser *)unsyncedUser
                    asynchronous:NO
                         timeout:_timeout
                 remoteStoreBusy:remoteStoreBusyHandler
                    authRequired:authReqdHandler
               completionHandler:remoteStoreComplHandler
       queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
      ^(PELMMainSupport *unsyncedUser,
        PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
        PELMRemoteMasterAuthReqdBlk authReqdHandler,
        PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
        dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveExistingUser:(FPUser *)unsyncedUser
                          asynchronous:NO
                               timeout:_timeout
                       remoteStoreBusy:remoteStoreBusyHandler
                          authRequired:authReqdHandler
                     completionHandler:remoteStoreComplHandler
             queueForCompletionHandler:backgroundQueue];
  };
  [PELMUtils flushUnsyncedChangesToEntity:user
                         systemFlushCount:_flushToRemoteMasterCount
                  contextForNotifications:self
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForUser:(FPUser *)user
                                            httpRespCode:@(503)
                                               errorMask:nil
                                                 retryAt:retryAt
                                             editActorId:editActorId
                                                   error:_bgProcessingErrorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                            remoteStoreErrorBlk:^(PELMMainSupport *unsyncedUser, NSError *err, NSNumber *httpStatusCode) {
                                [_localDao cancelSyncForUser:(FPUser *)unsyncedUser
                                                httpRespCode:httpStatusCode
                                                   errorMask:@([err code])
                                                     retryAt:nil
                                                 editActorId:editActorId
                                                       error:_bgProcessingErrorBlk];
                              [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                             error:err
                                                            addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                addlRemoteErrorBlk:addlRemoteErrorBlk];
                            }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:nil // because new users are always created in real-time, in main-thread of application
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedUser){
                                  [_localDao markAsSyncCompleteForUser:(FPUser *)unsyncedUser
                                                           editActorId:editActorId
                                                                 error:_bgProcessingErrorBlk];
                                  if (addlSuccessBlk) {
                                    addlSuccessBlk((FPUser *)unsyncedUser);
                                  }
                            }
             syncCompleteNotificationName:FPUserSynced
               syncFailedNotificationName:FPUserSyncFailed
               entityGoneNotificationName:FPUserDeleted
                physicallyDeleteEntityBlk:^(PELMMainSupport *unsyncedUser){[_localDao cascadeDeleteUser:(FPUser *)unsyncedUser
                                                                                                  error:_bgProcessingErrorBlk];}
                      authRequiredHandler:^(PELMMainSupport *unsyncedUser, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedUser, auth);
                        [_localDao cancelSyncForUser:(FPUser *)unsyncedUser
                                        httpRespCode:@(401)
                                           errorMask:nil
                                             retryAt:nil
                                         editActorId:editActorId
                                               error:_bgProcessingErrorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                backgroundProcessingQueue:_serialQueue
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:nil // because new users are always created in real-time, in main-thread of application
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:_bgProcessingErrorBlk];
}

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                          editActorId:(NSNumber *)editActorId
                       addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedVehicle) {
    [_localDao markAsInConflictForVehicle:(FPVehicle *)unsyncedVehicle
                              editActorId:editActorId
                                    error:_bgProcessingErrorBlk];
    [_conflictDelegate remoteStoreVersionOfVehicle:latestResourceModel isNewerThanLocalVersion:(FPVehicle *)unsyncedVehicle];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao deleteVehicle:(FPVehicle *)unsyncedVehicle
                       asynchronous:NO
                            timeout:_timeout
                    remoteStoreBusy:remoteStoreBusyHandler
                       authRequired:authReqdHandler
                  completionHandler:remoteStoreComplHandler
          queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveExistingVehicle:(FPVehicle *)unsyncedVehicle
                             asynchronous:NO
                                  timeout:_timeout
                          remoteStoreBusy:remoteStoreBusyHandler
                             authRequired:authReqdHandler
                        completionHandler:remoteStoreComplHandler
                queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveNewVehicle:(FPVehicle *)unsyncedVehicle
                             forUser:user
                        asynchronous:NO
                             timeout:_timeout
                     remoteStoreBusy:remoteStoreBusyHandler
                        authRequired:authReqdHandler
                   completionHandler:remoteStoreComplHandler
           queueForCompletionHandler:backgroundQueue];
  };
  [PELMUtils flushUnsyncedChangesToEntity:vehicle
                         systemFlushCount:_flushToRemoteMasterCount
                  contextForNotifications:self
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
      [_localDao cancelSyncForVehicle:vehicle
                         httpRespCode:@(503)
                            errorMask:nil
                              retryAt:retryAt
                          editActorId:editActorId
                                error:_bgProcessingErrorBlk];
      if (addlRemoteStoreBusyBlk) {
        addlRemoteStoreBusyBlk(retryAt);
      }
    }
  remoteStoreErrorBlk:^(PELMMainSupport *unsyncedVehicle, NSError *err, NSNumber *httpStatusCode) {
                              [_localDao cancelSyncForVehicle:(FPVehicle *)unsyncedVehicle
                                                 httpRespCode:httpStatusCode
                                                    errorMask:@([err code])
                                                      retryAt:nil
                                                  editActorId:editActorId
                                                        error:_bgProcessingErrorBlk];
                              [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                             error:err
                                                            addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                addlRemoteErrorBlk:addlRemoteErrorBlk];
                            }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedVehicle) {
                          [_localDao markAsSyncCompleteForNewVehicle:(FPVehicle *)unsyncedVehicle
                                                             forUser:user
                                                         editActorId:editActorId
                                                               error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPVehicle *)unsyncedVehicle);
                          }
        }
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedVehicle) {
                          [_localDao markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)unsyncedVehicle
                                                             editActorId:editActorId
                                                                   error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPVehicle *)unsyncedVehicle);
                          }
                        }
             syncCompleteNotificationName:FPVehicleSynced
               syncFailedNotificationName:FPVehicleSyncFailed
               entityGoneNotificationName:FPVehicleDeleted
                physicallyDeleteEntityBlk:^(PELMMainSupport *unsyncedVehicle){[_localDao cascadeDeleteVehicle:(FPVehicle *)unsyncedVehicle
                                                                                                        error:_bgProcessingErrorBlk];}
                      authRequiredHandler:^(PELMMainSupport *unsyncedVehicle, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedVehicle, auth);
                        [_localDao cancelSyncForVehicle:(FPVehicle *)unsyncedVehicle
                                           httpRespCode:@(401)
                                              errorMask:nil
                                                retryAt:nil
                                            editActorId:editActorId
                                                  error:_bgProcessingErrorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                backgroundProcessingQueue:_serialQueue
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:_bgProcessingErrorBlk];
}

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                              editActorId:(NSNumber *)editActorId
                           addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedFuelStation) {
    [_localDao markAsInConflictForFuelStation:(FPFuelStation *)unsyncedFuelStation
                                  editActorId:editActorId
                                        error:_bgProcessingErrorBlk];
    [_conflictDelegate remoteStoreVersionOfFuelStation:latestResourceModel
                               isNewerThanLocalVersion:(FPFuelStation *)unsyncedFuelStation];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao deleteFuelStation:(FPFuelStation *)unsyncedFuelStation
                           asynchronous:NO
                                timeout:_timeout
                        remoteStoreBusy:remoteStoreBusyHandler
                           authRequired:authReqdHandler
                      completionHandler:remoteStoreComplHandler
              queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveExistingFuelStation:(FPFuelStation *)unsyncedFuelStation
                                 asynchronous:NO
                                      timeout:_timeout
                              remoteStoreBusy:remoteStoreBusyHandler
                                 authRequired:authReqdHandler
                            completionHandler:remoteStoreComplHandler
                    queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveNewFuelStation:(FPFuelStation *)unsyncedFuelStation
                                 forUser:user
                            asynchronous:NO
                                 timeout:_timeout
                         remoteStoreBusy:remoteStoreBusyHandler
                            authRequired:authReqdHandler
                       completionHandler:remoteStoreComplHandler
               queueForCompletionHandler:backgroundQueue];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelStation
                         systemFlushCount:_flushToRemoteMasterCount
                  contextForNotifications:self
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
      [_localDao cancelSyncForFuelStation:fuelStation
                             httpRespCode:@(503)
                                errorMask:nil
                                  retryAt:retryAt
                              editActorId:editActorId
                                    error:_bgProcessingErrorBlk];
      if (addlRemoteStoreBusyBlk) {
        addlRemoteStoreBusyBlk(retryAt);
      }
    }
  remoteStoreErrorBlk:^(PELMMainSupport *unsyncedFuelStation, NSError *err, NSNumber *httpStatusCode) {
      [_localDao cancelSyncForFuelStation:(FPFuelStation *)unsyncedFuelStation
                             httpRespCode:httpStatusCode
                                errorMask:@([err code])
                                  retryAt:nil
                              editActorId:editActorId
                                    error:_bgProcessingErrorBlk];
      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                     error:err
                                    addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                        addlRemoteErrorBlk:addlRemoteErrorBlk];
    }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedFuelStation) {
                          [_localDao markAsSyncCompleteForNewFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                                 forUser:user
                                                             editActorId:editActorId
                                                                   error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPFuelStation *)unsyncedFuelStation);
                          }
                        }
  markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedFuelStation) {
                          [_localDao markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                                 editActorId:editActorId
                                                                       error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPFuelStation *)unsyncedFuelStation);
                          }
                        }
             syncCompleteNotificationName:FPFuelStationSynced
               syncFailedNotificationName:FPFuelStationSyncFailed
               entityGoneNotificationName:FPFuelStationDeleted
                physicallyDeleteEntityBlk:^(PELMMainSupport *unsyncedFuelStation){[_localDao cascadeDeleteFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                                                                                error:_bgProcessingErrorBlk];}
  authRequiredHandler:^(PELMMainSupport *unsyncedFuelStation, HCAuthentication *auth) {
               [self authReqdBlk](unsyncedFuelStation, auth);
               [_localDao cancelSyncForFuelStation:(FPFuelStation *)unsyncedFuelStation
                                      httpRespCode:@(401)
                                         errorMask:nil
                                           retryAt:nil
                                       editActorId:editActorId
                                             error:_bgProcessingErrorBlk];
               if (addlAuthRequiredBlk) {
                 addlAuthRequiredBlk();
               }
             }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                backgroundProcessingQueue:_serialQueue
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:_bgProcessingErrorBlk];
}

- (void)flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      forUser:(FPUser *)user
                                  editActorId:(NSNumber *)editActorId
                               addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  NSAssert([fuelPurchaseLog vehicleGlobalIdentifier], @"Fuel purchase log's vehicle global ID is nil");
  NSAssert([fuelPurchaseLog fuelStationGlobalIdentifier], @"Fuel purchase log's fuel station global ID is nil");
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedFuelPurchaseLog) {
    [_localDao markAsInConflictForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                      editActorId:editActorId
                                            error:_bgProcessingErrorBlk];
    [_conflictDelegate remoteStoreVersionOfFuelPurchaseLog:latestResourceModel
                                   isNewerThanLocalVersion:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao deleteFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                               asynchronous:NO
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler
                  queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                     asynchronous:NO
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyHandler
                                     authRequired:authReqdHandler
                                completionHandler:remoteStoreComplHandler
                        queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                     forUser:user
                                asynchronous:NO
                                     timeout:_timeout
                             remoteStoreBusy:remoteStoreBusyHandler
                                authRequired:authReqdHandler
                           completionHandler:remoteStoreComplHandler
                   queueForCompletionHandler:backgroundQueue];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelPurchaseLog
                         systemFlushCount:_flushToRemoteMasterCount
                  contextForNotifications:self
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
      [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog
                                 httpRespCode:@(503)
                                    errorMask:nil
                                      retryAt:retryAt
                                  editActorId:editActorId
                                        error:_bgProcessingErrorBlk];
      if (addlRemoteStoreBusyBlk) {
        addlRemoteStoreBusyBlk(retryAt);
      }
    }
  remoteStoreErrorBlk:^(PELMMainSupport *unsyncedFplog, NSError *err, NSNumber *httpStatusCode) {
      [_localDao cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFplog
                                 httpRespCode:httpStatusCode
                                    errorMask:@([err code])
                                      retryAt:nil
                                  editActorId:editActorId
                                        error:_bgProcessingErrorBlk];
      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                     error:err
                                    addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                        addlRemoteErrorBlk:addlRemoteErrorBlk];
    }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog) {
                          [_localDao markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                                     forUser:user
                                                                 editActorId:editActorId
                                                                       error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPFuelPurchaseLog *)unsyncedFuelPurchaseLog);
                          }
                        }
  markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog) {
                          [_localDao markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                                     editActorId:editActorId
                                                                           error:_bgProcessingErrorBlk];
                          if (addlSuccessBlk) {
                            addlSuccessBlk((FPFuelPurchaseLog *)unsyncedFuelPurchaseLog);
                          }
                        }
             syncCompleteNotificationName:FPFuelPurchaseLogSynced
               syncFailedNotificationName:FPFuelPurchaseLogSyncFailed
               entityGoneNotificationName:FPFuelPurchaseLogDeleted
                physicallyDeleteEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog){[_localDao cascadeDeleteFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                                                                                        error:_bgProcessingErrorBlk];}
  authRequiredHandler:^(PELMMainSupport *unsyncedFpLog, HCAuthentication *auth) {
               [self authReqdBlk](unsyncedFpLog, auth);
               [_localDao cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFpLog
                                          httpRespCode:@(401)
                                             errorMask:nil
                                               retryAt:nil
                                           editActorId:editActorId
                                                 error:_bgProcessingErrorBlk];
               if (addlAuthRequiredBlk) {
                 addlAuthRequiredBlk();
               }
             }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                backgroundProcessingQueue:_serialQueue
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:_bgProcessingErrorBlk];
}

- (void)flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     forUser:(FPUser *)user
                                 editActorId:(NSNumber *)editActorId
                              addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                       error:(PELMDaoErrorBlk)errorBlk {
  NSAssert([environmentLog vehicleGlobalIdentifier], @"Fuel purchase log's vehicle global ID is nil");
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedEnvironmentLog) {
    [_localDao markAsInConflictForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                     editActorId:editActorId
                                           error:_bgProcessingErrorBlk];
    [_conflictDelegate remoteStoreVersionOfEnvironmentLog:latestResourceModel
                                  isNewerThanLocalVersion:(FPEnvironmentLog *)unsyncedEnvironmentLog];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao deleteEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                              asynchronous:NO
                                   timeout:_timeout
                           remoteStoreBusy:remoteStoreBusyHandler
                              authRequired:authReqdHandler
                         completionHandler:remoteStoreComplHandler
                 queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    [_remoteMasterDao saveExistingEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                    asynchronous:NO
                                         timeout:_timeout
                                 remoteStoreBusy:remoteStoreBusyHandler
                                    authRequired:authReqdHandler
                               completionHandler:remoteStoreComplHandler
                       queueForCompletionHandler:backgroundQueue];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler,
    dispatch_queue_t backgroundQueue) {
    DDLogDebug(@"{%lu} - About to call remoteMasterDao / saveNewEnvironmentLog on thread: [%@]", (unsigned long)_flushToRemoteMasterCount, [NSThread currentThread]);
    [_remoteMasterDao saveNewEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                    forUser:user
                               asynchronous:NO
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler
                  queueForCompletionHandler:backgroundQueue];
  };
  [PELMUtils flushUnsyncedChangesToEntity:environmentLog
                         systemFlushCount:_flushToRemoteMasterCount
                  contextForNotifications:self
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
      [_localDao cancelSyncForEnvironmentLog:environmentLog
                                httpRespCode:@(503)
                                   errorMask:nil
                                     retryAt:retryAt
                                 editActorId:editActorId
                                       error:_bgProcessingErrorBlk];
      if (addlRemoteStoreBusyBlk) {
        addlRemoteStoreBusyBlk(retryAt);
      }
    }
  remoteStoreErrorBlk:^(PELMMainSupport *unsyncedEnvLog, NSError *err, NSNumber *httpStatusCode) {
      [_localDao cancelSyncForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvLog
                                httpRespCode:httpStatusCode
                                   errorMask:@([err code])
                                     retryAt:nil
                                 editActorId:editActorId
                                       error:_bgProcessingErrorBlk];
      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                     error:err
                                    addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                        addlRemoteErrorBlk:addlRemoteErrorBlk];
    }
  markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
    [_localDao markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                              forUser:user
                                          editActorId:editActorId
                                                error:_bgProcessingErrorBlk];
    if (addlSuccessBlk) {
      addlSuccessBlk((FPEnvironmentLog *)unsyncedEnvironmentLog);
    }
  }
  markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
    [_localDao markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                              editActorId:editActorId
                                                    error:_bgProcessingErrorBlk];
    if (addlSuccessBlk) {
      addlSuccessBlk((FPEnvironmentLog *)unsyncedEnvironmentLog);
    }
  }
  syncCompleteNotificationName:FPEnvironmentLogSynced
               syncFailedNotificationName:FPEnvironmentLogSyncFailed
               entityGoneNotificationName:FPEnvironmentLogDeleted
                physicallyDeleteEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
    [_localDao cascadeDeleteEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                     error:_bgProcessingErrorBlk];
  }
  authRequiredHandler:^(PELMMainSupport *unsyncedEnvLog, HCAuthentication *auth) {
    [self authReqdBlk](unsyncedEnvLog, auth);
    [_localDao cancelSyncForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvLog
                              httpRespCode:@(401)
                                 errorMask:nil
                                   retryAt:nil
                               editActorId:editActorId
                                     error:_bgProcessingErrorBlk];
    if (addlAuthRequiredBlk) {
      addlAuthRequiredBlk();
    }
  }
  newAuthTokenBlk:^(NSString *newAuthTkn){ [self processNewAuthToken:newAuthTkn forUser:user]; }
  backgroundProcessingQueue:_serialQueue
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:_bgProcessingErrorBlk];
}

- (void)flushUnsyncedChangesUsingFetcher:(NSArray *(^)(void))entityFetcherBlk
                                  syncer:(void(^)(PELMMainSupport *))syncerBlk
                       entityLabelForLog:(NSString *)entityLabelForLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  NSArray *entitiesToSync = entityFetcherBlk();
  LogSyncRemoteMaster([NSString stringWithFormat:@"coordDao/flushUnsynced, Found [%lu] %@s in main table.", (unsigned long)[entitiesToSync count], entityLabelForLog], _flushToRemoteMasterCount);
  int count = 0;
  for (PELMMainSupport *entity in entitiesToSync) {
    if ([entity syncInProgress]) {
      LogSyncRemoteMaster([NSString stringWithFormat:@"coordDao/flushUnsynced, %@ [%d] is in need of syncing.  Proceeding to sync it.", entityLabelForLog, count], _flushToRemoteMasterCount);
      syncerBlk(entity);
    } else {
      LogSyncRemoteMaster([NSString stringWithFormat:@"coordDao/flushUnsynced, %@ [%d] is NOT currently in need of syncing; skipping", entityLabelForLog, count], _flushToRemoteMasterCount);
    }
    count++;
  }
}

- (void)flushUnsyncedChangesToAllEntityTypes:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                 editActorId:(NSNumber *)editActorId
                                       error:(PELMDaoErrorBlk)errorBlk {
  FPUser *user;
  if (_includeUserInBackgroundFlush) {
    user = [_localDao markUserAsSyncInProgressWithEditActorId:editActorId
                                                        error:errorBlk];
  } else {
    user = [_localDao userWithError:errorBlk];
  }
  if (user) {
    if (_includeUserInBackgroundFlush) {
      LogSyncRemoteMaster(@"coordDao/flushUnsynced: 'user' instance found in main table.", _flushToRemoteMasterCount);
      if ([user syncInProgress]) {
        LogSyncRemoteMaster(@"coordDao/flushUnsynced: 'user' instance is in need of syncing", _flushToRemoteMasterCount);
        [self flushUnsyncedChangesToUser:user
                             editActorId:editActorId
                          addlSuccessBlk:nil
                  addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                  addlTempRemoteErrorBlk:nil
                      addlRemoteErrorBlk:nil
                     addlAuthRequiredBlk:nil
                                   error:errorBlk];
      } else {
        LogSyncRemoteMaster(@"coordDao/flushUnsynced: 'user' instance is NOT in need of syncing", _flushToRemoteMasterCount);
      }
    } else {
      DDLogInfo(@"coordDao configured to not include 'user' instance in background syncing process");
    }
    [self flushUnsyncedChangesUsingFetcher:^NSArray *(void){return [_localDao markVehiclesAsSyncInProgressForUser:user
                                                                                                      editActorId:editActorId
                                                                                                            error:errorBlk];}
                                    syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToVehicle:(FPVehicle *)entity
                                                                                                  forUser:user
                                                                                              editActorId:editActorId
                                                                                           addlSuccessBlk:nil
                                                                                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                                                                                   addlTempRemoteErrorBlk:nil
                                                                                       addlRemoteErrorBlk:nil
                                                                                      addlAuthRequiredBlk:nil
                                                                                                    error:errorBlk];}
                         entityLabelForLog:@"vehicle"
                                     error:errorBlk];
    [self flushUnsyncedChangesUsingFetcher:^NSArray *(void){return [_localDao markFuelStationsAsSyncInProgressForUser:user
                                                                                                          editActorId:editActorId
                                                                                                                error:errorBlk];}
                                    syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelStation:(FPFuelStation *)entity
                                                                                                      forUser:user
                                                                                                  editActorId:editActorId
                                                                                               addlSuccessBlk:nil
                                                                                       addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                                                                                       addlTempRemoteErrorBlk:nil
                                                                                           addlRemoteErrorBlk:nil
                                                                                          addlAuthRequiredBlk:nil
                                                                                                        error:errorBlk];}
                         entityLabelForLog:@"fuel station"
                                     error:errorBlk];
    [self flushUnsyncedChangesUsingFetcher:^NSArray *(void){return [_localDao markFuelPurchaseLogsAsSyncInProgressForUser:user
                                                                                                              editActorId:editActorId
                                                                                                                    error:errorBlk];}
                                    syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                          forUser:user
                                                                                                      editActorId:editActorId
                                                                                                   addlSuccessBlk:nil
                                                                                           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                                                                                           addlTempRemoteErrorBlk:nil
                                                                                               addlRemoteErrorBlk:nil
                                                                                              addlAuthRequiredBlk:nil
                                                                                                            error:errorBlk];}
                         entityLabelForLog:@"fuel purchase log"
                                     error:errorBlk];
    [self flushUnsyncedChangesUsingFetcher:^NSArray *(void){return [_localDao markEnvironmentLogsAsSyncInProgressForUser:user
                                                                                                             editActorId:editActorId
                                                                                                                   error:errorBlk];}
                                    syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                         forUser:user
                                                                                                     editActorId:editActorId
                                                                                                  addlSuccessBlk:nil
                                                                                          addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                                                                                          addlTempRemoteErrorBlk:nil
                                                                                              addlRemoteErrorBlk:nil
                                                                                             addlAuthRequiredBlk:nil
                                                                                                           error:errorBlk];}
                         entityLabelForLog:@"environment log"
                                     error:errorBlk];
    LogSyncRemoteMaster(@"coordDao/flushUnsynced: Done syncing all entity types.", _flushToRemoteMasterCount);
  } else {
    LogSyncRemoteMaster(@"coordDao/flushUnsynced: 'user' instance NOT found in main table (therefore, there are NO entities requiring flushing).", _flushToRemoteMasterCount);
  }
}

#pragma mark - System

- (void)logoutUser:(FPUser *)user error:(PELMDaoErrorBlk)error {
  // TODO -- issue DELETE to server to delete _authToken
  _authToken = nil;
}

- (void)cascadeDeleteLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)error {
  //[_localDao cascadeDeleteUser:user error:error];
  [_localDao deleteAllUsers:error];
}

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error {
  dispatch_async(_serialQueue, ^{
    [_localDao globalCancelSyncInProgressWithError:error];
  });
}

#pragma mark - User

- (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                username:(NSString *)username
                password:(NSString *)password {
  return [FPUser userWithName:name
                        email:email
                     username:username
                     password:password
                    mediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]];
}

- (void)immediateRemoteSyncSaveNewUser:(FPUser *)user
                       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                     completionHandler:(FPSavedNewEntityCompletionHandler)complHandler
                 localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler remoteMasterComplHandler =
    ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
      NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
      BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    FPUser *respUser = nil;
    if (globalId) { // success!
      respUser = (FPUser *)resourceModel;
      [_localDao saveNewUser:respUser error:localSaveErrorHandler];
      [self processNewAuthToken:newAuthTkn forUser:respUser];
    };
    complHandler(respUser, err);
  };
  [_remoteMasterDao saveNewUser:user
                   asynchronous:YES
                        timeout:_timeout
                remoteStoreBusy:busyHandler
                   authRequired:[self authReqdBlk]
              completionHandler:remoteMasterComplHandler
      queueForCompletionHandler:dispatch_get_main_queue()];
}

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               completionHandler:(FPFetchedEntityCompletionHandler)complHandler
           localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    FPUser *user = (FPUser *)resourceModel;
    if (user) {
      [_localDao persistDeepUserFromRemoteMaster:user error:localSaveErrorHandler];
      [self processNewAuthToken:newAuthTkn forUser:user];
    }
    complHandler(user, err);
  };
  PELMRemoteMasterAuthReqdBlk authReqdBlk = ^(PELMMainSupport *entity, HCAuthentication *authReqd) {
    NSError *error = [NSError errorWithDomain:FPUserFaultedErrorDomain
                                         code:(FPSignInAnyIssues | FPSignInInvalidCredentials)
                                     userInfo:nil];
    complHandler(nil, error);
  };
  [_remoteMasterDao loginWithUsernameOrEmail:usernameOrEmail
                                    password:password
                                asynchronous:YES
                                     timeout:_timeout
                             remoteStoreBusy:busyHandler
                                authRequired:authReqdBlk
                           completionHandler:masterStoreComplHandler
                   queueForCompletionHandler:dispatch_get_main_queue()];
}

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk {
  return [_localDao userWithError:errorBlk];
}

- (BOOL)prepareUserForEdit:(FPUser *)user
               editActorId:(NSNumber *)editActorId
         entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
             entityDeleted:(void(^)(void))entityDeletedBlk
          entityInConflict:(void(^)(void))entityInConflictBlk
entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareUserForEdit:user
                           editActorId:editActorId
                     entityBeingSynced:entityBeingSyncedBlk
                         entityDeleted:entityDeletedBlk
                      entityInConflict:entityInConflictBlk
         entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                                 error:errorBlk];
}

- (void)saveUser:(FPUser *)user
     editActorId:(NSNumber *)editActorId
           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveUser:user
          editActorId:editActorId
                error:errorBlk];
}

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                                  editActorId:(NSNumber *)editActorId
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncUser:user
                                    editActorId:editActorId
                                          error:errorBlk];
  [self flushUnsyncedChangesToUser:user
                       editActorId:editActorId
                    addlSuccessBlk:^(PELMMainSupport *user) {successBlk();}
            addlRemoteStoreBusyBlk:remoteStoreBusyBlk
            addlTempRemoteErrorBlk:tempRemoteErrorBlk
                addlRemoteErrorBlk:remoteErrorBlk
               addlAuthRequiredBlk:authRequiredBlk
                             error:errorBlk];
}

- (void)markAsDoneEditingUser:(FPUser *)user
                  editActorId:(NSNumber *)editActorId
                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingUser:user
                       editActorId:editActorId
                             error:errorBlk];
}

- (void)reloadUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadUser:user error:errorBlk];
}

- (void)cancelEditOfUser:(FPUser *)user
             editActorId:(NSNumber *)editActorId
                   error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfUser:user
                  editActorId:editActorId
                        error:errorBlk];
}

- (void)markAsDeletedUser:(FPUser *)user
              editActorId:(NSNumber *)editActorId
                    error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedUser:user
                   editActorId:editActorId
                         error:errorBlk];
}

#pragma mark - Vehicle

- (NSInteger)numVehiclesForUser:(FPUser *)user
                          error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numVehiclesForUser:user error:errorBlk];
}

- (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity {
  return [FPVehicle vehicleWithName:name
                      defaultOctane:defaultOctane
                       fuelCapacity:fuelCapacity
                          mediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:_vehicleResMtVersion]];
}

- (NSArray *)vehiclesForUser:(FPUser *)user
                       error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao vehiclesForUser:user
                              error:errorBlk];
}

- (FPUser *)userForVehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao userForVehicle:vehicle error:errorBlk];
}

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
                 error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewVehicle:vehicle forUser:user error:errorBlk];
}

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                            successBlk:(void(^)(void))successBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                        remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                       authRequiredBlk:(void(^)(void))authRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewAndSyncImmediateVehicle:vehicle forUser:user error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                          editActorId:nil
                       addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                  editActorId:(NSNumber *)editActorId
            entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                entityDeleted:(void(^)(void))entityDeletedBlk
             entityInConflict:(void(^)(void))entityInConflictBlk
entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                        error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareVehicleForEdit:vehicle
                                  forUser:user
                              editActorId:editActorId
                        entityBeingSynced:entityBeingSyncedBlk
                            entityDeleted:entityDeletedBlk
                         entityInConflict:entityInConflictBlk
            entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                                    error:errorBlk];
}

- (void)saveVehicle:(FPVehicle *)vehicle
        editActorId:(NSNumber *)editActorId
              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveVehicle:vehicle
             editActorId:editActorId
                   error:errorBlk];
}

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                     editActorId:(NSNumber *)editActorId
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingVehicle:vehicle
                          editActorId:editActorId
                                error:errorBlk];
}

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                                     editActorId:(NSNumber *)editActorId
                                      successBlk:(void(^)(void))successBlk
                              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                 authRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncVehicle:vehicle
                                       editActorId:editActorId
                                             error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                          editActorId:editActorId
                       addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (void)reloadVehicle:(FPVehicle *)vehicle
                error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadVehicle:vehicle error:errorBlk];
}

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle
                editActorId:(NSNumber *)editActorId
                      error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfVehicle:vehicle
                     editActorId:editActorId
                           error:errorBlk];
}

- (void)markAsDeletedVehicle:(FPVehicle *)vehicle
                 editActorId:(NSNumber *)editActorId
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedVehicle:vehicle
                      editActorId:editActorId
                            error:errorBlk];
}

#pragma mark - Fuel Station

- (NSInteger)numFuelStationsForUser:(FPUser *)user
                              error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelStationsForUser:user error:errorBlk];
}

- (FPFuelStation *)fuelStationWithName:(NSString *)name
                                street:(NSString *)street
                                  city:(NSString *)city
                                 state:(NSString *)state
                                   zip:(NSString *)zip
                              latitude:(NSDecimalNumber *)latitude
                             longitude:(NSDecimalNumber *)longitude {
  return [FPFuelStation fuelStationWithName:name
                                     street:street
                                       city:city
                                      state:state
                                        zip:zip
                                   latitude:latitude
                                  longitude:longitude
                                  mediaType:[FPKnownMediaTypes fuelStationMediaTypeWithVersion:_fuelStationResMtVersion]];
}

- (NSArray *)fuelStationsForUser:(FPUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao fuelStationsForUser:user
                                  error:errorBlk];
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao userForFuelStation:fuelStation error:errorBlk];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewFuelStation:fuelStation forUser:user error:errorBlk];
}

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                                successBlk:(void(^)(void))successBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                           authRequiredBlk:(void(^)(void))authRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewAndSyncImmediateFuelStation:fuelStation forUser:user error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                              editActorId:nil
                           addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                   addlTempRemoteErrorBlk:tempRemoteErrorBlk
                       addlRemoteErrorBlk:remoteErrorBlk
                      addlAuthRequiredBlk:authRequiredBlk
                                    error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                      editActorId:(NSNumber *)editActorId
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                    entityDeleted:(void(^)(void))entityDeletedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
    entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                            error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelStationForEdit:fuelStation
                                      forUser:user
                                  editActorId:editActorId
                            entityBeingSynced:entityBeingSyncedBlk
                                entityDeleted:entityDeletedBlk
                             entityInConflict:entityInConflictBlk
                entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                                        error:errorBlk];
}

- (void)saveFuelStation:(FPFuelStation *)fuelStation
            editActorId:(NSNumber *)editActorId
                  error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveFuelStation:fuelStation
                 editActorId:editActorId
                       error:errorBlk];
}

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                         editActorId:(NSNumber *)editActorId
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingFuelStation:fuelStation
                              editActorId:editActorId
                                    error:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                         editActorId:(NSNumber *)editActorId
                                          successBlk:(void(^)(void))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                      remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     authRequiredBlk:(void(^)(void))authRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncFuelStation:fuelStation
                                           editActorId:editActorId
                                                 error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                              editActorId:editActorId
                           addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                   addlTempRemoteErrorBlk:tempRemoteErrorBlk
                       addlRemoteErrorBlk:remoteErrorBlk
                      addlAuthRequiredBlk:authRequiredBlk
                                    error:errorBlk];
}

- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadFuelStation:fuelStation error:errorBlk];
}

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                    editActorId:(NSNumber *)editActorId
                          error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfFuelStation:fuelStation
                         editActorId:editActorId
                               error:errorBlk];
}

- (void)markAsDeletedFuelStation:(FPFuelStation *)fuelStation
                     editActorId:(NSNumber *)editActorId
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedFuelStation:fuelStation
                          editActorId:editActorId
                                error:errorBlk];
}

#pragma mark - Fuel Purchase Log

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForUser:user error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForUser:user
                                     newerThan:newerThan
                                         error:errorBlk];
}

- (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate {
  return [FPFuelPurchaseLog fuelPurchaseLogWithNumGallons:numGallons
                                                   octane:octane
                                              gallonPrice:gallonPrice
                                               gotCarWash:gotCarWash
                                 carWashPerGallonDiscount:carWashPerGallonDiscount
                                                  purchasedAt:logDate
                                                mediaType:[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:_fuelPurchaseLogResMtVersion]];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:pageSize
                      beforeDateLogged:nil
                                 error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao fuelPurchaseLogsForUser:user
                                   pageSize:pageSize
                           beforeDateLogged:beforeDateLogged
                                      error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForVehicle:vehicle error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForVehicle:vehicle
                                        newerThan:newerThan
                                            error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForVehicle:vehicle
                                 pageSize:pageSize
                         beforeDateLogged:nil
                                    error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                               pageSize:(NSInteger)pageSize
                       beforeDateLogged:(NSDate *)beforeDateLogged
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao fuelPurchaseLogsForVehicle:vehicle
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                         error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForFuelStation:fuelStation error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                     newerThan:(NSDate *)newerThan
                                         error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numFuelPurchaseLogsForFuelStation:fuelStation
                                            newerThan:newerThan
                                                error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                     pageSize:pageSize
                             beforeDateLogged:nil
                                        error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                   pageSize:(NSInteger)pageSize
                           beforeDateLogged:(NSDate *)beforeDateLogged
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao fuelPurchaseLogsForFuelStation:fuelStation
                                          pageSize:pageSize
                                  beforeDateLogged:beforeDateLogged
                                             error:errorBlk];
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao vehicleForFuelPurchaseLog:fpLog error:errorBlk];
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao fuelStationForFuelPurchaseLog:fpLog error:errorBlk];
}

- (FPVehicle *)defaultVehicleForNewFuelPurchaseLogForUser:(FPUser *)user
                                                    error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao defaultVehicleForNewFuelPurchaseLogForUser:user error:errorBlk];
}

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao defaultFuelStationForNewFuelPurchaseLogForUser:user
                                                   currentLocation:currentLocation
                                                             error:errorBlk];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                   fuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewFuelPurchaseLog:fuelPurchaseLog
                            forUser:user
                            vehicle:vehicle
                        fuelStation:fuelStation
                              error:errorBlk];
}

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:(FPVehicle *)vehicle
                                   fuelStation:(FPFuelStation *)fuelStation
                                    successBlk:(void(^)(void))successBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                               authRequiredBlk:(void(^)(void))authRequiredBlk
                                         error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier] && [fuelStation globalIdentifier]) {
    [_localDao saveNewAndSyncImmediateFuelPurchaseLog:fuelPurchaseLog
                                              forUser:user
                                              vehicle:vehicle
                                          fuelStation:fuelStation
                                                error:errorBlk];
    [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                        forUser:user
                                    editActorId:nil
                                 addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                         addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                         addlTempRemoteErrorBlk:tempRemoteErrorBlk
                             addlRemoteErrorBlk:remoteErrorBlk
                            addlAuthRequiredBlk:authRequiredBlk
                                          error:errorBlk];
  } else {
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                           error:errorBlk];
  }
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                          editActorId:(NSNumber *)editActorId
                    entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                        entityDeleted:(void(^)(void))entityDeletedBlk
                     entityInConflict:(void(^)(void))entityInConflictBlk
        entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                          forUser:user
                                      editActorId:editActorId
                                entityBeingSynced:entityBeingSyncedBlk
                                    entityDeleted:entityDeletedBlk
                                 entityInConflict:entityInConflictBlk
                    entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                                            error:errorBlk];
}

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                editActorId:(NSNumber *)editActorId
                      error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                     editActorId:editActorId
                           error:errorBlk];
}

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                             editActorId:(NSNumber *)editActorId
                                   error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog
                                  editActorId:editActorId
                                        error:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                 forUser:(FPUser *)user
                                             editActorId:(NSNumber *)editActorId
                                              successBlk:(void(^)(void))successBlk
                                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                          remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                         authRequiredBlk:(void(^)(void))authRequiredBlk
                                                   error:(PELMDaoErrorBlk)errorBlk {
  if ([fuelPurchaseLog vehicleGlobalIdentifier] && [fuelPurchaseLog fuelStationGlobalIdentifier]) {
    [_localDao markAsDoneEditingImmediateSyncFuelPurchaseLog:fuelPurchaseLog editActorId:editActorId error:errorBlk];
    [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                        forUser:user
                                    editActorId:editActorId
                                 addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                         addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                         addlTempRemoteErrorBlk:tempRemoteErrorBlk
                             addlRemoteErrorBlk:remoteErrorBlk
                            addlAuthRequiredBlk:authRequiredBlk
                                          error:errorBlk];
  } else {
    [self markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog editActorId:editActorId error:errorBlk];
  }
}

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
}

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfFuelPurchaseLog:fuelPurchaseLog
                             editActorId:editActorId
                                   error:errorBlk];
}

- (void)markAsDeletedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                         editActorId:(NSNumber *)editActorId
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedFuelPurchaseLog:fuelPurchaseLog
                              editActorId:editActorId
                                    error:errorBlk];
}

#pragma mark - Environment Log

- (FPEnvironmentLog *)environmentLogWithOdometer:(NSDecimalNumber *)odometer
                                  reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                                  reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                             reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                         logDate:(NSDate *)logDate
                                     reportedDte:(NSNumber *)reportedDte {
  return [FPEnvironmentLog envLogWithOdometer:odometer
                               reportedAvgMpg:reportedAvgMpg
                               reportedAvgMph:reportedAvgMph
                          reportedOutsideTemp:reportedOutsideTemp
                                      logDate:logDate
                                  reportedDte:reportedDte
                                    mediaType:[FPKnownMediaTypes environmentLogMediaTypeWithVersion:_environmentLogResMtVersion]];
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numEnvironmentLogsForUser:user error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numEnvironmentLogsForUser:user
                                    newerThan:newerThan
                                        error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                              error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForUser:user
                             pageSize:pageSize
                     beforeDateLogged:nil
                                error:errorBlk];
}

- (NSArray *)environmentLogsForUser:(FPUser *)user
                           pageSize:(NSInteger)pageSize
                   beforeDateLogged:(NSDate *)beforeDateLogged
                              error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao environmentLogsForUser:user
                                  pageSize:pageSize
                          beforeDateLogged:beforeDateLogged
                                     error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numEnvironmentLogsForVehicle:vehicle error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                newerThan:(NSDate *)newerThan
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao numEnvironmentLogsForVehicle:vehicle
                                       newerThan:newerThan
                                           error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self environmentLogsForVehicle:vehicle
                                pageSize:pageSize
                        beforeDateLogged:nil
                                   error:errorBlk];
}

- (NSArray *)environmentLogsForVehicle:(FPVehicle *)vehicle
                              pageSize:(NSInteger)pageSize
                      beforeDateLogged:(NSDate *)beforeDateLogged
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao environmentLogsForVehicle:vehicle
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                        error:errorBlk];
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)fpLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao vehicleForEnvironmentLog:fpLog error:errorBlk];
}

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao defaultVehicleForNewEnvironmentLogForUser:user error:errorBlk];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:(FPVehicle *)vehicle
                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewEnvironmentLog:environmentLog
                           forUser:user
                           vehicle:vehicle
                             error:errorBlk];
}

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)envLog
                                      forUser:(FPUser *)user
                                      vehicle:(FPVehicle *)vehicle
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier]) {
    [_localDao saveNewAndSyncImmediateEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                                   editActorId:nil
                                addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                        addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                        addlTempRemoteErrorBlk:tempRemoteErrorBlk
                            addlRemoteErrorBlk:remoteErrorBlk
                           addlAuthRequiredBlk:authRequiredBlk
                                         error:errorBlk];
  } else {
    [self saveNewEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
  }
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                         editActorId:(NSNumber *)editActorId
                   entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                       entityDeleted:(void(^)(void))entityDeletedBlk
                    entityInConflict:(void(^)(void))entityInConflictBlk
       entityBeingEditedByOtherActor:(void(^)(NSNumber *))entityBeingEditedByOtherActorBlk
                               error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareEnvironmentLogForEdit:environmentLog
                                         forUser:user
                                     editActorId:editActorId
                               entityBeingSynced:entityBeingSyncedBlk
                                   entityDeleted:entityDeletedBlk
                                entityInConflict:entityInConflictBlk
                   entityBeingEditedByOtherActor:entityBeingEditedByOtherActorBlk
                                           error:errorBlk];
}

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
               editActorId:(NSNumber *)editActorId
                     error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                    editActorId:editActorId
                          error:errorBlk];
}

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                            editActorId:(NSNumber *)editActorId
                                  error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingEnvironmentLog:environmentLog
                                 editActorId:editActorId
                                       error:errorBlk];
}

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
                                                forUser:(FPUser *)user
                                            editActorId:(NSNumber *)editActorId
                                             successBlk:(void(^)(void))successBlk
                                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                         remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                        authRequiredBlk:(void(^)(void))authRequiredBlk
                                                  error:(PELMDaoErrorBlk)errorBlk {
  if ([envLog vehicleGlobalIdentifier]) {
    [_localDao markAsDoneEditingImmediateSyncEnvironmentLog:envLog editActorId:editActorId error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                                   editActorId:editActorId
                                addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                        addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                        addlTempRemoteErrorBlk:tempRemoteErrorBlk
                            addlRemoteErrorBlk:remoteErrorBlk
                           addlAuthRequiredBlk:authRequiredBlk
                                         error:errorBlk];
  } else {
    [self markAsDoneEditingEnvironmentLog:envLog editActorId:editActorId error:errorBlk];
  }
}

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadEnvironmentLog:environmentLog error:errorBlk];
}

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       editActorId:(NSNumber *)editActorId
                             error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfEnvironmentLog:environmentLog
                            editActorId:editActorId
                                  error:errorBlk];
}

- (void)markAsDeletedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                        editActorId:(NSNumber *)editActorId
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedEnvironmentLog:environmentLog
                             editActorId:editActorId
                                   error:errorBlk];
}

#pragma mark - Flush to Remote Master helpers (private)

- (PELMRemoteMasterAuthReqdBlk) authReqdBlk {
  return ^(PELMMainSupport *entity, HCAuthentication *auth) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_authTokenDelegate authRequired:auth];
    });
  };
}

#pragma mark - Other helpers (private)

- (void)processNewAuthToken:(NSString *)newAuthToken forUser:(FPUser *)user {
  if (newAuthToken) {
    [self setAuthToken:newAuthToken];
    dispatch_async(dispatch_get_main_queue(), ^{
      [_authTokenDelegate didReceiveNewAuthToken:newAuthToken
                         forUserGlobalIdentifier:[user globalIdentifier]];
    });
  }
}

@end
