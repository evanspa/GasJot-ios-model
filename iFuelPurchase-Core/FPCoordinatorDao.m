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
#import <PEHateoas-Client/HCRelation.h>

@implementation FPCoordinatorDao {
  id<FPRemoteMasterDao> _remoteMasterDao;
  NSInteger _timeout;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  NSString *_apiResMtVersion;
  NSString *_changelogResMtVersion;
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
       ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
     ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
     loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
   accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
    bundleHoldingApiJsonResource:(NSBundle *)bundle
       nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
                 apiResMtVersion:(NSString *)apiResMtVersion
           changelogResMtVersion:(NSString *)changelogResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
             vehicleResMtVersion:(NSString *)vehicleResMtVersion
         fuelStationResMtVersion:(NSString *)fuelStationResMtVersion
     fuelPurchaseLogResMtVersion:(NSString *)fuelPurchaseLogResMtVersion
      environmentLogResMtVersion:(NSString *)environmentLogResMtVersion
               authTokenDelegate:(id<FPAuthTokenDelegate>)authTokenDelegate
        allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super initWithSqliteDataFilePath:sqliteDataFilePath];
  if (self) {
    _timeout = timeout;
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _authToken = authToken;
    _apiResMtVersion = apiResMtVersion;
    _changelogResMtVersion = changelogResMtVersion;
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
    PEUserSerializer *userSerializer =
      [self userSerializerForCharset:acceptCharset
                   vehicleSerializer:vehicleSerializer
               fuelStationSerializer:fuelStationSerializer
           fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
            environmentLogSerializer:environmentLogSerializer];
    FPChangelogSerializer *changelogSerializer = [self changelogSerializerForCharset:acceptCharset
                                                                      userSerializer:userSerializer
                                                                   vehicleSerializer:vehicleSerializer
                                                               fuelStationSerializer:fuelStationSerializer
                                                           fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
                                                            environmentLogSerializer:environmentLogSerializer];
    PELoginSerializer *loginSerializer =
      [[PELoginSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                           charset:acceptCharset
                                    userSerializer:userSerializer];
    PELogoutSerializer *logoutSerializer = [self logoutSerializerForCharset:acceptCharset];
    PEResendVerificationEmailSerializer *resendVerificationEmailSerializer = [self resendVerificationEmailSerializerForCharset:acceptCharset];
    PEPasswordResetSerializer *passwordResetSerializer = [self passwordResetSerializerForCharset:acceptCharset];
    _remoteMasterDao = [[FPRestRemoteMasterDao alloc]  initWithAcceptCharset:acceptCharset
                                                              acceptLanguage:acceptLanguage
                                                          contentTypeCharset:contentTypeCharset
                                                                  authScheme:authScheme
                                                          authTokenParamName:authTokenParamName
                                                                   authToken:authToken
                                                         errorMaskHeaderName:errorMaskHeaderName
                                                  establishSessionHeaderName:establishHeaderSessionName
                                                         authTokenHeaderName:authTokenHeaderName
                                                   ifModifiedSinceHeaderName:ifModifiedSinceHeaderName
                                                 ifUnmodifiedSinceHeaderName:ifUnmodifiedSinceHeaderName
                                                 loginFailedReasonHeaderName:loginFailedReasonHeaderName
                                               accountClosedReasonHeaderName:accountClosedReasonHeaderName
                                                bundleHoldingApiJsonResource:bundle
                                                   nameOfApiJsonResourceFile:apiResourceFileName
                                                             apiResMtVersion:apiResMtVersion
                                                         changelogSerializer:changelogSerializer
                                                              userSerializer:userSerializer
                                                             loginSerializer:loginSerializer
                                                            logoutSerializer:logoutSerializer
                                           resendVerificationEmailSerializer:resendVerificationEmailSerializer
                                                     passwordResetSerializer:passwordResetSerializer
                                                           vehicleSerializer:vehicleSerializer
                                                       fuelStationSerializer:fuelStationSerializer
                                                   fuelPurchaseLogSerializer:fuelPurchaseLogSerializer
                                                    environmentLogSerializer:environmentLogSerializer
                                                    allowInvalidCertificates:allowInvalidCertificates];
    _authTokenDelegate = authTokenDelegate;
  }
  return self;
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

- (PELogoutSerializer *)logoutSerializerForCharset:(HCCharset *)charset {
  return [[PELogoutSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                               charset:charset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}];
}

- (PEResendVerificationEmailSerializer *)resendVerificationEmailSerializerForCharset:(HCCharset *)charset {
  return [[PEResendVerificationEmailSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                                charset:charset
                                        serializersForEmbeddedResources:@{}
                                            actionsForEmbeddedResources:@{}];
}

- (PEPasswordResetSerializer *)passwordResetSerializerForCharset:(HCCharset *)charset {
  return [[PEPasswordResetSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                      charset:charset
                              serializersForEmbeddedResources:@{}
                                  actionsForEmbeddedResources:@{}];
}

- (FPChangelogSerializer *)changelogSerializerForCharset:(HCCharset *)charset
                                          userSerializer:(PEUserSerializer *)userSerializer
                                       vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
                                   fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
                               fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
                                environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer {
  HCActionForEmbeddedResource actionForEmbeddedUser = ^(FPChangelog *changelog, id embeddedUser) {
    [changelog setUser:embeddedUser];
  };
  HCActionForEmbeddedResource actionForEmbeddedVehicle = ^(FPChangelog *changelog, id embeddedVehicle) {
    [changelog addVehicle:embeddedVehicle];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelStation = ^(FPChangelog *changelog, id embeddedFuelStation) {
    [changelog addFuelStation:embeddedFuelStation];
  };
  HCActionForEmbeddedResource actionForEmbeddedFuelPurchaseLog = ^(FPChangelog *changelog, id embeddedFuelPurchaseLog) {
    [changelog addFuelPurchaseLog:embeddedFuelPurchaseLog];
  };
  HCActionForEmbeddedResource actionForEmbeddedEnvironmentLog = ^(FPChangelog *changelog, id embeddedEnvironmentLog) {
    [changelog addEnvironmentLog:embeddedEnvironmentLog];
  };
  return [[FPChangelogSerializer alloc] initWithMediaType:[FPKnownMediaTypes changelogMediaTypeWithVersion:_changelogResMtVersion]
                                                  charset:charset
                          serializersForEmbeddedResources:@{[[userSerializer mediaType] description] : userSerializer,
                                                            [[vehicleSerializer mediaType] description] : vehicleSerializer,
                                                            [[fuelStationSerializer mediaType] description] : fuelStationSerializer,
                                                            [[fuelPurchaseLogSerializer mediaType] description] : fuelPurchaseLogSerializer,
                                                            [[environmentLogSerializer mediaType] description] : environmentLogSerializer}
                              actionsForEmbeddedResources:@{[[userSerializer mediaType] description] : actionForEmbeddedUser,
                                                            [[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle,
                                                            [[fuelStationSerializer mediaType] description] : actionForEmbeddedFuelStation,
                                                            [[fuelPurchaseLogSerializer mediaType] description] : actionForEmbeddedFuelPurchaseLog,
                                                            [[environmentLogSerializer mediaType] description] : actionForEmbeddedEnvironmentLog}];
}

- (PEUserSerializer *)userSerializerForCharset:(HCCharset *)charset
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
  return [[PEUserSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                             charset:charset
                     serializersForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : vehicleSerializer,
                                                       [[fuelStationSerializer mediaType] description] : fuelStationSerializer,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : fuelPurchaseLogSerializer,
                                                       [[environmentLogSerializer mediaType] description] : environmentLogSerializer}
                         actionsForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle,
                                                       [[fuelStationSerializer mediaType] description] : actionForEmbeddedFuelStation,
                                                       [[fuelPurchaseLogSerializer mediaType] description] : actionForEmbeddedFuelPurchaseLog,
                                                       [[environmentLogSerializer mediaType] description] : actionForEmbeddedEnvironmentLog}
                                           userClass:[FPUser class]];
}

+ (void)invokeErrorBlocksForHttpStatusCode:(NSNumber *)httpStatusCode
                                     error:(NSError *)err
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk {
  if (httpStatusCode) {
    if ([[err domain] isEqualToString:FPUserFaultedErrorDomain]) {
      if ([err code] > 0) {
        if (remoteErrorBlk) remoteErrorBlk([err code]);
      } else {
        if (tempRemoteErrorBlk) tempRemoteErrorBlk();
      }
    } else {
      if (tempRemoteErrorBlk) tempRemoteErrorBlk();
    }
  } else {
    // if no http status code, then it was a connection failure, and that by nature is temporary
    if (tempRemoteErrorBlk) tempRemoteErrorBlk();
  }
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
  NSArray *vehiclesToSync = [self markVehiclesAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fuelStationsToSync = [self markFuelStationsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *fpLogsToSync = [self markFuelPurchaseLogsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *envLogsToSync = [self markEnvironmentLogsAsSyncInProgressForUser:user error:errorBlk];
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

- (NSInteger)totalNumSyncNeededEntitiesForUser:(FPUser *)user {
  return [self totalNumSyncNeededEntitiesForUser:user];
}

- (BOOL)doesUserHaveAnyUnsyncedEntities:(FPUser *)user {
  return ([self totalNumUnsyncedEntitiesForUser:user] > 0);
}

- (void)resetAsLocalUser:(FPUser *)user error:(PELMDaoErrorBlk)error {
  [self deleteUser:user error:error];
  FPUser *newLocalUser = [self newLocalUserWithError:error];
  [user overwrite:newLocalUser];
  [user setLocalMainIdentifier:[newLocalUser localMainIdentifier]];
  [user setLocalMasterIdentifier:nil];
}

- (FPUser *)newLocalUserWithError:(PELMDaoErrorBlk)errorBlk {
  FPUser *user = [self userWithName:nil email:nil password:nil];
  [self saveNewLocalUser:user error:errorBlk];
  return user;
}

- (FPUser *)userWithName:(NSString *)name
                   email:(NSString *)email
                password:(NSString *)password {
  return [FPUser userWithName:name
                        email:email
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
      [self saveNewRemoteUser:remoteUser
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

- (void)loginWithEmail:(NSString *)email
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
      [self deepSaveNewRemoteUser:remoteUser
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
  [_remoteMasterDao loginWithEmail:email
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
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
 addlCompletionBlk:(void(^)(void))addlCompletionBlk
localSaveErrorHandler:(PELMDaoErrorBlk)localSaveErrorHandler {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    // whether error or success, we're going to call the additional completion
    // block and delete the local user
    if (addlCompletionBlk) { addlCompletionBlk(); }
    [self deleteUser:user error:localSaveErrorHandler];
    _authToken = nil;
  };
  [_remoteMasterDao logoutUser:user
                       timeout:_timeout
               remoteStoreBusy:remoteStoreBusyBlk
             completionHandler:masterStoreComplHandler];
}

- (void)resendVerificationEmailForUser:(FPUser *)user
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            successBlk:(void(^)(void))successBlk
                              errorBlk:(void(^)(void))errorBlk {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    if (isConflict ||
        gone ||
        notFound ||
        movedPermanently ||
        ![PEUtils isNil:err]) {
      errorBlk();
    } else {
      successBlk();
    }
  };
  [_remoteMasterDao resendVerificationEmailForUser:user
                                           timeout:_timeout
                                   remoteStoreBusy:remoteStoreBusyBlk
                                 completionHandler:masterStoreComplHandler];
}

- (void)sendPasswordResetEmailToEmail:(NSString *)email
                   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                           successBlk:(void(^)(void))successBlk
                      unknownEmailBlk:(void(^)(void))unknownEmailBlk
                             errorBlk:(void(^)(void))errorBlk {
  PELMRemoteMasterCompletionHandler masterStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL isConflict, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    if (isConflict ||
        gone ||
        notFound ||
        movedPermanently) {
      errorBlk();
    } else if (![PEUtils isNil:err]) {
      if ([err code] & FPSendPasswordResetUnknownEmail) {
        unknownEmailBlk();
      } else {
        errorBlk();
      }
    } else {
      successBlk();
    }
  };
  [_remoteMasterDao sendPasswordResetEmailToEmail:email
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyBlk
                                completionHandler:masterStoreComplHandler];
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
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:user
                                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                        [self cancelSyncForUser:user httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                       error:err
                                                                      tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                          remoteErrorBlk:addlRemoteErrorBlk];
                                      }
                                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                        markAsConflictBlk:^(FPUser *serverUser) {
                                          [self cancelSyncForUser:user httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                          if (addlConflictBlk) { addlConflictBlk(serverUser); }
                                        }
                        markAsSyncCompleteForNewEntityBlk:nil // because new users are always immediately synced upon creation
                   markAsSyncCompleteForExistingEntityBlk:^{
                     [self markAsSyncCompleteForUser:user error:errorBlk];
                     if (addlSuccessBlk) { addlSuccessBlk(); }
                   }
                                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao saveExistingUser:user
                             timeout:_timeout
                     remoteStoreBusy:^(NSDate *retryAt) {
                       [self cancelSyncForUser:user httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
                       if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
                     }
                        authRequired:^(HCAuthentication *auth) {
                          [self authReqdBlk](auth);
                          [self cancelSyncForUser:(FPUser *)user httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                        }
                   completionHandler:remoteStoreComplHandler];
}

- (void)markAsDoneEditingAndSyncUserImmediate:(FPUser *)user
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                               addlSuccessBlk:(void(^)(void))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                              addlConflictBlk:(void(^)(FPUser *))addlConflictBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                        error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncUser:user error:errorBlk];
  [self flushUnsyncedChangesToUser:user
               notFoundOnServerBlk:notFoundOnServerBlk
                    addlSuccessBlk:addlSuccessBlk
            addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                addlRemoteErrorBlk:addlRemoteErrorBlk
                   addlConflictBlk:addlConflictBlk
               addlAuthRequiredBlk:addlAuthRequiredBlk
                             error:errorBlk];
}

- (void)deleteUser:(FPUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
    addlSuccessBlk:(void(^)(void))addlSuccessBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
    remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
       conflictBlk:(void(^)(FPUser *))conflictBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
             error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:user
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      tempRemoteErrorBlk:tempRemoteErrorBlk
                                                          remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPUser *serverUser) { if (conflictBlk) { conflictBlk(serverUser); } }
                         deleteSuccessBlk:^{
                           [self deleteUser:user error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteUser:user
                       timeout:_timeout
               remoteStoreBusy:^(NSDate *retryAfter) { if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAfter); } }
                  authRequired:^(HCAuthentication *auth) {
                    [self authReqdBlk](auth);
                    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                  }
             completionHandler:remoteStoreComplHandler];
}

- (void)fetchUser:(FPUser *)user
  ifModifiedSince:(NSDate *)ifModifiedSince
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
       successBlk:(void(^)(FPUser *))successBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:user.globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPUser *fetchedUser) {
                                    if (successBlk) { successBlk(fetchedUser); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchUserWithGlobalId:user.globalIdentifier
                          ifModifiedSince:ifModifiedSince
                                  timeout:_timeout
                          remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                             authRequired:^(HCAuthentication *auth) {
                               [self authReqdBlk](auth);
                               if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                             }
                        completionHandler:remoteStoreComplHandler];
}

- (void)fetchChangelogForUser:(FPUser *)user
              ifModifiedSince:(NSDate *)ifModifiedSince
          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                   successBlk:(void(^)(FPChangelog *))successBlk
           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  HCRelation *changelogRelation = [[user relations] objectForKey:FPChangelogRelation];
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:changelogRelation.target.uri.absoluteString
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPChangelog *fetchedChangelog) {
                                    if (successBlk) { successBlk(fetchedChangelog); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchChangelogWithGlobalId:changelogRelation.target.uri.absoluteString
                               ifModifiedSince:ifModifiedSince
                                       timeout:_timeout
                               remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                  authRequired:^(HCAuthentication *auth) {
                                    [self authReqdBlk](auth);
                                    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                  }
                             completionHandler:remoteStoreComplHandler];
}

#pragma mark - Vehicle

- (FPVehicle *)vehicleWithName:(NSString *)name
                 defaultOctane:(NSNumber *)defaultOctane
                  fuelCapacity:(NSDecimalNumber *)fuelCapacity
                      isDiesel:(BOOL)isDiesel
                 hasDteReadout:(BOOL)hasDteReadout
                 hasMpgReadout:(BOOL)hasMpgReadout
                 hasMphReadout:(BOOL)hasMphReadout
         hasOutsideTempReadout:(BOOL)hasOutsideTempReadout
                           vin:(NSString *)vin
                         plate:(NSString *)plate {
  return [FPVehicle vehicleWithName:name
                      defaultOctane:defaultOctane
                       fuelCapacity:fuelCapacity
                           isDiesel:isDiesel
                      hasDteReadout:hasDteReadout
                      hasMpgReadout:hasMpgReadout
                      hasMphReadout:hasMphReadout
              hasOutsideTempReadout:hasOutsideTempReadout
                                vin:vin
                              plate:plate
                          mediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:_vehicleResMtVersion]];
}

- (void)saveNewAndSyncImmediateVehicle:(FPVehicle *)vehicle
                               forUser:(FPUser *)user
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(void))addlSuccessBlk
                addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                    addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                       addlConflictBlk:(void(^)(id))addlConflictBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewAndSyncImmediateVehicle:vehicle forUser:user error:errorBlk];
  [self flushUnsyncedChangesToVehicle:vehicle
                              forUser:user
                  notFoundOnServerBlk:notFoundOnServerBlk
                       addlSuccessBlk:addlSuccessBlk
               addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
               addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                   addlRemoteErrorBlk:addlRemoteErrorBlk
                      addlConflictBlk:addlConflictBlk
                  addlAuthRequiredBlk:addlAuthRequiredBlk
                                error:errorBlk];
}

/*- (BOOL)prepareVehicleForEdit:(FPVehicle *)vehicle forUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self prepareVehicleForEdit:vehicle forUser:user error:errorBlk];
}

- (void)saveVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self saveVehicle:vehicle error:errorBlk];
}*/

/*- (void)markAsDoneEditingVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingVehicle:vehicle error:errorBlk];
}*/

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
  if ([vehicle synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
    [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:vehicle
                                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                        [self cancelSyncForVehicle:vehicle httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                       error:err
                                                                      tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                          remoteErrorBlk:addlRemoteErrorBlk];
                                      }
                                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                        markAsConflictBlk:^(FPVehicle *latestVehicle) {
                                          [self cancelSyncForVehicle:vehicle httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                          if (addlConflictBlk) { addlConflictBlk(latestVehicle); }
                                        }
                        markAsSyncCompleteForNewEntityBlk:^{
                          [self markAsSyncCompleteForNewVehicle:vehicle forUser:user error:errorBlk];
                          if (addlSuccessBlk) { addlSuccessBlk(); }
                        }
                   markAsSyncCompleteForExistingEntityBlk:^{
                     [self markAsSyncCompleteForUpdatedVehicle:vehicle error:errorBlk];
                     if (addlSuccessBlk) { addlSuccessBlk(); }
                   }
                                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForVehicle:vehicle httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [self authReqdBlk](auth);
    [self cancelSyncForVehicle:vehicle httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };  
  if ([vehicle globalIdentifier]) {
    [_remoteMasterDao saveExistingVehicle:vehicle
                                  timeout:_timeout
                          remoteStoreBusy:remoteStoreBusyBlk
                             authRequired:authRequiredBlk
                        completionHandler:complHandler];
  } else {
    [_remoteMasterDao saveNewVehicle:vehicle
                             forUser:user
                             timeout:_timeout
                     remoteStoreBusy:remoteStoreBusyBlk
                        authRequired:authRequiredBlk
                   completionHandler:complHandler];
  }
}

- (void)markAsDoneEditingAndSyncVehicleImmediate:(FPVehicle *)vehicle
                                         forUser:(FPUser *)user
                             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      addlSuccessBlk:(void(^)(void))successBlk
                              addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                              addlTempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                                  addlRemoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                                     addlConflictBlk:(void(^)(FPVehicle *))conflictBlk
                                 addlAuthRequiredBlk:(void(^)(void))authRequiredBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncVehicle:vehicle error:errorBlk];
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
   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
   tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
       remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
          conflictBlk:(void(^)(FPVehicle *))addlConflictBlk
  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:vehicle
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      tempRemoteErrorBlk:tempRemoteErrorBlk
                                                          remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPVehicle *serverVehicle) { if (addlConflictBlk) { addlConflictBlk(serverVehicle); } }
                         deleteSuccessBlk:^{
                           [self deleteVehicle:vehicle error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteVehicle:vehicle
                          timeout:_timeout
                  remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                     authRequired:^(HCAuthentication *auth) {
                       [self authReqdBlk](auth);
                       if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                     }
                completionHandler:remoteStoreComplHandler];
}

- (void)fetchVehicleWithGlobalId:(NSString *)globalIdentifier
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         forUser:(FPUser *)user
             notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                      successBlk:(void(^)(FPVehicle *))successBlk
              remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
              tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
             addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPVehicle *fetchedVehicle) {
                                    if (successBlk) { successBlk(fetchedVehicle); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchVehicleWithGlobalId:globalIdentifier
                             ifModifiedSince:ifModifiedSince
                                     timeout:_timeout
                             remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                authRequired:^(HCAuthentication *auth) {
                                  [self authReqdBlk](auth);
                                  if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                }
                           completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewVehicleWithGlobalId:(NSString *)globalIdentifier
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(FPVehicle *))addlSuccessBlk
                        remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self fetchVehicleWithGlobalId:globalIdentifier
                 ifModifiedSince:nil
                         forUser:user
             notFoundOnServerBlk:notFoundOnServerBlk
                      successBlk:^(FPVehicle *fetchedVehicle) {
                        [self saveNewMasterVehicle:fetchedVehicle forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(fetchedVehicle); }
                      }
              remoteStoreBusyBlk:remoteStoreBusyBlk
              tempRemoteErrorBlk:tempRemoteErrorBlk
             addlAuthRequiredBlk:addlAuthRequiredBlk];
}

/*- (void)reloadVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self reloadVehicle:vehicle error:errorBlk];
}

- (void)cancelEditOfVehicle:(FPVehicle *)vehicle error:(PELMDaoErrorBlk)errorBlk {
  [self cancelEditOfVehicle:vehicle error:errorBlk];
}*/

#pragma mark - Fuel Station

/*- (NSInteger)numFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelStationsForUser:user error:errorBlk];
}*/

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

/*- (NSArray *)fuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelStationsForUser:user error:errorBlk];
}

- (NSArray *)unsyncedFuelStationsForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self unsyncedFuelStationsForUser:user error:errorBlk];
}

- (FPUser *)userForFuelStation:(FPFuelStation *)fuelStation error:(PELMDaoErrorBlk)errorBlk {
  return [self userForFuelStation:fuelStation error:errorBlk];
}

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation forUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewFuelStation:fuelStation forUser:user error:errorBlk];
}*/

- (void)saveNewAndSyncImmediateFuelStation:(FPFuelStation *)fuelStation
                                   forUser:(FPUser *)user
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(void))addlSuccessBlk
                    addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                    addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                           addlConflictBlk:(void(^)(id))addlConflictBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewAndSyncImmediateFuelStation:fuelStation forUser:user error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:addlSuccessBlk
                   addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:addlRemoteErrorBlk
                          addlConflictBlk:addlConflictBlk
                      addlAuthRequiredBlk:addlAuthRequiredBlk
                                    error:errorBlk];
}

/*- (BOOL)prepareFuelStationForEdit:(FPFuelStation *)fuelStation
                          forUser:(FPUser *)user
                            error:(PELMDaoErrorBlk)errorBlk {
  return [self prepareFuelStationForEdit:fuelStation
                                      forUser:user
                                        error:errorBlk];
}

- (void)saveFuelStation:(FPFuelStation *)fuelStation
                  error:(PELMDaoErrorBlk)errorBlk {
  [self saveFuelStation:fuelStation
                       error:errorBlk];
}

- (void)markAsDoneEditingFuelStation:(FPFuelStation *)fuelStation
                               error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingFuelStation:fuelStation
                                    error:errorBlk];
}*/

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
  if ([fuelStation synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:fuelStation
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForFuelStation:fuelStation httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPFuelStation *latestFuelStation) {
                                        [self cancelSyncForFuelStation:fuelStation httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestFuelStation); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewFuelStation:fuelStation forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedFuelStation:fuelStation error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForFuelStation:fuelStation httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [self authReqdBlk](auth);
    [self cancelSyncForFuelStation:fuelStation httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([fuelStation globalIdentifier]) {
    [_remoteMasterDao saveExistingFuelStation:fuelStation
                                      timeout:_timeout
                              remoteStoreBusy:remoteStoreBusyBlk
                                 authRequired:authRequiredBlk
                            completionHandler:complHandler];
  } else {
    [_remoteMasterDao saveNewFuelStation:fuelStation
                                 forUser:user
                                 timeout:_timeout
                         remoteStoreBusy:remoteStoreBusyBlk
                            authRequired:authRequiredBlk
                       completionHandler:complHandler];
  }
}

- (void)markAsDoneEditingAndSyncFuelStationImmediate:(FPFuelStation *)fuelStation
                                             forUser:(FPUser *)user
                                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                      addlSuccessBlk:(void(^)(void))addlSuccessBlk
                              addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                              addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                  addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                     addlConflictBlk:(void(^)(FPFuelStation *))addlConflictBlk
                                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                               error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncFuelStation:fuelStation error:errorBlk];
  [self flushUnsyncedChangesToFuelStation:fuelStation
                                  forUser:user
                      notFoundOnServerBlk:notFoundOnServerBlk
                           addlSuccessBlk:addlSuccessBlk
                   addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                   addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                       addlRemoteErrorBlk:addlRemoteErrorBlk
                          addlConflictBlk:addlConflictBlk
                      addlAuthRequiredBlk:addlAuthRequiredBlk
                                    error:errorBlk];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  forUser:(FPUser *)user
      notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
           addlSuccessBlk:(void(^)(void))addlSuccessBlk
       remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
       tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
           remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
              conflictBlk:(void(^)(FPFuelStation *))conflictBlk
      addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                    error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:fuelStation
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                      tempRemoteErrorBlk:tempRemoteErrorBlk
                                                          remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPFuelStation *serverFuelstation) { if (conflictBlk) { conflictBlk(serverFuelstation); } }
                         deleteSuccessBlk:^{
                           [self deleteFuelstation:fuelStation error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteFuelStation:fuelStation
                              timeout:_timeout
                      remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                         authRequired:^(HCAuthentication *auth) {
                           [self authReqdBlk](auth);
                           if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                         }
                    completionHandler:remoteStoreComplHandler];
}

- (void)fetchFuelstationWithGlobalId:(NSString *)globalIdentifier
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             forUser:(FPUser *)user
                 notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                          successBlk:(void(^)(FPFuelStation *))successBlk
                  remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                  tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                 addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPFuelStation *fetchedFuelstation) {
                                    if (successBlk) { successBlk(fetchedFuelstation); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchFuelstationWithGlobalId:globalIdentifier
                                 ifModifiedSince:ifModifiedSince
                                         timeout:_timeout
                                 remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                    authRequired:^(HCAuthentication *auth) {
                                      [self authReqdBlk](auth);
                                      if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                    }
                               completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewFuelstationWithGlobalId:(NSString *)globalIdentifier
                                       forUser:(FPUser *)user
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                addlSuccessBlk:(void(^)(FPFuelStation *))addlSuccessBlk
                            remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                            tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                           addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                         error:(PELMDaoErrorBlk)errorBlk {
  [self fetchFuelstationWithGlobalId:globalIdentifier
                     ifModifiedSince:nil
                             forUser:user
                 notFoundOnServerBlk:notFoundOnServerBlk
                          successBlk:^(FPFuelStation *fetchedFuelstation) {
                            [self saveNewMasterFuelstation:fetchedFuelstation forUser:user error:errorBlk];
                            if (addlSuccessBlk) addlSuccessBlk(fetchedFuelstation);
                          }
                  remoteStoreBusyBlk:remoteStoreBusyBlk
                  tempRemoteErrorBlk:tempRemoteErrorBlk
                 addlAuthRequiredBlk:addlAuthRequiredBlk];  
}

/*- (void)reloadFuelStation:(FPFuelStation *)fuelStation
                    error:(PELMDaoErrorBlk)errorBlk {
  [self reloadFuelStation:fuelStation error:errorBlk];
}

- (void)cancelEditOfFuelStation:(FPFuelStation *)fuelStation
                          error:(PELMDaoErrorBlk)errorBlk {
  [self cancelEditOfFuelStation:fuelStation
                               error:errorBlk];
}*/

#pragma mark - Fuel Purchase Log

/*- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForUser:user error:errorBlk];
}*/

/*- (NSInteger)numFuelPurchaseLogsForUser:(FPUser *)user
                              newerThan:(NSDate *)newerThan
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForUser:user
                                     newerThan:newerThan
                                         error:errorBlk];
}*/

- (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                            odometer:(NSDecimalNumber *)odometer
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             logDate:(NSDate *)logDate
                                            isDiesel:(BOOL)isDiesel {
  return [FPFuelPurchaseLog fuelPurchaseLogWithNumGallons:numGallons
                                                   octane:octane
                                                 odometer:odometer
                                              gallonPrice:gallonPrice
                                               gotCarWash:gotCarWash
                                 carWashPerGallonDiscount:carWashPerGallonDiscount
                                              purchasedAt:logDate
                                                 isDiesel:isDiesel
                                                mediaType:[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:_fuelPurchaseLogResMtVersion]];
}

/*- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                              pageSize:pageSize
                      beforeDateLogged:nil
                                 error:errorBlk];
}

- (NSArray *)unsyncedFuelPurchaseLogsForUser:(FPUser *)user
                                       error:(PELMDaoErrorBlk)errorBlk {
  return [self unsyncedFuelPurchaseLogsForUser:user error:errorBlk];
}

- (NSArray *)fuelPurchaseLogsForUser:(FPUser *)user
                            pageSize:(NSInteger)pageSize
                    beforeDateLogged:(NSDate *)beforeDateLogged
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelPurchaseLogsForUser:user
                                   pageSize:pageSize
                           beforeDateLogged:beforeDateLogged
                                      error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForVehicle:vehicle error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForVehicle:(FPVehicle *)vehicle
                                 newerThan:(NSDate *)newerThan
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForVehicle:vehicle
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
  return [self fuelPurchaseLogsForVehicle:vehicle
                                      pageSize:pageSize
                              beforeDateLogged:beforeDateLogged
                                         error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForFuelStation:fuelStation error:errorBlk];
}

- (NSInteger)numFuelPurchaseLogsForFuelStation:(FPFuelStation *)fuelStation
                                     newerThan:(NSDate *)newerThan
                                         error:(PELMDaoErrorBlk)errorBlk {
  return [self numFuelPurchaseLogsForFuelStation:fuelStation
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
  return [self fuelPurchaseLogsForFuelStation:fuelStation
                                          pageSize:pageSize
                                  beforeDateLogged:beforeDateLogged
                                             error:errorBlk];
}

- (FPVehicle *)vehicleForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self vehicleForFuelPurchaseLog:fpLog error:errorBlk];
}

- (FPFuelStation *)fuelStationForFuelPurchaseLog:(FPFuelPurchaseLog *)fpLog
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self fuelStationForFuelPurchaseLog:fpLog error:errorBlk];
}

- (FPVehicle *)vehicleForMostRecentFuelPurchaseLogForUser:(FPUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self vehicleForMostRecentFuelPurchaseLogForUser:user error:errorBlk];
}

- (FPFuelStation *)defaultFuelStationForNewFuelPurchaseLogForUser:(FPUser *)user
                                                  currentLocation:(CLLocation *)currentLocation
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return [self defaultFuelStationForNewFuelPurchaseLogForUser:user
                                                   currentLocation:currentLocation
                                                             error:errorBlk];
}

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       vehicle:(FPVehicle *)vehicle
                   fuelStation:(FPFuelStation *)fuelStation
                         error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewFuelPurchaseLog:fuelPurchaseLog
                            forUser:user
                            vehicle:vehicle
                        fuelStation:fuelStation
                              error:errorBlk];
}*/

- (void)saveNewAndSyncImmediateFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                       forUser:(FPUser *)user
                                       vehicle:(FPVehicle *)vehicle
                                   fuelStation:(FPFuelStation *)fuelStation
                           notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                    addlSuccessBlk:(void(^)(void))addlSuccessBlk
                            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                   addlConflictBlk:(void(^)(id))addlConflictBlk
                               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                  skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
              skippedDueToFuelStationNotSynced:(void(^)(void))skippedDueToFuelStationNotSynced
                                         error:(PELMDaoErrorBlk)errorBlk {
  
  if ([vehicle globalIdentifier]) {
    if ([fuelStation globalIdentifier]) {
      [self saveNewAndSyncImmediateFuelPurchaseLog:fuelPurchaseLog
                                                forUser:user
                                                vehicle:vehicle
                                            fuelStation:fuelStation
                                                  error:errorBlk];
      [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                          forUser:user
                              notFoundOnServerBlk:notFoundOnServerBlk
                                   addlSuccessBlk:addlSuccessBlk
                           addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                           addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                               addlRemoteErrorBlk:addlRemoteErrorBlk
                                  addlConflictBlk:addlConflictBlk
                              addlAuthRequiredBlk:addlAuthRequiredBlk
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

/*- (BOOL)prepareFuelPurchaseLogForEdit:(FPFuelPurchaseLog *)fuelPurchaseLog
                              forUser:(FPUser *)user
                                error:(PELMDaoErrorBlk)errorBlk {
  return [self prepareFuelPurchaseLogForEdit:fuelPurchaseLog
                                          forUser:user
                                            error:errorBlk];
}

- (void)saveFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                    forUser:(FPUser *)user
                    vehicle:(FPVehicle *)vehicle
                fuelStation:(FPFuelStation *)fuelStation
                      error:(PELMDaoErrorBlk)errorBlk {
  [self saveFuelPurchaseLog:fuelPurchaseLog
                         forUser:user
                         vehicle:vehicle
                     fuelStation:fuelStation
                           error:errorBlk];
}

- (void)markAsDoneEditingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                                   error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingFuelPurchaseLog:fuelPurchaseLog
                                        error:errorBlk];
}*/

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
  FPVehicle *vehicleForFpLog = [self vehicleForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  FPFuelStation *fuelStationForFpLog = [self fuelStationForFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [fuelPurchaseLog setVehicleGlobalIdentifier:[vehicleForFpLog globalIdentifier]];
  [fuelPurchaseLog setFuelStationGlobalIdentifier:[fuelStationForFpLog globalIdentifier]];
  if ([vehicleForFpLog globalIdentifier] == nil) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([fuelStationForFpLog globalIdentifier] == nil) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToFuelStationNotSynced();
    return;
  }
  if ([fuelPurchaseLog synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:fuelPurchaseLog
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPFuelPurchaseLog *latestFplog) {
                                        [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestFplog); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewFuelPurchaseLog:fuelPurchaseLog forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [self authReqdBlk](auth);
    [self cancelSyncForFuelPurchaseLog:fuelPurchaseLog httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([fuelPurchaseLog globalIdentifier]) {
    [_remoteMasterDao saveExistingFuelPurchaseLog:fuelPurchaseLog
                                          timeout:_timeout
                                  remoteStoreBusy:remoteStoreBusyBlk
                                     authRequired:authRequiredBlk
                                completionHandler:remoteStoreComplHandler];
  } else {
    [_remoteMasterDao saveNewFuelPurchaseLog:fuelPurchaseLog
                                     forUser:user
                                     timeout:_timeout
                             remoteStoreBusy:remoteStoreBusyBlk
                                authRequired:authRequiredBlk
                           completionHandler:remoteStoreComplHandler];
  }
}

- (void)markAsDoneEditingAndSyncFuelPurchaseLogImmediate:(FPFuelPurchaseLog *)fuelPurchaseLog
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
  [self markAsDoneEditingImmediateSyncFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
  [self flushUnsyncedChangesToFuelPurchaseLog:fuelPurchaseLog
                                      forUser:user
                          notFoundOnServerBlk:notFoundOnServerBlk
                               addlSuccessBlk:addlSuccessBlk
                       addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:addlRemoteErrorBlk
                              addlConflictBlk:addlConflictBlk
                          addlAuthRequiredBlk:addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
             skippedDueToFuelStationNotSynced:skippedDueToFuelStationNotSynced
                                        error:errorBlk];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fplog
                      forUser:(FPUser *)user
          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
               addlSuccessBlk:(void(^)(void))addlSuccessBlk
           remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
           tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
               remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                  conflictBlk:(void(^)(FPFuelPurchaseLog *))conflictBlk
          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                        error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:fplog
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                          tempRemoteErrorBlk:tempRemoteErrorBlk
                                                              remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPFuelPurchaseLog *serverFplog) { if (conflictBlk) { conflictBlk(serverFplog); } }
                         deleteSuccessBlk:^{
                           [self deleteFuelPurchaseLog:fplog error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteFuelPurchaseLog:fplog
                                  timeout:_timeout
                          remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                             authRequired:^(HCAuthentication *auth) {
                               [self authReqdBlk](auth);
                               if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                             }
                        completionHandler:remoteStoreComplHandler];
}

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalIdentifier
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 forUser:(FPUser *)user
                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              successBlk:(void(^)(FPFuelPurchaseLog *))successBlk
                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPFuelPurchaseLog *fetchedFplog) {
                                    if (successBlk) { successBlk(fetchedFplog); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchFuelPurchaseLogWithGlobalId:globalIdentifier
                                     ifModifiedSince:ifModifiedSince
                                             timeout:_timeout
                                     remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                        authRequired:^(HCAuthentication *auth) {
                                          [self authReqdBlk](auth);
                                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                        }
                                   completionHandler:remoteStoreComplHandler];
}

/*- (void)reloadFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                        error:(PELMDaoErrorBlk)errorBlk {
  [self reloadFuelPurchaseLog:fuelPurchaseLog error:errorBlk];
}

- (void)cancelEditOfFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                              error:(PELMDaoErrorBlk)errorBlk {
  [self cancelEditOfFuelPurchaseLog:fuelPurchaseLog
                                   error:errorBlk];
}*/

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

/*- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self numEnvironmentLogsForUser:user error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForUser:(FPUser *)user
                             newerThan:(NSDate *)newerThan
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self numEnvironmentLogsForUser:user
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
  return [self environmentLogsForUser:user
                                  pageSize:pageSize
                          beforeDateLogged:beforeDateLogged
                                     error:errorBlk];
}

- (NSArray *)unsyncedEnvironmentLogsForUser:(FPUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  return [self unsyncedEnvironmentLogsForUser:user error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self numEnvironmentLogsForVehicle:vehicle error:errorBlk];
}

- (NSInteger)numEnvironmentLogsForVehicle:(FPVehicle *)vehicle
                                newerThan:(NSDate *)newerThan
                                    error:(PELMDaoErrorBlk)errorBlk {
  return [self numEnvironmentLogsForVehicle:vehicle
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
  return [self environmentLogsForVehicle:vehicle
                                     pageSize:pageSize
                             beforeDateLogged:beforeDateLogged
                                        error:errorBlk];
}

- (FPVehicle *)vehicleForEnvironmentLog:(FPEnvironmentLog *)fpLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  return [self vehicleForEnvironmentLog:fpLog error:errorBlk];
}

- (FPVehicle *)defaultVehicleForNewEnvironmentLogForUser:(FPUser *)user
                                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self defaultVehicleForNewEnvironmentLogForUser:user error:errorBlk];
}

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      vehicle:(FPVehicle *)vehicle
                        error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewEnvironmentLog:environmentLog
                           forUser:user
                           vehicle:vehicle
                             error:errorBlk];
}*/

- (void)saveNewAndSyncImmediateEnvironmentLog:(FPEnvironmentLog *)envLog
                                      forUser:(FPUser *)user
                                      vehicle:(FPVehicle *)vehicle
                          notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                               addlSuccessBlk:(void(^)(void))addlSuccessBlk
                       addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                       addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                           addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                              addlConflictBlk:(void(^)(id))addlConflictBlk
                          addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 skippedDueToVehicleNotSynced:(void(^)(void))skippedDueToVehicleNotSynced
                                        error:(PELMDaoErrorBlk)errorBlk {
  if ([vehicle globalIdentifier]) {
    [self saveNewAndSyncImmediateEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    [self flushUnsyncedChangesToEnvironmentLog:envLog
                                       forUser:user
                           notFoundOnServerBlk:notFoundOnServerBlk
                                addlSuccessBlk:addlSuccessBlk
                        addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                        addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                            addlRemoteErrorBlk:addlRemoteErrorBlk
                               addlConflictBlk:addlConflictBlk
                           addlAuthRequiredBlk:addlAuthRequiredBlk
                  skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                         error:errorBlk];
  } else {
    [self saveNewEnvironmentLog:envLog forUser:user vehicle:vehicle error:errorBlk];
    skippedDueToVehicleNotSynced();
  }
}

/*- (BOOL)prepareEnvironmentLogForEdit:(FPEnvironmentLog *)environmentLog
                             forUser:(FPUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  return [self prepareEnvironmentLogForEdit:environmentLog
                                         forUser:user
                                           error:errorBlk];
}

- (void)saveEnvironmentLog:(FPEnvironmentLog *)environmentLog
                   forUser:(FPUser *)user
                   vehicle:(FPVehicle *)vehicle
                     error:(PELMDaoErrorBlk)errorBlk {
  [self saveEnvironmentLog:environmentLog
                        forUser:user
                        vehicle:vehicle
                          error:errorBlk];
}

- (void)markAsDoneEditingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                                  error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingEnvironmentLog:environmentLog
                                       error:errorBlk];
}*/

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
  FPVehicle *vehicleForEnvLog = [self vehicleForEnvironmentLog:environmentLog error:errorBlk];
  [environmentLog setVehicleGlobalIdentifier:[vehicleForEnvLog globalIdentifier]];
  if ([vehicleForEnvLog globalIdentifier] == nil) {
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:nil errorMask:nil retryAt:nil error:errorBlk];
    skippedDueToVehicleNotSynced();
    return;
  }
  if ([environmentLog synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:environmentLog
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                     error:err
                                                                    tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                        remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                      markAsConflictBlk:^(FPEnvironmentLog *latestEnvlog) {
                                        [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(409) errorMask:nil retryAt:nil error:errorBlk];
                                        if (addlConflictBlk) { addlConflictBlk(latestEnvlog); }
                                      }
                      markAsSyncCompleteForNewEntityBlk:^{
                        [self markAsSyncCompleteForNewEnvironmentLog:environmentLog forUser:user error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^{
                   [self markAsSyncCompleteForUpdatedEnvironmentLog:environmentLog error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [self authReqdBlk](auth);
    [self cancelSyncForEnvironmentLog:environmentLog httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  if ([environmentLog globalIdentifier]) {
    [_remoteMasterDao saveExistingEnvironmentLog:environmentLog
                                         timeout:_timeout
                                 remoteStoreBusy:remoteStoreBusyBlk
                                    authRequired:authRequiredBlk
                               completionHandler:remoteStoreComplHandler];
  } else {
    [_remoteMasterDao saveNewEnvironmentLog:environmentLog
                                    forUser:user
                                    timeout:_timeout
                            remoteStoreBusy:remoteStoreBusyBlk
                               authRequired:authRequiredBlk
                          completionHandler:remoteStoreComplHandler];
  }
}

- (void)markAsDoneEditingAndSyncEnvironmentLogImmediate:(FPEnvironmentLog *)envLog
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
  [self markAsDoneEditingImmediateSyncEnvironmentLog:envLog error:errorBlk];
  [self flushUnsyncedChangesToEnvironmentLog:envLog
                                     forUser:user
                         notFoundOnServerBlk:notFoundOnServerBlk
                              addlSuccessBlk:addlSuccessBlk
                      addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:addlRemoteErrorBlk
                             addlConflictBlk:addlConflictBlk
                         addlAuthRequiredBlk:addlAuthRequiredBlk
                skippedDueToVehicleNotSynced:skippedDueToVehicleNotSynced
                                       error:errorBlk];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)envlog
                     forUser:(FPUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
              addlSuccessBlk:(void(^)(void))addlSuccessBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
              remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                 conflictBlk:(void(^)(FPEnvironmentLog *))conflictBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                       error:(PELMDaoErrorBlk)errorBlk {
    PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
    [PELMUtils complHandlerToDeleteEntity:envlog
                      remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                        [FPCoordinatorDao invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                       error:err
                                                          tempRemoteErrorBlk:tempRemoteErrorBlk
                                                              remoteErrorBlk:remoteErrorBlk];
                      }
                        entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                        markAsConflictBlk:^(FPEnvironmentLog *serverEnvlog) { if (conflictBlk) { conflictBlk(serverEnvlog); } }
                         deleteSuccessBlk:^{
                           [self deleteEnvironmentLog:envlog error:errorBlk];
                           if (addlSuccessBlk) { addlSuccessBlk(); }
                         }
                          newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteEnvironmentLog:envlog
                                 timeout:_timeout
                         remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                            authRequired:^(HCAuthentication *auth) {
                              [self authReqdBlk](auth);
                              if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                            }
                       completionHandler:remoteStoreComplHandler];
}

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalIdentifier
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                forUser:(FPUser *)user
                    notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                             successBlk:(void(^)(FPEnvironmentLog *))successBlk
                     remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                     tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                    addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(FPEnvironmentLog *fetchedEnvlog) {
                                    if (successBlk) { successBlk(fetchedEnvlog); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[self processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchEnvironmentLogWithGlobalId:globalIdentifier
                                    ifModifiedSince:ifModifiedSince
                                            timeout:_timeout
                                    remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                       authRequired:^(HCAuthentication *auth) {
                                          [self authReqdBlk](auth);
                                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                        }
                                  completionHandler:remoteStoreComplHandler];
}

/*- (void)reloadEnvironmentLog:(FPEnvironmentLog *)environmentLog
                       error:(PELMDaoErrorBlk)errorBlk {
  [self reloadEnvironmentLog:environmentLog error:errorBlk];
}

- (void)cancelEditOfEnvironmentLog:(FPEnvironmentLog *)environmentLog
                             error:(PELMDaoErrorBlk)errorBlk {
  [self cancelEditOfEnvironmentLog:environmentLog
                                  error:errorBlk];
}*/

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
