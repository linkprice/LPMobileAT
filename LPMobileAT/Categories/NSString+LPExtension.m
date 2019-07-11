//
//  NSString+LPExtension.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/21/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import "NSString+LPExtension.h"
#import "LPMTCrypto.h"

@implementation NSString (LPMT)

// decrypt a base64-encoded string with AES and generate a dictionary
- (NSDictionary *)lpmt_decryptAES:(NSString *)key {

    // decode base64
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *data_encrypted = [NSData respondsToSelector:@selector(initWithBase64EncodedString:options:)] ?
    [[NSData alloc] initWithBase64EncodedString:self options:kNilOptions] :
    [[NSData alloc] initWithBase64Encoding:self];
#pragma clang diagnostic pop
    
    // decrypt AES
    NSData *data_json = [LPMTCrypto AESDecrypt:key data:data_encrypted];
    if (data_json == nil) {
        DLog(@"ERROR: Unable to decrypt message");
        return nil;
    }

    // unserialize JSON
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data_json options:kNilOptions error:&error];
    if (dict == nil) {
        DLog(@"ERROR: Unable to parse JSON to Dictionary: %@", error.localizedDescription);
        return nil;
    }
    
    return dict;
}

@end
