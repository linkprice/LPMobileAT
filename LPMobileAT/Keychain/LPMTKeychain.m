//
//  LPMTKeychain.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 12/16/14.
//  Copyright (c) 2014 LinkPrice. All rights reserved.
//

#import "LPMTKeychain.h"
#import <Security/Security.h>

@implementation LPMTKeychain

- (id)initWithService:(NSString *)serviceName withGroup:(NSString*)groupName {
    self = [super init];
    if (self) {
        service = [NSString stringWithString:serviceName];

        if (groupName) {
            group = [NSString stringWithString:groupName];
        }
    }

    return self;
}

- (NSMutableDictionary*)prepareDict:(NSString *)key {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

    NSData *encodedKey = [key dataUsingEncoding:NSUTF8StringEncoding];
    [dict setObject:encodedKey forKey:(__bridge id)kSecAttrGeneric];
    [dict setObject:encodedKey forKey:(__bridge id)kSecAttrAccount];
    [dict setObject:service forKey:(__bridge id)kSecAttrService];
    [dict setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];

    // This is for sharing data across apps
    if (group != nil) {
        [dict setObject:group forKey:(__bridge id)kSecAttrAccessGroup];
    }

    return  dict;
}

- (BOOL)insert:(NSString *)key data:(NSData *)data {
    NSMutableDictionary * dict =[self prepareDict:key];
    [dict setObject:data forKey:(__bridge id)kSecValueData];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if (status != errSecSuccess) {
        DLog(@"Unable to add item for key '%@' (error: %ld)", key, (long)status);
    }
    return (errSecSuccess == status);
}

- (BOOL)insert:(NSString *)key string:(NSString *)string {
    return [self insert:key data:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)update:(NSString*)key data:(NSData*)data {
    NSMutableDictionary *dictKey = [self prepareDict:key];
    NSMutableDictionary *dictUpdate = [[NSMutableDictionary alloc] init];
    [dictUpdate setObject:data forKey:(__bridge id)kSecValueData];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)dictKey, (__bridge CFDictionaryRef)dictUpdate);
    if (status != errSecSuccess) {
        DLog(@"Unable to update for key '%@' (error: %ld)", key, (long)status);
    }
    return (status == errSecSuccess);
}

- (BOOL)update:(NSString *)key string:(NSString *)string {
    return [self update:key data:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)remove:(NSString *)key {
    NSMutableDictionary *dict = [self prepareDict:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dict);
    if (status != errSecSuccess) {
        DLog(@"Unable to remove item for key '%@' (error: %ld)", key, (long)status);
    }
    return (status == errSecSuccess);
}

- (NSData *)dataForKey:(NSString *)key {
    NSMutableDictionary *dict = [self prepareDict:key];
    [dict setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &result);
    if (status != errSecSuccess) {
        DLog(@"Unable to fetch item for key '%@' (error: %ld)", key, (long)status);
        return nil;
    }

    return (__bridge NSData *)result;
}

- (NSString *)stringForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    return (data != nil) ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

@end
