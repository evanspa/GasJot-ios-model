//
//  FPEnvironmentLog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PEObjc-Commons/PEUtils.h>
#import "FPEnvironmentLog.h"
#import "FPDDLUtils.h"
#import "FPNotificationNames.h"

@implementation FPEnvironmentLog

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedDate:(NSDate *)deletedDate
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                      editActorId:(NSNumber *)editActorId
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                       inConflict:(BOOL)inConflict
                          deleted:(BOOL)deleted
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
          vehicleGlobalIdentifier:(NSString *)vehicleGlobalIdentifier
                         odometer:(NSDecimalNumber *)odometer
                   reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                   reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
              reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                          logDate:(NSDate *)logDate
                      reportedDte:(NSNumber *)reportedDte {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_ENV_LOG
                          masterEntityTable:TBL_MASTER_ENV_LOG
                                  mediaType:mediaType
                                  relations:relations
                                deletedDate:deletedDate
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                                editActorId:editActorId
                             syncInProgress:syncInProgress
                                     synced:synced
                                 inConflict:inConflict
                                    deleted:deleted
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _vehicleGlobalIdentifier = vehicleGlobalIdentifier;
    _odometer = odometer;
    _reportedAvgMpg = reportedAvgMpg;
    _reportedAvgMph = reportedAvgMph;
    _reportedOutsideTemp = reportedOutsideTemp;
    _logDate = logDate;
    _reportedDte = reportedDte;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPEnvironmentLog *copy = [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                                                           localMasterIdentifier:[self localMasterIdentifier]
                                                                globalIdentifier:[self globalIdentifier]
                                                                       mediaType:[self mediaType]
                                                                       relations:[self relations]
                                                                     deletedDate:[self deletedDate]
                                                                       updatedAt:[self updatedAt]
                                                            dateCopiedFromMaster:[self dateCopiedFromMaster]
                                                                  editInProgress:[self editInProgress]
                                                                     editActorId:[self editActorId]
                                                                  syncInProgress:[self syncInProgress]
                                                                          synced:[self synced]
                                                                      inConflict:[self inConflict]
                                                                         deleted:[self deleted]
                                                                       editCount:[self editCount]
                                                                syncHttpRespCode:[self syncHttpRespCode]
                                                                     syncErrMask:[self syncErrMask]
                                                                     syncRetryAt:[self syncRetryAt]
                                                         vehicleGlobalIdentifier:_vehicleGlobalIdentifier
                                                                        odometer:_odometer
                                                                  reportedAvgMpg:_reportedAvgMpg
                                                                  reportedAvgMph:_reportedAvgMph
                                                             reportedOutsideTemp:_reportedOutsideTemp
                                                                         logDate:_logDate
                                                                     reportedDte:_reportedDte];
  return copy;
}

#pragma mark - Creation Functions

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                               mediaType:(HCMediaType *)mediaType {
  return [FPEnvironmentLog envLogWithOdometer:odometer
                               reportedAvgMpg:reportedAvgMpg
                               reportedAvgMph:reportedAvgMph
                          reportedOutsideTemp:reportedOutsideTemp
                                      logDate:logDate
                                  reportedDte:reportedDte
                             globalIdentifier:nil
                                    mediaType:mediaType
                                    relations:nil
                                 updatedAt:nil];
}

+ (FPEnvironmentLog *)envLogWithOdometer:(NSDecimalNumber *)odometer
                          reportedAvgMpg:(NSDecimalNumber *)reportedAvgMpg
                          reportedAvgMph:(NSDecimalNumber *)reportedAvgMph
                     reportedOutsideTemp:(NSNumber *)reportedOutsideTemp
                                 logDate:(NSDate *)logDate
                             reportedDte:(NSNumber *)reportedDte
                        globalIdentifier:(NSString *)globalIdentifier
                               mediaType:(HCMediaType *)mediaType
                               relations:(NSDictionary *)relations
                               updatedAt:(NSDate *)updatedAt {
  return [[FPEnvironmentLog alloc] initWithLocalMainIdentifier:nil
                                         localMasterIdentifier:nil
                                              globalIdentifier:globalIdentifier
                                                     mediaType:mediaType
                                                     relations:relations
                                                   deletedDate:nil
                                                     updatedAt:updatedAt
                                          dateCopiedFromMaster:nil
                                                editInProgress:NO
                                                   editActorId:nil
                                                syncInProgress:NO
                                                        synced:NO
                                                    inConflict:NO
                                                       deleted:NO
                                                     editCount:0
                                              syncHttpRespCode:nil
                                                   syncErrMask:nil
                                                   syncRetryAt:nil
                                       vehicleGlobalIdentifier:nil
                                                      odometer:odometer
                                                reportedAvgMpg:reportedAvgMpg
                                                reportedAvgMph:reportedAvgMph
                                           reportedOutsideTemp:reportedOutsideTemp
                                                       logDate:logDate
                                                   reportedDte:reportedDte];
}

#pragma mark - Methods

- (void)overwrite:(FPEnvironmentLog *)envLog {
  [super overwrite:envLog];
  [self setOdometer:[envLog odometer]];
  [self setReportedAvgMpg:[envLog reportedAvgMpg]];
  [self setReportedAvgMph:[envLog reportedAvgMph]];
  [self setReportedOutsideTemp:[envLog reportedOutsideTemp]];
  [self setLogDate:[envLog logDate]];
  [self setReportedDte:[envLog reportedDte]];
}

#pragma mark - Equality

- (BOOL)isEqualToEnvironmentLog:(FPEnvironmentLog *)envLog {
  if (!envLog) { return NO; }
  if ([super isEqualToMainSupport:envLog]) {
    return [PEUtils isNumProperty:@selector(odometer) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedAvgMpg) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedAvgMph) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedOutsideTemp) equalFor:self and:envLog] &&
      [PEUtils isNumProperty:@selector(reportedDte) equalFor:self and:envLog] &&
      [PEUtils isDate:[self logDate] msprecisionEqualTo:[envLog logDate]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPEnvironmentLog class]]) { return NO; }
  return [self isEqualToEnvironmentLog:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self odometer] hash] ^
  [[self reportedAvgMpg] hash] ^
  [[self reportedAvgMph] hash] ^
  [[self reportedOutsideTemp] hash] ^
  [[self reportedDte] hash] ^
  [[self logDate] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, odometer: [%@], reported avg mpg: [%@], \
          reported avg mph: [%@], reported outside temp: [%@], \
          log date: [%@], reported DTE: [%@]", [super description],
          _odometer,
          _reportedAvgMpg,
          _reportedAvgMph,
          _reportedOutsideTemp,
          _logDate,
          _reportedDte];
}

@end
