//
//  FPLoginSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPLoginSerializer.h"
#import "PELMLoginUser.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>

NSString * const FPLoginUserEmailKey    = @"user/username-or-email";
NSString * const FPLoginUserPasswordKey = @"user/password";

@implementation FPLoginSerializer {
  FPUserSerializer *_userSerializer;
}

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
         userSerializer:(FPUserSerializer *)userSerializer {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:[userSerializer embeddedSerializers]
      actionsForEmbeddedResources:[userSerializer embeddedResourceActions]];
  if (self) {
    _userSerializer = userSerializer;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMLoginUser *loginUser = (PELMLoginUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict setObjectIfNotNull:[loginUser email] forKey:FPLoginUserEmailKey];
  [userDict setObjectIfNotNull:[loginUser password] forKey:FPLoginUserPasswordKey];
  return userDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [_userSerializer resourceModelWithDictionary:resDict
                                            relations:relations
                                            mediaType:mediaType
                                             location:location
                                         lastModified:lastModified];
}

@end
