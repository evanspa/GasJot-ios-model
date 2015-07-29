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
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt;

#pragma mark - Methods

- (void)overwrite:(PELMMainSupport *)entity;

#pragma mark - Properties

@property (nonatomic) NSDate *dateCopiedFromMaster;

@property (nonatomic) BOOL editInProgress;

@property (nonatomic) BOOL syncInProgress;

@property (nonatomic) BOOL synced;

@property (nonatomic) BOOL inConflict;

@property (nonatomic) NSUInteger editCount;

@property (nonatomic) NSNumber *syncHttpRespCode;

@property (nonatomic) NSNumber *syncErrMask;

@property (nonatomic) NSDate *syncRetryAt;

#pragma mark - Methods

- (NSUInteger)incrementEditCount;

- (NSUInteger)decrementEditCount;

#pragma mark - Equality

- (BOOL)isEqualToMainSupport:(PELMMainSupport *)mainSupport;

@end
