//
//  FPCoordinatorDaoTests_13.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <fuelpurchase-common/FPTransactionCodes.h>
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

SPEC_BEGIN(FPCoordinatorDaoSpec_13)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block TLTransactionManager *_txnMgr;
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
    _txnMgr = [_coordTestCtx newTxnManager];
    _coordDao = [_coordTestCtx newStoreCoordWithTxnManager:_txnMgr];
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
    it(@"Gives expected behavior when remote master store gives error for User Creation", ^{
      TLTransaction *txn = [_txnMgr transactionWithUsecase:@(FPTxnCreateAccount)
                                                     error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.500", 0, 0);
      user = [_coordDao userWithName:@"Joe Smith"
                              email:@"joe.smith@example.com"
                           username:@"smithjoe"
                           password:@"pa55w0rd"
                       creationDate:[NSDate date]];
      [_coordDao immediateRemoteSyncSaveNewUser:user
                                    transaction:txn
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
