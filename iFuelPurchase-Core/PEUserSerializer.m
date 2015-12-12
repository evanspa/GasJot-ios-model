//
//  PEUserSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEUserSerializer.h"
#import "PELMUser.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>

NSString * const PEUserFullnameKey     = @"user/name";
NSString * const PEUserEmailKey        = @"user/email";
NSString * const PEUserPasswordKey     = @"user/password";
NSString * const PEUserVerifiedAtKey   = @"user/verified-at";
NSString * const PEUserCreatedAtKey    = @"user/created-at";
NSString * const PEUserUpdatedAtKey    = @"user/updated-at";
NSString * const PEUserDeletedAtKey    = @"user/deleted-at";

@implementation PEUserSerializer {
  Class _userClass;
}

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
              userClass:(Class)userClass {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:embeddedSerializers
      actionsForEmbeddedResources:actions];
  if (self) {
    _userClass = userClass;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMUser *user = (PELMUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict nullSafeSetObject:[user name] forKey:PEUserFullnameKey];
  [userDict nullSafeSetObject:[user email] forKey:PEUserEmailKey];
  [userDict setStringIfNotBlank:[user password] forKey:PEUserPasswordKey];
  return userDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [PELMUser userOfClass:_userClass
                      withName:[resDict objectForKey:PEUserFullnameKey]
                         email:[resDict objectForKey:PEUserEmailKey]
                      password:[resDict objectForKey:PEUserPasswordKey]
                    verifiedAt:[resDict dateSince1970ForKey:PEUserVerifiedAtKey]
              globalIdentifier:location
                     mediaType:mediaType
                     relations:relations
                     createdAt:[resDict dateSince1970ForKey:PEUserCreatedAtKey]
                     deletedAt:[resDict dateSince1970ForKey:PEUserDeletedAtKey]
                     updatedAt:[resDict dateSince1970ForKey:PEUserUpdatedAtKey]];
}

@end
