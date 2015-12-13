//
//  PECoordinatorDao.m
//  Gas Jot Model
//
//  Created by Paul Evans on 12/12/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "PECoordinatorDaoImpl.h"

@implementation PECoordinatorDaoImpl {
  NSString *_authToken;
}

#pragma mark - Getters

- (NSString *)authToken {
  return _authToken;
}

@end
