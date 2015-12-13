//
//  FPCoordinatorDao+AdditionsForTesting.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDaoImpl.h"

@interface FPCoordinatorDaoImpl (AdditionsForTesting)

- (void)deleteUser:(PELMDaoErrorBlk)errorBlk;

@end
