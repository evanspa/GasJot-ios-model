//
//  FPPriceEvent.h
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPFuelStationType;

@interface FPPriceEvent : NSObject

#pragma mark - Initializers

- (instancetype)initWithFuelstationType:(FPFuelStationType *)fsType
                                  price:(NSDecimalNumber *)price
                                 octane:(NSNumber *)octane
                               isDiesel:(BOOL)isDiesel
                                   date:(NSDate *)date
                               latitude:(NSDecimalNumber *)latitude
                              longitude:(NSDecimalNumber *)longitude
                               distance:(NSDecimalNumber *)distance;

#pragma mark - Properties

@property (nonatomic, readonly) FPFuelStationType *fsType;

@property (nonatomic, readonly) NSDecimalNumber *price;

@property (nonatomic, readonly) NSNumber *octane;

@property (nonatomic, readonly) BOOL isDiesel;

@property (nonatomic, readonly) NSDate *date;

@property (nonatomic, readonly) NSDecimalNumber *latitude;

@property (nonatomic, readonly) NSDecimalNumber *longitude;

@property (nonatomic, readonly) NSDecimalNumber *distance;

@end
