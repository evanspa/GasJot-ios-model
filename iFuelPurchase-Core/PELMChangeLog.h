//
//  PELMChangeLog.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PELMChangeLog : NSObject

#pragma mark - Initializers

- (id)initWithLastModified:(NSDate *)lastModified;

- (id)initWithEdits:(NSArray *)edits deletions:(NSArray *)deletions;

#pragma mark - Properties

@property (readonly, nonatomic) NSDate *lastModified;

@property (readonly, nonatomic) NSArray *edits;

@property (readonly, nonatomic) NSArray *deletions;

@end
