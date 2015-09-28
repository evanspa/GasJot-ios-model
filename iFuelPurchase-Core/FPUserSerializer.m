//
//  FPUserSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPUserSerializer.h"
#import "FPUser.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPUserFullnameKey     = @"user/name";
NSString * const FPUserEmailKey        = @"user/email";
NSString * const FPUserPasswordKey     = @"user/password";
NSString * const FPUserCreatedAtKey    = @"user/created-at";
NSString * const FPUserUpdatedAtKey    = @"user/updated-at";
NSString * const FPUserDeletedAtKey    = @"user/deleted-at";

@implementation FPUserSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPUser *user = (FPUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict nullSafeSetObject:[user name] forKey:FPUserFullnameKey];
  [userDict nullSafeSetObject:[user email] forKey:FPUserEmailKey];
  [userDict setObjectIfNotNull:[user password] forKey:FPUserPasswordKey];
  return userDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [FPUser userWithName:[resDict objectForKey:FPUserFullnameKey]
                        email:[resDict objectForKey:FPUserEmailKey]
                     password:[resDict objectForKey:FPUserPasswordKey]
             globalIdentifier:location
                    mediaType:mediaType
                    relations:relations
                    createdAt:[resDict dateSince1970ForKey:FPUserCreatedAtKey]
                    deletedAt:[resDict dateSince1970ForKey:FPUserDeletedAtKey]
                    updatedAt:[resDict dateSince1970ForKey:FPUserUpdatedAtKey]];
}

@end
