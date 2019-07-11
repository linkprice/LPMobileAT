//
//  LPMTCrypto.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 7/7/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface LPMTCrypto : NSObject

+ (NSData *)AESEncrypt:(NSString *)key data:(NSData *)data;
+ (NSData *)AESDecrypt:(NSString *)key data:(NSData *)data;
+ (NSData *)HKDF:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(NSInteger)outputSize;

@end
