//
//  FPCoordinatorDao.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCCharset.h>
#import <PEFuelPurchase-Common/FPAuthTokenDelegate.h>
#import "FPRemoteMasterDao.h"
#import "FPLocalDaoImpl.h"
#import "FPCoordinatorDao.h"

@interface FPCoordinatorDaoImpl : FPLocalDaoImpl <FPCoordinatorDao>

@end
