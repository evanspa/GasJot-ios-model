//
//  FPFuelPurchaseLog.m
//  PEFuelPurchase-Model
//
//  Created by Evans, Paul on 9/4/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import <PEObjc-Commons/PEUtils.h>
#import "FPFuelPurchaseLog.h"
#import "FPDDLUtils.h"

NSString * const FPFplogNumGallonsField = @"FPFplogNumGallonsField";
NSString * const FPFplogOctaneField = @"FPFplogOctaneField";
NSString * const FPFplogGallonPriceField = @"FPFplogGallonPriceField";
NSString * const FPFplogGotCarWashField = @"FPFplogGotCarWashField";
NSString * const FPFplogCarWashPerGallonDiscountField = @"FPFplogCarWashPerGallonDiscountField";
NSString * const FPFplogPurchasedAtField = @"FPFplogPurchasedAtField";

@implementation FPFuelPurchaseLog

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                      deletedAt:(NSDate *)deletedAt
                     updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
            vehicleMainIdentifier:(NSNumber *)vehicleMainIdentifier
        fuelStationMainIdentifier:(NSNumber *)fuelStationMainIdentifier
                       numGallons:(NSDecimalNumber *)numGallons
                           octane:(NSNumber *)octane
                      gallonPrice:(NSDecimalNumber *)gallonPrice
                       gotCarWash:(BOOL)gotCarWash
         carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                      purchasedAt:(NSDate *)purchasedAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                            mainEntityTable:TBL_MAIN_FUELPURCHASE_LOG
                          masterEntityTable:TBL_MASTER_FUELPURCHASE_LOG
                                  mediaType:mediaType
                                  relations:relations
                                deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _vehicleMainIdentifier = vehicleMainIdentifier;
    _fuelStationMainIdentifier = fuelStationMainIdentifier;
    _numGallons = numGallons;
    _gallonPrice = gallonPrice;
    _octane = octane;
    _gotCarWash = gotCarWash;
    _carWashPerGallonDiscount = carWashPerGallonDiscount;
    _purchasedAt = purchasedAt;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  FPFuelPurchaseLog *copy = [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                                                             localMasterIdentifier:[self localMasterIdentifier]
                                                                  globalIdentifier:[self globalIdentifier]
                                                                         mediaType:[self mediaType]
                                                                         relations:[self relations]
                                                                         deletedAt:[self deletedAt]
                                                                         updatedAt:[self updatedAt]
                                                              dateCopiedFromMaster:[self dateCopiedFromMaster]
                                                                    editInProgress:[self editInProgress]
                                                                    syncInProgress:[self syncInProgress]
                                                                            synced:[self synced]
                                                                         editCount:[self editCount]
                                                                  syncHttpRespCode:[self syncHttpRespCode]
                                                                       syncErrMask:[self syncErrMask]
                                                                       syncRetryAt:[self syncRetryAt]
                                                           vehicleMainIdentifier:_vehicleMainIdentifier
                                                       fuelStationMainIdentifier:_fuelStationMainIdentifier
                                                                        numGallons:_numGallons
                                                                            octane:_octane
                                                                       gallonPrice:_gallonPrice
                                                                        gotCarWash:_gotCarWash
                                                          carWashPerGallonDiscount:_carWashPerGallonDiscount
                                                                       purchasedAt:_purchasedAt];
  return copy;
}

#pragma mark - Creation Functions

+ (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                             purchasedAt:(NSDate *)purchasedAt
                                           mediaType:(HCMediaType *)mediaType {
  return [FPFuelPurchaseLog fuelPurchaseLogWithNumGallons:numGallons
                                                   octane:octane
                                              gallonPrice:gallonPrice
                                               gotCarWash:gotCarWash
                                 carWashPerGallonDiscount:carWashPerGallonDiscount
                                              purchasedAt:purchasedAt
                                         globalIdentifier:nil
                                                mediaType:mediaType
                                                relations:nil
                                                updatedAt:nil];
}

+ (FPFuelPurchaseLog *)fuelPurchaseLogWithNumGallons:(NSDecimalNumber *)numGallons
                                              octane:(NSNumber *)octane
                                         gallonPrice:(NSDecimalNumber *)gallonPrice
                                          gotCarWash:(BOOL)gotCarWash
                            carWashPerGallonDiscount:(NSDecimalNumber *)carWashPerGallonDiscount
                                         purchasedAt:(NSDate *)purchasedAt
                                    globalIdentifier:(NSString *)globalIdentifier
                                           mediaType:(HCMediaType *)mediaType
                                           relations:(NSDictionary *)relations
                                           updatedAt:(NSDate *)updatedAt {
  return [[FPFuelPurchaseLog alloc] initWithLocalMainIdentifier:nil
                                          localMasterIdentifier:nil
                                               globalIdentifier:globalIdentifier
                                                      mediaType:mediaType
                                                      relations:relations
                                                      deletedAt:nil
                                                      updatedAt:updatedAt
                                           dateCopiedFromMaster:nil
                                                 editInProgress:NO
                                                 syncInProgress:NO
                                                         synced:NO
                                                      editCount:0
                                               syncHttpRespCode:nil
                                                    syncErrMask:nil
                                                    syncRetryAt:nil
                                        vehicleMainIdentifier:nil
                                    fuelStationMainIdentifier:nil
                                                     numGallons:numGallons
                                                         octane:octane
                                                    gallonPrice:gallonPrice
                                                     gotCarWash:gotCarWash
                                       carWashPerGallonDiscount:carWashPerGallonDiscount
                                                    purchasedAt:purchasedAt];
}

#pragma mark - Merging

+ (NSDictionary *)mergeRemoteEntity:(FPFuelPurchaseLog *)remoteFplog
                    withLocalEntity:(FPFuelPurchaseLog *)localFplog
                  localMasterEntity:(FPFuelPurchaseLog *)localMasterFplog {
  NSMutableDictionary *allMergeConflicts = [NSMutableDictionary dictionary];
  NSDictionary *superMergeConflicts = [super mergeRemoteEntity:remoteFplog
                                               withLocalEntity:localFplog
                                             localMasterEntity:localMasterFplog];
  NSDictionary *mergeConflicts;
  mergeConflicts = [PEUtils mergeRemoteObject:remoteFplog
                              withLocalObject:localFplog
                          previousLocalObject:localMasterFplog
                  getterSetterKeysComparators:@[@[[NSValue valueWithPointer:@selector(numGallons)],
                                                  [NSValue valueWithPointer:@selector(setNumGallons:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) {[localObject setNumGallons:[remoteObject numGallons]];},
                                                  FPFplogNumGallonsField],
                                                @[[NSValue valueWithPointer:@selector(octane)],
                                                  [NSValue valueWithPointer:@selector(setOctane:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) {[localObject setOctane:[remoteObject octane]];},
                                                  FPFplogOctaneField],
                                                @[[NSValue valueWithPointer:@selector(gallonPrice)],
                                                  [NSValue valueWithPointer:@selector(setGallonPrice:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) { [localObject setGallonPrice:[remoteObject gallonPrice]];},
                                                  FPFplogGallonPriceField],
                                                @[[NSValue valueWithPointer:@selector(gotCarWash)],
                                                  [NSValue valueWithPointer:@selector(setGotCarWash:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isBoolProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) {[localObject setGotCarWash:[remoteObject gotCarWash]];},
                                                  FPFplogGotCarWashField],
                                                @[[NSValue valueWithPointer:@selector(carWashPerGallonDiscount)],
                                                  [NSValue valueWithPointer:@selector(setCarWashPerGallonDiscount:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isNumProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) {[localObject setCarWashPerGallonDiscount:[remoteObject carWashPerGallonDiscount]];},
                                                  FPFplogCarWashPerGallonDiscountField],
                                                @[[NSValue valueWithPointer:@selector(purchasedAt)],
                                                  [NSValue valueWithPointer:@selector(setPurchasedAt:)],
                                                  ^(SEL getter, id obj1, id obj2) {return [PEUtils isDateProperty:getter equalFor:obj1 and:obj2];},
                                                  ^(FPFuelPurchaseLog * localObject, FPFuelPurchaseLog * remoteObject) {[localObject setPurchasedAt:[remoteObject purchasedAt]];},
                                                  FPFplogPurchasedAtField]]];
  [allMergeConflicts addEntriesFromDictionary:superMergeConflicts];
  [allMergeConflicts addEntriesFromDictionary:mergeConflicts];
  return allMergeConflicts;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(FPFuelPurchaseLog *)fplog {
  [super overwriteDomainProperties:fplog];
  [self setNumGallons:[fplog numGallons]];
  [self setOctane:[fplog octane]];
  [self setGallonPrice:[fplog gallonPrice]];
  [self setGotCarWash:[fplog gotCarWash]];
  [self setCarWashPerGallonDiscount:[fplog carWashPerGallonDiscount]];
  [self setPurchasedAt:[fplog purchasedAt]];
}

- (void)overwrite:(FPFuelPurchaseLog *)fplog {
  [super overwrite:fplog];
  [self overwriteDomainProperties:fplog];
}

#pragma mark - Equality

- (BOOL)isEqualToFuelPurchaseLog:(FPFuelPurchaseLog *)fuelPurchaseLog {
  if (!fuelPurchaseLog) { return NO; }
  if ([super isEqualToMainSupport:fuelPurchaseLog]) {
    return [PEUtils isNumProperty:@selector(numGallons) equalFor:self and:fuelPurchaseLog] &&
      [PEUtils isNumProperty:@selector(octane) equalFor:self and:fuelPurchaseLog] &&
      [PEUtils isNumProperty:@selector(gallonPrice) equalFor:self and:fuelPurchaseLog] &&
      [PEUtils isBoolProperty:@selector(gotCarWash) equalFor:self and:fuelPurchaseLog] &&
      [PEUtils isNumProperty:@selector(carWashPerGallonDiscount) equalFor:self and:fuelPurchaseLog] &&
      [PEUtils isDate:[self purchasedAt] msprecisionEqualTo:[fuelPurchaseLog purchasedAt]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[FPFuelPurchaseLog class]]) { return NO; }
  return [self isEqualToFuelPurchaseLog:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self numGallons] hash] ^
    [[self octane] hash] ^
    [[self gallonPrice] hash] ^
    [[self gallonPrice] hash] ^
    [[self carWashPerGallonDiscount] hash] ^
    [[self purchasedAt] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, num gallons: [%@], octane: [%@], \
gallon price: [%@], got car wash: [%d], car wash per gallon discount: [%@], \
log date: [%@]", [super description],
          _numGallons,
          _octane,
          _gallonPrice,
          _gotCarWash,
          _carWashPerGallonDiscount,
          _purchasedAt];
}

@end
