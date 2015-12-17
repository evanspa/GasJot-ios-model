//
//  FPModelSupportTests.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/7/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMModelSupport.h"
#import <Kiwi/Kiwi.h>
#import <PEHateoas-Client/HCMediaType.h>

SPEC_BEGIN(FPModelSupportSpec)

describe(@"FPModelSupport", ^{
  context(@"Equality", ^{
    
    __block PELMModelSupport *ms1;
    __block PELMModelSupport *ms2;
    
    beforeEach(^{
      ms1 =
        [[PELMModelSupport alloc] initWithLocalMainIdentifier:[NSNumber numberWithInt:0]
                                        localMasterIdentifier:nil
                                             globalIdentifier:@"http://someuri.com"
                                              mainEntityTable:nil
                                            masterEntityTable:nil
                                                    mediaType:[HCMediaType MediaTypeFromString:@"application/json"]
                                                    relations:nil];
      ms2 =
        [[PELMModelSupport alloc] initWithLocalMainIdentifier:[NSNumber numberWithInt:0]
                                        localMasterIdentifier:nil
                                             globalIdentifier:@"http://someuri.com"
                                              mainEntityTable:nil
                                            masterEntityTable:nil
                                                    mediaType:[HCMediaType MediaTypeFromString:@"application/json"]
                                                    relations:nil];
    });
    
    it(@"Works for 2 equal objects", ^{
      [[ms1 should] equal:ms2];
    });
    
/*    it(@"Are still considered equal even when local IDs are different", ^{
      [ms1 setLocalIdentifier:[NSNumber numberWithInt:1]];
      [[ms1 should] equal:ms2];
    });*/
    
    it(@"Works when global IDs are different", ^{
      [ms1 setGlobalIdentifier:@"abc"];
      [[ms1 shouldNot] equal:ms2];
    });
  });
});

SPEC_END
