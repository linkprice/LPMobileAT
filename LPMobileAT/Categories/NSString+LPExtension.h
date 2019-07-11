//
//  NSString+LPExtension.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/21/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LPMT)

- (NSDictionary *)lpmt_decryptAES:(NSString *)key;

@end
