//
//  NSDictionary+LPExtension.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/11/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (LPMT_AES)

- (NSString *)lpmt_AESEncrypt:(NSString *)key;

- (NSString *)lpmt_JSONEncodedStringWithOptions:(NSJSONWritingOptions)options;
- (NSData *)lpmt_JSONEncodedDataWithOptions:(NSJSONWritingOptions)options;

- (NSString *)lpmt_stringForKey:(id)key;
- (NSString *)lpmt_stringForKey:(id)key nullAsEmptyString:(BOOL)nullAsEmptyString;

@end
