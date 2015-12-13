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
#import "PELocalDaoImpl.h"
#import "FPLocalDao.h"

@interface FPLocalDaoImpl : PELocalDaoImpl <FPLocalDao>

@end
