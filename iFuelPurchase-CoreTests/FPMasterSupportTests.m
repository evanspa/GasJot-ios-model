//
//  FPMasterSupportTests.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/7/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "PELMMasterSupport.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPMasterSupportSpec)

describe(@"FPMasterSupport", ^{
  context(@"Equality", ^{
    
    __block PELMMasterSupport *ms1;
    __block PELMMasterSupport *ms2;
    
    beforeEach(^{
      NSDate *now = [NSDate date];
      ms1 =
        [[PELMMasterSupport alloc] initWithLocalMainIdentifier:[NSNumber numberWithInt:0]
                                         localMasterIdentifier:[NSNumber numberWithInt:0]
                                              globalIdentifier:@"http://someuri.com"
                                               mainEntityTable:nil
                                             masterEntityTable:nil
                                                     mediaType:[HCMediaType MediaTypeFromString:@"application/json"]
                                                     relations:nil
                                                   deletedDate:now
                                                  lastModified:now];
      ms2 =
        [[PELMMasterSupport alloc] initWithLocalMainIdentifier:[NSNumber numberWithInt:0]
                                         localMasterIdentifier:[NSNumber numberWithInt:0]
                                              globalIdentifier:@"http://someuri.com"
                                               mainEntityTable:nil
                                             masterEntityTable:nil
                                                     mediaType:[HCMediaType MediaTypeFromString:@"application/json"]
                                                     relations:nil
                                                   deletedDate:now
                                                  lastModified:now];
    });
    
    it(@"Works for 2 equal objects", ^{
      [[ms1 should] equal:ms2];
    });
    
   /* it(@"Are still considered equal when local IDs are different", ^{
      [ms1 setLocalIdentifier:[NSNumber numberWithInt:1]];
      [[ms1 should] equal:ms2];
    }); */
    
    it(@"Works when global IDs are different", ^{
      [ms1 setGlobalIdentifier:@"abc"];
      [[ms1 shouldNot] equal:ms2];
    });
    
    it(@"Works when deleted dates are different", ^{
      [ms1 setDeletedDate:[NSDate dateWithTimeIntervalSinceNow:5000]];
      [[ms1 shouldNot] equal:ms2];
    });
    
    it(@"Works when last update dates are different", ^{
      [ms1 setLastModified:[NSDate dateWithTimeIntervalSinceNow:5000]];
      [[ms1 shouldNot] equal:ms2];
    });
  });
});

SPEC_END
