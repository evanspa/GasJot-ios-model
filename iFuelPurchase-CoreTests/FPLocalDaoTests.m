 //
//  FPLocalDaoTests.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 8/5/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPLocalDao.h"
#import <FMDB/FMDatabase.h>
#import "FPCoordDaoTestContext.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <Kiwi/Kiwi.h>

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

SPEC_BEGIN(FPLocalDaoSpec)

describe(@"FPLocalDao", ^{

  __block FPLocalDao *localDao;
  __block FPCoordDaoTestContext *_coordTestCtx;

  /*
   * ---------------------------------------------------------------------------
   * Test utility blocks
   * ---------------------------------------------------------------------------
   */

  void (^errLogger)(NSError *, int, NSString *) =
    ^(NSError *err, int errCode, NSString *errMsg) {
    DDLogError(@"Error code: [%d], error msg: [%@], error: [%@]", errCode, errMsg, err);
  };
  
  HCMediaType *(^appJsonMediaType)(void) = ^HCMediaType *{
    return [HCMediaType MediaTypeFromString:@"application/json"];
  };

  /*
   * ---------------------------------------------------------------------------
   * Specs
   * ---------------------------------------------------------------------------
   */

  beforeEach(^{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSURL *sqliteDataFileUrl =
    [testBundle URLForResource:@"sqlite-datafile-for-testing"
                 withExtension:@"data"];
    NSString *sqliteDataFilePath = [sqliteDataFileUrl path];
    [[NSFileManager defaultManager] removeItemAtPath:sqliteDataFilePath
                                               error:nil];
    DDLogDebug(@"FPLocalDaoTest SQLite data file: [%@]", sqliteDataFilePath);
    localDao = [[FPLocalDao alloc] initWithSqliteDataFilePath:sqliteDataFilePath];
    [localDao initializeDatabaseWithError:errLogger];
    FPUser *user = [localDao userWithError:errLogger];
    [localDao deleteUser:user error:errLogger];
    _coordTestCtx = [[FPCoordDaoTestContext alloc] initWithTestBundle:testBundle];
  });
  
  context(@"Fuel Station entity operations", ^{
    it(@"Just works", ^{
      // =======================================================================
      // First we try to fetch the user instance, knowing the database is empty,
      // and sanity-checking that we get a nil result.
      // =======================================================================
      FPUser *user = [localDao userWithError:errLogger];
      [user shouldBeNil];
      
      // =======================================================================
      // So now we create one, and save it.
      // =======================================================================
      user = [FPUser userWithName:@"John Smith"
                            email:@"jsmith@example.com"
                         username:@"jsmith"
                         password:@"IFJSOSKDF02910"
                     creationDate:[NSDate date]
                        mediaType:appJsonMediaType()];
      [user setGlobalIdentifier:@"http://rest.ex.com/jsmith"];
      [user setLastModified:[NSDate date]];
      [localDao saveNewUser:user error:errLogger]; // this saves it into master-user table
      
      // =======================================================================
      // Now lets do some fuel station stuff.  Lets fetch all our existing fuel stations
      // (which should be an empty set), create a new one, save it, and make
      // sure it comes back when we re-fetch them.
      // =======================================================================
      NSArray *fetchedFuelStations = [localDao fuelStationsForUser:user pageSize:5 error:errLogger];
      [fetchedFuelStations shouldNotBeNil];
      [[fetchedFuelStations should] beEmpty];
      FPFuelStation *fuelStation = [FPFuelStation fuelStationWithName:@"Exxon Express"
                                                                 city:@"Charlotte"
                                                                state:@"NC"
                                                                  zip:@"28277"
                                                             latitude:nil
                                                            longitude:nil
                                                            dateAdded:[NSDate date]
                                                            mediaType:appJsonMediaType()];
      [localDao saveNewFuelStation:fuelStation forUser:user error:errLogger];
      fetchedFuelStations = [localDao fuelStationsForUser:user pageSize:5 error:errLogger];
      [fetchedFuelStations shouldNotBeNil];
      [[fetchedFuelStations should] haveCountOf:1];
      FPFuelStation *fetchedFuelStation = [fetchedFuelStations objectAtIndex:0];
      [[fuelStation should] equal:fetchedFuelStation];
      
      // =======================================================================
      // Lets create another, re-fetch 'em, and verify their order is correct.
      // =======================================================================
      FPFuelStation *fuelStation2 = [FPFuelStation fuelStationWithName:@"Kangaroo Express"
                                                                  city:@"Matthews"
                                                                 state:@"NC"
                                                                   zip:@"28207"
                                                              latitude:nil
                                                             longitude:nil
                                                             dateAdded:[NSDate date]
                                                             mediaType:appJsonMediaType()];
      [localDao saveNewFuelStation:fuelStation2 forUser:user error:errLogger];
      fetchedFuelStations = [localDao fuelStationsForUser:user pageSize:5 error:errLogger];
      [[fetchedFuelStations should] haveCountOf:2];
      [[fuelStation should] equal:[fetchedFuelStations objectAtIndex:1]];
      [[fuelStation2 should] equal:[fetchedFuelStations objectAtIndex:0]];
      
      // =======================================================================
      // At this point the fuel stations are saved in the local main store.  Our goal
      // is to make changes to one of them and save them.  In order to be able to
      // do this, we must first prepare a fuel station for editing.
      // =======================================================================
      
      // Before we prepare a fuel station for editing, lets make sure trying to edit
      // and saving a fuel station raises the appropriate exception.
      [[theBlock(^ { [localDao saveFuelStation:fuelStation
                                   editActorId:@(FPForegroundActorId)
                                         error:errLogger]; }) should]
       raiseWithName:NSInternalInconsistencyException];
      
      // Now we prepare the fuelStation for editing.
      [[fuelStation dateCopiedFromMaster] shouldBeNil]; // sanity check
      [[theValue([fuelStation editInProgress]) should] beNo]; // sanity check
      BOOL prepareForEditSuccess =
        [localDao prepareFuelStationForEdit:fuelStation
                                    forUser:user
                                editActorId:@(FPForegroundActorId)
                          entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                              entityDeleted:[_coordTestCtx entityDeletedBlk]
                           entityInConflict:[_coordTestCtx entityInConflictBlk]
              entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                      error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[fuelStation dateCopiedFromMaster] shouldBeNil]; // we have not yet synced w/master
      [[theValue([fuelStation editInProgress]) should] beYes];
      
      // =======================================================================
      // Now lets change some properties, save the fuel station, re-fetch, and do
      // another equality check.
      // =======================================================================
      [fuelStation setName:@"Exxon eXpress fuel"];
      [localDao saveFuelStation:fuelStation
                    editActorId:@(FPForegroundActorId)
                          error:errLogger];
      fetchedFuelStations = [localDao fuelStationsForUser:user pageSize:5 error:errLogger];
      [[fetchedFuelStations should] haveCountOf:2];
      [[fuelStation should] equal:[fetchedFuelStations objectAtIndex:1]];
    });
  });
  
  context(@"Vehicle entity operations", ^{
    it(@"Just works", ^{
      // =======================================================================
      // First we try to fetch the user instance, knowing the database is empty,
      // and sanity-checking that we get a nil result.
      // =======================================================================
      FPUser *user = [localDao userWithError:errLogger];
      [user shouldBeNil];
      
      // =======================================================================
      // So now we create one, and save it.
      // =======================================================================
      user = [FPUser userWithName:@"John Smith"
                            email:@"jsmith@example.com"
                         username:@"jsmith"
                         password:@"IFJSOSKDF02910"
                     creationDate:[NSDate date]
                        mediaType:appJsonMediaType()];
      [user setGlobalIdentifier:@"http://rest.ex.com/jsmith"];
      [user setLastModified:[NSDate date]];
      [localDao saveNewUser:user error:errLogger]; // this saves it into master-user table
      
      // =======================================================================
      // Now lets do some vehicle stuff.  Lets fetch all our existing vehicles
      // (which should be an empty set), create a new one, save it, and make
      // sure it comes back when we re-fetch them.
      // =======================================================================
      NSArray *fetchedVehicles = [localDao vehiclesForUser:user pageSize:5 error:errLogger];
      [fetchedVehicles shouldNotBeNil];
      [[fetchedVehicles should] beEmpty];
      FPVehicle *vehicle = [FPVehicle vehicleWithName:@"My Beem"
                                            dateAdded:[NSDate date]
                                            mediaType:appJsonMediaType()];
      [localDao saveNewVehicle:vehicle forUser:user error:errLogger];      
      fetchedVehicles = [localDao vehiclesForUser:user pageSize:5 error:errLogger];
      [fetchedVehicles shouldNotBeNil];
      [[fetchedVehicles should] haveCountOf:1];
      FPVehicle *fetchedVehicle = [fetchedVehicles objectAtIndex:0];
      [[vehicle should] equal:fetchedVehicle];
       
      // =======================================================================
      // Lets create another, re-fetch 'em, and verify their order is correct.
      // =======================================================================
      FPVehicle *vehicle2 = [FPVehicle vehicleWithName:@"My Mazda"
                                            dateAdded:[NSDate date]
                                             mediaType:appJsonMediaType()];
      [localDao saveNewVehicle:vehicle2 forUser:user error:errLogger];
      fetchedVehicles = [localDao vehiclesForUser:user pageSize:5 error:errLogger];
      [[fetchedVehicles should] haveCountOf:2];
      [[vehicle should] equal:[fetchedVehicles objectAtIndex:1]];
      [[vehicle2 should] equal:[fetchedVehicles objectAtIndex:0]];
      
      // =======================================================================
      // At this point the vehicles are saved in the local main store.  Our goal
      // is to make changes to one of them and save them.  In order to be able to
      // do this, we must first prepare a vehicle for editing.
      // =======================================================================
      
      // Before we prepare a vehicle for editing, lets make sure trying to edit
      // and saving a vehicle raises the appropriate exception.
      [[theBlock(^ { [localDao saveVehicle:vehicle
                               editActorId:@(FPForegroundActorId)
                                     error:errLogger]; }) should]
       raiseWithName:NSInternalInconsistencyException];
      
      // Now we prepare the vehicle for editing.
      [[vehicle dateCopiedFromMaster] shouldBeNil]; // sanity check
      [[theValue([vehicle editInProgress]) should] beNo]; // sanity check
      BOOL prepareForEditSuccess =
        [localDao prepareVehicleForEdit:vehicle
                                forUser:user
                            editActorId:@(FPForegroundActorId)
                      entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                          entityDeleted:[_coordTestCtx entityDeletedBlk]
                       entityInConflict:[_coordTestCtx entityInConflictBlk]
          entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                                  error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[vehicle dateCopiedFromMaster] shouldBeNil]; // we have not yet synced w/master
      [[theValue([vehicle editInProgress]) should] beYes];
      
      // =======================================================================
      // Now lets change some properties, save the vehicle, re-fetch, and do
      // another equality check.
      // =======================================================================
      [vehicle setName:@"My 328i"];
      [localDao saveVehicle:vehicle
                editActorId:@(FPForegroundActorId)
                      error:errLogger];
      fetchedVehicles = [localDao vehiclesForUser:user pageSize:5 error:errLogger];
      [[fetchedVehicles should] haveCountOf:2];
      [[vehicle should] equal:[fetchedVehicles objectAtIndex:1]];
    });
  });

  context(@"User entity operations", ^{
    it(@"Just works", ^{

      // =======================================================================
      // First we try to fetch the user instance, knowing the database is empty,
      // and sanity-checking that we get a nil result.
      // =======================================================================
      FPUser *user = [localDao userWithError:errLogger];
      [user shouldBeNil];

      // =======================================================================
      // So now we create one, and save it.
      // =======================================================================
      user = [FPUser userWithName:@"John Smith"
                            email:@"jsmith@example.com"
                         username:@"jsmith"
                     password:@"IFJSOSKDF02910"
                     creationDate:[NSDate date]
                        mediaType:appJsonMediaType()];
      [user setGlobalIdentifier:@"http://rest.ex.com/jsmith"];
      [user setLastModified:[NSDate date]];
      [localDao saveNewUser:user error:errLogger];

      // =======================================================================
      // We re-fetch the user, make sure its not nil, and that the fetched user
      // object is equal to the instance that we just saved.
      // =======================================================================
      FPUser *fetchedUser = [localDao userWithError:errLogger];
      [fetchedUser shouldNotBeNil];
      [[fetchedUser localMasterIdentifier] shouldNotBeNil];

      // before we compare our fetched user with the original, copy the fetched
      // user's local ID to our original; now, our fetched user should be
      // identical to our original user
      [user setLocalMasterIdentifier:[fetchedUser localMasterIdentifier]];
      [[user should] equal:fetchedUser];

      // =======================================================================
      // At this point the user is saved in the local master store.  Our goal
      // is to make changes to the user and save them.  In order to be able to
      // do this, we must first prepare the user for editing.  This will copying
      // the master user entity table to the main user entity table.
      // =======================================================================

      // Before we prepare the user for editing, lets make sure trying to edit
      // and saving the user now raises the appropriate exception.
      [[theBlock(^ { [localDao saveUser:user
                            editActorId:@(FPForegroundActorId)
                                  error:errLogger]; }) should]
        raiseWithName:NSInternalInconsistencyException];

      // Now we prepare the user for editing.
      [[user dateCopiedFromMaster] shouldBeNil]; // sanity check
      [[theValue([user editInProgress]) should] beNo]; // sanity check
      BOOL prepareForEditSuccess =
        [localDao prepareUserForEdit:user
                         editActorId:@(FPForegroundActorId)
                   entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                       entityDeleted:[_coordTestCtx entityDeletedBlk]
                    entityInConflict:[_coordTestCtx entityInConflictBlk]
       entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                               error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [[user dateCopiedFromMaster] shouldNotBeNil];
      [[theValue([user editInProgress]) should] beYes];

      // =======================================================================
      // Now lets change some properties, save the user, re-fetch it, and do
      // another equality check.
      // =======================================================================
      [user setName:@"Jack Ryan"];
      [user setUsername:@"jryan"];
      [user setPassword:@"_____"];
      [user setEmail:@"jack.ryan@gmail.com"];
      [localDao saveUser:user
             editActorId:@(FPForegroundActorId)
                   error:errLogger];
      fetchedUser = [localDao userWithError:errLogger];
      [[user should] equal:fetchedUser];

      // =======================================================================
      // Since we're done editing our user, we'll mark it as edit-complete.
      // =======================================================================
      [localDao markAsDoneEditingUser:user
                          editActorId:@(FPForegroundActorId)
                                error:errLogger];
      [[theValue([user editInProgress]) should] beNo];
      fetchedUser = [localDao userWithError:errLogger];
      [[user should] equal:fetchedUser];
      
      // =======================================================================
      // Now lets prepare the user for edit, change some properties, and then
      // cancel the edit.
      // =======================================================================
      [[theBlock(^ { [localDao cancelEditOfUser:user
                                    editActorId:@(FPForegroundActorId)
                                          error:errLogger]; }) should]
       raiseWithName:NSInternalInconsistencyException]; // we cannot cancel w/out first doing a 'prepare-for-edit'
      fetchedUser = [localDao userWithError:errLogger]; // sanity check
      [[user should] equal:fetchedUser];
      prepareForEditSuccess =
        [localDao prepareUserForEdit:user
                         editActorId:@(FPForegroundActorId)
                   entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                       entityDeleted:[_coordTestCtx entityDeletedBlk]
                    entityInConflict:[_coordTestCtx entityInConflictBlk]
       entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                               error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [user setName:@"Jim Grear"];
      [localDao cancelEditOfUser:user
                     editActorId:@(FPForegroundActorId)
                           error:errLogger];
      fetchedUser = [localDao userWithError:errLogger];
      [[[fetchedUser name] should] equal:@"Jack Ryan"]; // 'Jack' is from our last successful save
      
      // =======================================================================
      // Now lets mark the user for deletion.  FYI, after doing a mark-for-
      // deletion, we don't have to invoke 'markAsDoneEditing' - the editInProgress
      // flag will have been set to NO by 'markAsDeletedUser'.
      // =======================================================================
      user = [localDao userWithError:errLogger];
      [[theBlock(^ { [localDao markAsDeletedUser:user
                                     editActorId:@(FPForegroundActorId)
                                           error:errLogger]; }) should]
       raiseWithName:NSInternalInconsistencyException]; // we cannot delete w/out first doing a 'prepare-for-edit'
      prepareForEditSuccess =
        [localDao prepareUserForEdit:user
                         editActorId:@(FPForegroundActorId)
                   entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                       entityDeleted:[_coordTestCtx entityDeletedBlk]
                    entityInConflict:[_coordTestCtx entityInConflictBlk]
       entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                               error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      [localDao markAsDeletedUser:user
                      editActorId:@(FPForegroundActorId)
                            error:errLogger];
      fetchedUser = [localDao userWithError:errLogger];
      [fetchedUser shouldBeNil];
      [[theValue([user editInProgress]) should] beNo];
      [[theValue([user deleted]) should] beYes];
      
      // =======================================================================
      // In order to continue with our testing, we're going to manually undelete
      // the user, edit him, and mark him as edit-complete.
      // =======================================================================
      [user setDeleted:NO];
      [user setEditInProgress:YES];
      [localDao saveUser:user
             editActorId:@(FPForegroundActorId)
                   error:errLogger];
      prepareForEditSuccess =
        [localDao prepareUserForEdit:user
                         editActorId:@(FPForegroundActorId)
                   entityBeingSynced:[_coordTestCtx entityBeingSyncedBlk]
                       entityDeleted:[_coordTestCtx entityDeletedBlk]
                    entityInConflict:[_coordTestCtx entityInConflictBlk]
       entityBeingEditedByOtherActor:[_coordTestCtx entityBeingEditedByOtherActorBlk]
                               error:errLogger];
      [[theValue(prepareForEditSuccess) should] beYes];
      [[theValue([_coordTestCtx prepareForEditEntityBeingSynced]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityDeleted]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityInConflict]) should] beNo];
      [[theValue([_coordTestCtx prepareForEditEntityBeingEditedByOtherActor]) should] beNo];
      
      // =======================================================================
      // Now lets pretend we're the bg job, and we're looking for things to
      // sync; specifically, the user object.  As it stands now, our user object
      // is not ready to sync because we haven't called "markAsDone...".  Lets
      // make sure everything is working okay.
      // =======================================================================
      fetchedUser = [localDao markUserAsSyncInProgressWithEditActorId:@(FPForegroundActorId)
                                                                error:errLogger];
      [[theValue([fetchedUser editInProgress]) should] beYes];
      [localDao markAsDoneEditingUser:user
                          editActorId:@(FPForegroundActorId)
                                error:errLogger];
      fetchedUser = [localDao markUserAsSyncInProgressWithEditActorId:@(FPForegroundActorId)
                                                                error:errLogger];
      [fetchedUser shouldNotBeNil];
      [[theValue([fetchedUser syncInProgress]) should] beYes];
      
      // =======================================================================
      // Now lets assume the BG job is done and the user was synced.
      // =======================================================================
      [localDao markAsSyncCompleteForUser:user
                              editActorId:@(FPForegroundActorId)
                                    error:errLogger]; // this will result in main-user being deleted
      
      // =======================================================================
      // Now lets prune the synced entities (just the user in our case) as the
      // BG job would do it, and ensure that the main-user instance was deleted,
      // yet the master-user instance still rightfully exists.
      // =======================================================================
      [localDao pruneAllSyncedEntitiesWithError:errLogger
                               systemPruneCount:1];
      FPUser *fetchedMainUser = [localDao mainUserWithError:errLogger];
      [fetchedMainUser shouldBeNil];
      fetchedUser = [localDao userWithError:errLogger]; // still exists in master of course
      [fetchedUser shouldNotBeNil];
    });
  });
});

SPEC_END
