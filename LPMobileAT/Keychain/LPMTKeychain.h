//
//  LPMTKeychain.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 12/16/14.
//  Copyright (c) 2014 LinkPrice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPMTKeychain : NSObject {
    NSString *service;
    NSString *group;
}

- (id)initWithService:(NSString *)serviceName withGroup:(NSString*)groupName;

- (BOOL)insert:(NSString *)key data:(NSData *)data;
- (BOOL)insert:(NSString *)key string:(NSString *)string;
- (BOOL)update:(NSString *)key data:(NSData *)data;
- (BOOL)update:(NSString *)key string:(NSString *)string;
- (BOOL)remove:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

@end
