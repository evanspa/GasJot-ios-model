//
//  FPCoordDaoTestContext.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 1/5/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import "FPCoordDaoTestContext.h"
#import "PELMDDL.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEWire-Control/PEHttpResponseSimulator.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <UIKit/UIDevice.h>
#import "FPAuthTokenDelegateForTesting.h"
#import <fuelpurchase-common/FPTransactionCodes.h>
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import "FPLogging.h"

NSInteger const FPBackgroundActorId = 0;
NSInteger const FPForegroundActorId = 1;

@implementation FPCoordDaoTestContext {
  __block BOOL _authTokenReceived;
  __block BOOL _authRequired;
  __block NSString *_authToken;
  __block HCAuthentication *_authentication;
  __block BOOL _errorDeletingUser;
  __block BOOL _localSaveError;
  __block BOOL _localDaoErrDuringBgProcessing;
  __block BOOL _errorFetchingVehicles;
  __block BOOL _remoteStoreBusy;
  __block BOOL _success;
  __block BOOL _generalComplError;
  __block BOOL _localFetchError;
  __block NSTimer *_timerForAsyncWork;
  __block BOOL _prepareForEditEntityBeingSynced;
  __block BOOL _prepareForEditEntityDeleted;
  __block BOOL _prepareForEditEntityInConflict;
  __block BOOL _prepareForEditEntityBeingEditedByOtherActor;
  __block NSNumber *_prepareForEditEntityBeingEditedByOtherActorId;
  NSBundle *_testBundle;
}

#pragma mark - Initializers

- (id)initWithTestBundle:(NSBundle *)testBundle {
  self = [super init];
  if (self) {
    _testBundle = testBundle;
    _timerForAsyncWork = nil;
  }
  return self;
}

#pragma mark - Test Helpers

- (FPCoordTestingFlusher)newFlusherWithCoordDao:(FPCoordinatorDao *)coordDao {
  return ^(NSInteger waitInterval) {
    [coordDao asynchronousWorkSynchronously:[self newLocalFetchErrBlkMaker]()];
    [NSThread sleepForTimeInterval:waitInterval];
  };
}

- (FPCoordTestingMocker)newMocker {
  return ^(NSString *mockResponseFile, NSInteger reqLatency, NSInteger respLatency) {
    NSStringEncoding enc;
    NSError *err;
    NSString *path =
    [_testBundle
     pathForResource:mockResponseFile
              ofType:@"xml"
         inDirectory:@"http-mock-responses"];
    [PEHttpResponseSimulator
      simulateResponseFromXml:[NSString stringWithContentsOfFile:path
                                                    usedEncoding:&enc
                                                           error:&err]
               requestLatency:reqLatency
              responseLatency:respLatency];
  };
}

- (FPCoordTestingNumEntitiesComputer)newNumEntitiesComputerWithCoordDao:(FPCoordinatorDao *)coordDao {
  return (^ NSNumber * (NSString *table) {
    return [[[coordDao localDao] localModelUtils]
              numEntitiesFromTable:table
                             error:[self newLocalBgErrBlkMaker]()];
  });
}

- (FPCoordTestingErrLogger)newErrLogger {
  return ^(NSError *err, int errCode, NSString *errMsg) {
    DDLogError(@"Error code: [%d], error msg: [%@], error: [%@]", errCode, errMsg, err);
  };
}

- (FPCoordTestingNewLocalSaveErrBlkMaker)newLocalSaveErrBlkMaker {
  return ^{
    return (^(NSError *err, int code, NSString *msg) {
      _localSaveError = YES;
      [self newErrLogger](err, code, msg);
    });
  };
}

- (FPCoordTestingNewLocalFetchErrBlkMaker)newLocalFetchErrBlkMaker{
  return ^{
    return (^(NSError *err, int code, NSString *msg) {
      _localFetchError = YES;
      [self newErrLogger](err, code, msg);
    });
  };
}

- (FPCoordTestingNewLocalBgErrBlkMaker)newLocalBgErrBlkMaker {
  return ^{
    return (^(NSError *err, int code, NSString *msg) {
      _localDaoErrDuringBgProcessing = YES;
      [self newErrLogger](err, code, msg);
    });
  };
}

- (FPCoordTestingNewRemoteStoreBusyBlkMaker)newRemoteStoreBusyBlkMaker {
  return ^{
    return (^(NSDate *retryAfter) {
      _remoteStoreBusy = YES;
    });
  };
}

- (FPCoordTestingNew1ErrArgComplHandlerBlkMaker)new1ErrArgComplHandlerBlkMaker {
  return ^{
    return (^(FPUser *savedUser, NSError *error) {
      if (error) {
        _generalComplError = YES;
      } else {
        _success = YES;
      }
    });
  };
}

- (void(^)(void))entityBeingSyncedBlk {
  return ^{
    _prepareForEditEntityBeingSynced = YES;
  };
}

- (void(^)(void))entityDeletedBlk {
  return ^{
    _prepareForEditEntityDeleted = YES;
  };
}

- (void(^)(void))entityInConflictBlk {
  return ^{
    _prepareForEditEntityInConflict = YES;
  };
}

- (void(^)(NSNumber *))entityBeingEditedByOtherActorBlk {
  return ^(NSNumber *otherActorId) {
    _prepareForEditEntityBeingEditedByOtherActor = YES;
    _prepareForEditEntityBeingEditedByOtherActorId = otherActorId;
  };
}

- (FPCoordTestingNumValueFetcher)newNumValueFetcher {
  return ^NSNumber *(FPCoordinatorDao *coordDao, NSString *table, NSString *selectColumn, NSNumber *keyValue) {
    return [[[coordDao localDao]
              localModelUtils] numberFromTable:table
                                  selectColumn:selectColumn
                                   whereColumn:COL_LOCAL_ID
                                    whereValue:keyValue
                                         error:[self newLocalFetchErrBlkMaker]()];
  };
}

- (FPCoordTestingFreshUserMaker)newFreshUserMaker {
  return ^ FPUser * (NSString *Two01MockResponseFile,
                     NSString *name,
                     NSString *email,
                     NSString *username,
                     NSString *password,
                     FPCoordinatorDao *coordDao,
                     TLTransaction *txn,
                     void (^waitBlock)(void)) {
    [self newMocker](Two01MockResponseFile, 0, 0);
    FPUser *user = [coordDao userWithName:name
                                    email:email
                                 username:username
                                 password:password
                             creationDate:[NSDate date]];
    FPSavedNewEntityCompletionHandler complHandler = ^(FPUser *savedUser, NSError *error) { };
    PELMDaoErrorBlk localDaoErrHandler = ^(NSError *error, int code, NSString *msg) { };
    [coordDao immediateRemoteSyncSaveNewUser:user
                                 transaction:txn
                             remoteStoreBusy:[self newRemoteStoreBusyBlkMaker]()
                           completionHandler:complHandler
                       localSaveErrorHandler:localDaoErrHandler];
    waitBlock();
    return [coordDao userWithError:^(NSError *error, int code, NSString *msg) {
      DDLogError(@"Error fetching local user from within 'fetchUser' helper block.  Error: [%@]", error);
    }];
  };
}

- (FPCoordTestingFreshJoeSmithMaker)newFreshJoeSmithMaker {
  return ^ FPUser * (FPCoordinatorDao *coordDao, TLTransaction *txn, void (^waitBlock)(void)) {
    return [self newFreshUserMaker](@"http-response.users.POST.201",
                                    @"Joe Smith",
                                    @"joe.smith@example.com",
                                    @"smithjoe",
                                    @"pa55w0rd",
                                    coordDao,
                                    txn,
                                    waitBlock);
  };
}

- (FPCoordTestingObserver)newObserver {
  return ^(NSArray *notificationNames) {
    FPToggler *toggler = [[FPToggler alloc] initWithNotificationNames:notificationNames];
    for (NSString *notificationName in notificationNames) {
      [[NSNotificationCenter defaultCenter] addObserver:toggler
                                               selector:@selector(toggleValue:)
                                                   name:notificationName
                                                 object:nil];
    }
    return toggler;
  };
}

- (void)stopTimerForAsyncWork {
  [PEUtils stopTimer:_timerForAsyncWork];
}

- (void)startTimerForAsyncWorkWithInterval:(NSInteger)timerInterval
                                  coordDao:(FPCoordinatorDao *)coordDao {
  _timerForAsyncWork =
    [PEUtils startNewTimerWithTargetObject:coordDao
                                  selector:@selector(asynchronousWork:)
                                  interval:timerInterval
                                  oldTimer:_timerForAsyncWork];
  [coordDao setSystemPruneCount:0];
  [coordDao setFlushToRemoteMasterCount:0];
}

- (TLTransactionManager *)newTxnManager {
  NSURL *txnsSqlLiteDataFileUrl =
    [_testBundle URLForResource:@"transactions-sqlite-datafile-for-testing"
                  withExtension:@"data"];
  HCRelationExecutor *relExecutor =
    [[HCRelationExecutor alloc] initWithDefaultAcceptCharset:[HCCharset UTF8]
                                       defaultAcceptLanguage:@"en-US"
                                   defaultContentTypeCharset:[HCCharset UTF8]
                                    allowInvalidCertificates:NO];
  TLTransactionManager *txnMg =
    [[TLTransactionManager alloc] initWithDataFilePath:[txnsSqlLiteDataFileUrl absoluteString]
                                   userAgentDeviceMake:@"iPhone5,2"
                                     userAgentDeviceOS:@"iPhone OS"
                              userAgentDeviceOSVersion:@"7.0.2"
                                      relationExecutor:relExecutor
                                            authScheme:@"token-scheme"
                                    authTokenParamName:@"auth-token"
                                    contentTypeCharset:[HCCharset UTF8]
                                    apptxnResMtVersion:@"0.0.1"
                              apptxnMediaSubtypePrefix:@"vnd.fp."
                                                 error:[self newLocalSaveErrBlkMaker]()];
  return txnMg;
}

- (FPCoordinatorDao *)newStoreCoordWithTxnManager:(TLTransactionManager *)txnMgr {
  NSURL *localSqlLiteDataFileUrl =
  [_testBundle URLForResource:@"sqlite-datafile-for-testing"
                withExtension:@"data"];
  DDLogDebug(@"FPCoordinatorDaoTests SQLite data file: [%@]", localSqlLiteDataFileUrl);
  FPAuthTokenDelegateForTesting *authTokenDelegate =
  [[FPAuthTokenDelegateForTesting alloc]
   initWithBlockForNewAuthTokenReceived:^(NSString *newAuthToken) {
     _authTokenReceived = YES;
     _authToken = newAuthToken;
   }
   authRequiredBlk:^(HCAuthentication *auth) {
     _authRequired = YES;
     _authentication = auth;
   }];
  FPCoordinatorDao *coordDao =
    [[FPCoordinatorDao alloc] initWithSqliteDataFilePath:[localSqlLiteDataFileUrl absoluteString]
                                   localDatabaseCreationError:^(NSError *err, int code, NSString *msg) {
                                                                 DDLogDebug(@"Error creating local database: [%@]", err); }
                               timeoutForMainThreadOperations:10
                                                acceptCharset:[HCCharset UTF8]
                                               acceptLanguage:@"en-US"
                                           contentTypeCharset:[HCCharset UTF8]
                                                   authScheme:@"fp-auth"
                                           authTokenParamName:@"fp-token"
                                                    authToken:nil
                                          errorMaskHeaderName:@"fp-error-mask"
                                              txnIdHeaderName:@"fp-transaction-id"
                                userAgentDeviceMakeHeaderName:@"fp-user-agent-device-make"
                                  userAgentDeviceOSHeaderName:@"fp-user-agent-device-os"
                           userAgentDeviceOSVersionHeaderName:@"fp-user-agent-device-version"
                                          userAgentDeviceMake:[PEUtils deviceMake]
                                            userAgentDeviceOS:[[UIDevice currentDevice] systemName]
                                     userAgentDeviceOSVersion:[[UIDevice currentDevice] systemVersion]
                                   establishSessionHeaderName:@"fp-establish-session"
                                  authTokenResponseHeaderName:@"fp-auth-token"
                                 bundleHoldingApiJsonResource:_testBundle
                                    nameOfApiJsonResourceFile:@"fpapi-resource"
                                              apiResMtVersion:@"0.0.1"
                                             userResMtVersion:@"0.0.1"
                                          vehicleResMtVersion:@"0.0.1"
                                      fuelStationResMtVersion:@"0.0.1"
                                  fuelPurchaseLogResMtVersion:@"0.0.1"
                                   environmentLogResMtVersion:@"0.0.1"
                                           transactionManager:txnMgr
                                   remoteSyncConflictDelegate:nil
                                            authTokenDelegate:authTokenDelegate
                              errorBlkForBackgroundProcessing:[self newLocalFetchErrBlkMaker]()
                                                bgEditActorId:@(FPBackgroundActorId)
                                     allowInvalidCertificates:NO];
  [coordDao initializeLocalDatabaseWithError:[self newLocalSaveErrBlkMaker]()];
  return coordDao;
}

@end