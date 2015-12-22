//
//  FPCoordDaoTestContext.m
//  PEFuelPurchase-Model
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
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import "FPLogging.h"
#import "PEUserCoordinatorDao.h"
#import <PEHateoas-Client/HCCharset.h>

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
  __block BOOL _prepareForEditEntityDeleted;
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
        pathsRelativeToBundle:_testBundle
               requestLatency:reqLatency
              responseLatency:respLatency];
  };
}

- (FPCoordTestingNumEntitiesComputer)newNumEntitiesComputerWithCoordDao:(FPCoordinatorDaoImpl *)coordDao {
  return (^ NSNumber * (NSString *table) {
    return [NSNumber numberWithInteger:[[coordDao localModelUtils] numEntitiesFromTable:table
                                                                                  error:[self newLocalBgErrBlkMaker]()]];
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
    return (^(PELMUser *savedUser, NSError *error) {
      if (error) {
        _generalComplError = YES;
      } else {
        _success = YES;
      }
    });
  };
}

- (FPCoordTestingNew0ErrArgComplHandlerBlkMaker)new0ErrArgComplHandlerBlkMaker {
  return ^{
    return (^(NSError *error) {
      if (error) {
        _generalComplError = YES;
      } else {
        _success = YES;
      }
    });
  };
}

- (FPCoordTestingNumValueFetcher)newNumValueFetcher {
  return ^NSNumber *(FPCoordinatorDaoImpl *coordDao, NSString *table, NSString *selectColumn, NSNumber *keyValue) {
    return [[coordDao localModelUtils] numberFromTable:table
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
                     NSString *password,
                     FPCoordinatorDaoImpl *coordDao,
                     void (^waitBlock)(void)) {
    [self newMocker](Two01MockResponseFile, 0, 0);
    /*FPUser *user = [coordDao userWithName:name
                                    email:email
                                 username:username
                                 password:password];*/
    PELMDaoErrorBlk localDaoErrHandler = ^(NSError *error, int code, NSString *msg) { };
    FPUser *localUser = (FPUser *)[coordDao.userCoordinatorDao newLocalUserWithError:localDaoErrHandler];
    [localUser setName:name];
    [localUser setEmail:email];
    [localUser setPassword:password];
    PESavedNewEntityCompletionHandler complHandler = ^(PELMUser *savedUser, NSError *error) { };
    [coordDao.userCoordinatorDao establishRemoteAccountForLocalUser:localUser
                                      preserveExistingLocalEntities:YES
                                                    remoteStoreBusy:[self newRemoteStoreBusyBlkMaker]()
                                                  completionHandler:complHandler
                                              localSaveErrorHandler:localDaoErrHandler];
    waitBlock();
    return (FPUser *)[coordDao userWithError:^(NSError *error, int code, NSString *msg) {
      DDLogError(@"Error fetching local user from within 'fetchUser' helper block.  Error: [%@]", error);
    }];
  };
}

- (FPCoordTestingFreshJoeSmithMaker)newFreshJoeSmithMaker {
  return ^ FPUser * (FPCoordinatorDaoImpl *coordDao, void (^waitBlock)(void)) {
    return [self newFreshUserMaker](@"http-response.users.POST.201",
                                    @"Joe Smith",
                                    @"joe.smith@example.com",
                                    @"pa55w0rd",
                                    coordDao,
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

- (FPCoordinatorDaoImpl *)newStoreCoord {
  NSURL *localSqlLiteDataFileUrl = [_testBundle URLForResource:@"sqlite-datafile-for-testing" withExtension:@"data"];
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
  FPCoordinatorDaoImpl *coordDao =
    [[FPCoordinatorDaoImpl alloc] initWithSqliteDataFilePath:[localSqlLiteDataFileUrl absoluteString]
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
                                   establishSessionHeaderName:@"fp-establish-session"
                                  authTokenResponseHeaderName:@"fp-auth-token"
                                    ifModifiedSinceHeaderName:@"fp-if-modified-since"
                                  ifUnmodifiedSinceHeaderName:@"fp-if-unmodified-since"
                                  loginFailedReasonHeaderName:@"fp-login-failed-reason"
                                accountClosedReasonHeaderName:@"fp-delete-reason"
                                 bundleHoldingApiJsonResource:_testBundle
                                    nameOfApiJsonResourceFile:@"fpapi-resource"
                                              apiResMtVersion:@"0.0.1"
                                        changelogResMtVersion:@"0.0.1"
                                             userResMtVersion:@"0.0.1"
                                          vehicleResMtVersion:@"0.0.1"
                                      fuelStationResMtVersion:@"0.0.1"
                                  fuelPurchaseLogResMtVersion:@"0.0.1"
                                   environmentLogResMtVersion:@"0.0.1"                                        
                                            authTokenDelegate:authTokenDelegate
                                     allowInvalidCertificates:NO];
  [coordDao initializeDatabaseWithError:[self newLocalSaveErrBlkMaker]()];
  return coordDao;
}

@end
