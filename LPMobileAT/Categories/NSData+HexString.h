//
//  NSData+Hexa.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 7/7/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (LPMT_HexString)

+ (instancetype)lpmt_dataWithHexString:(NSString *)hex;
- (NSString *)lpmt_hexString;

@end
