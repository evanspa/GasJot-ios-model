//
//  FPCoordinatorDaoTests_12.m
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
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_12)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingObserver _observer;
__block FPCoordTestingNumValueFetcher _numValueFetcher;

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
    _numValueFetcher = [_coordTestCtx newNumValueFetcher];
  });
  
  afterAll(^{
  });
  
  context(@"Tests", ^{
    it(@"Can delete a user and have it sync via background job", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
      NSNumber *userLocalId = [user localMainIdentifier];
      NSNumber *masterUserId = _numValueFetcher(_coordDao, TBL_MAIN_USER, COL_MASTER_USER_ID, userLocalId);
      [masterUserId shouldNotBeNil];
      [[theValue([user editInProgress]) should] beNo];
      [[user globalIdentifier] shouldNotBeNil];
      BOOL prepareForEditSuccess =
        [_coordDao prepareUserForEdit:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[theValue([user editInProgress]) should] beYes];
      [[theValue([_coordTestCtx localSaveError]) should] beNo];
      _mocker(@"http-response.user.DELETE.204", 0, 0);
      __block BOOL saveSuccess = NO;
      [_coordDao deleteUser:user
        notFoundOnServerBlk:nil
             addlSuccessBlk:^{ saveSuccess = YES; }
     addlRemoteStoreBusyBlk:nil
     addlTempRemoteErrorBlk:nil
         addlRemoteErrorBlk:nil
            addlConflictBlk:nil
        addlAuthRequiredBlk:nil
                      error:nil];
      [[expectFutureValue(theValue(saveSuccess)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      [_numValueFetcher(_coordDao, TBL_MAIN_USER, COL_MASTER_USER_ID, userLocalId) shouldBeNil];
      [_numValueFetcher(_coordDao, TBL_MASTER_USER, COL_LOCAL_ID, masterUserId) shouldBeNil];
    });
  });
});

SPEC_END
