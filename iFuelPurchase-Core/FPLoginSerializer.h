//
//  FPLoginSerializer.h
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/17/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PEHateoas-Client/HCHalJsonSerializerExtensionSupport.h>
#import "FPUserSerializer.h"

@interface FPLoginSerializer : HCHalJsonSerializerExtensionSupport

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
         userSerializer:(FPUserSerializer *)userSerializer;

@end
