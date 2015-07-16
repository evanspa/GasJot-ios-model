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
        allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super init];
  if (self) {
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

#pragma mark - Pruning

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk {
  [_localDao pruneAllSyncedEntitiesWithError:errorBlk];
}

#pragma mark - System

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error {
  [_localDao globalCancelSyncInProgressWithError:error];
}

#pragma mark - Flushing to Remote Master

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
                    addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                             error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedUser) {
    [_localDao markAsInConflictForUser:(FPUser *)unsyncedUser
                                 error:errorBlk];
    [_conflictDelegate remoteStoreVersionOfUser:latestResourceModel isNewerThanLocalVersion:(FPUser *)unsyncedUser];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedUser,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteUser:(FPUser *)unsyncedUser
                         timeout:_timeout
                 remoteStoreBusy:remoteStoreBusyHandler
                    authRequired:authReqdHandler
               completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedUser,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingUser:(FPUser *)unsyncedUser
                               timeout:_timeout
                       remoteStoreBusy:remoteStoreBusyHandler
                          authRequired:authReqdHandler
                     completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:user
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForUser:(FPUser *)user
                                         httpRespCode:@(503)
                                            errorMask:nil
                                              retryAt:retryAt
                                                error:errorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                      remoteStoreErrorBlk:^(PELMMainSupport *unsyncedUser, NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForUser:(FPUser *)unsyncedUser
                                        httpRespCode:httpStatusCode
                                           errorMask:@([err code])
                                             retryAt:nil
                                               error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:nil // because new users are always immediately synced upon creation
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedUser){
     [_localDao markAsSyncCompleteForUser:(FPUser *)unsyncedUser
                                    error:errorBlk];
     if (addlSuccessBlk) {
       addlSuccessBlk((FPUser *)unsyncedUser);
     }
   }
                markAsSyncCompleteForDeletedEntityBlk:^(PELMMainSupport *unsyncedUser){
                  [_localDao deleteAllUsers:errorBlk];
                  if (addlSuccessBlk) {
                    addlSuccessBlk((FPUser *)unsyncedUser);
                  }
                }
                      authRequiredHandler:^(PELMMainSupport *unsyncedUser, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedUser, auth);
                        [_localDao cancelSyncForUser:(FPUser *)unsyncedUser
                                        httpRespCode:@(401)
                                           errorMask:nil
                                             retryAt:nil
                                               error:errorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:nil // because new users are always created in real-time, in main-thread of application
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                       addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedVehicle) {
    [_localDao markAsInConflictForVehicle:(FPVehicle *)unsyncedVehicle
                                    error:errorBlk];
    [_conflictDelegate remoteStoreVersionOfVehicle:latestResourceModel isNewerThanLocalVersion:(FPVehicle *)unsyncedVehicle];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteVehicle:(FPVehicle *)unsyncedVehicle
                            timeout:_timeout
                    remoteStoreBusy:remoteStoreBusyHandler
                       authRequired:authReqdHandler
                  completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingVehicle:(FPVehicle *)unsyncedVehicle
                                  timeout:_timeout
                          remoteStoreBusy:remoteStoreBusyHandler
                             authRequired:authReqdHandler
                        completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedVehicle,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewVehicle:(FPVehicle *)unsyncedVehicle
                             forUser:user
                             timeout:_timeout
                     remoteStoreBusy:remoteStoreBusyHandler
                        authRequired:authReqdHandler
                   completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:vehicle
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForVehicle:vehicle
                                            httpRespCode:@(503)
                                               errorMask:nil
                                                 retryAt:retryAt
                                                   error:errorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                      remoteStoreErrorBlk:^(PELMMainSupport *unsyncedVehicle, NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForVehicle:(FPVehicle *)unsyncedVehicle
                                           httpRespCode:httpStatusCode
                                              errorMask:@([err code])
                                                retryAt:nil
                                                  error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedVehicle) {
          [_localDao markAsSyncCompleteForNewVehicle:(FPVehicle *)unsyncedVehicle
                                             forUser:user
                                               error:errorBlk];
          if (addlSuccessBlk) {
            addlSuccessBlk((FPVehicle *)unsyncedVehicle);
          }
        }
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedVehicle) {
     [_localDao markAsSyncCompleteForUpdatedVehicle:(FPVehicle *)unsyncedVehicle
                                              error:errorBlk];
     if (addlSuccessBlk) {
       addlSuccessBlk((FPVehicle *)unsyncedVehicle);
     }
   }
                markAsSyncCompleteForDeletedEntityBlk:^(PELMMainSupport *unsyncedVehicle){[_localDao cascadeDeleteVehicle:(FPVehicle *)unsyncedVehicle
                                                                                                        error:errorBlk];}
                      authRequiredHandler:^(PELMMainSupport *unsyncedVehicle, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedVehicle, auth);
                        [_localDao cancelSyncForVehicle:(FPVehicle *)unsyncedVehicle
                                           httpRespCode:@(401)
                                              errorMask:nil
                                                retryAt:nil
                                                  error:errorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                           addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedFuelStation) {
    [_localDao markAsInConflictForFuelStation:(FPFuelStation *)unsyncedFuelStation
                                        error:errorBlk];
    [_conflictDelegate remoteStoreVersionOfFuelStation:latestResourceModel
                               isNewerThanLocalVersion:(FPFuelStation *)unsyncedFuelStation];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteFuelStation:(FPFuelStation *)unsyncedFuelStation
                                timeout:_timeout
                        remoteStoreBusy:remoteStoreBusyHandler
                           authRequired:authReqdHandler
                      completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingFuelStation:(FPFuelStation *)unsyncedFuelStation
                                      timeout:_timeout
                              remoteStoreBusy:remoteStoreBusyHandler
                                 authRequired:authReqdHandler
                            completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedFuelStation,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewFuelStation:(FPFuelStation *)unsyncedFuelStation
                                 forUser:user
                                 timeout:_timeout
                         remoteStoreBusy:remoteStoreBusyHandler
                            authRequired:authReqdHandler
                       completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelStation
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForFuelStation:fuelStation
                                                httpRespCode:@(503)
                                                   errorMask:nil
                                                     retryAt:retryAt
                                                       error:errorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                      remoteStoreErrorBlk:^(PELMMainSupport *unsyncedFuelStation, NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForFuelStation:(FPFuelStation *)unsyncedFuelStation
                                               httpRespCode:httpStatusCode
                                                  errorMask:@([err code])
                                                    retryAt:nil
                                                      error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedFuelStation) {
          [_localDao markAsSyncCompleteForNewFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                 forUser:user
                                                   error:errorBlk];
          if (addlSuccessBlk) {
            addlSuccessBlk((FPFuelStation *)unsyncedFuelStation);
          }
        }
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedFuelStation) {
     [_localDao markAsSyncCompleteForUpdatedFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                  error:errorBlk];
     if (addlSuccessBlk) {
       addlSuccessBlk((FPFuelStation *)unsyncedFuelStation);
     }
   }
                markAsSyncCompleteForDeletedEntityBlk:^(PELMMainSupport *unsyncedFuelStation){[_localDao cascadeDeleteFuelStation:(FPFuelStation *)unsyncedFuelStation
                                                                                                                error:errorBlk];}
                      authRequiredHandler:^(PELMMainSupport *unsyncedFuelStation, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedFuelStation, auth);
                        [_localDao cancelSyncForFuelStation:(FPFuelStation *)unsyncedFuelStation
                                               httpRespCode:@(401)
                                                  errorMask:nil
                                                    retryAt:nil
                                                      error:errorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      forUser:(FPUser *)user
                               addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForFpLog = [_localDao vehicleForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  FPFuelStation *fuelStationForFpLog = [_localDao fuelStationForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicleForFpLog globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStationForFpLog globalIdentifier]];
  if ([vehicleForFpLog globalIdentifier] == nil) {
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([fuelStationForFpLog globalIdentifier] == nil) {
    skippedDueToFuelStationNotSynced();
    return;
  }
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedFuelPurchaseLog) {
    [_localDao markAsInConflictForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                            error:errorBlk];
    [_conflictDelegate remoteStoreVersionOfFuelPurchaseLog:latestResourceModel
                                   isNewerThanLocalVersion:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyHandler
                                     authRequired:authReqdHandler
                                completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedFuelPurchaseLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                     forUser:user
                                     timeout:_timeout
                             remoteStoreBusy:remoteStoreBusyHandler
                                authRequired:authReqdHandler
                           completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelPurchaseLog
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog
                                                    httpRespCode:@(503)
                                                       errorMask:nil
                                                         retryAt:retryAt
                                                           error:errorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                      remoteStoreErrorBlk:^(PELMMainSupport *unsyncedFplog, NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFplog
                                                   httpRespCode:httpStatusCode
                                                      errorMask:@([err code])
                                                        retryAt:nil
                                                          error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog) {
          [_localDao markAsSyncCompleteForNewFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                     forUser:user
                                                       error:errorBlk];
          if (addlSuccessBlk) {
            addlSuccessBlk((FPFuelPurchaseLog *)unsyncedFuelPurchaseLog);
          }
        }
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog) {
     [_localDao markAsSyncCompleteForUpdatedFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                      error:errorBlk];
     if (addlSuccessBlk) {
       addlSuccessBlk((FPFuelPurchaseLog *)unsyncedFuelPurchaseLog);
     }
   }
                markAsSyncCompleteForDeletedEntityBlk:^(PELMMainSupport *unsyncedFuelPurchaseLog){[_localDao cascadeDeleteFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFuelPurchaseLog
                                                                                                                        error:errorBlk];}
                      authRequiredHandler:^(PELMMainSupport *unsyncedFpLog, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedFpLog, auth);
                        [_localDao cancelSyncForFuelPurchaseLog:(FPFuelPurchaseLog *)unsyncedFpLog
                                                   httpRespCode:@(401)
                                                      errorMask:nil
                                                        retryAt:nil
                                                          error:errorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     forUser:(FPUser *)user
                              addlSuccessBlk:(void(^)(PELMMainSupport *))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                       error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForEnvLog = [_localDao vehicleForEnvironmentLog:environmentLog error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicleForEnvLog globalIdentifier]];
  if ([vehicleForEnvLog globalIdentifier] == nil) {
    skippedDueToVehicleNotSynced();
    return;
  }
  void (^markAsConflictBlk)(id, PELMMainSupport *) = ^ (id latestResourceModel, PELMMainSupport *unsyncedEnvironmentLog) {
    [_localDao markAsInConflictForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                           error:errorBlk];
    [_conflictDelegate remoteStoreVersionOfEnvironmentLog:latestResourceModel
                                  isNewerThanLocalVersion:(FPEnvironmentLog *)unsyncedEnvironmentLog];
  };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                   timeout:_timeout
                           remoteStoreBusy:remoteStoreBusyHandler
                              authRequired:authReqdHandler
                         completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                         timeout:_timeout
                                 remoteStoreBusy:remoteStoreBusyHandler
                                    authRequired:authReqdHandler
                               completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMMainSupport *unsyncedEnvironmentLog,
    PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                    forUser:user
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:environmentLog
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForEnvironmentLog:environmentLog
                                                   httpRespCode:@(503)
                                                      errorMask:nil
                                                        retryAt:retryAt
                                                          error:errorBlk];
                         if (addlRemoteStoreBusyBlk) {
                           addlRemoteStoreBusyBlk(retryAt);
                         }
                       }
                      remoteStoreErrorBlk:^(PELMMainSupport *unsyncedEnvLog, NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvLog
                                                  httpRespCode:httpStatusCode
                                                     errorMask:@([err code])
                                                       retryAt:nil
                                                         error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
          [_localDao markAsSyncCompleteForNewEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                                    forUser:user
                                                      error:errorBlk];
          if (addlSuccessBlk) {
            addlSuccessBlk((FPEnvironmentLog *)unsyncedEnvironmentLog);
          }
        }
   markAsSyncCompleteForExistingEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
     [_localDao markAsSyncCompleteForUpdatedEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                                     error:errorBlk];
     if (addlSuccessBlk) {
       addlSuccessBlk((FPEnvironmentLog *)unsyncedEnvironmentLog);
     }
   }
                markAsSyncCompleteForDeletedEntityBlk:^(PELMMainSupport *unsyncedEnvironmentLog) {
                  [_localDao cascadeDeleteEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvironmentLog
                                                   error:errorBlk];
                }
                      authRequiredHandler:^(PELMMainSupport *unsyncedEnvLog, HCAuthentication *auth) {
                        [self authReqdBlk](unsyncedEnvLog, auth);
                        [_localDao cancelSyncForEnvironmentLog:(FPEnvironmentLog *)unsyncedEnvLog
                                                  httpRespCode:@(401)
                                                     errorMask:nil
                                                       retryAt:nil
                                                         error:errorBlk];
                        if (addlAuthRequiredBlk) {
                          addlAuthRequiredBlk();
                        }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){ [self processNewAuthToken:newAuthTkn forUser:user]; }
                    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)flushUnsyncedChangesToEntities:(NSArray *)entitiesToSync
                                syncer:(void(^)(PELMMainSupport *))syncerBlk {
  for (PELMMainSupport *entity in entitiesToSync) {
    if ([entity syncInProgress]) {
      syncerBlk(entity);
    }
  }
}

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(FPUser *)user
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                          allDone:(void(^)(void))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk {
  NSArray *vehiclesToSync = [_localDao markVehiclesAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fuelStationsToSync = [_localDao markFuelStationsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fpLogsToSync = [_localDao markFuelPurchaseLogsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *envLogsToSync = [_localDao markEnvironmentLogsAsSyncInProgressForUser:user error:errorBlk];
  NSInteger totalNumToSync = [vehiclesToSync count] + [fuelStationsToSync count] + [fpLogsToSync count] + [envLogsToSync count];
  if (totalNumToSync == 0) {
    allDoneBlk();
    return 0;
  }
  NSDecimalNumber *individualEntitySyncProgress = [[NSDecimalNumber one] decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)totalNumToSync]]];
  __block NSInteger totalSyncAttempted = 0;
  void (^incrementSyncAttemptedAndCheckDoneness)(void) = ^{
    totalSyncAttempted++;
    if (totalSyncAttempted == totalNumToSync) {
      allDoneBlk();
    }
  };
  void (^commonSuccessBlk)(id) = ^(id entity) {
    if (successBlk) successBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteStoreyBusyBlk)(NSDate *) = ^(NSDate *retryAfter) {
    if (remoteStoreBusyBlk) remoteStoreBusyBlk([individualEntitySyncProgress floatValue], retryAfter);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonTempRemoteErrorBlk)(void) = ^{
    if (tempRemoteErrorBlk) tempRemoteErrorBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteErrorBlk)(NSInteger) = ^(NSInteger errMask) {
    if (remoteErrorBlk) remoteErrorBlk([individualEntitySyncProgress floatValue], errMask);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonAuthReqdBlk)(void) = ^{
    if (authRequiredBlk) authRequiredBlk([individualEntitySyncProgress floatValue]);
    allDoneBlk();
  };
  void (^commonSyncSkippedBlk)(void) = ^{
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^syncFpLogs)(void) = ^{
    [self flushUnsyncedChangesToEntities:fpLogsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)entity
                                                                                                        forUser:user
                                                                                                 addlSuccessBlk:^(id e){ commonSuccessBlk(e); }
                                                                                         addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                         addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                             addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                            addlAuthRequiredBlk:^{ commonAuthReqdBlk(); }
                                                                                   skippedDueToVehicleNotSynced:^{ commonSyncSkippedBlk(); }
                                                                               skippedDueToFuelStationNotSynced:^{ commonSyncSkippedBlk(); }
                                                                                                          error:errorBlk];}];
  };
  void (^syncEnvLogs)(void) = ^{
    [self flushUnsyncedChangesToEntities:envLogsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                       forUser:user
                                                                                                addlSuccessBlk:^(id e){ commonSuccessBlk(e); }
                                                                                        addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                        addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                            addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                           addlAuthRequiredBlk:^{ commonAuthReqdBlk(); }
                                                                                  skippedDueToVehicleNotSynced:^{ commonSyncSkippedBlk(); }
                                                                                                         error:errorBlk];}];
  };
  __block NSInteger totalVehiclesSyncAttempted = 0;
  __block NSInteger totalFuelStationsSynced = 0;
  NSInteger totalNumVehiclesToSync = [vehiclesToSync count];
  NSInteger totalNumFuelStationsToSync = [fuelStationsToSync count];
  __block BOOL haveSyncedFpLogs = NO;
  // FYI, we won't have a concurrency issue with the inner-most calls to syncFpLogs
  // because all completion blocks associated with network calls execute in a serial
  // queue.  This is a guarantee made by our remote store DAO.  So, in the case where
  // we have vehicles, fuelstations and fp logs to sync, we're guaranteed that syncFpLogs
  // will only get invoked once.
  if (totalNumVehiclesToSync > 0) {
    void (^vehicleSyncAttempted)(void) = ^{
      totalVehiclesSyncAttempted++;
      if (totalVehiclesSyncAttempted == totalNumVehiclesToSync) {
        syncEnvLogs();
        if (totalNumFuelStationsToSync > 0) {
          if (totalFuelStationsSynced == totalNumFuelStationsToSync) {
            if (!haveSyncedFpLogs) {
              haveSyncedFpLogs = YES;
              syncFpLogs();
            }
          }
        } else {
          syncFpLogs();
        }
      }
    };
    [self flushUnsyncedChangesToEntities:vehiclesToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToVehicle:(FPVehicle *)entity
                                                                                                forUser:user
                                                                                         addlSuccessBlk:^(id e) { commonSuccessBlk(e); vehicleSyncAttempted(); }
                                                                                 addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); vehicleSyncAttempted(); }
                                                                                 addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); vehicleSyncAttempted(); }
                                                                                     addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); vehicleSyncAttempted(); }
                                                                                    addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                                  error:errorBlk];}];
  } else {
    syncEnvLogs();
  }
  if (totalNumFuelStationsToSync > 0) {
    void (^fuelStationSyncAttempted)(void) = ^{
      totalFuelStationsSynced++;
      if (totalFuelStationsSynced == totalNumFuelStationsToSync) {
        if (totalNumVehiclesToSync > 0) {
          if (totalVehiclesSyncAttempted == totalNumVehiclesToSync) {
            if (!haveSyncedFpLogs) {
              haveSyncedFpLogs = YES;
              syncFpLogs();
            }
          }
        } else {
          syncFpLogs();
        }
      }
    };
    [self flushUnsyncedChangesToEntities:fuelStationsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToFuelStation:(FPFuelStation *)entity
                                                                                                    forUser:user
                                                                                             addlSuccessBlk:^(id e) { commonSuccessBlk(e); fuelStationSyncAttempted(); }
                                                                                     addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); fuelStationSyncAttempted(); }
                                                                                     addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); fuelStationSyncAttempted(); }
                                                                                         addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); fuelStationSyncAttempted(); }
                                                                                        addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                                      error:errorBlk];}];
  }
  if ((totalNumVehiclesToSync == 0) && (totalNumFuelStationsToSync == 0)) {
    syncFpLogs();
  }
  return totalNumToSync;
}

#pragma mark - User

- (NSInteger)numUnsyncedVehiclesForUser:(FPUser *)user {
  return [_localDao numUnsyncedVehiclesForUser:user];
}

- (NSInteger)numUnsyncedFuelStationsForUser:(FPUser *)user {
  return [_localDao numUnsyncedFuelStationsForUser:user];
}

- (NSInteger)numUnsyncedFuelPurchaseLogsForUser:(FPUser *)user {
  return [_localDao numUnsyncedFuelPurchaseLogsForUser:user];
}

- (NSInteger)numUnsyncedEnvironmentLogsForUser:(FPUser *)user {
  return [_localDao numUnsyncedEnvironmentLogsForUser:user];
}

- (NSInteger)totalNumUnsyncedEntitiesForUser:(FPUser *)user {
  return [_localDao totalNumUnsyncedEntitiesForUser:user];
}

- (BOOL)doesUserHaveAnyUnsyncedEntities:(FPUser *)user {
  return ([self totalNumUnsyncedEntitiesForUser:user] > 0);
}

- (void)deleteRemoteAuthenticationTokenWithRemoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                                     addlCompletionHandler:(void(^)(void))addlCompletionHandler {
  // TODO
  _authToken = nil;
  addlCompletionHandler();
}

- (void)resetAsLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)error {
  [_localDao deleteAllUsers:error];
  FPUser *newLocalUser = [self newLocalUserWithError:error];
  [user overwrite:newLocalUser];
  [user setLocalMainIdentifier:[newLocalUser localMainIdentifier]];
  [user setLocalMasterIdentifier:nil];
}

- (FPUser *)newLocalUserWithError:(PELMDaoErrorBlk)errorBlk {
  FPUser *user = [self userWithName:nil email:nil username:nil password:nil];
  [_localDao saveNewLocalUser:user error:errorBlk];
  return user;
}

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

- (void)establishRemoteAccountForLocalUser:(FPUser *)localUser
             preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                         completionHandler:(FPSavedNewEntityCompletionHandler)complHandler
                     localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler remoteMasterComplHandler =
    ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
      NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
      BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    FPUser *remoteUser = nil;
    if (globalId) { // success!
      remoteUser = (FPUser *)resourceModel;
      [_localDao saveNewRemoteUser:remoteUser
                andLinkToLocalUser:localUser
     preserveExistingLocalEntities:preserveExistingLocalEntities
                             error:localSaveErrorHandler];
      [self processNewAuthToken:newAuthTkn forUser:remoteUser];
    };
    complHandler(remoteUser, err);
  };
  [_remoteMasterDao establishAccountForUser:localUser
                                    timeout:_timeout
                            remoteStoreBusy:busyHandler
                               authRequired:[self authReqdBlk]
                          completionHandler:remoteMasterComplHandler];
}

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
    andLinkRemoteUserToLocalUser:(FPUser *)localUser
   preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               completionHandler:(FPFetchedEntityCompletionHandler)complHandler
           localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    FPUser *remoteUser = (FPUser *)resourceModel;
    if (remoteUser) {
      [_localDao deepSaveNewRemoteUser:remoteUser
                    andLinkToLocalUser:localUser
         preserveExistingLocalEntities:preserveExistingLocalEntities
                                 error:localSaveErrorHandler];
      [self processNewAuthToken:newAuthTkn forUser:remoteUser];
    }
    complHandler(remoteUser, err);
  };
  PELMRemoteMasterAuthReqdBlk authReqdBlk = ^(PELMMainSupport *entity, HCAuthentication *authReqd) {
    NSError *error = [NSError errorWithDomain:FPUserFaultedErrorDomain
                                         code:(FPSignInAnyIssues | FPSignInInvalidCredentials)
                                     userInfo:nil];
    complHandler(nil, error);
  };
  [_remoteMasterDao loginWithUsernameOrEmail:usernameOrEmail
                                    password:password
                                     timeout:_timeout
                             remoteStoreBusy:busyHandler
                                authRequired:authReqdBlk
                           completionHandler:masterStoreComplHandler];
}

- (void)lightLoginForUser:(FPUser *)user
                 password:(NSString *)password
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
        completionHandler:(void(^)(NSError *))complHandler
    localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    if (newAuthTkn) {
      [self processNewAuthToken:newAuthTkn forUser:user];
    }
    complHandler(err);
  };
  PELMRemoteMasterAuthReqdBlk authReqdBlk = ^(PELMMainSupport *entity, HCAuthentication *authReqd) {
    NSError *error = [NSError errorWithDomain:FPUserFaultedErrorDomain
                                         code:(FPSignInAnyIssues | FPSignInInvalidCredentials)
                                     userInfo:nil];
    complHandler(error);
  };
  [_remoteMasterDao lightLoginForUser:user
                             password:password
                              timeout:_timeout
                      remoteStoreBusy:busyHandler
                         authRequired:authReqdBlk
                    completionHandler:masterStoreComplHandler];
}

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk {
  return [_localDao userWithError:errorBlk];
}

- (BOOL)prepareUserForEdit:(FPUser *)user
         entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
             entityDeleted:(void(^)(void))entityDeletedBlk
          entityInConflict:(void(^)(void))entityInConflictBlk
                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareUserForEdit:user
                     entityBeingSynced:entityBeingSyncedBlk
                         entityDeleted:entityDeletedBlk
                      entityInConflict:entityInConflictBlk
                                 error:errorBlk];
}

- (void)saveUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveUser:user error:errorBlk];
}

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncUser:user error:errorBlk];
  [self flushUnsyncedChangesToUser:user
                    addlSuccessBlk:^(PELMMainSupport *user) {successBlk();}
            addlRemoteStoreBusyBlk:remoteStoreBusyBlk
            addlTempRemoteErrorBlk:tempRemoteErrorBlk
                addlRemoteErrorBlk:remoteErrorBlk
               addlAuthRequiredBlk:authRequiredBlk
                             error:errorBlk];
}

- (void)reloadUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadUser:user error:errorBlk];
}

- (void)cancelEditOfUser:(FPUser *)user
                   error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfUser:user
                        error:errorBlk];
}

- (void)markAsDeletedAndSyncUserImmediate:(FPUser *)user
                               successBlk:(void(^)(void))successBlk
                       remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                       tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                           remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                          authRequiredBlk:(void(^)(void))authRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedImmediateSyncUser:user error:errorBlk];
  [self flushUnsyncedChangesToUser:user
                    addlSuccessBlk:^(PELMMainSupport *user) {successBlk();}
            addlRemoteStoreBusyBlk:remoteStoreBusyBlk
            addlTempRemoteErrorBlk:tempRemoteErrorBlk
                addlRemoteErrorBlk:remoteErrorBlk
               addlAuthRequiredBlk:authRequiredBlk
                             error:errorBlk];
}

#pragma mark - Vehicle

- (void)copyVehicleToMaster:(FPVehicle *)vehicle
                      error:(PELMDaoErrorBlk)errorBlk {
  
}

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

- (NSArray *)unsyncedVehiclesForUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao unsyncedVehiclesForUser:user error:errorBlk];
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
                       addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
            entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                entityDeleted:(void(^)(void))entityDeletedBlk
             entityInConflict:(void(^)(void))entityInConflictBlk
                        error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareVehicleForEdit:vehicle
                                  forUser:user
                        entityBeingSynced:entityBeingSyncedBlk
                            entityDeleted:entityDeletedBlk
                         entityInConflict:entityInConflictBlk
                                    error:errorBlk];
}

- (void)saveVehicle:(FPVehicle *)vehicle
              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveVehicle:vehicle
                   error:errorBlk];
}

- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingVehicle:vehicle
                                error:errorBlk];
}

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                                      successBlk:(void(^)(void))successBlk
                              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                 authRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncVehicle:vehicle
                                             error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
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
                      error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfVehicle:vehicle
                           error:errorBlk];
}

- (void)markAsDeletedVehicle:(FPVehicle *)vehicle
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedVehicle:vehicle
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

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao unsyncedFuelStationsForUser:user error:errorBlk];
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
                           addlSuccessBlk:^(PELMMainSupport *vehicle) {successBlk();}
                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                   addlTempRemoteErrorBlk:tempRemoteErrorBlk
                       addlRemoteErrorBlk:remoteErrorBlk
                      addlAuthRequiredBlk:authRequiredBlk
                                    error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                    entityDeleted:(void(^)(void))entityDeletedBlk
                 entityInConflict:(void(^)(void))entityInConflictBlk
                            error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelStationForEdit:fuelStation
                                      forUser:user
                            entityBeingSynced:entityBeingSyncedBlk
                                entityDeleted:entityDeletedBlk
                             entityInConflict:entityInConflictBlk
                                        error:errorBlk];
}

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveFuelStation:fuelStation
                       error:errorBlk];
}

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingFuelStation:fuelStation
                                    error:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                          successBlk:(void(^)(void))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                      remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     authRequiredBlk:(void(^)(void))authRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncFuelStation:fuelStation
                                                 error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
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
                          error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfFuelStation:fuelStation
                               error:errorBlk];
}

- (void)markAsDeletedFuelStation:(FPFuelStation *)fuelStation
                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedFuelStation:fuelStation
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

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao unsyncedFuelPurchaseLogsForUser:user error:errorBlk];
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
                  skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
              skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                         error:(PELMDaoErrorBlk)errorBlk {
  
  if ([vehicle globalIdentifier]) {
    if ([fuelStation globalIdentifier]) {
      [_localDao saveNewAndSyncImmediateFuelPurchaseLog:fuelPurchaseLog
                                                forUser:user
                                                vehicle:vehicle
                                            fuelStation:fuelStation
                                                  error:errorBlk];
      [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                          forUser:user
                                   addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                           addlTempRemoteErrorBlk:tempRemoteErrorBlk
                               addlRemoteErrorBlk:remoteErrorBlk
                              addlAuthRequiredBlk:authRequiredBlk
                     skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                 skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                            error:errorBlk];
    } else {
      [self saveNewFuelPurchaseLog:fuelPurchaseLog
                           forUser:user
                           vehicle:vehicle
                       fuelStation:fuelStation
                             error:errorBlk];
      skippedDueToFuelStationNotSynced();
    }
  } else {
    [self saveNewFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                           error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                    entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                        entityDeleted:(void(^)(void))entityDeletedBlk
                     entityInConflict:(void(^)(void))entityInConflictBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                          forUser:user
                                entityBeingSynced:entityBeingSyncedBlk
                                    entityDeleted:entityDeletedBlk
                                 entityInConflict:entityInConflictBlk
                                            error:errorBlk];
}

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                           error:errorBlk];
}

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog
                                        error:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                 forUser:(FPUser *)user
                                              successBlk:(void(^)(void))successBlk
                                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                          remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                         authRequiredBlk:(void(^)(void))authRequiredBlk
                            skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                        skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                                   error:(PELMDaoErrorBlk)errorBlk {
  if ([fuelPurchaseLog vehicleGlobalIdentifier]) {
    if ([fuelPurchaseLog fuelStationGlobalIdentifier]) {
      [_localDao markAsDoneEditingImmediateSyncFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
      [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                          forUser:user
                                   addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                           addlTempRemoteErrorBlk:tempRemoteErrorBlk
                               addlRemoteErrorBlk:remoteErrorBlk
                              addlAuthRequiredBlk:authRequiredBlk
                     skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                 skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                            error:errorBlk];
    } else {
      [self markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
      skippedDueToFuelStationNotSynced();
    }
  } else {
    [self markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
}

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfFuelPurchaseLog:fuelPurchaseLog
                                   error:errorBlk];
}

- (void)markAsDeletedFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedFuelPurchaseLog:fuelPurchaseLog
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

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao unsyncedEnvironmentLogsForUser:user error:errorBlk];
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
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier]) {
    [_localDao saveNewAndSyncImmediateEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                                addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                        addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                        addlTempRemoteErrorBlk:tempRemoteErrorBlk
                            addlRemoteErrorBlk:remoteErrorBlk
                           addlAuthRequiredBlk:authRequiredBlk
                  skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                         error:errorBlk];
  } else {
    [self saveNewEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                   entityBeingSynced:(void(^)(void))entityBeingSyncedBlk
                       entityDeleted:(void(^)(void))entityDeletedBlk
                    entityInConflict:(void(^)(void))entityInConflictBlk
                               error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareEnvironmentLogForEdit:environmentLog
                                         forUser:user
                               entityBeingSynced:entityBeingSyncedBlk
                                   entityDeleted:entityDeletedBlk
                                entityInConflict:entityInConflictBlk
                                           error:errorBlk];
}

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                          error:errorBlk];
}

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingEnvironmentLog:environmentLog
                                       error:errorBlk];
}

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
                                                forUser:(FPUser *)user
                                             successBlk:(void(^)(void))successBlk
                                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                         remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                        authRequiredBlk:(void(^)(void))authRequiredBlk
                           skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                                  error:(PELMDaoErrorBlk)errorBlk {
  if ([envLog vehicleGlobalIdentifier]) {
    [_localDao markAsDoneEditingImmediateSyncEnvironmentLog:envLog error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                                addlSuccessBlk:^(PELMMainSupport *fplog) {successBlk();}
                        addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                        addlTempRemoteErrorBlk:tempRemoteErrorBlk
                            addlRemoteErrorBlk:remoteErrorBlk
                           addlAuthRequiredBlk:authRequiredBlk
                  skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                         error:errorBlk];
  } else {
    [self markAsDoneEditingEnvironmentLog:envLog error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk {
  [_localDao reloadEnvironmentLog:environmentLog error:errorBlk];
}

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk {
  [_localDao cancelEditOfEnvironmentLog:environmentLog
                                  error:errorBlk];
}

- (void)markAsDeletedEnvironmentLog:(FPEnvironmentLog *)environmentLog
                              error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDeletedEnvironmentLog:environmentLog
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
