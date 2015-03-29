//
//  FPCoordinatorDaoTests_12.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/23/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPCoordinatorDao.h"
#import "FPCoordinatorDao+AdditionsForTesting.h"
#import <PEFuelPurchase-Common/FPTransactionCodes.h>
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

SPEC_BEGIN(FPCoordinatorDaoSpec_12)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block TLTransactionManager *_txnMgr;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingFlusher _flusher;
__block FPCoordTestingObserver _observer;
__block FPCoordTestingNumValueFetcher _numValueFetcher;

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
    _numValueFetcher = [_coordTestCtx newNumValueFetcher];
  });
  
  afterAll(^{
    [_coordTestCtx stopTimerForAsyncWork];
  });
  
  context(@"Tests", ^{
    it(@"Can delete a user and have it sync via background job", ^{
      TLTransaction *txn = [_txnMgr transactionWithUsecase:@(FPTxnCreateAccount)
                                                     error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, txn, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      NSNumber *userLocalId = [user localMainIdentifier];
      [[theValue([user editInProgress]) should] beNo];
      [[user globalIdentifier] shouldNotBeNil];
      BOOL prepareForEditSuccess =
        [_coordDao prepareUserForEdit:user
                          editActorId:@(FPForegroundActorId)
                    entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                        entityDeleted:[_coordTestCtx entityDeletedBlk]
                     entityInConflict:[_coordTestCtx entityInConflictBlk]
        entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[theValue([user editInProgress]) should] beYes];
      [[theValue([_coordTestCtx localSaveError]) should] beNo];
      [_coordDao markAsDeletedUser:user
                       editActorId:@(FPForegroundActorId)
                             error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue([_coordTestCtx localSaveError]) should] beNo];
      [[theValue([user deleted]) should] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldBeNil];
      // sanity check and make sure the user row physically exists in our main/
      // master user tables
      NSNumber *masterUserId = _numValueFetcher(_coordDao, TBL_MAIN_USER, COL_MASTER_USER_ID, userLocalId);
      [masterUserId shouldNotBeNil];
      [_numValueFetcher(_coordDao, TBL_MASTER_USER, COL_LOCAL_ID, masterUserId) shouldNotBeNil];
      FPToggler *syncCompleteToggler = _observer(@[FPUserSynced]);
      _mocker(@"http-response.user.DELETE.204", 0, 0);
      [_coordTestCtx startTimerForAsyncWorkWithInterval:1 coordDao:_coordDao];
      [[expectFutureValue(theValue([syncCompleteToggler value])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[theValue([_coordTestCtx localFetchError]) should] beNo];
      [user shouldBeNil];
      // TODO - re-enable once you have deletes working properly...
      //[_numValueFetcher(_coordDao, TBL_MAIN_USER, COL_MASTER_USER_ID, userLocalId) shouldBeNil];
      //[_numValueFetcher(_coordDao, TBL_MASTER_USER, COL_LOCAL_ID, masterUserId) shouldBeNil];
    });
  });
});

SPEC_END
