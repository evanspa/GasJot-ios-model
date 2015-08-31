//
//  FPRestRemoteMasterDao.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPRestRemoteMasterDao.h"
#import <PEHateoas-Client/HCRelationExecutor.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEHateoas-Client/HCRelation.h>
#import "FPErrorDomainsAndCodes.h"
#import "FPRemoteDaoErrorDomains.h"
#import "FPKnownMediaTypes.h"
#import "PELMLoginUser.h"

NSString * const LAST_MODIFIED_HEADER = @"last-modified";

@implementation FPRestRemoteMasterDao {
  HCRelationExecutor *_relationExecutor;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  NSString *_errorMaskHeaderName;
  NSString *_establishSessionHeaderName;
  NSString *_authTokenHeaderName;
  NSString *_ifModifiedSinceHeaderName;
  NSString *_ifUnmodifiedSinceHeaderName;
  NSString *_loginFailedReasonHeaderName;
  NSString *_accountClosedReasonHeaderName;
  NSDictionary *_restApiRelations;
  FPUserSerializer *_userSerializer;
  FPLoginSerializer *_loginSerializer;
  FPLogoutSerializer *_logoutSerializer;
  FPVehicleSerializer *_vehicleSerializer;
  FPFuelStationSerializer *_fuelStationSerializer;
  FPFuelPurchaseLogSerializer *_fuelPurchaseLogSerializer;
  FPEnvironmentLogSerializer *_environmentLogSerializer;
  dispatch_queue_t _serialQueue;
}

#pragma mark - Initializers

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
 establishSessionHeaderName:(NSString *)establishHeaderSessionName
        authTokenHeaderName:(NSString *)authTokenHeaderName
  ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(FPUserSerializer *)userSerializer
            loginSerializer:(FPLoginSerializer *)loginSerializer
           logoutSerializer:(FPLogoutSerializer *)logoutSerializer
          vehicleSerializer:(FPVehicleSerializer *)vehicleSerializer
      fuelStationSerializer:(FPFuelStationSerializer *)fuelStationSerializer
  fuelPurchaseLogSerializer:(FPFuelPurchaseLogSerializer *)fuelPurchaseLogSerializer
   environmentLogSerializer:(FPEnvironmentLogSerializer *)environmentLogSerializer
   allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super init];
  if (self) {
    _relationExecutor = [[HCRelationExecutor alloc]
                          initWithDefaultAcceptCharset:acceptCharset
                                 defaultAcceptLanguage:acceptLanguage
                             defaultContentTypeCharset:contentTypeCharset
                              allowInvalidCertificates:allowInvalidCertificates];
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _authToken = authToken;
    _errorMaskHeaderName = errorMaskHeaderName;
    _establishSessionHeaderName = establishHeaderSessionName;
    _authTokenHeaderName = authTokenHeaderName;
    _ifModifiedSinceHeaderName = ifModifiedSinceHeaderName;
    _ifUnmodifiedSinceHeaderName = ifUnmodifiedSinceHeaderName;
    _loginFailedReasonHeaderName = loginFailedReasonHeaderName;
    _accountClosedReasonHeaderName = accountClosedReasonHeaderName;
    _restApiRelations =
      [HCUtils relsFromLocalHalJsonResource:bundle
                                   fileName:apiResourceFileName
                       resourceApiMediaType:[FPKnownMediaTypes apiMediaTypeWithVersion:apiResMtVersion]];
    _userSerializer = userSerializer;
    _loginSerializer = loginSerializer;
    _logoutSerializer = logoutSerializer;
    _vehicleSerializer = vehicleSerializer;
    _fuelStationSerializer = fuelStationSerializer;
    _fuelPurchaseLogSerializer = fuelPurchaseLogSerializer;
    _environmentLogSerializer = environmentLogSerializer;
    _serialQueue = dispatch_queue_create("name.paulevans.fp.serialqueue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

#pragma mark - Helpers

- (NSDictionary *)addDateHeaderToHeaders:(NSDictionary *)headers
                              headerName:(NSString *)headerName
                                   value:(NSDate *)value {
  if (value) {
    NSMutableDictionary *newHeaders = [headers mutableCopy];
    [newHeaders setObject:[[NSNumber numberWithInteger:([value timeIntervalSince1970] * 1000)] description]
                   forKey:headerName];
    return newHeaders;
  } else {
    return headers;
  }
}

- (NSDictionary *)addFpIfUnmodifiedSinceHeaderToHeader:(NSDictionary *)headers
                                                entity:(PELMMasterSupport *)entity {
  return [self addDateHeaderToHeaders:headers
                           headerName:_ifUnmodifiedSinceHeaderName
                                value:[entity updatedAt]];
}

+ (HCServerUnavailableBlk)serverUnavailableBlk:(PELMRemoteMasterBusyBlk)busyHandler {
  return ^(NSDate *retryAfter, NSHTTPURLResponse *resp) {
    if (busyHandler) { busyHandler(retryAfter); }
  };
}

+ (HCResource *)resourceFromModel:(PELMModelSupport *)model {
  return [[HCResource alloc]
           initWithMediaType:[model mediaType]
                         uri:[NSURL URLWithString:[model globalIdentifier]]
                       model:model];
}

+ (HCAuthReqdErrorBlk)toHCAuthReqdBlk:(PELMRemoteMasterAuthReqdBlk)authReqdBlk {
  return ^(HCAuthentication *auth, NSHTTPURLResponse *resp) {
    if (authReqdBlk) { authReqdBlk(auth); }
  };
}

- (HCClientErrorBlk)newClientErrBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSHTTPURLResponse *httpResp) {
    NSString *fpErrMaskStr = [[httpResp allHeaderFields] objectForKey:_errorMaskHeaderName];
    NSError *error =
      [NSError errorWithDomain:FPUserFaultedErrorDomain code:[fpErrMaskStr intValue] userInfo:nil];
    BOOL gone = [httpResp statusCode] == 410;
    BOOL notFound = [httpResp statusCode] == 404;
    // now, the reason why "NO" is harded into the 'inConflict' block parameter
    // is because we have a specific block type (HCConflictBlk) to handle the
    // special case of the "409" client error type
    complHandler(nil, nil, nil, nil, nil, NO, gone, notFound, NO, NO, error, httpResp);
  };
}

- (HCRedirectionBlk)newRedirectionBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSURL *location, BOOL movedPermanently, BOOL notModified, NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    complHandler(authToken, [location absoluteString], nil, nil, nil, NO, NO, NO, movedPermanently, notModified, nil, resp);
  };
}

- (HCServerErrorBlk)newServerErrBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSHTTPURLResponse *resp) {
    NSString *fpErrMaskStr = [[resp allHeaderFields] objectForKey:_errorMaskHeaderName];
    NSInteger codeForError = 0;
    if (fpErrMaskStr) {
      codeForError = [fpErrMaskStr integerValue];
    }
    NSError *error = [NSError errorWithDomain:FPSystemFaultedErrorDomain code:codeForError userInfo:nil];
    complHandler(nil, nil, nil, nil, nil, NO, NO, NO, NO, NO, error, resp);
  };
}

- (HCConnFailureBlk)newConnFailureBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSInteger nsurlErr) {
    NSError *error = [NSError errorWithDomain:FPConnFaultedErrorDomain code:nsurlErr userInfo:nil];
    complHandler(nil, nil, nil, nil, nil, NO, NO, NO, NO, NO, error, nil);
  };
}

- (HCGETSuccessBlk)newGetSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSURL *location, id resModel, NSDate *lastModified, NSDictionary *rels, NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    complHandler(authToken, [location absoluteString], resModel, rels, lastModified, NO, NO, NO, NO, NO, nil, resp);
  };
}

- (HCPOSTSuccessBlk)newPostSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSURL *location, id resModel, NSDate *lastModified, NSDictionary *rels, NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    complHandler(authToken, [location absoluteString], resModel, rels, lastModified, NO, NO, NO, NO, NO, nil, resp);
  };
}

- (HCDELETESuccessBlk)newDeleteSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    complHandler(authToken, nil, nil, nil, nil, NO, NO, NO, NO, NO, nil, resp);
  };
}

- (HCPUTSuccessBlk)newPutSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSURL *location, id resModel, NSDate *lastModified, NSDictionary *rels, NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    complHandler(authToken, [location absoluteString], resModel, rels, lastModified, NO, NO, NO, NO, NO, nil, resp);
  };
}

- (HCConflictBlk)newConflictBlk:(PELMRemoteMasterCompletionHandler)complHandler {
  return ^(NSURL *location, id resModel, NSDate *lastModified, NSDictionary *rels, NSHTTPURLResponse *resp) {
    NSString *authToken = [[resp allHeaderFields] objectForKey:_authTokenHeaderName];
    NSError *error = [NSError errorWithDomain:FPClientFaultedErrorDomain code:[resp statusCode] userInfo:nil];
    complHandler(authToken, [location absoluteString], resModel, rels, lastModified, YES, NO, NO, NO, NO, error, resp);
  };
}

- (HCAuthorization *)authorization {
  HCAuthorization *authorization = nil;
  if (_authToken) {
    authorization = [HCAuthorization authWithScheme:_authScheme
                                singleAuthParamName:_authTokenParamName
                                     authParamValue:_authToken];
  }
  return authorization;
}

- (void)doPostToRelation:(HCRelation *)relation
      resourceModelParam:(id)resourceModelParam
              serializer:(id<HCResourceSerializer>)serializer
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
            otherHeaders:(NSDictionary *)otherHeaders {
  [_relationExecutor
    doPostForTargetResource:[relation target]
         resourceModelParam:resourceModelParam
            paramSerializer:serializer
   responseEntitySerializer:serializer
               asynchronous:YES
            completionQueue:_serialQueue
              authorization:[self authorization]
                    success:[self newPostSuccessBlk:complHandler]
                redirection:[self newRedirectionBlk:complHandler]
                clientError:[self newClientErrBlk:complHandler]
     authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                serverError:[self newServerErrBlk:complHandler]
           unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
          connectionFailure:[self newConnFailureBlk:complHandler]
                    timeout:timeout
               otherHeaders:otherHeaders];
}

#pragma mark - General Operations

- (void)setAuthToken:(NSString *)authToken {
  _authToken = authToken;
}

#pragma mark - Vehicle Operations

- (void)saveNewVehicle:(FPVehicle *)vehicle
               forUser:(FPUser *)user
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPVehiclesRelation]
      resourceModelParam:vehicle
              serializer:_vehicleSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingVehicle:(FPVehicle *)vehicle
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
          targetSerializer:_vehicleSerializer
              asynchronous:YES
           completionQueue:_serialQueue
             authorization:[self authorization]
                   success:[self newPutSuccessBlk:complHandler]
               redirection:[self newRedirectionBlk:complHandler]
               clientError:[self newClientErrBlk:complHandler]
    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
               serverError:[self newServerErrBlk:complHandler]
          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                  conflict:[self newConflictBlk:complHandler]
         connectionFailure:[self newConnFailureBlk:complHandler]
                   timeout:timeout
              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:vehicle]];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
     wouldBeTargetSerializer:_vehicleSerializer
                asynchronous:YES
             completionQueue:_serialQueue
               authorization:[self authorization]
                     success:[self newDeleteSuccessBlk:complHandler]
                 redirection:[self newRedirectionBlk:complHandler]
                 clientError:[self newClientErrBlk:complHandler]
      authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                 serverError:[self newServerErrBlk:complHandler]
            unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                    conflict:[self newConflictBlk:complHandler]
           connectionFailure:[self newConnFailureBlk:complHandler]
                     timeout:timeout
                otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:vehicle]];
}

- (void)fetchVehicleWithGlobalId:(NSString *)globalId
                 ifModifiedSince:(NSDate *)ifModifiedSince
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doGetForURLString:globalId
                       ifModifiedSince:nil
                      targetSerializer:_vehicleSerializer
                          asynchronous:YES
                       completionQueue:_serialQueue
                         authorization:[self authorization]
                               success:[self newGetSuccessBlk:complHandler]
                           redirection:[self newRedirectionBlk:complHandler]
                           clientError:[self newClientErrBlk:complHandler]
                authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                           serverError:[self newServerErrBlk:complHandler]
                      unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                     connectionFailure:[self newConnFailureBlk:complHandler]
                               timeout:timeout
                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                          otherHeaders:[self addDateHeaderToHeaders:@{}
                                                         headerName:_ifModifiedSinceHeaderName
                                                              value:ifModifiedSince]];
}

#pragma mark - FuelStation Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelStationsRelation]
      resourceModelParam:fuelStation
              serializer:_fuelStationSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
          targetSerializer:_fuelStationSerializer
              asynchronous:YES
           completionQueue:_serialQueue
             authorization:[self authorization]
                   success:[self newPutSuccessBlk:complHandler]
               redirection:[self newRedirectionBlk:complHandler]
               clientError:[self newClientErrBlk:complHandler]
    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
               serverError:[self newServerErrBlk:complHandler]
          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                  conflict:[self newConflictBlk:complHandler]
         connectionFailure:[self newConnFailureBlk:complHandler]
                   timeout:timeout
              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelStation]];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
     wouldBeTargetSerializer:_fuelStationSerializer
                asynchronous:YES
             completionQueue:_serialQueue
               authorization:[self authorization]
                     success:[self newDeleteSuccessBlk:complHandler]
                 redirection:[self newRedirectionBlk:complHandler]
                 clientError:[self newClientErrBlk:complHandler]
      authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                 serverError:[self newServerErrBlk:complHandler]
            unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                    conflict:[self newConflictBlk:complHandler]
           connectionFailure:[self newConnFailureBlk:complHandler]
                     timeout:timeout
                otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelStation]];
}

- (void)fetchFuelstationWithGlobalId:(NSString *)globalId
                     ifModifiedSince:(NSDate *)ifModifiedSince
                             timeout:(NSInteger)timeout
                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                        authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doGetForURLString:globalId
                       ifModifiedSince:nil
                      targetSerializer:_fuelStationSerializer
                          asynchronous:YES
                       completionQueue:_serialQueue
                         authorization:[self authorization]
                               success:[self newGetSuccessBlk:complHandler]
                           redirection:[self newRedirectionBlk:complHandler]
                           clientError:[self newClientErrBlk:complHandler]
                authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                           serverError:[self newServerErrBlk:complHandler]
                      unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                     connectionFailure:[self newConnFailureBlk:complHandler]
                               timeout:timeout
                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                          otherHeaders:[self addDateHeaderToHeaders:@{} headerName:_ifModifiedSinceHeaderName value:ifModifiedSince]];
}

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelPurchaseLogsRelation]
      resourceModelParam:fuelPurchaseLog
              serializer:_fuelPurchaseLogSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
                           targetSerializer:_fuelPurchaseLogSerializer
                               asynchronous:YES
                            completionQueue:_serialQueue
                              authorization:[self authorization]
                                    success:[self newPutSuccessBlk:complHandler]
                                redirection:[self newRedirectionBlk:complHandler]
                                clientError:[self newClientErrBlk:complHandler]
                     authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                serverError:[self newServerErrBlk:complHandler]
                           unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                   conflict:[self newConflictBlk:complHandler]
                          connectionFailure:[self newConnFailureBlk:complHandler]
                                    timeout:timeout
                               otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelPurchaseLog]];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
                      wouldBeTargetSerializer:_fuelPurchaseLogSerializer
                                 asynchronous:YES
                              completionQueue:_serialQueue
                                authorization:[self authorization]
                                      success:[self newDeleteSuccessBlk:complHandler]
                                  redirection:[self newRedirectionBlk:complHandler]
                                  clientError:[self newClientErrBlk:complHandler]
                       authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                  serverError:[self newServerErrBlk:complHandler]
                             unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                     conflict:[self newConflictBlk:complHandler]
                            connectionFailure:[self newConnFailureBlk:complHandler]
                                      timeout:timeout
                                 otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:fuelPurchaseLog]];
}

- (void)fetchFuelPurchaseLogWithGlobalId:(NSString *)globalId
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doGetForURLString:globalId
                       ifModifiedSince:nil
                      targetSerializer:_fuelPurchaseLogSerializer
                          asynchronous:YES
                       completionQueue:_serialQueue
                         authorization:[self authorization]
                               success:[self newGetSuccessBlk:complHandler]
                           redirection:[self newRedirectionBlk:complHandler]
                           clientError:[self newClientErrBlk:complHandler]
                authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                           serverError:[self newServerErrBlk:complHandler]
                      unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                     connectionFailure:[self newConnFailureBlk:complHandler]
                               timeout:timeout
                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                          otherHeaders:[self addDateHeaderToHeaders:@{} headerName:_ifModifiedSinceHeaderName value:ifModifiedSince]];
}

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:FPEnvironmentLogsRelation]
      resourceModelParam:environmentLog
              serializer:_environmentLogSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
                           targetSerializer:_environmentLogSerializer
                               asynchronous:YES
                            completionQueue:_serialQueue
                              authorization:[self authorization]
                                    success:[self newPutSuccessBlk:complHandler]
                                redirection:[self newRedirectionBlk:complHandler]
                                clientError:[self newClientErrBlk:complHandler]
                     authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                serverError:[self newServerErrBlk:complHandler]
                           unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                   conflict:[self newConflictBlk:complHandler]
                          connectionFailure:[self newConnFailureBlk:complHandler]
                                    timeout:timeout
                               otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:environmentLog]];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)environmentLog
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
                      wouldBeTargetSerializer:_environmentLogSerializer
                                 asynchronous:YES
                              completionQueue:_serialQueue
                                authorization:[self authorization]
                                      success:[self newDeleteSuccessBlk:complHandler]
                                  redirection:[self newRedirectionBlk:complHandler]
                                  clientError:[self newClientErrBlk:complHandler]
                       authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                  serverError:[self newServerErrBlk:complHandler]
                             unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                                     conflict:[self newConflictBlk:complHandler]
                            connectionFailure:[self newConnFailureBlk:complHandler]
                                      timeout:timeout
                                 otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:environmentLog]];
}

- (void)fetchEnvironmentLogWithGlobalId:(NSString *)globalId
                        ifModifiedSince:(NSDate *)ifModifiedSince
                                timeout:(NSInteger)timeout
                        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor doGetForURLString:globalId
                       ifModifiedSince:nil
                      targetSerializer:_environmentLogSerializer
                          asynchronous:YES
                       completionQueue:_serialQueue
                         authorization:[self authorization]
                               success:[self newGetSuccessBlk:complHandler]
                           redirection:[self newRedirectionBlk:complHandler]
                           clientError:[self newClientErrBlk:complHandler]
                authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                           serverError:[self newServerErrBlk:complHandler]
                      unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                     connectionFailure:[self newConnFailureBlk:complHandler]
                               timeout:timeout
                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                          otherHeaders:[self addDateHeaderToHeaders:@{} headerName:_ifModifiedSinceHeaderName value:ifModifiedSince]];
}

#pragma mark - User Operations

- (void)logoutUser:(FPUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[[user relations] objectForKey:PELMLogoutRelation]
      resourceModelParam:user
              serializer:_logoutSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:nil
       completionHandler:complHandler
            otherHeaders:@{}];
}

- (void)establishAccountForUser:(FPUser *)user
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToRelation:[_restApiRelations objectForKey:PELMUsersRelation]
      resourceModelParam:user
              serializer:_userSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:@{_establishSessionHeaderName : @"true"}];
}

- (void)saveExistingUser:(FPUser *)user
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:user]
          targetSerializer:_userSerializer
              asynchronous:YES
           completionQueue:_serialQueue
             authorization:[self authorization]
                   success:[self newPutSuccessBlk:complHandler]
               redirection:[self newRedirectionBlk:complHandler]
               clientError:[self newClientErrBlk:complHandler]
    authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
               serverError:[self newServerErrBlk:complHandler]
          unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                  conflict:[self newConflictBlk:complHandler]
         connectionFailure:[self newConnFailureBlk:complHandler]
                   timeout:timeout
              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:user]];
}

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                   loginRelation:(NSString *)loginRelation
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  NSMutableDictionary *headers = [NSMutableDictionary new];
  [headers setObject:@"true" forKey:_establishSessionHeaderName];
  PELMLoginUser *loginUser = [[PELMLoginUser alloc] init];
  [loginUser setUsernameOrEmail:usernameOrEmail];
  [loginUser setPassword:password];
  [self doPostToRelation:[_restApiRelations objectForKey:loginRelation]
      resourceModelParam:loginUser
              serializer:_loginSerializer
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
            otherHeaders:headers];
}

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self loginWithUsernameOrEmail:usernameOrEmail
                        password:password
                   loginRelation:PELMLoginRelation
                         timeout:timeout
                 remoteStoreBusy:busyHandler
                    authRequired:authRequired
               completionHandler:complHandler];
}

- (void)lightLoginForUser:(FPUser *)user
                 password:(NSString *)password
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self loginWithUsernameOrEmail:[user usernameOrEmail]
                        password:password
                   loginRelation:PELMLightLoginRelation
                         timeout:timeout
                 remoteStoreBusy:busyHandler
                    authRequired:authRequired
               completionHandler:complHandler];
}

- (void)deleteUser:(FPUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:user]
     wouldBeTargetSerializer:_userSerializer
                asynchronous:YES
             completionQueue:_serialQueue
               authorization:[self authorization]
                     success:[self newDeleteSuccessBlk:complHandler]
                 redirection:[self newRedirectionBlk:complHandler]
                 clientError:[self newClientErrBlk:complHandler]
      authenticationRequired:[FPRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                 serverError:[self newServerErrBlk:complHandler]
            unavailableError:[FPRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                    conflict:[self newConflictBlk:complHandler]
           connectionFailure:[self newConnFailureBlk:complHandler]
                     timeout:timeout
                otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:user]];
}

@end
