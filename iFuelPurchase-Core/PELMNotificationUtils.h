//
//  PELMNotificationUtils.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 9/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

FOUNDATION_EXPORT NSString * const PELMNotificationEntitiesUserInfoKey;

@interface PELMNotificationUtils : NSObject

#pragma mark - Notification related

+ (void)postNotificationWithName:(NSString *)notificationName
                        entities:(NSArray *)entities;

+ (void)postNotificationWithName:(NSString *)notificationName
                          entity:(PELMMainSupport *)entity;

+ (void)postNotificationWithName:(NSString *)notificationName;

+ (NSArray *)entitiesFromNotification:(NSNotification *)notification;

+ (NSNumber *)indexOfEntityRef:(PELMMainSupport *)entity
                  notification:(NSNotification *)notification;

+ (PELMMainSupport *)entityAtIndex:(NSInteger)index
                      notification:(NSNotification *)notification;

@end
