//
//  FPCoordinatorDaoTests_14.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPNotificationNames.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_14)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingFlusher _flusher;
__block FPCoordTestingObserver _observer;

describe(@"FPCoordinatorDao", ^{
  
  beforeAll(^{
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:[NSBundle bundleForClass:[self class]]];
    _coordDao = [_coordTestCtx newStoreCoord];
    [_coordDao deleteAllUsers:^(NSError *error, int code, NSString *msg) { [_coordTestCtx setErrorDeletingUser:YES]; }];
    _numEntitiesBlk = [_coordTestCtx newNumEntitiesComputerWithCoordDao:_coordDao];
    _mocker = [_coordTestCtx newMocker];
    _flusher = [_coordTestCtx newFlusherWithCoordDao:_coordDao];
    _observer = [_coordTestCtx newObserver];
  });
  
  afterAll(^{
    [_coordTestCtx stopTimerForAsyncWork];
  });
  
  context(@"Tests", ^{
    it(@"Is working properly for creating and fetching a user", ^{
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.201", 0, 0);
      FPUser *localUser = [_coordDao newLocalUserWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [localUser setName:@"Joe Smith"];
      [localUser setEmail:@"joe.smith@example.com"];
      [localUser setUsername:@"smithjoe"];
      [localUser setPassword:@"pa55w0rd"];
      [_coordDao establishRemoteAccountForLocalUser:localUser
                      preserveExistingLocalEntities:YES
                                    remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                                  completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                              localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      [[_coordTestCtx authToken] shouldNotBeNil];
      [[[_coordTestCtx authToken] should] equal:@"1092348123049OLSDFJLIE001234"];
      [[theValue([_coordTestCtx success]) should] beYes];
      [[theValue([_coordTestCtx remoteStoreBusy]) should] beNo];
      [[theValue([_coordTestCtx generalComplError]) should] beNo];
      [[theValue([_coordTestCtx localSaveError]) should] beNo];      
      [_coordTestCtx setLocalFetchError:NO];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldNotBeNil];
    });
  });
});

SPEC_END
