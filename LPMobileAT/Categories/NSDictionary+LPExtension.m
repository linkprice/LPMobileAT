//
//  NSDictionary+LPExtension.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/11/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import "NSDictionary+LPExtension.h"
#import "LPMTCrypto.h"

@implementation NSDictionary (LPMT_AES)

// encrypt a dictionary with AES and generate a base64-encoded string
- (NSString *)lpmt_AESEncrypt:(NSString *)key {
    
    // serialize JSON
    NSData *data = [self lpmt_JSONEncodedDataWithOptions:kNilOptions];
    if (data == nil) {
        DLog(@"ERROR: Unable to JSON encode");
        return nil;
    }

    // encrypt AES
    NSData *data_encrypted = [LPMTCrypto AESEncrypt:key data:data];
    if (data_encrypted == nil) {
        DLog(@"ERROR: Unable to AES encrypt");
        return nil;
    }

    // encode base64
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *data_base64 = [data_encrypted respondsToSelector:@selector(base64EncodedStringWithOptions:)] ?
        [data_encrypted base64EncodedStringWithOptions:kNilOptions] :
        [data_encrypted base64Encoding];
#pragma clang diagnostic pop
    
    return data_base64;
}

- (NSString *)lpmt_JSONEncodedStringWithOptions:(NSJSONWritingOptions)options {
    NSData *data = [self lpmt_JSONEncodedDataWithOptions:options];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)lpmt_JSONEncodedDataWithOptions:(NSJSONWritingOptions)options {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:options error:&error];
    if (data == nil) {
        DLog(@"ERROR: Unable to serialize Dictionary to JSON: %@", error.localizedDescription);
    }

    return data;
}

- (NSString *)lpmt_stringForKey:(id)key {
    return [self lpmt_stringForKey:key nullAsEmptyString:YES];
}

- (NSString *)lpmt_stringForKey:(id)key nullAsEmptyString:(BOOL)nullAsEmptyString {

    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        if (nullAsEmptyString == NO && [(NSString *)object isEqualToString:@""]) {
            object = nil;
        }
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        object = [(NSNumber *)object stringValue];
    }
    else if (object == nil || object == [NSNull null]) {
        object = nullAsEmptyString ? @"" : nil;
    }

    return object;
}

@end
