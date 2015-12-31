//
//  FPPriceEvent.m
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPPriceEvent.h"

@implementation FPPriceEvent

#pragma mark - Initializers

- (instancetype)initWithFuelstationType:(FPFuelStationType *)fsType
                                  price:(NSDecimalNumber *)price
                                 octane:(NSNumber *)octane
                               isDiesel:(BOOL)isDiesel
                                   date:(NSDate *)date
                               latitude:(NSDecimalNumber *)latitude
                              longitude:(NSDecimalNumber *)longitude {
  self = [super init];
  if (self) {
    _fsType = fsType;
    _price = price;
    _octane = octane;
    _isDiesel = isDiesel;
    _date = date;
    _latitude = latitude;
    _longitude = longitude;
  }
  return self;
}

@end
