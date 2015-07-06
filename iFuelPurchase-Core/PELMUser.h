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

@interface PELMUser : PELMMainSupport <NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                             name:(NSString *)name
                            email:(NSString *)email
                         username:(NSString *)username
                         password:(NSString *)password;

#pragma mark - Creation Functions

+ (PELMUser *)userWithName:(NSString *)name
                     email:(NSString *)email
                  username:(NSString *)username
                  password:(NSString *)password
                 mediaType:(HCMediaType *)mediaType;

+ (PELMUser *)userWithName:(NSString *)name
                     email:(NSString *)email
                  username:(NSString *)username
                  password:(NSString *)password
          globalIdentifier:(NSString *)globalIdentifier
                 mediaType:(HCMediaType *)mediaType
                 relations:(NSDictionary *)relations
                 updatedAt:(NSDate *)updatedAt;

#pragma mark - Methods

- (void)overwrite:(PELMUser *)user;

- (NSString *)usernameOrEmail;

#pragma mark - Properties

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *email;

@property (nonatomic) NSString *username;

@property (nonatomic) NSString *password;

#pragma mark - Equality

- (BOOL)isEqualToUser:(PELMUser *)user;

@end
