//
//  PECoordinatorDao.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/12/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PECoordinatorDao.h"
#import "PELocalDao.h"
#import "PELocalDaoImpl.h"

@interface PECoordinatorDaoImpl : PELocalDaoImpl <PECoordinatorDao>

@end
