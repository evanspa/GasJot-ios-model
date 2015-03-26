//
//  FPEnvironmentLogSerializer.m
//  iFuelPurchase-Core
//
//  Created by Evans, Paul on 10/24/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPEnvironmentLogSerializer.h"
#import "FPEnvironmentLog.h"
#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>

NSString * const FPEnvironmentLogVehicleGlobalIdKey     = @"fpenvironmentlog/vehicle";
NSString * const FPEnvironmentLogOdometerKey            = @"fpenvironmentlog/odometer";
NSString * const FPEnvironmentLogReportedAvgMpgKey      = @"fpenvironmentlog/reported-avg-mpg";
NSString * const FPEnvironmentLogReportedAvgMphKey      = @"fpenvironmentlog/reported-avg-mph";
NSString * const FPEnvironmentLogReportedOutsideTempKey = @"fpenvironmentlog/outside-temp";
NSString * const FPEnvironmentLogLogDateKey             = @"fpenvironmentlog/log-date";
NSString * const FPEnvironmentLogReportedDte            = @"fpenvironmentlog/dte";

@implementation FPEnvironmentLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPEnvironmentLog *environmentLog = (FPEnvironmentLog *)resourceModel;
  NSMutableDictionary *environmentLogDict = [NSMutableDictionary dictionary];
  [environmentLogDict setObjectIfNotNull:[environmentLog vehicleGlobalIdentifier] forKey:FPEnvironmentLogVehicleGlobalIdKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog odometer] forKey:FPEnvironmentLogOdometerKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedDte] forKey:FPEnvironmentLogReportedDte];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedAvgMpg] forKey:FPEnvironmentLogReportedAvgMpgKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedAvgMph] forKey:FPEnvironmentLogReportedAvgMphKey];
  [environmentLogDict setObjectIfNotNull:[environmentLog reportedOutsideTemp] forKey:FPEnvironmentLogReportedOutsideTempKey];
  [environmentLogDict setObjectIfNotNull:[HCUtils rfc7231StringFromDate:[environmentLog logDate]]
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
                logDate:[HCUtils rfc7231DateFromString:resDict[FPEnvironmentLogLogDateKey]]
            reportedDte:resDict[FPEnvironmentLogReportedDte]
       globalIdentifier:location
              mediaType:mediaType
              relations:relations
           lastModified:lastModified];
  [envlog setVehicleGlobalIdentifier:resDict[FPEnvironmentLogVehicleGlobalIdKey]];
  return envlog;
}

@end
