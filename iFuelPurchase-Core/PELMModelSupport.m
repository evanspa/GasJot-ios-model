//
//  PELMModelSupport.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 7/26/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMModelSupport.h"
#import <PEObjc-Commons/PEUtils.h>
#import <PEHateoas-Client/HCRelation.h>
#import "PELMUtils.h"

@implementation PELMModelSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                  mainEntityTable:(NSString *)mainEntityTable
                masterEntityTable:(NSString *)masterEntityTable
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations {
  self = [super init];
  if (self) {
    _localMainIdentifier = localMainIdentifier;
    _localMasterIdentifier = localMasterIdentifier;
    _globalIdentifier = globalIdentifier;
    _mainEntityTable = mainEntityTable;
    _masterEntityTable = masterEntityTable;
    _mediaType = mediaType;
    _relations = relations;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMModelSupport *)entity {
  [self setRelations:[entity relations]];
  [self setGlobalIdentifier:[entity globalIdentifier]];
  [self setMediaType:[entity mediaType]];
}

- (BOOL)doesHaveEqualIdentifiers:(PELMModelSupport *)entity {
  if (_localMainIdentifier && [entity localMainIdentifier]) {
    return ([_localMainIdentifier isEqualToNumber:[entity localMainIdentifier]]);
  } else if (_globalIdentifier && [entity globalIdentifier]) {
    return ([_globalIdentifier isEqualToString:[entity globalIdentifier]]);
  } else if (_localMasterIdentifier && [entity localMasterIdentifier]) {
    return ([_localMasterIdentifier isEqualToNumber:[entity localMasterIdentifier]]);
  }
  return NO;
}

#pragma mark - Equality

- (BOOL)isEqualToModelSupport:(PELMModelSupport *)modelSupport {
  if (!modelSupport) { return NO; }
  BOOL hasEqualGlobalIds =
    [PEUtils isString:[self globalIdentifier]
              equalTo:[modelSupport globalIdentifier]];
  BOOL hasEqualMediaTypes = [PEUtils nilSafeIs:[self mediaType] equalTo:[modelSupport mediaType]];
  return hasEqualGlobalIds && hasEqualMediaTypes;
}

#pragma mark - NSObject

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMModelSupport class]]) { return NO; }
  return [self isEqualToModelSupport:object];
}

- (NSUInteger)hash {
  return [[self globalIdentifier] hash] ^
    [[self localMainIdentifier] hash] ^ [[self localMasterIdentifier] hash] ^
    [[self mediaType] hash];
}

- (NSString *)description {
  NSMutableString *relationsDesc = [NSMutableString stringWithString:@"relations: ["];
  __block NSUInteger numRelations = [_relations count];
  [_relations enumerateKeysAndObjectsUsingBlock:^(id key, id relation, BOOL *stop) {
    [relationsDesc appendFormat:@"%@", relation];
    if ((numRelations + 1) < numRelations) {
      [relationsDesc appendString:@", "];
    }
    numRelations++;
  }];
  [relationsDesc appendString:@"]"];
  return [NSString stringWithFormat:@"type: [%@], memory address: [%p], local main ID: [%@], \
local master ID: [%@], global ID: [%@], media type: [%@], %@",
          NSStringFromClass([self class]), self, _localMainIdentifier, _localMasterIdentifier,
          _globalIdentifier, [_mediaType description], relationsDesc];
}

@end
