//
//  PELMMasterSupport.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMModelSupport.h"

@interface PELMMasterSupport : PELMModelSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                     lastModified:(NSDate *)lastModified;

#pragma mark - Methods

- (void)overwrite:(PELMMasterSupport *)entity;

#pragma mark - Properties

@property (nonatomic) NSDate *lastModified;

@property (nonatomic) NSDate *deletedDate;

#pragma mark - Equality

- (BOOL)isEqualToMasterSupport:(PELMMasterSupport *)masterSupport;

@end
