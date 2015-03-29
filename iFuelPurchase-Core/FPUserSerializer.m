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
#import <PEHateoas-Client/HCUtils.h>

NSString * const FPUserFullnameKey     = @"user/name";
NSString * const FPUserEmailKey        = @"user/email";
NSString * const FPUserUsernameKey     = @"user/username";
NSString * const FPUserPasswordKey     = @"user/password";
NSString * const FPUserCreationDateKey = @"user/creation-date";

@implementation FPUserSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPUser *user = (FPUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict setObjectIfNotNull:[user name] forKey:FPUserFullnameKey];
  [userDict setObjectIfNotNull:[user email] forKey:FPUserEmailKey];
  [userDict setObjectIfNotNull:[user username] forKey:FPUserUsernameKey];
  [userDict setObjectIfNotNull:[user password] forKey:FPUserPasswordKey];
  [userDict setObjectIfNotNull:[HCUtils rfc7231StringFromDate:[user creationDate]]
                        forKey:FPUserCreationDateKey];
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
                     username:[resDict objectForKey:FPUserUsernameKey]
                     password:[resDict objectForKey:FPUserPasswordKey]
                 creationDate:[HCUtils rfc7231DateFromString:[resDict objectForKey:FPUserCreationDateKey]]
             globalIdentifier:location
                    mediaType:mediaType
                    relations:relations
                 lastModified:lastModified];
}

@end
