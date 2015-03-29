//
//  PELMChangeLog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMChangeLog.h"

@implementation PELMChangeLog

#pragma mark - Initializers

- (id)initWithLastModified:(NSDate *)lastModified {
  self = [super init];
  if (self) {
    _lastModified = lastModified;
  }
  return self;
}

- (id)initWithEdits:(NSArray *)edits deletions:(NSArray *)deletions {
  self = [self initWithLastModified:nil];
  if (self) {
    _edits = edits;
    _deletions = deletions;
  }
  return self;
}

@end
