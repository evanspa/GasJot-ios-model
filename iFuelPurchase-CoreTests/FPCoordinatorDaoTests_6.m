//
//  FPCoordinatorDaoTests_6.m
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
#import <PEHateoas-Client/HCUtils.h>
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_6)

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
    it(@"Can fetch an existing user and view vehicles using pagination w/logout", ^{
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.200.1", 0, 0);
      [_coordDao loginWithUsernameOrEmail:@"evansp2"
                                 password:@"1n53cur3"
                          remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                        completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                    localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil]; // sanity check
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(20)];
      NSArray *vehicles = [_coordDao vehiclesForUser:user pageSize:5 error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:5];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V19"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V18"];
      [[[vehicles[3] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V17"];
      [[[vehicles[4] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V16"];
      vehicles = [_coordDao vehiclesForUser:user
                                  pageSize:5
                           beforeDateAdded:[vehicles[4] dateAdded]
                                     error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      // SIDE-BAR - lets test our "numVehiclesForUser:newerThan:error:" message
      [[theValue([_coordDao numVehiclesForUser:user
                                     newerThan:[HCUtils rfc7231DateFromString:@"Fri, 06 Sep 2014 10:34:13 GMT"] // V11's 'dateAdded' date
                                         error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(9)];
      
      [[theValue([_coordDao numVehiclesForUser:user
                                     newerThan:[HCUtils rfc7231DateFromString:@"Fri, 06 Sep 2014 10:34:03 GMT"] // V1's 'dateAdded' date
                                         error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(19)];
      [[theValue([_coordDao numVehiclesForUser:user
                                     newerThan:[HCUtils rfc7231DateFromString:@"Fri, 06 Sep 2014 10:34:02 GMT"] // all Vs are newer than this
                                         error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(20)];
      [[theValue([_coordDao numVehiclesForUser:user
                                     newerThan:[HCUtils rfc7231DateFromString:@"Sat, 07 Sep 2014 04:34:57 GMT"] // no Vs are newer than this
                                         error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(0)];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:5];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V15"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V14"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V13"];
      [[[vehicles[3] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V12"];
      [[[vehicles[4] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V11"];
      
      // now lets try an edge case (page size = 0)
      vehicles = [_coordDao vehiclesForUser:user
                                  pageSize:0
                                     error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:0];
      
      // another edge case (page size = size of full data set)
      vehicles = [_coordDao vehiclesForUser:user
                                  pageSize:20
                                     error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:20];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[19] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V1"];
      
      // another edge case (page size > size of full data set)
      vehicles = [_coordDao vehiclesForUser:user
                                  pageSize:21
                                     error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:20];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[19] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V1"];
      
      // Okay, so now that we know pagination is working when ALL the vehicles
      // are sitting in the vehicle-master, lets make sure things are still working
      // when we put some in 'edit-in-progress' mode, and thus are sitting in
      // vehicle-main.
      BOOL prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicles[0] // V20
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
      prepareForEditSuccess =
        [_coordDao prepareVehicleForEdit:vehicles[6] // V14
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
      
      // vehicles[0] should be V20, with edit-in-progress = YES
      vehicles = [_coordDao vehiclesForUser:user pageSize:3 error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:3];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V19"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V18"];
      [[theValue([vehicles[0] editInProgress]) should] beYes];
      [[theValue([vehicles[1] editInProgress]) should] beNo];
      [[theValue([vehicles[2] editInProgress]) should] beNo];
      
      // All 3 from master-vehicle
      vehicles = [_coordDao vehiclesForUser:user
                                   pageSize:3
                            beforeDateAdded:[vehicles[2] dateAdded]
                                      error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:3];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V17"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V16"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V15"];
      [[theValue([vehicles[0] editInProgress]) should] beNo];
      [[theValue([vehicles[1] editInProgress]) should] beNo];
      [[theValue([vehicles[2] editInProgress]) should] beNo];
      
      // vehicles[0] should be V14, with edit-in-progress = YES
      vehicles = [_coordDao vehiclesForUser:user
                                   pageSize:3
                            beforeDateAdded:[vehicles[2] dateAdded]
                                      error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:3];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V14"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V13"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V12"];
      [[theValue([vehicles[0] editInProgress]) should] beYes];
      [[theValue([vehicles[1] editInProgress]) should] beNo];
      [[theValue([vehicles[2] editInProgress]) should] beNo];
      
      // get a page of 10, with indexes 0 and 6 coming from main-vehicle
      vehicles = [_coordDao vehiclesForUser:user pageSize:10 error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:10];
      [[[vehicles[0] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V19"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V18"];
      [[[vehicles[3] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V17"];
      [[[vehicles[4] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V16"];
      [[[vehicles[5] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V15"];
      [[[vehicles[6] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V14"];
      [[[vehicles[7] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V13"];
      [[[vehicles[8] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V12"];
      [[[vehicles[9] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V11"];
      [[theValue([vehicles[0] editInProgress]) should] beYes]; // from main vehicle
      [[theValue([vehicles[1] editInProgress]) should] beNo];
      [[theValue([vehicles[2] editInProgress]) should] beNo];
      [[theValue([vehicles[3] editInProgress]) should] beNo];
      [[theValue([vehicles[4] editInProgress]) should] beNo];
      [[theValue([vehicles[5] editInProgress]) should] beNo];
      [[theValue([vehicles[6] editInProgress]) should] beYes]; // from main vehicle
      [[theValue([vehicles[7] editInProgress]) should] beNo];
      [[theValue([vehicles[8] editInProgress]) should] beNo];
      [[theValue([vehicles[9] editInProgress]) should] beNo];

      // sanity check
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(20)];
      
      // lets create a new vehicle, and make sure it comes back in our paged results
      FPVehicle *newVehicle = [_coordDao vehicleWithName:@"My Z32" dateAdded:[NSDate date]];
      [_coordDao saveNewVehicle:newVehicle forUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      vehicles = [_coordDao vehiclesForUser:user pageSize:3 error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:3];
      [[[vehicles[0] name] should] equal:@"My Z32"];
      [[vehicles[0] globalIdentifier] shouldBeNil];
      [[[vehicles[1] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V20"];
      [[[vehicles[2] globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V19"];
      [[theValue([_coordDao numVehiclesForUser:user error:[_coordTestCtx newLocalFetchErrBlkMaker]()]) should] equal:theValue(21)];
      
      // finally, lets make sure we can do a 'logout'
      [_coordDao logoutUser:user error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
    });
  });
});

SPEC_END
