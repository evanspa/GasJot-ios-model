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
#import "FPUserSerializer.h"
#import "FPLoginSerializer.h"
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
  NSDictionary *_restApiRelations;
  FPUserSerializer *_userSerializer;
  FPLoginSerializer *_loginSerializer;
  FPVehicleSerializer *_vehicleSerializer;
  FPFuelStationSerializer *_fuelStationSerializer;
  FPFuelPurchaseLogSerializer *_fuelPurchaseLogSerializer;
  FPEnvironmentLogSerializer *_environmentLogSerializer;
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
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(FPUserSerializer *)userSerializer
            loginSerializer:(FPLoginSerializer *)loginSerializer
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
    _restApiRelations =
      [HCUtils relsFromLocalHalJsonResource:bundle
                                   fileName:apiResourceFileName
                       resourceApiMediaType:[FPKnownMediaTypes apiMediaTypeWithVersion:apiResMtVersion]];
    _userSerializer = userSerializer;
    _loginSerializer = loginSerializer;
    _vehicleSerializer = vehicleSerializer;
    _fuelStationSerializer = fuelStationSerializer;
    _fuelPurchaseLogSerializer = fuelPurchaseLogSerializer;
    _environmentLogSerializer = environmentLogSerializer;
  }
  return self;
}

#pragma mark - Helpers

+ (HCServerUnavailableBlk)serverUnavailableBlk:(PELMRemoteMasterBusyBlk)busyHandler {
  return ^(NSDate *retryAfter, NSHTTPURLResponse *resp) {
    busyHandler(retryAfter);
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
    authReqdBlk(auth);
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
    NSError *error = [NSError errorWithDomain:FPSystemFaultedErrorDomain code:[fpErrMaskStr intValue] userInfo:nil];
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
    complHandler(authToken, [location absoluteString], resModel, rels, lastModified, NO, NO, NO, NO, NO, error, resp);
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
            asynchronous:(BOOL)asynchronous
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue
            otherHeaders:(NSDictionary *)otherHeaders {
  [_relationExecutor
    doPostForTargetResource:[relation target]
         resourceModelParam:resourceModelParam
            paramSerializer:serializer
    responseEntitySerializer:serializer
               asynchronous:asynchronous
            completionQueue:queue
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
          asynchronous:(BOOL)asynchronous
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [self doPostToRelation:[[user relations] objectForKey:FPVehiclesRelation]
      resourceModelParam:vehicle
              serializer:_vehicleSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:@{}];
}

- (void)saveExistingVehicle:(FPVehicle *)vehicle
               asynchronous:(BOOL)asynchronous
                    timeout:(NSInteger)timeout
            remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
               authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
          completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
  queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
          targetSerializer:_vehicleSerializer
              asynchronous:asynchronous
           completionQueue:queue
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
              otherHeaders:@{}];
}

- (void)deleteVehicle:(FPVehicle *)vehicle
         asynchronous:(BOOL)asynchronous
              timeout:(NSInteger)timeout
      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:vehicle]
                asynchronous:asynchronous
             completionQueue:queue
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
                otherHeaders:@{}];
}

#pragma mark - FuelStation Operations

- (void)saveNewFuelStation:(FPFuelStation *)fuelStation
                   forUser:(FPUser *)user
              asynchronous:(BOOL)asynchronous
                   timeout:(NSInteger)timeout
           remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
              authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
 queueForCompletionHandler:(dispatch_queue_t)queue {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelStationsRelation]
      resourceModelParam:fuelStation
              serializer:_fuelStationSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:@{}];
}

- (void)saveExistingFuelStation:(FPFuelStation *)fuelStation
                   asynchronous:(BOOL)asynchronous
                        timeout:(NSInteger)timeout
                remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                   authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
      queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
          targetSerializer:_fuelStationSerializer
              asynchronous:asynchronous
           completionQueue:queue
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
              otherHeaders:@{}];
}

- (void)deleteFuelStation:(FPFuelStation *)fuelStation
             asynchronous:(BOOL)asynchronous
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelStation]
                asynchronous:asynchronous
             completionQueue:queue
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
                otherHeaders:@{}];
}

#pragma mark - Fuel Purchase Log Operations

- (void)saveNewFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       forUser:(FPUser *)user
                  asynchronous:(BOOL)asynchronous
                       timeout:(NSInteger)timeout
               remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                  authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
             completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
     queueForCompletionHandler:(dispatch_queue_t)queue {
  [self doPostToRelation:[[user relations] objectForKey:FPFuelPurchaseLogsRelation]
      resourceModelParam:fuelPurchaseLog
              serializer:_fuelPurchaseLogSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:@{}];
}

- (void)saveExistingFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                       asynchronous:(BOOL)asynchronous
                            timeout:(NSInteger)timeout
                    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
          queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
   doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
   targetSerializer:_fuelPurchaseLogSerializer
   asynchronous:asynchronous
   completionQueue:queue
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
   otherHeaders:@{}];
}

- (void)deleteFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog
                 asynchronous:(BOOL)asynchronous
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
    queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
   doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:fuelPurchaseLog]
   asynchronous:asynchronous
   completionQueue:queue
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
   otherHeaders:@{}];
}

#pragma mark - Environment Log Operations

- (void)saveNewEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      forUser:(FPUser *)user
                 asynchronous:(BOOL)asynchronous
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
    queueForCompletionHandler:(dispatch_queue_t)queue {
  [self doPostToRelation:[[user relations] objectForKey:FPEnvironmentLogsRelation]
      resourceModelParam:environmentLog
              serializer:_environmentLogSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:@{}];
}

- (void)saveExistingEnvironmentLog:(FPEnvironmentLog *)environmentLog
                      asynchronous:(BOOL)asynchronous
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
         queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
   doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
   targetSerializer:_environmentLogSerializer
   asynchronous:asynchronous
   completionQueue:queue
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
   otherHeaders:@{}];
}

- (void)deleteEnvironmentLog:(FPEnvironmentLog *)environmentLog
                asynchronous:(BOOL)asynchronous
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
   queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
   doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:environmentLog]
   asynchronous:asynchronous
   completionQueue:queue
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
   otherHeaders:@{}];
}


#pragma mark - User Operations

- (void)saveNewUser:(FPUser *)user
       asynchronous:(BOOL)asynchronous
            timeout:(NSInteger)timeout
    remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
       authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
  completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [self doPostToRelation:[_restApiRelations objectForKey:FPUsersRelation]
      resourceModelParam:user
              serializer:_userSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:@{_establishSessionHeaderName : @"true"}];
}

- (void)saveExistingUser:(FPUser *)user
            asynchronous:(BOOL)asynchronous
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doPutForTargetResource:[FPRestRemoteMasterDao resourceFromModel:user]
          targetSerializer:_userSerializer
              asynchronous:asynchronous
           completionQueue:queue
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
              otherHeaders:@{}];
}

- (void)loginWithUsernameOrEmail:(NSString *)usernameOrEmail
                        password:(NSString *)password
                    asynchronous:(BOOL)asynchronous
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
       queueForCompletionHandler:(dispatch_queue_t)queue {
  NSMutableDictionary *headers = [NSMutableDictionary new];
  [headers setObject:@"true" forKey:_establishSessionHeaderName];
  PELMLoginUser *loginUser = [[PELMLoginUser alloc] init];
  [loginUser setUsernameOrEmail:usernameOrEmail];
  [loginUser setPassword:password];
  [self doPostToRelation:[_restApiRelations objectForKey:FPLoginRelation]
      resourceModelParam:loginUser
              serializer:_loginSerializer
            asynchronous:asynchronous
                 timeout:timeout
         remoteStoreBusy:busyHandler
            authRequired:authRequired
       completionHandler:complHandler
queueForCompletionHandler:queue
            otherHeaders:headers];
}

- (void)deleteUser:(FPUser *)user
      asynchronous:(BOOL)asynchronous
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
queueForCompletionHandler:(dispatch_queue_t)queue {
  [_relationExecutor
    doDeleteOfTargetResource:[FPRestRemoteMasterDao resourceFromModel:user]
                asynchronous:asynchronous
             completionQueue:queue
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
                otherHeaders:@{}];
}

@end
