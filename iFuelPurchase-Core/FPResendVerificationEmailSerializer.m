//
//  FPResendVerificationEmailSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Paul Evans on 9/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import "FPResendVerificationEmailSerializer.h"

@implementation FPResendVerificationEmailSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return @{};
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [[NSObject alloc] init];
}

@end
