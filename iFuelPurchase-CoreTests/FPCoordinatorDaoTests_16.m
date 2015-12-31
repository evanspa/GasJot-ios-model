//
//  FPCoordinatorDaoTests_16.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDaoImpl.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPPriceEvent.h"
#import "FPFuelStationType.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import "PEUserCoordinatorDao.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_16)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDaoImpl *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;

describe(@"FPCoordinatorDao", ^{
  
  beforeAll(^{
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:[NSBundle bundleForClass:[self class]]];
    _coordDao = [_coordTestCtx newStoreCoord];
    [_coordDao deleteUser:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
    _mocker = [_coordTestCtx newMocker];
  });
  
  afterAll(^{
  });
  
  context(@"Tests", ^{
    it(@"Price stream fetch is working", ^{
      _mocker(@"http-response.priceeventstream.GET.200", 0, 0);
      __block BOOL success = NO;
      __block NSArray *priceEventStream = nil;
      [_coordDao fetchPriceEventsNearLatitude:nil
                                    longitude:nil
                                       within:nil
                                      timeout:30
                          notFoundOnServerBlk:nil
                                   successBlk:^(NSArray *innerPriceEventStream) {
                                     success = YES;
                                     priceEventStream = innerPriceEventStream;
                                   }
                           remoteStoreBusyBlk:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                           tempRemoteErrorBlk:nil];
      [[expectFutureValue(theValue(success)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [priceEventStream shouldNotBeNil];
      [[priceEventStream should] haveCountOf:1];
      for (FPPriceEvent *priceEvent in priceEventStream) {
        FPFuelStationType *fsType = priceEvent.fsType;
        [fsType shouldNotBeNil];
        [[fsType.identifier should] equal:@(5)];
        [[priceEvent.price should] equal:[NSDecimalNumber decimalNumberWithString:@"2.999"]];
        [[theValue(priceEvent.isDiesel) should] equal:theValue(NO)];
        [[priceEvent.date should] equal:[NSDate dateWithTimeIntervalSince1970:1409644992.000]];
        [[priceEvent.latitude should] equal:[NSDecimalNumber decimalNumberWithString:@"35.0125209215553"]];
        [[priceEvent.longitude should] equal:[NSDecimalNumber decimalNumberWithString:@"-80.8517863328359 "]];
      }
    });
  });
});

SPEC_END
