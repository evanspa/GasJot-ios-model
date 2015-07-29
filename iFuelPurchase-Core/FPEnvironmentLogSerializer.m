//
//  FPEnvironmentLogSerializer.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 10/24/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEnvironmentLogSerializer.h"
#import "FPEnvironmentLog.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>

NSString * const FPEnvironmentLogVehicleGlobalIdKey     = @"envlog/vehicle";
NSString * const FPEnvironmentLogOdometerKey            = @"envlog/odometer";
NSString * const FPEnvironmentLogReportedAvgMpgKey      = @"envlog/reported-avg-mpg";
NSString * const FPEnvironmentLogReportedAvgMphKey      = @"envlog/reported-avg-mph";
NSString * const FPEnvironmentLogReportedOutsideTempKey = @"envlog/reported-outside-temp";
NSString * const FPEnvironmentLogLogDateKey             = @"envlog/logged-at";
NSString * const FPEnvironmentLogReportedDteKey         = @"envlog/dte";
NSString * const FPEnvironmentLogUpdatedAtKey           = @"envlog/updated-at";

@implementation FPEnvironmentLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPEnvironmentLog *environmentLog = (FPEnvironmentLog *)resourceModel;
  NSMutableDictionary *environmentLogDict = [NSMutableDictionary dictionary];
  [environmentLogDict setObjectIfNotNull:[environmentLog vehicleGlobalIdentifier] forKey:FPEnvironmentLogVehicleGlobalIdKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog odometer] forKey:FPEnvironmentLogOdometerKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedDte] forKey:FPEnvironmentLogReportedDteKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedAvgMpg] forKey:FPEnvironmentLogReportedAvgMpgKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedAvgMph] forKey:FPEnvironmentLogReportedAvgMphKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedOutsideTemp] forKey:FPEnvironmentLogReportedOutsideTempKey];
  [environmentLogDict setMillisecondsSince1970FromDate:[environmentLog logDate]
                                                forKey:FPEnvironmentLogLogDateKey];
  return environmentLogDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  FPEnvironmentLog *envlog =
    [FPEnvironmentLog
     envLogWithOdometer:resDict[FPEnvironmentLogOdometerKey]
         reportedAvgMpg:resDict[FPEnvironmentLogReportedAvgMpgKey]
         reportedAvgMph:resDict[FPEnvironmentLogReportedAvgMphKey]
    reportedOutsideTemp:resDict[FPEnvironmentLogReportedOutsideTempKey]
                logDate:[resDict dateSince1970ForKey:FPEnvironmentLogLogDateKey]
            reportedDte:resDict[FPEnvironmentLogReportedDteKey]
       globalIdentifier:location
              mediaType:mediaType
              relations:relations
              updatedAt:[resDict dateSince1970ForKey:FPEnvironmentLogUpdatedAtKey]];
  [envlog setVehicleGlobalIdentifier:resDict[FPEnvironmentLogVehicleGlobalIdKey]];
  return envlog;
}

@end
