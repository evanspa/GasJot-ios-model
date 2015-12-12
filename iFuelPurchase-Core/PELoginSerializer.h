//
//  PELoginSerializer.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCHalJsonSerializerExtensionSupport.h>
#import "PEUserSerializer.h"

@interface PELoginSerializer : HCHalJsonSerializerExtensionSupport

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
         userSerializer:(PEUserSerializer *)userSerializer;

@end
