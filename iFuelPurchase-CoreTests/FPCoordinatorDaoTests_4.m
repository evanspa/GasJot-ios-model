//
//  FPCoordinatorDaoTests_4.m
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
#import "FPLogging.h"

SPEC_BEGIN(FPCoordinatorDaoSpec_4)

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
    it(@"2 or more saves, followed by cancel-edit leaves entity in main table", ^{
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      user = [_coordDao newLocalUserWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      _mocker(@"http-response.users.POST.200", 0, 0);
      [_coordDao loginWithUsernameOrEmail:@"evansp2"
                                 password:@"1n53cur3"
             andLinkRemoteUserToLocalUser:user
            preserveExistingLocalEntities:YES
                          remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                        completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                    localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      // sanity checks
      [user shouldNotBeNil];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      FPVehicle *vehicle = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()][0];
      [vehicle shouldNotBeNil]; // sanity check
      BOOL prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
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
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      [_coordDao cancelEditOfVehicle:vehicle
                         editActorId:@(FPForegroundActorId)
                               error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // because this was first edit, cancelling blows away the vehicle from
      // main-vehicle table
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
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
      [vehicle setName:@"300ZX Edit 1"];
      [[theValue([vehicle editCount]) should] equal:theValue(1)];
      [_coordDao saveVehicle:vehicle
                 editActorId:@(FPForegroundActorId)
                       error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                             editActorId:@(FPForegroundActorId)
                       entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                           entityDeleted:[_coordTestCtx entityDeletedBlk]
                        entityInConflict:[_coordTestCtx entityInConflictBlk]
           entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([vehicle editCount]) should] equal:theValue(2)];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      [_coordDao cancelEditOfVehicle:vehicle
                         editActorId:@(FPForegroundActorId)
                               error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // this time, after cancelling, vehicle is still in main due to previous editing
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:2]];
      // sanity checking (making sure 2 are returned)
      NSArray *vehicles = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [[vehicles should] haveCountOf:2];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
      vehicle = vehicles[1];
      [[[vehicle name] should] equal:@"300ZX Edit 1"];
      [[theValue([vehicle editCount]) should] equal:theValue(1)]; // canceling previous edit decrements the edit count
      [[theValue([vehicle editInProgress]) should] beNo];
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                             editActorId:@(FPForegroundActorId)
                       entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                           entityDeleted:[_coordTestCtx entityDeletedBlk]
                        entityInConflict:[_coordTestCtx entityInConflictBlk]
           entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([vehicle editCount]) should] equal:theValue(2)]; // edit count is now back to 2 again
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                             editActorId:@(FPForegroundActorId)
                       entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                           entityDeleted:[_coordTestCtx entityDeletedBlk]
                        entityInConflict:[_coordTestCtx entityInConflictBlk]
           entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([vehicle editCount]) should] equal:theValue(3)];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                             editActorId:@(FPForegroundActorId)
                       entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                           entityDeleted:[_coordTestCtx entityDeletedBlk]
                        entityInConflict:[_coordTestCtx entityInConflictBlk]
           entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([vehicle editCount]) should] equal:theValue(4)];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [_coordDao markAsDoneEditingVehicle:vehicle
                              editActorId:@(FPForegroundActorId)
                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      // 1 more sanity check
      vehicle = [_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()][1];
      [[[vehicle name] should] equal:@"300ZX Edit 1"];
      [[theValue([vehicle editCount]) should] equal:theValue(4)];
      [[theValue([vehicle editInProgress]) should] beNo];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(2)];
    });
  });
});

SPEC_END
