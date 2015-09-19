//
//  FPCoordDaoTestContext.h
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 1/5/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPUser.h"
#import "FPCoordinatorDao.h"
#import "FPToggler.h"

typedef void (^FPCoordTestingErrLogger)(NSError *, int, NSString *);
typedef void (^(^FPCoordTestingNewLocalSaveErrBlkMaker)(void))(NSError *, int, NSString *);
typedef void (^(^FPCoordTestingNewLocalFetchErrBlkMaker)(void))(NSError *, int, NSString *);
typedef void (^(^FPCoordTestingNewLocalBgErrBlkMaker)(void))(NSError *, int, NSString *);
typedef void (^(^FPCoordTestingNewRemoteStoreBusyBlkMaker)(void))(NSDate *);
typedef void (^(^FPCoordTestingNew1ErrArgComplHandlerBlkMaker)(void))(FPUser *, NSError *);
typedef void (^(^FPCoordTestingNew0ErrArgComplHandlerBlkMaker)(void))(NSError *);
typedef NSNumber * (^FPCoordTestingNumValueFetcher)(FPCoordinatorDao *, NSString *, NSString *, NSNumber *);
typedef FPUser *(^FPCoordTestingFreshUserMaker)(NSString *, NSString *, NSString *, NSString *, FPCoordinatorDao *, void (^)(void));
typedef FPUser * (^FPCoordTestingFreshJoeSmithMaker)(FPCoordinatorDao *, void (^waitBlock)(void));
typedef FPToggler * (^FPCoordTestingObserver)(NSArray *);
typedef void (^FPCoordTestingExpectedNumberOfEntitiesAsserter)(FPCoordinatorDao *, NSString *, int);
typedef NSNumber *(^FPCoordTestingNumEntitiesComputer)(NSString *);
typedef void (^FPCoordTestingMocker)(NSString *, NSInteger, NSInteger);

@interface FPCoordDaoTestContext : NSObject

#pragma mark - Initializers

- (id)initWithTestBundle:(NSBundle *)testBundle;

#pragma mark - Properties

@property (nonatomic) BOOL authTokenReceived;
@property (nonatomic) BOOL errorDeletingUser;
@property (nonatomic) BOOL success;
@property (nonatomic) BOOL localFetchError;
@property (nonatomic) BOOL localSaveError;
@property (nonatomic) BOOL remoteStoreBusy;
@property (nonatomic) BOOL generalComplError;
@property (nonatomic) NSString *authToken;
@property (nonatomic) BOOL prepareForEditEntityBeingSynced;
@property (nonatomic) BOOL prepareForEditEntityDeleted;
@property (nonatomic) BOOL prepareForEditEntityInConflict;
@property (nonatomic) BOOL prepareForEditEntityBeingEditedByOtherActor;
@property (nonatomic) NSNumber *prepareForEditEntityBeingEditedByOtherActorId;

#pragma mark - Test Helpers

- (FPCoordTestingMocker)newMocker;
- (FPCoordTestingNumEntitiesComputer)newNumEntitiesComputerWithCoordDao:(FPCoordinatorDao *)coordDao;
- (FPCoordTestingErrLogger)newErrLogger;
- (FPCoordTestingNewLocalSaveErrBlkMaker)newLocalSaveErrBlkMaker;
- (FPCoordTestingNewLocalFetchErrBlkMaker)newLocalFetchErrBlkMaker;
- (FPCoordTestingNewLocalBgErrBlkMaker)newLocalBgErrBlkMaker;
- (FPCoordTestingNewRemoteStoreBusyBlkMaker)newRemoteStoreBusyBlkMaker;
- (FPCoordTestingNew1ErrArgComplHandlerBlkMaker)new1ErrArgComplHandlerBlkMaker;
- (FPCoordTestingNew0ErrArgComplHandlerBlkMaker)new0ErrArgComplHandlerBlkMaker;

- (FPCoordTestingNumValueFetcher)newNumValueFetcher;
- (FPCoordTestingFreshUserMaker)newFreshUserMaker;
- (FPCoordTestingFreshJoeSmithMaker)newFreshJoeSmithMaker;
- (FPCoordTestingObserver)newObserver;

- (FPCoordinatorDao *)newStoreCoord;

@end
