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
#import "FPNotificationNames.h"

@implementation FPFuelPurchaseLog

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
      fuelStationGlobalIdentifier:(NSString *)fuelStationGlobalIdentifier
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
    _fuelStationGlobalIdentifier = fuelStationGlobalIdentifier;
    _numGallons = numGallons;
    _gallonPrice = gallonPrice;
    _octane = octane;
    _gotCarWash = gotCarWash;
    _carWashPerGallonDiscount = carWashPerGallonDiscount;
    _purchasedAt = purchasedAt;
  }
  return self;
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
                                    fuelStationGlobalIdentifier:nil
                                                     numGallons:numGallons
                                                         octane:octane
                                                    gallonPrice:gallonPrice
                                                     gotCarWash:gotCarWash
                                       carWashPerGallonDiscount:carWashPerGallonDiscount
                                                    purchasedAt:purchasedAt];
}

#pragma mark - Methods

- (void)overwrite:(FPFuelPurchaseLog *)fuelPurchaseLog {
  [super overwrite:fuelPurchaseLog];
  [self setNumGallons:[fuelPurchaseLog numGallons]];
  [self setOctane:[fuelPurchaseLog octane]];
  [self setGallonPrice:[fuelPurchaseLog gallonPrice]];
  [self setGotCarWash:[fuelPurchaseLog gotCarWash]];
  [self setCarWashPerGallonDiscount:[fuelPurchaseLog carWashPerGallonDiscount]];
  [self setPurchasedAt:[fuelPurchaseLog purchasedAt]];
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
