//
//  PEChangelog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEChangelog.h"

@implementation PEChangelog {
  PELMUser *_user;
}

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt {
  if (self) {
    _updatedAt = updatedAt;
  }
  return self;
}

#pragma mark - Creation Functions

+ (PEChangelog *)changelogOfClass:(Class)clazz
                    withUpdatedAt:(NSDate *)updatedAt {
  return [[clazz alloc] initWithUpdatedAt:updatedAt];
}

#pragma mark - Methods

- (void)setUser:(PELMUser *)user {
  _user = user;
}

- (PELMUser *)user {
  return _user;
}

@end
