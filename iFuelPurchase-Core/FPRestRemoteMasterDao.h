//
//  FPRestRemoteMasterDao.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/18/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCMediaType.h>
#import <PEHateoas-Client/HCCharset.h>
#import "FPRemoteMasterDao.h"
#import "FPUserSerializer.h"
#import "FPLoginSerializer.h"
#import "FPVehicleSerializer.h"
#import "FPFuelStationSerializer.h"
#import "FPFuelPurchaseLogSerializer.h"
#import "FPEnvironmentLogSerializer.h"

FOUNDATION_EXPORT NSString * const LAST_MODIFIED_HEADER;

@interface FPRestRemoteMasterDao : NSObject <FPRemoteMasterDao>

#pragma mark - Initializers

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
            txnIdHeaderName:(NSString *)txnIdHeaderName
userAgentDeviceMakeHeaderName:(NSString *)userAgentDeviceMakeHeaderName
userAgentDeviceOSHeaderName:(NSString *)userAgentDeviceOSHeaderName
userAgentDeviceOSVersionHeaderName:(NSString *)userAgentDeviceOSVersionHeaderName
        userAgentDeviceMake:(NSString *)userAgentDeviceMake
          userAgentDeviceOS:(NSString *)userAgentDeviceOS
   userAgentDeviceOSVersion:(NSString *)userAgentDeviceOSVersion
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
   allowInvalidCertificates:(BOOL)allowInvalidCertifications;

#pragma mark - Properties

@property (nonatomic) NSString *authToken;

@end