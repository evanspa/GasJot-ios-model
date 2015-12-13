//
//  PEChangelogSerializer.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/11/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PEHateoas-Client/HCHalJsonSerializerExtensionSupport.h>

@interface PEChangelogSerializer : HCHalJsonSerializerExtensionSupport

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         changelogClass:(Class)changelogClass;

@end
