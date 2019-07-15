//
//  NSURL+queryItems.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/10/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import "NSURL+queryItems.h"

@implementation NSURL (LPMT)

- (NSDictionary *)lpmt_queryItems {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSArray *pairs = [self.query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *key = [kv[0] stringByRemovingPercentEncoding];
        NSString *value = [kv[1] stringByRemovingPercentEncoding];
        params[key] = value;
    }
    return params;
}

@end
