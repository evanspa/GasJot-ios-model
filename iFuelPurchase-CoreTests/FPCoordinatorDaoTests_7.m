//
//  FPCoordinatorDaoTests_7.m
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
#import <PEHateoas-Client/HCUtils.h>
#import <PEHateoas-Client/HCRelation.h>
#import "FPKnownMediaTypes.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(FPCoordinatorDaoSpec_7)

__block FPCoordDaoTestContext *_coordTestCtx;
__block FPCoordinatorDao *_coordDao;
__block TLTransactionManager *_txnMgr;
__block FPCoordTestingNumEntitiesComputer _numEntitiesBlk;
__block FPCoordTestingMocker _mocker;
__block FPCoordTestingFlusher _flusher;
__block FPCoordTestingObserver _observer;

describe(@"FPCoordinatorDao", ^{
  
  void (^assertRelation)(NSString *, NSString *, NSString *, NSString *, NSString *, NSDictionary *) =
  ^(NSString *expectedRelName,
    NSString *expectedSubjectMediaType,
    NSString *expectedSubjectUri,
    NSString *expectedTargetMediaType,
    NSString *expectedTargetUri,
    NSDictionary *actualRelations) {
    HCRelation *rel = [actualRelations objectForKey:expectedRelName];
    [rel shouldNotBeNil];
    [[[rel name] should] equal:expectedRelName];
    HCResource *subjectRes = [rel subject];
    HCResource *targetRes = [rel target];
    [[[subjectRes mediaType] should] equal:[HCMediaType MediaTypeFromString:expectedSubjectMediaType]];
    [[[subjectRes uri] should] equal:[NSURL URLWithString:expectedSubjectUri]];
    [[[targetRes mediaType] should] equal:[HCMediaType MediaTypeFromString:expectedTargetMediaType]];
    [[[targetRes uri] should] equal:[NSURL URLWithString:expectedTargetUri]];
  };
  
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
    it(@"Can fetch an existing user (login)", ^{
      TLTransaction *txn = [_txnMgr transactionWithUsecase:@(FPTxnLogin)
                                                     error:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      FPUser *user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldBeNil];
      _mocker(@"http-response.users.POST.200", 0, 0);
      [_coordDao loginWithUsernameOrEmail:@"evansp2"
                                 password:@"1n53cur3"
                              transaction:txn
                          remoteStoreBusy:[_coordTestCtx newRemoteStoreBusyBlkMaker]()
                        completionHandler:[_coordTestCtx new1ErrArgComplHandlerBlkMaker]()
                    localSaveErrorHandler:[_coordTestCtx newLocalSaveErrBlkMaker]()];
      [[expectFutureValue(theValue([_coordTestCtx authTokenReceived])) shouldEventuallyBeforeTimingOutAfter(60)] beYes];
      user = [_coordDao userWithError:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [user shouldNotBeNil]; // sanity check
      [[[user name] should] equal:@"Paul Evans"];
      [[[user email] should] equal:@"evansp2@gmail.com"];
      [[[user username] should] equal:@"evansp2"];
      [[[user creationDate] should] equal:[HCUtils rfc7231DateFromString:@"Tue, 02 Sep 2014 8:03:12 GMT"]];
      NSDictionary *rels = [user relations];
      [[rels should] haveCountOf:4];
      assertRelation(FPVehiclesRelation,
                     [[FPKnownMediaTypes userMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100",
                     [[FPKnownMediaTypes vehicleMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100/vehicles",
                     rels);
      assertRelation(FPFuelStationsRelation,
                     [[FPKnownMediaTypes userMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100",
                     [[FPKnownMediaTypes fuelStationMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100/fuelstations",
                     rels);
      assertRelation(FPFuelPurchaseLogsRelation,
                     [[FPKnownMediaTypes userMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100",
                     [[FPKnownMediaTypes fuelPurchaseLogMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100/fplogs",
                     rels);
      assertRelation(FPEnvironmentLogsRelation,
                     [[FPKnownMediaTypes userMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100",
                     [[FPKnownMediaTypes environmentLogMediaTypeWithVersion:@"0.0.1"] description],
                     @"http://example.com/fp/users/U1123409100/envlogs",
                     rels);
      NSArray *vehicles = [_coordDao vehiclesForUser:user pageSize:5 error:[_coordTestCtx newLocalFetchErrBlkMaker]()];
      [vehicles shouldNotBeNil];
      [[vehicles should] haveCountOf:2];
      FPVehicle *vehicle = [vehicles objectAtIndex:1];
      [[[vehicle globalIdentifier] should] equal:@"http://example.com/fp/users/U1123409100/vehicles/V429"];
      [[[vehicle mediaType] should] equal:[HCMediaType MediaTypeFromString:@"application/vnd.fp.vehicle-v0.0.1+json"]];
      [[[vehicle lastModified] should] equal:[HCUtils rfc7231DateFromString:@"Fri, 06 Sep 2014 10:34:22 GMT"]];
      [[[vehicle name] should] equal:@"My Mazda"];
      [[[vehicle dateAdded] should] equal:[HCUtils rfc7231DateFromString:@"Fri, 06 Sep 2014 10:34:22 GMT"]];
      rels = [vehicle relations];
      [[rels should] haveCountOf:0];
    });
  });
});

SPEC_END
