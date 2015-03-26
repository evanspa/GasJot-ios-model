//
//  FPToggler.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPToggler.h"

@implementation FPToggler {
  NSMutableDictionary *_notificationNames;
  NSString *_singleNotificationName;
  NSInteger _totalObservedCount;
}

- (id)initWithNotificationNames:(NSArray *)notificationNames {
  self = [super init];
  if (self) {
    _notificationNames = [NSMutableDictionary dictionary];
    for (NSString *notificationName in notificationNames) {
      [_notificationNames setObject:@(0) forKey:notificationName];
    }
    if ([notificationNames count] == 1) {
      _singleNotificationName = notificationNames[0];
    }
    _value = NO;
    _totalObservedCount = 0;
  }
  return self;
}

- (void)toggleValue:(NSNotification *)notification {
  @synchronized(self) {
    NSString *notificationName = [notification name];
    if ([_notificationNames objectForKey:notificationName]) {
      _value = !_value;
      NSNumber *observedCountNumber = _notificationNames[notificationName];
      NSInteger observedCount = [observedCountNumber integerValue];
      observedCount++;
      _notificationNames[notificationName] = @(observedCount);
      _totalObservedCount++;
    }
  }
}

- (NSInteger)observedCountForNotificationName:(NSString *)notificationName {
  return [_notificationNames[notificationName] integerValue];
}

- (NSInteger)observedCount {
  return [self observedCountForNotificationName:_singleNotificationName];
}

#pragma mark - NSObject overrides

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
