//
//  FPToggler.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

@import Foundation;

@interface FPToggler : NSObject

- (id)initWithNotificationNames:(NSArray *)notificationNames;

- (void)toggleValue:(NSNotification *)notification;

- (NSInteger)observedCountForNotificationName:(NSString *)notificationName;

@property (nonatomic, readonly) BOOL value;
@property (nonatomic, readonly) NSInteger observedCount;
@property (nonatomic, readonly) NSInteger totalObservedCount;

@end
