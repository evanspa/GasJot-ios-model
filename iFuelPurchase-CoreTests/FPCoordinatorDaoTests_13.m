//
//  FPCoordinatorDaoTests_13.m
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
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import "PEUserCoordinatorDao.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_13)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDaoImpl *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingObserver _observer;

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
    _observer = [_coordTestCtx newObserver];
  });
  
  context(@"Tests", ^{
    it(@"Gives expected behavior when remote master store gives error for User Creation", ^{
      FPUser *user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.500", 0, 0);
      user = (FPUser *)[_coordDao.userCoordinatorDao newLocalUserWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [user setName:@"Joe Smith"];
      [user setEmail:@"joe.smith@example.com"];
      [user setPassword:@"pa55w0rd"];
      [_coordDao.userCoordinatorDao establishRemoteAccountForLocalUser:user
                                         preserveExistingLocalEntities:YES
                                                       remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                                                     completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                                                 localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beNo];
      [[_coordTestCtx authToken] shouldBeNil];
      [[theValue([_coordTestCtx success]) should] beNo];
      [[theValue([_coordTestCtx remoteStoreBusy]) should] beNo];
      [[theValue([_coordTestCtx generalComplError]) should] beYes];
      [[theValue([_coordTestCtx localSaveError]) should] beNo];
    });
  });
});

SPEC_END
