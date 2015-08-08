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
     ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
     loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
   accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
    bundleHoldingApiJsonResource:(NSBundle *)bundle
       nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
                 apiResMtVersion:(NSString *)apiResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
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
    FPLogoutSerializer *logoutSerializer = [self logoutSerializerForCharset:acceptCharset];
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
  ifUnmodifiedSinceHeaderName:ifUnmodifiedSinceHeaderName
  loginFailedReasonHeaderName:loginFailedReasonHeaderName
accountClosedReasonHeaderName:accountClosedReasonHeaderName
 bundleHoldingApiJsonResource:bundle
    nameOfApiJsonResourceFile:apiResourceFileName
              apiResMtVersion:apiResMtVersion
               userSerializer:userSerializer
              loginSerializer:loginSerializer
             logoutSerializer:logoutSerializer
            vehicleSerializer:vehicleSerializer
        fuelStationSerializer:fuelStationSerializer
    fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
     environmentLogSerializer:environmentLogSerializer
     allowInvalidCertificates:allowInvalidCertificates];
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

#pragma mark - Helpers

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

- (FPLogoutSerializer *)logoutSerializerForCharset:(HCCharset *)charset {
  return [[FPLogoutSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
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

#pragma mark - Pruning

- (void)pruneAllSyncedEntitiesWithError:(PELMDaoErrorBlk)errorBlk {
  [_localDao pruneAllSyncedEntitiesWithError:errorBlk];
}

#pragma mark - System

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error {
  [_localDao globalCancelSyncInProgressWithError:error];
}

#pragma mark - Flushing All Unsynced Edits to Remote Master

- (void)flushUnsyncedChangesToEntities:(NSArray *)entitiesToSync
                                syncer:(void(^)(PELMMainSupport *))syncerBlk {
  for (PELMMainSupport *entity in entitiesToSync) {
    if ([entity syncInProgress]) {
      syncerBlk(entity);
    }
  }
}

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(FPUser *)user
                                entityNotFoundBlk:(void(^)(float))entityNotFoundBlk
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                      conflictBlk:(void(^)(float, id))conflictBlk
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
  void (^commonEntityNotFoundBlk)(void) = ^{
    if (entityNotFoundBlk) entityNotFoundBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonConflictBlk)(id) = ^(id latestEntity) {
    if (conflictBlk) conflictBlk([individualEntitySyncProgress floatValue], latestEntity);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonSuccessBlk)(void) = ^{
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
                                                                                            notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                                 addlSuccessBlk:^{ commonSuccessBlk(); }
                                                                                         addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                         addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                             addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                                addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                            addlAuthRequiredBlk:^{ commonAuthReqdBlk(); }
                                                                                   skippedDueToVehicleNotSynced:^{ commonSyncSkippedBlk(); }
                                                                               skippedDueToFuelStationNotSynced:^{ commonSyncSkippedBlk(); }
                                                                                                          error:errorBlk];}];
  };
  void (^syncEnvLogs)(void) = ^{
    [self flushUnsyncedChangesToEntities:envLogsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)entity
                                                                                                       forUser:user
                                                                                           notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                                addlSuccessBlk:^{ commonSuccessBlk(); }
                                                                                        addlRemoteStoreBusyBlk:^(NSDate *d) {commonRemoteStoreyBusyBlk(d); }
                                                                                        addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                            addlRemoteErrorBlk:^(NSInteger m) {commonRemoteErrorBlk(m);}
                                                                                               addlConflictBlk:^(id e) { commonConflictBlk(e); }
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
                                                                                    notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                         addlSuccessBlk:^{ commonSuccessBlk(); vehicleSyncAttempted(); }
                                                                                 addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); vehicleSyncAttempted(); }
                                                                                 addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); vehicleSyncAttempted(); }
                                                                                     addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); vehicleSyncAttempted(); }
                                                                                        addlConflictBlk:^(id e) { commonConflictBlk(e); }
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
                                                                                        notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                             addlSuccessBlk:^{ commonSuccessBlk(); fuelStationSyncAttempted(); }
                                                                                     addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); fuelStationSyncAttempted(); }
                                                                                     addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); fuelStationSyncAttempted(); }
                                                                                         addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); fuelStationSyncAttempted(); }
                                                                                            addlConflictBlk:^(id e) { commonConflictBlk(e); }
                                                                                        addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                                      error:errorBlk];}];
  }
  if ((totalNumVehiclesToSync == 0) && (totalNumFuelStationsToSync == 0)) {
    syncFpLogs();
  }
  return totalNumToSync;
}

#pragma mark - User

- (void)deleteUser:(FPUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [_localDao deleteUser:user error:errorBlk];
}

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

- (void)resetAsLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)error {
  [_localDao deleteUser:user error:error];
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
  PELMRemoteMasterAuthReqdBlk authReqdBlk = ^(HCAuthentication *authReqd) {
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
  PELMRemoteMasterAuthReqdBlk authReqdBlk = ^(HCAuthentication *authReqd) {
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

- (void)logoutUser:(FPUser *)user
addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
 addlCompletionBlk:(void(^)(void))addlCompletionBlk
localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    // whether error or success, we're going to call the additional completion
    // block and delete the local user
    if (addlCompletionBlk) { addlCompletionBlk(); }
    [_localDao deleteUser:user error:localSaveErrorHandler];
    _authToken = nil;
  };
  [_remoteMasterDao logoutUser:user
                       timeout:_timeout
               remoteStoreBusy:addlRemoteStoreBusyBlk
             completionHandler:masterStoreComplHandler];
}

- (FPUser *)userWithError:(PELMDaoErrorBlk)errorBlk {
  return [_localDao userWithError:errorBlk];
}

- (BOOL)prepareUserForEdit:(FPUser *)user
                     error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareUserForEdit:user error:errorBlk];
}

- (void)saveUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveUser:user error:errorBlk];
}

- (void)flushUnsyncedChangesToUser:(FPUser *)user
               notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                    addlSuccessBlk:(void(^)(void))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                   addlConflictBlk:(void(^)(FPUser *))addlConflictBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                             error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingUser:user
                               timeout:_timeout
                       remoteStoreBusy:remoteStoreBusyHandler
                          authRequired:authReqdHandler
                     completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:user
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForUser:user httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                         if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                       }
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForUser:user httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        entityNotFoundBlk:notFoundOnServerBlk
                        markAsConflictBlk:^(FPUser *serverUser) {
                          [_localDao cancelSyncForUser:user httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                          if (addlConflictBlk) { addlConflictBlk(serverUser); }
                        }
        markAsSyncCompleteForNewEntityBlk:nil // because new users are always immediately synced upon creation
   markAsSyncCompleteForExistingEntityBlk:^{
     [_localDao markAsSyncCompleteForUser:user error:errorBlk];
     if (addlSuccessBlk) { addlSuccessBlk(); }
   }
                      authRequiredHandler:^(HCAuthentication *auth) {
                        [self authReqdBlk](auth);
                        [_localDao cancelSyncForUser:(FPUser *)user
                                        httpRespCode:@(401)
                                           errorMask:nil
                                             retryAt:nil
                                               error:errorBlk];
                        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                   remoteMasterSaveNewBlk:nil // because new users are always created in real-time, in main-thread of application
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                  conflictBlk:(void(^)(FPUser *))conflictBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncUser:user error:errorBlk];
  [self flushUnsyncedChangesToUser:user
               notFoundOnServerBlk:notFoundOnServerBlk
                    addlSuccessBlk:successBlk
            addlRemoteStoreBusyBlk:remoteStoreBusyBlk
            addlTempRemoteErrorBlk:tempRemoteErrorBlk
                addlRemoteErrorBlk:remoteErrorBlk
                   addlConflictBlk:conflictBlk
               addlAuthRequiredBlk:authRequiredBlk
                             error:errorBlk];
}

- (void)deleteUser:(FPUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
    addlSuccessBlk:(void(^)(void))addlSuccessBlk
addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
   addlConflictBlk:(void(^)(FPUser *))addlConflictBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
             error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteUser:user
                         timeout:_timeout
                 remoteStoreBusy:remoteStoreBusyHandler
                    authRequired:authReqdHandler
               completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils deleteEntity:user
       remoteStoreBusyBlk:addlRemoteStoreBusyBlk
      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                       error:err
                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
      }
        entityNotFoundBlk:notFoundOnServerBlk
        markAsConflictBlk:^(FPUser *serverUser) { if (addlConflictBlk) { addlConflictBlk(serverUser); } }
        deleteCompleteBlk:^{
          [_localDao deleteUser:user error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
      authRequiredHandler:^(HCAuthentication *auth) {
        [self authReqdBlk](auth);
        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
      }
          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
    localSaveErrorHandler:errorBlk];
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
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            successBlk:(void(^)(void))successBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                        remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                           conflictBlk:(void(^)(id))conflictBlk
                       authRequiredBlk:(void(^)(void))authRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewAndSyncImmediateVehicle:vehicle forUser:user error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                  notFoundOnServerBlk:notFoundOnServerBlk
                       addlSuccessBlk:successBlk
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                      addlConflictBlk:conflictBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle
                      forUser:(FPUser *)user
                        error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareVehicleForEdit:vehicle
                                  forUser:user
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

- (void)flushUnsyncedChangesToVehicle:(FPVehicle *)vehicle
                              forUser:(FPUser *)user
                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                       addlSuccessBlk:(void(^)(void))addlSuccessBlk
               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                      addlConflictBlk:(void(^)(FPVehicle *))addlConflictBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPVehicle *latestVehicle) {
    [_localDao cancelSyncForVehicle:vehicle httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
    if (addlConflictBlk) { addlConflictBlk(latestVehicle); }
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingVehicle:vehicle
                                  timeout:_timeout
                          remoteStoreBusy:remoteStoreBusyHandler
                             authRequired:authReqdHandler
                        completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewVehicle:vehicle
                             forUser:user
                             timeout:_timeout
                     remoteStoreBusy:remoteStoreBusyHandler
                        authRequired:authReqdHandler
                   completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:vehicle
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForVehicle:vehicle httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                         if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                       }
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForVehicle:vehicle httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        entityNotFoundBlk:notFoundOnServerBlk
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^{
          [_localDao markAsSyncCompleteForNewVehicle:vehicle
                                             forUser:user
                                               error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
   markAsSyncCompleteForExistingEntityBlk:^{
     [_localDao markAsSyncCompleteForUpdatedVehicle:vehicle error:errorBlk];
     if (addlSuccessBlk) { addlSuccessBlk(); }
   }
                      authRequiredHandler:^(HCAuthentication *auth) {
                        [self authReqdBlk](auth);
                        [_localDao cancelSyncForVehicle:vehicle
                                           httpRespCode:@(401)
                                              errorMask:nil
                                                retryAt:nil
                                                  error:errorBlk];
                        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      successBlk:(void(^)(void))successBlk
                              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     conflictBlk:(void(^)(FPVehicle *))conflictBlk
                                 authRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncVehicle:vehicle
                                             error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                  notFoundOnServerBlk:notFoundOnServerBlk
                       addlSuccessBlk:successBlk
               addlRemoteStoreBusyBlk:remoteStoreBusyBlk
               addlTempRemoteErrorBlk:tempRemoteErrorBlk
                   addlRemoteErrorBlk:remoteErrorBlk
                      addlConflictBlk:conflictBlk
                  addlAuthRequiredBlk:authRequiredBlk
                                error:errorBlk];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
              forUser:(FPUser *)user
  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
       addlSuccessBlk:(void(^)(void))addlSuccessBlk
addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
      addlConflictBlk:(void(^)(FPVehicle *))addlConflictBlk
  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPVehicle *latestVehicle) { if (addlConflictBlk) { addlConflictBlk(latestVehicle); } };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteVehicle:vehicle
                            timeout:_timeout
                    remoteStoreBusy:remoteStoreBusyHandler
                       authRequired:authReqdHandler
                  completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils deleteEntity:vehicle
       remoteStoreBusyBlk:addlRemoteStoreBusyBlk
      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                       error:err
                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
      }
        entityNotFoundBlk:notFoundOnServerBlk
        markAsConflictBlk:markAsConflictBlk
        deleteCompleteBlk:^{
          [_localDao deleteVehicle:vehicle error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
      authRequiredHandler:^(HCAuthentication *auth) {
        [self authReqdBlk](auth);
        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
      }
          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
    localSaveErrorHandler:errorBlk];
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
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                successBlk:(void(^)(void))successBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                               conflictBlk:(void(^)(id))conflictBlk
                           authRequiredBlk:(void(^)(void))authRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [_localDao saveNewAndSyncImmediateFuelStation:fuelStation forUser:user error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:successBlk
                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                   addlTempRemoteErrorBlk:tempRemoteErrorBlk
                       addlRemoteErrorBlk:remoteErrorBlk
                          addlConflictBlk:conflictBlk
                      addlAuthRequiredBlk:authRequiredBlk
                                    error:errorBlk];
}

- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelStationForEdit:fuelStation
                                      forUser:user
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

- (void)flushUnsyncedChangesToFuelStation:(FPFuelStation *)fuelStation
                                  forUser:(FPUser *)user
                      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                           addlSuccessBlk:(void(^)(void))addlSuccessBlk
                   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                          addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                    error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPFuelStation *latestFuelStation) {
    [_localDao cancelSyncForFuelStation:fuelStation httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
    if (addlConflictBlk) { addlConflictBlk(latestFuelStation); }
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingFuelStation:fuelStation
                                      timeout:_timeout
                              remoteStoreBusy:remoteStoreBusyHandler
                                 authRequired:authReqdHandler
                            completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewFuelStation:fuelStation
                                 forUser:user
                                 timeout:_timeout
                         remoteStoreBusy:remoteStoreBusyHandler
                            authRequired:authReqdHandler
                       completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelStation
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForFuelStation:fuelStation httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                         if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                       }
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForFuelStation:fuelStation httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        entityNotFoundBlk:notFoundOnServerBlk
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^{
          [_localDao markAsSyncCompleteForNewFuelStation:fuelStation forUser:user error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
   markAsSyncCompleteForExistingEntityBlk:^{
     [_localDao markAsSyncCompleteForUpdatedFuelStation:fuelStation error:errorBlk];
     if (addlSuccessBlk) { addlSuccessBlk(); }
   }
                      authRequiredHandler:^(HCAuthentication *auth) {
                        [self authReqdBlk](auth);
                        [_localDao cancelSyncForFuelStation:fuelStation httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
                        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                          successBlk:(void(^)(void))successBlk
                                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                      remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                         conflictBlk:(void(^)(FPFuelStation *))conflictBlk
                                     authRequiredBlk:(void(^)(void))authRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncFuelStation:fuelStation
                                                 error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:successBlk
                   addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                   addlTempRemoteErrorBlk:tempRemoteErrorBlk
                       addlRemoteErrorBlk:remoteErrorBlk
                          addlConflictBlk:conflictBlk
                      addlAuthRequiredBlk:authRequiredBlk
                                    error:errorBlk];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  forUser:(FPUser *)user
      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
           addlSuccessBlk:(void(^)(void))addlSuccessBlk
   addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
   addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
       addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
          addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                    error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPFuelStation *latestFuelStation) { if (addlConflictBlk) { addlConflictBlk(latestFuelStation); } };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteFuelStation:fuelStation
                                timeout:_timeout
                        remoteStoreBusy:remoteStoreBusyHandler
                           authRequired:authReqdHandler
                      completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils deleteEntity:fuelStation
       remoteStoreBusyBlk:addlRemoteStoreBusyBlk
      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                       error:err
                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
      }
        entityNotFoundBlk:notFoundOnServerBlk
        markAsConflictBlk:markAsConflictBlk
        deleteCompleteBlk:^{
          [_localDao deleteFuelstation:fuelStation error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
      authRequiredHandler:^(HCAuthentication *auth) {
        [self authReqdBlk](auth);
        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
      }
          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
    localSaveErrorHandler:errorBlk];
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
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                    successBlk:(void(^)(void))successBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                   conflictBlk:(void(^)(id))conflictBlk
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
                              notFoundOnServerBlk:notFoundOnServerBlk
                                   addlSuccessBlk:successBlk
                           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                           addlTempRemoteErrorBlk:tempRemoteErrorBlk
                               addlRemoteErrorBlk:remoteErrorBlk
                                  addlConflictBlk:conflictBlk
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
                                error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                          forUser:user
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

- (void)flushUnsyncedChangesToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                      forUser:(FPUser *)user
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                               addlSuccessBlk:(void(^)(void))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                              addlConflictBlk:(void(^)(FPFuelPurchaseLog *))addlConflictBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForFpLog = [_localDao vehicleForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  FPFuelStation *fuelStationForFpLog = [_localDao fuelStationForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicleForFpLog globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStationForFpLog globalIdentifier]];
  if ([vehicleForFpLog globalIdentifier] == nil) {
    [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([fuelStationForFpLog globalIdentifier] == nil) {
    [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToFuelStationNotSynced();
    return;
  }
  void (^markAsConflictBlk)(id) = ^ (FPFuelPurchaseLog *latestFplog) {
    [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
    if (addlConflictBlk) { addlConflictBlk(latestFplog); }
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingFuelPurchaseLog:fuelPurchaseLog
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyHandler
                                     authRequired:authReqdHandler
                                completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewFuelPurchaseLog:fuelPurchaseLog
                                     forUser:user
                                     timeout:_timeout
                             remoteStoreBusy:remoteStoreBusyHandler
                                authRequired:authReqdHandler
                           completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:fuelPurchaseLog
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                         if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                       }
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        entityNotFoundBlk:notFoundOnServerBlk
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^{
          [_localDao markAsSyncCompleteForNewFuelPurchaseLog:fuelPurchaseLog forUser:user error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
   markAsSyncCompleteForExistingEntityBlk:^{
     [_localDao markAsSyncCompleteForUpdatedFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
     if (addlSuccessBlk) { addlSuccessBlk(); }
   }
                      authRequiredHandler:^(HCAuthentication *auth) {
                        [self authReqdBlk](auth);
                        [_localDao cancelSyncForFuelPurchaseLog:fuelPurchaseLog
                                                   httpRespCode:@(401)
                                                      errorMask:nil
                                                        retryAt:nil
                                                          error:errorBlk];
                        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
                                                 forUser:(FPUser *)user
                                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                              successBlk:(void(^)(void))successBlk
                                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                          remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                             conflictBlk:(void(^)(FPFuelPurchaseLog *))conflictBlk
                                         authRequiredBlk:(void(^)(void))authRequiredBlk
                            skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                        skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                                   error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                      forUser:user
                          notFoundOnServerBlk:notFoundOnServerBlk
                               addlSuccessBlk:successBlk
                       addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                       addlTempRemoteErrorBlk:tempRemoteErrorBlk
                           addlRemoteErrorBlk:remoteErrorBlk
                              addlConflictBlk:conflictBlk
                          addlAuthRequiredBlk:authRequiredBlk
                 skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                        error:errorBlk];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                      forUser:(FPUser *)user
          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
               addlSuccessBlk:(void(^)(void))addlSuccessBlk
       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
              addlConflictBlk:(void(^)(FPFuelPurchaseLog *))addlConflictBlk
          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                        error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPFuelPurchaseLog *latestFplog) { if (addlConflictBlk) { addlConflictBlk(latestFplog); } };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteFuelPurchaseLog:fplog
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils deleteEntity:fplog
       remoteStoreBusyBlk:addlRemoteStoreBusyBlk
      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                       error:err
                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
      }
        entityNotFoundBlk:notFoundOnServerBlk
        markAsConflictBlk:markAsConflictBlk
        deleteCompleteBlk:^{
          [_localDao deleteFuelPurchaseLog:fplog error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
      authRequiredHandler:^(HCAuthentication *auth) {
        [self authReqdBlk](auth);
        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
      }
          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
    localSaveErrorHandler:errorBlk];
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
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                   successBlk:(void(^)(void))successBlk
                           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                  conflictBlk:(void(^)(id))conflictBlk
                              authRequiredBlk:(void(^)(void))authRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier]) {
    [_localDao saveNewAndSyncImmediateEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                           notFoundOnServerBlk:notFoundOnServerBlk
                                addlSuccessBlk:successBlk
                        addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                        addlTempRemoteErrorBlk:tempRemoteErrorBlk
                            addlRemoteErrorBlk:remoteErrorBlk
                               addlConflictBlk:conflictBlk
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
                               error:(PELMDaoErrorBlk)errorBlk {
  return [_localDao prepareEnvironmentLogForEdit:environmentLog
                                         forUser:user
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

- (void)flushUnsyncedChangesToEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                     forUser:(FPUser *)user
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                             addlConflictBlk:(void(^)(FPEnvironmentLog *))addlConflictBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                       error:(PELMDaoErrorBlk)errorBlk {
  FPVehicle *vehicleForEnvLog = [_localDao vehicleForEnvironmentLog:environmentLog error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicleForEnvLog globalIdentifier]];
  if ([vehicleForEnvLog globalIdentifier] == nil) {
    [_localDao cancelSyncForEnvironmentLog:environmentLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  void (^markAsConflictBlk)(id) = ^ (FPEnvironmentLog *latestEnvlog) {
    [_localDao cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
    if (addlConflictBlk) { addlConflictBlk(latestEnvlog); }
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveExistingEnvironmentLog:environmentLog
                                         timeout:_timeout
                                 remoteStoreBusy:remoteStoreBusyHandler
                                    authRequired:authReqdHandler
                               completionHandler:remoteStoreComplHandler];
  };
  PELMRemoteMasterSaveBlk remoteMasterSaveNewBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao saveNewEnvironmentLog:environmentLog
                                    forUser:user
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyHandler
                               authRequired:authReqdHandler
                          completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils flushUnsyncedChangesToEntity:environmentLog
                       remoteStoreBusyBlk:^(NSDate *retryAt) {
                         [_localDao cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                         if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                       }
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [_localDao cancelSyncForEnvironmentLog:environmentLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
                      }
                        entityNotFoundBlk:notFoundOnServerBlk
                        markAsConflictBlk:markAsConflictBlk
        markAsSyncCompleteForNewEntityBlk:^{
          [_localDao markAsSyncCompleteForNewEnvironmentLog:environmentLog forUser:user error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
   markAsSyncCompleteForExistingEntityBlk:^{
     [_localDao markAsSyncCompleteForUpdatedEnvironmentLog:environmentLog error:errorBlk];
     if (addlSuccessBlk) { addlSuccessBlk(); }
   }
                      authRequiredHandler:^(HCAuthentication *auth) {
                        [self authReqdBlk](auth);
                        [_localDao cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
                        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                      }
                          newAuthTokenBlk:^(NSString *newAuthTkn){ [self processNewAuthToken:newAuthTkn forUser:user]; }
                   remoteMasterSaveNewBlk:remoteMasterSaveNewBlk
              remoteMasterSaveExistingBlk:remoteMasterSaveExistingBlk
                    localSaveErrorHandler:errorBlk];
}

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
                                                forUser:(FPUser *)user
                                    notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                             successBlk:(void(^)(void))successBlk
                                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                         remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                            conflictBlk:(void(^)(FPEnvironmentLog *))conflictBlk
                                        authRequiredBlk:(void(^)(void))authRequiredBlk
                           skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [_localDao markAsDoneEditingImmediateSyncEnvironmentLog:envLog error:errorBlk];
  [self flushUnsyncedChangesToEnvironmentLog:envLog
                                     forUser:user
                         notFoundOnServerBlk:notFoundOnServerBlk
                              addlSuccessBlk:successBlk
                      addlRemoteStoreBusyBlk:remoteStoreBusyBlk
                      addlTempRemoteErrorBlk:tempRemoteErrorBlk
                          addlRemoteErrorBlk:remoteErrorBlk
                             addlConflictBlk:conflictBlk
                         addlAuthRequiredBlk:authRequiredBlk
                skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                       error:errorBlk];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                     forUser:(FPUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
              addlSuccessBlk:(void(^)(void))addlSuccessBlk
      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
             addlConflictBlk:(void(^)(FPEnvironmentLog *))addlConflictBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                       error:(PELMDaoErrorBlk)errorBlk {
  void (^markAsConflictBlk)(id) = ^ (FPEnvironmentLog *latestEnvlog) { if (addlConflictBlk) { addlConflictBlk(latestEnvlog); } };
  PELMRemoteMasterDeletionBlk remoteMasterDeletionExistingBlk =
  ^(PELMRemoteMasterBusyBlk remoteStoreBusyHandler,
    PELMRemoteMasterAuthReqdBlk authReqdHandler,
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler) {
    [_remoteMasterDao deleteEnvironmentLog:envlog
                                   timeout:_timeout
                           remoteStoreBusy:remoteStoreBusyHandler
                              authRequired:authReqdHandler
                         completionHandler:remoteStoreComplHandler];
  };
  [PELMUtils deleteEntity:envlog
       remoteStoreBusyBlk:addlRemoteStoreBusyBlk
      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                       error:err
                                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                                          addlRemoteErrorBlk:addlRemoteErrorBlk];
      }
        entityNotFoundBlk:notFoundOnServerBlk
        markAsConflictBlk:markAsConflictBlk
        deleteCompleteBlk:^{
          [_localDao deleteEnvironmentLog:envlog error:errorBlk];
          if (addlSuccessBlk) { addlSuccessBlk(); }
        }
      authRequiredHandler:^(HCAuthentication *auth) {
        [self authReqdBlk](auth);
        if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
      }
          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}
    remoteMasterDeleteBlk:remoteMasterDeletionExistingBlk
    localSaveErrorHandler:errorBlk];
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

#pragma mark - Flush to Remote Master helpers (private)

- (PELMRemoteMasterAuthReqdBlk) authReqdBlk {
  return ^(HCAuthentication *auth) {
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
