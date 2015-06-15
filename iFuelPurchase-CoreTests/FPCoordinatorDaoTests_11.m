//
//  FPCoordinatorDaoTests_11.m
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
#import <PEWire-Control/PEHttpResponseSimulator.h>
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_11)

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
    it(@"Can edit a user and have it sync via immediately", ^{
      FPUser *user = [_coordTestCtx newFreshJoeSmithMaker](_coordDao, ^{
        [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      });
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
      [user setName:@"Paul Evans"];
      [user setEmail:@"paul.evans@example.com"];
      
      FPToggler *toggler = _observer(@[FPUserSynced]);
      _mocker(@"http-response.user.PUT.204", 0, 0);
      __block BOOL saveSuccess = NO;
      [_coordDao markAsDoneEditingAndSyncUserImmediate:user
                                           editActorId:@(FPForegroundActorId)
                                            successBlk:^{saveSuccess = YES;}
                                        remoteErrorBlk:^(NSError *err) {}
                                    remoteStoreBusyBlk:^(NSDate *retryAfter) {}
                                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue(saveSuccess)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue([toggler value]) should] beYes];
      // notice that I didn't even have to start the flusher job!
      
      // explicitly get the user from master
      user = [[_coordDao localDao] masterUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil];
      [[[user name] should] equal:@"Paul Evans"];
      [[[user email] should] equal:@"paul.evans@example.com"];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[[_coordDao localDao] mainUserWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()] shouldBeNil]; // it should have been pruned
      
      [_coordDao prepareUserForEdit:user
                        editActorId:@(FPForegroundActorId)
                  entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                      entityDeleted:[_coordTestCtx entityDeletedBlk]
                   entityInConflict:[_coordTestCtx entityInConflictBlk]
      entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                              error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [PEHttpResponseSimulator simulateCannotConnectToHostForRequestUrl:[NSURL URLWithString:@"http://example.com/fp/users/U8890209302"]
                                                   andRequestHttpMethod:@"PUT"];
      __block BOOL saveFailed = NO;
      [_coordDao markAsDoneEditingAndSyncUserImmediate:user
                                           editActorId:@(FPForegroundActorId)
                                            successBlk:^{}
                                        remoteErrorBlk:^(NSError *err) {saveFailed = YES;}
                                    remoteStoreBusyBlk:^(NSDate *retryAfter) {}
                                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue(saveFailed)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
    });
  });
});

SPEC_END
