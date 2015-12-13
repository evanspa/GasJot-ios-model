//
//  FPChangelogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEChangelogSerializer.h"
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import "PEChangelog.h"

NSString * const PEChangelogUpdatedAtKey = @"changelog/updated-at";

@implementation PEChangelogSerializer {
  Class _changelogClass;
}

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         changelogClass:(Class)changelogClass {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:embeddedSerializers
      actionsForEmbeddedResources:actions];
  if (self) {
    _changelogClass = changelogClass;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return nil;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [PEChangelog changelogOfClass:_changelogClass
                         withUpdatedAt:[resDict dateSince1970ForKey:PEChangelogUpdatedAtKey]];
}

@end
