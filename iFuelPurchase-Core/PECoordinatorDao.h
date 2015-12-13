//
//  PECoordinatorDao.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/12/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "PELocalDao.h"

typedef void (^PESavedNewEntityCompletionHandler)(PELMUser *, NSError *);

@protocol PECoordinatorDao <PELocalDao>

#pragma mark - Getters

- (NSString *)authToken;

@end
