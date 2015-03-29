//
//  PELMModelSupport.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCMediaType.h>

@interface PELMModelSupport : NSObject

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations;

#pragma mark - Methods

- (void)overwrite:(PELMModelSupport *)entity;

- (BOOL)doesHaveEqualIdentifiers:(PELMModelSupport *)entity;

#pragma mark - Properties

@property (nonatomic) NSNumber *localMainIdentifier;

@property (nonatomic) NSNumber *localMasterIdentifier;

@property (nonatomic) NSString *globalIdentifier;

@property (nonatomic, readonly) NSString *mainEntityTable;

@property (nonatomic, readonly) NSString *masterEntityTable;

@property (nonatomic) HCMediaType *mediaType;

@property (nonatomic) NSDictionary *relations;

#pragma mark - Equality

- (BOOL)isEqualToModelSupport:(PELMModelSupport *)modelSupport;

@end
