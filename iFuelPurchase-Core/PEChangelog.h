//
//  PEChangelog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMUser.h"

@interface PEChangelog : NSObject

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Creation Functions

+ (PEChangelog *)changelogOfClass:(Class)clazz
                    withUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Properties

@property (nonatomic) NSString *globalIdentifier;

@property (nonatomic) HCMediaType *mediaType;

@property (nonatomic) NSDictionary *relations;

@property (nonatomic) NSDate *updatedAt;

#pragma mark - Methods

- (void)setUser:(PELMUser *)user;

- (PELMUser *)user;

@end
