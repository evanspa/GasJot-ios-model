//
//  PELMMainSupport.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/27/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMasterSupport.h"

@interface PELMMainSupport : PELMMasterSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                      editActorId:(NSNumber *)editActorId
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount;

#pragma mark - Methods

- (void)overwrite:(PELMMainSupport *)entity;

#pragma mark - Properties

@property (nonatomic) NSDate *dateCopiedFromMaster;

@property (nonatomic) NSNumber *editActorId;

@property (nonatomic) BOOL editInProgress;

@property (nonatomic) BOOL syncInProgress;

@property (nonatomic) BOOL synced;

@property (nonatomic) BOOL inConflict;

@property (nonatomic) BOOL deleted;

@property (nonatomic) NSUInteger editCount;

#pragma mark - Methods

- (NSUInteger)incrementEditCount;

- (NSUInteger)decrementEditCount;

#pragma mark - Equality

- (BOOL)isEqualToMainSupport:(PELMMainSupport *)mainSupport;

@end
