//
//  FPCoordinatorDaoTests_8_1.m
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
#import <PELocal-Data/PELMDDL.h>
#import "FPUser.h"
#import "FPVehicle.h"
#import "FPDDLUtils.h"
#import "FPToggler.h"
#import "FPCoordDaoTestContext.h"
#import "PEUserCoordinatorDao.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_8_1)

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
  
  afterAll(^{
  });
  
  context(@"Tests", ^{
    it(@"Can create and edit a vehicle by itself and have it sync immediately", ^{
      FPUser *user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.201", 0, 0);
      user = (FPUser *)[_coordDao.userCoordinatorDao newLocalUserWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [user setName:@"Joe Smith"];
      [user setEmail:@"joe.smith@example.com"];
      [user setPassword:@"pa55w0rd"];
      [_coordDao.userCoordinatorDao establishRemoteAccountForLocalUser:user
                                         preserveExistingLocalEntities:YES
                                                       remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                                                     completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                                                 localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      [[theValue([_coordTestCtx success]) should] beYes];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()]; // should prune main user
      // sanity check that the user is ONLY in master
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      user = (FPUser *)[_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      // Now lets create a vehicle and immediately sync it
      FPVehicle *vehicle = [_coordDao vehicleWithName:@"My Bimmer"
                                        defaultOctane:@87
                                         fuelCapacity:[NSDecimalNumber decimalNumberWithString:@"20.5"]
                                             isDiesel:NO
                                        hasDteReadout:NO
                                        hasMpgReadout:NO
                                        hasMphReadout:NO
                                hasOutsideTempReadout:NO
                                                  vin:nil
                                                plate:nil];
      [[vehicle updatedAt] shouldBeNil];
      _mocker(@"http-response.vehicles.POST.201", 0, 0);
      __block BOOL saveSuccess = NO;
      [_coordDao saveNewAndSyncImmediateVehicle:vehicle
                                        forUser:user
                            notFoundOnServerBlk:^{}
                                     addlSuccessBlk:^{saveSuccess = YES;}
                             addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {}
                             addlTempRemoteErrorBlk:^{}
                                 addlRemoteErrorBlk:^(NSInteger fpErrMask) {}
                                    addlConflictBlk:^(FPVehicle *latestVehicle) {}
                                addlAuthRequiredBlk:^{}
                                          error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue(saveSuccess)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      NSDate *createdAt = [vehicle updatedAt];
      [createdAt shouldNotBeNil];
      // our user had to have been copied down to main from master in order for the
      // new vehicle to have been saved to its main_vehicle table
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      // since we did sync immediate, the vehicle should be in main AND master
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      // do a prune
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];      
      // now lets edit the vehicle
      vehicle = [[_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()] objectAtIndex:0];
      BOOL prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicle
                                 forUser:user
                                   error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [vehicle setName:@"My Blue Bimmer"];
      _mocker(@"http-response.vehicle.PUT.200", 0, 0);
      [_coordDao saveVehicle:vehicle
                       error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      saveSuccess = NO;
      [_coordDao markAsDoneEditingAndSyncVehicleImmediate:vehicle
                                                  forUser:user
                                      notFoundOnServerBlk:^{}
                                               addlSuccessBlk:^{saveSuccess = YES;}
                                       addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {}
                                       addlTempRemoteErrorBlk:^{}
                                           addlRemoteErrorBlk:^(NSInteger fpErrMask) {}
                                              addlConflictBlk:^(FPVehicle *latestVehicle) {}
                                          addlAuthRequiredBlk:^{}
                                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];      
      [[expectFutureValue(theValue(saveSuccess)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [[theValue([[vehicle updatedAt] timeIntervalSince1970]) should] beGreaterThan:theValue([createdAt timeIntervalSince1970])];
      [_coordDao pruneAllSyncedEntitiesWithError:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]]; // synced
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:0]]; // pruned
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [[[[[_coordDao vehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()] objectAtIndex:0] name] should] equal:@"My Blue Bimmer"];
      
      // now lets try another update, but this time we'll get a conflict response
      prepareForEditSuccess =
      [_coordDao prepareVehicleForEdit:vehicle
                               forUser:user
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[_numEntitiesBlk(TBL_MAIN_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_VEHICLE) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MAIN_USER) should] equal:[NSNumber numberWithInt:1]];
      [[_numEntitiesBlk(TBL_MASTER_USER) should] equal:[NSNumber numberWithInt:1]];
      [vehicle setName:@"Orange Bimmer"];
      _mocker(@"http-response.vehicle.PUT.409.1", 0, 0);
      [_coordDao saveVehicle:vehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      __block BOOL conflict = NO;
      __block FPVehicle *serverVehicle = nil;
      [_coordDao markAsDoneEditingAndSyncVehicleImmediate:vehicle
                                                  forUser:user
                                      notFoundOnServerBlk:^{}
                                               addlSuccessBlk:^{}
                                       addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {}
                                       addlTempRemoteErrorBlk:^{}
                                           addlRemoteErrorBlk:^(NSInteger fpErrMask) {}
                                              addlConflictBlk:^(FPVehicle *latestVehicle) { conflict = YES; serverVehicle = latestVehicle; }
                                          addlAuthRequiredBlk:^{}
                                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue(conflict)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
      [serverVehicle shouldNotBeNil];
      [[[serverVehicle name] should] equal:@"Black Bimmer"];
      
      // now lets try another update, but this time we'll get a 'not found' response
      prepareForEditSuccess =
      [_coordDao prepareVehicleForEdit:vehicle
                               forUser:user
                                 error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[theValue(prepareForEditSuccess) should] beYes];
      [vehicle setName:@"Red Bimmer"];
      _mocker(@"http-response.vehicle.PUT.404.1", 0, 0);
      [_coordDao saveVehicle:vehicle error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      __block BOOL notFound = NO;
      [_coordDao markAsDoneEditingAndSyncVehicleImmediate:vehicle
                                                  forUser:user
                                      notFoundOnServerBlk:^{ notFound = YES; }
                                               addlSuccessBlk:^{}
                                       addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {}
                                       addlTempRemoteErrorBlk:^{}
                                           addlRemoteErrorBlk:^(NSInteger fpErrMask) {}
                                              addlConflictBlk:^(FPVehicle *latestVehicle) {}
                                          addlAuthRequiredBlk:^{}
                                                    error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue(notFound)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
    });
  });
});

SPEC_END
