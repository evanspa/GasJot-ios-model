//
//  PELMUser.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 2/27/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

FOUNDATION_EXPORT NSString * const PELMUsersRelation;
FOUNDATION_EXPORT NSString * const PELMLoginRelation;
FOUNDATION_EXPORT NSString * const PELMLightLoginRelation;
FOUNDATION_EXPORT NSString * const PELMLogoutRelation;

@interface PELMUser : PELMMainSupport <NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                             name:(NSString *)name
                            email:(NSString *)email
                         password:(NSString *)password
                       verifiedAt:(NSDate *)verifiedAt;

#pragma mark - Creation Functions

+ (PELMUser *)userWithName:(NSString *)name
                     email:(NSString *)email
                  password:(NSString *)password
                 mediaType:(HCMediaType *)mediaType;

+ (PELMUser *)userWithName:(NSString *)name
                     email:(NSString *)email
                  password:(NSString *)password
                verifiedAt:(NSDate *)verifiedAt
          globalIdentifier:(NSString *)globalIdentifier
                 mediaType:(HCMediaType *)mediaType
                 relations:(NSDictionary *)relations
                 createdAt:(NSDate *)createdAt
                 deletedAt:(NSDate *)deletedAt
                 updatedAt:(NSDate *)updatedAt;

#pragma mark - Methods

- (void)overwrite:(PELMUser *)user;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *email;

@property (nonatomic) NSString *password;

@property (nonatomic) NSDate *verifiedAt;

#pragma mark - Equality

- (BOOL)isEqualToUser:(PELMUser *)user;

@end
