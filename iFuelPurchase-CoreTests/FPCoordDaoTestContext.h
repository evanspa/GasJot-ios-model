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
typedef NSNumber * (^FPCoordTestingNumValueFetcher)(FPCoordinatorDao *, NSString *, NSString *, NSNumber *);
typedef FPUser *(^FPCoordTestingFreshUserMaker)(NSString *, NSString *, NSString *, NSString *, NSString *, FPCoordinatorDao *, TLTransaction *, void (^)(void));
typedef FPUser * (^FPCoordTestingFreshJoeSmithMaker)(FPCoordinatorDao *, TLTransaction *, void (^waitBlock)(void));
typedef FPToggler * (^FPCoordTestingObserver)(NSArray *);
typedef void (^FPCoordTestingExpectedNumberOfEntitiesAsserter)(FPCoordinatorDao *, NSString *, int);
typedef NSNumber *(^FPCoordTestingNumEntitiesComputer)(NSString *);
typedef void (^FPCoordTestingMocker)(NSString *, NSInteger, NSInteger);
typedef void (^FPCoordTestingFlusher)(NSInteger);

FOUNDATION_EXPORT NSInteger const FPBackgroundActorId;
FOUNDATION_EXPORT NSInteger const FPForegroundActorId;

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

- (FPCoordTestingFlusher)newFlusherWithCoordDao:(FPCoordinatorDao *)coordDao;
- (FPCoordTestingMocker)newMocker;
- (FPCoordTestingNumEntitiesComputer)newNumEntitiesComputerWithCoordDao:(FPCoordinatorDao *)coordDao;
- (FPCoordTestingErrLogger)newErrLogger;
- (FPCoordTestingNewLocalSaveErrBlkMaker)newLocalSaveErrBlkMaker;
- (FPCoordTestingNewLocalFetchErrBlkMaker)newLocalFetchErrBlkMaker;
- (FPCoordTestingNewLocalBgErrBlkMaker)newLocalBgErrBlkMaker;
- (FPCoordTestingNewRemoteStoreBusyBlkMaker)newRemoteStoreBusyBlkMaker;
- (FPCoordTestingNew1ErrArgComplHandlerBlkMaker)new1ErrArgComplHandlerBlkMaker;

- (void(^)(void))entityBeingSyncedBlk;
- (void(^)(void))entityDeletedBlk;
- (void(^)(void))entityInConflictBlk;
- (void(^)(NSNumber *))entityBeingEditedByOtherActorBlk;

- (FPCoordTestingNumValueFetcher)newNumValueFetcher;
- (FPCoordTestingFreshUserMaker)newFreshUserMaker;
- (FPCoordTestingFreshJoeSmithMaker)newFreshJoeSmithMaker;
- (FPCoordTestingObserver)newObserver;

- (void)stopTimerForAsyncWork;
- (void)startTimerForAsyncWorkWithInterval:(NSInteger)timerInterval
                                  coordDao:(FPCoordinatorDao *)coordDao;

- (TLTransactionManager *)newTxnManager;
- (FPCoordinatorDao *)newStoreCoordWithTxnManager:(TLTransactionManager *)txnMgr;

@end
