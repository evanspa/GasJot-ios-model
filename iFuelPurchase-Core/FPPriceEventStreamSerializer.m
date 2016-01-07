//
//  FPPriceEventStreamSerializer.m
//  Gas Jot Model
//
//  Created by Paul Evans on 12/29/15.
//  Copyright © 2015 Paul Evans. All rights reserved.
//

#import <PEObjc-Commons/NSMutableDictionary+PEAdditions.h>
#import <PEObjc-Commons/NSDictionary+PEAdditions.h>
#import <PEHateoas-Client/HCUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPCoordinatorDao.h"
#import "FPLocalDao.h"
#import "FPPriceEventStreamSerializer.h"
#import "FPPriceEvent.h"
#import "FPPriceStreamFilterCriteria.h"

// request keys
NSString * const FPPriceStreamFilterLatitudeKey       = @"price-stream-filter/latitude";
NSString * const FPPriceStreamFilterLongitudeKey      = @"price-stream-filter/longitude";
NSString * const FPPriceStreamFilterDistanceWithinKey = @"price-stream-filter/distance-within";
NSString * const FPPriceStreamFilterMaxResultsKey     = @"price-stream-filter/max-results";
NSString * const FPPriceStreamFilterSortByKey         = @"price-stream-filter/sort-by";

// response keys
NSString * const FPPriceEventStreamKey    = @"price-event-stream";
NSString * const FPPriceEventFsTypeIdKey  = @"price-event/fs-type-id";
NSString * const FPPriceEventPriceKey     = @"price-event/price";
NSString * const FPPriceEventOctaneKey    = @"price-event/octane";
NSString * const FPPriceEventIsDieselKey  = @"price-event/is-diesel";
NSString * const FPPriceEventDateKey      = @"price-event/event-date";
NSString * const FPPriceEventLatitudeKey  = @"price-event/latitude";
NSString * const FPPriceEventLongitudeKey = @"price-event/longitude";
NSString * const FPPriceEventDistanceKey  = @"price-event/distance";

@implementation FPPriceEventStreamSerializer {
  id<FPCoordinatorDao> _coordDao;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         coordinatorDao:(id<FPCoordinatorDao>)coordinatorDao
                  error:(PELMDaoErrorBlk)errorBlk {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:embeddedSerializers
      actionsForEmbeddedResources:actions];
  if (self) {
    _coordDao = coordinatorDao;
    _errorBlk = errorBlk;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  FPPriceStreamFilterCriteria *filterCriteria = (FPPriceStreamFilterCriteria *)resourceModel;
  NSMutableDictionary *filterCriteriaDict = [NSMutableDictionary dictionary];
  [filterCriteriaDict setObjectIfNotNull:filterCriteria.latitude forKey:FPPriceStreamFilterLatitudeKey];
  [filterCriteriaDict setObjectIfNotNull:filterCriteria.longitude forKey:FPPriceStreamFilterLongitudeKey];
  [filterCriteriaDict setObject:@(filterCriteria.distanceWithin) forKey:FPPriceStreamFilterDistanceWithinKey];
  [filterCriteriaDict setObject:@(filterCriteria.maxResults) forKey:FPPriceStreamFilterMaxResultsKey];
  [filterCriteriaDict setObjectIfNotNull:filterCriteria.sortBy forKey:FPPriceStreamFilterSortByKey];
  return filterCriteriaDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  
  NSArray *priceEventsJsonArray = (NSArray *)resDict[FPPriceEventStreamKey];
  NSMutableArray *priceEvents = [NSMutableArray arrayWithCapacity:priceEventsJsonArray.count];
  for (NSDictionary *priceEventDict in priceEventsJsonArray) {
    [priceEvents addObject:[[FPPriceEvent alloc] initWithFuelstationType:[_coordDao fuelstationTypeForIdentifier:priceEventDict[FPPriceEventFsTypeIdKey] error:_errorBlk]
                                                                   price:[PEUtils nullSafeDecimalNumberFromString:[priceEventDict[FPPriceEventPriceKey] description]]
                                                                  octane:priceEventDict[FPPriceEventOctaneKey]
                                                                isDiesel:[priceEventDict boolForKey:FPPriceEventIsDieselKey]
                                                                    date:[priceEventDict dateSince1970ForKey:FPPriceEventDateKey]
                                                                latitude:[PEUtils nullSafeDecimalNumberFromString:[[priceEventDict objectForKey:FPPriceEventLatitudeKey] description]]
                                                               longitude:[PEUtils nullSafeDecimalNumberFromString:[[priceEventDict objectForKey:FPPriceEventLongitudeKey] description]]
                                                                distance:[PEUtils nullSafeDecimalNumberFromString:[[priceEventDict objectForKey:FPPriceEventDistanceKey] description]]]];
  }
  return priceEvents;
}


@end
