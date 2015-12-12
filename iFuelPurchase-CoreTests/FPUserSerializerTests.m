//
//  FPUserSerializerTests.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/12/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PEUserSerializer.h"
#import "FPVehicleSerializer.h"
#import "FPUser.h"
#import "FPKnownMediaTypes.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPUserSerializerSpec)

describe(@"FPUserSerializer", ^{
    FPVehicleSerializer *vehicleSerializer =
      [[FPVehicleSerializer alloc] initWithMediaType:[FPKnownMediaTypes vehicleMediaTypeWithVersion:@"0.0.1"]
                                             charset:[HCCharset UTF8]
                     serializersForEmbeddedResources:@{}
                         actionsForEmbeddedResources:@{}];
    HCActionForEmbeddedResource actionForEmbeddedVehicle = ^(id user, id embeddedVehicle) {
      [(FPUser *)user addVehicle:embeddedVehicle];
    };
    PEUserSerializer *userSerializer =
      [[PEUserSerializer alloc] initWithMediaType:[FPKnownMediaTypes userMediaTypeWithVersion:@"0.0.1"]
                                          charset:[HCCharset UTF8]
                  serializersForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : vehicleSerializer}
                      actionsForEmbeddedResources:@{[[vehicleSerializer mediaType] description] : actionForEmbeddedVehicle}
                                        userClass:[FPUser class]];

    /*
     * ---------------------------------------------------------------------------
     * Test utility blocks
     * ---------------------------------------------------------------------------
     */

    NSDictionary *(^jsonObjFromFile)(NSString *) = ^ NSDictionary *(NSString *fileName) {
      NSStringEncoding enc;
      NSString *path = [[NSBundle bundleForClass:[self class]]
                                 pathForResource:[NSString stringWithFormat:@"json-strings/%@", fileName]
                                          ofType:@"json"];
      NSString *fileContents = [NSString stringWithContentsOfFile:path
                                                     usedEncoding:&enc
                                                            error:nil];
      NSData *fileContentsAsData =
        [fileContents dataUsingEncoding:NSUTF8StringEncoding];
      return [NSJSONSerialization JSONObjectWithData:fileContentsAsData
                                             options:0
                                               error:nil];
    };

    /*
     * ---------------------------------------------------------------------------
     * Contexts
     * ---------------------------------------------------------------------------
     */

    context(@"Works for varying JSON shapes", ^{
        it(@"Works when payload contains multiple embedded vehicle resources", ^{
            NSDictionary *jsonObj = jsonObjFromFile(@"user_with_embedded");
            [jsonObj shouldNotBeNil];
            HCDeserializedPair *pair = [userSerializer deserializeEmbeddedResource:jsonObj];
            [pair shouldNotBeNil];
            FPUser *user = [pair resourceModel];
            [user shouldNotBeNil];
            [[[user name] should] equal:@"Paul Evans"];
            [[[user email] should] equal:@"evansp2@gmail.com"];
            [[[user relations] should] haveCountOf:3];
            [[[user vehicles] should] haveCountOf:2];
          });
      });
  });

SPEC_END
