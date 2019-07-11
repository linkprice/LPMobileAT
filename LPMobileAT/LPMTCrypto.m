//
//  LPMTCrypto.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 7/7/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import "LPMTCrypto.h"
#import "NSData+HexString.h"

@implementation LPMTCrypto

+ (NSData *)AESEncrypt:(NSString *)key data:(NSData *)data {
    DLog(@"entered");

    NSParameterAssert(key != nil);
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    // prepare buffer
    size_t bufferSize = (8 +                                    // encSalt
                         8 +                                    // hmacSalt
                         kCCBlockSizeAES128 +                   // iv (16 bytes)
                         [data length] + kCCBlockSizeAES128 +   // cipher
                         32);                                   // hmac
    UInt8 *buffer = malloc(bufferSize);

    // generate key, salt
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    SecRandomCopyBytes(kSecRandomDefault, 8, buffer);           // encSalt
    SecRandomCopyBytes(kSecRandomDefault, 8, buffer+8);         // hmacSalt
#pragma clang diagnostic pop
    NSData *encSalt = [NSData dataWithBytes:buffer length:8];
    NSData *hmacSalt = [NSData dataWithBytes:buffer+8 length:8];
    NSData *encKey = [LPMTCrypto HKDF:keyData info:nil salt:encSalt outputSize:kCCKeySizeAES256];
    NSData *hmacKey = [LPMTCrypto HKDF:keyData info:nil salt:hmacSalt outputSize:kCCKeySizeAES256];
    //    DLog(@"encSalt: %@", [encSalt lp_hexString]);
    //    DLog(@"hmacSalt: %@", [hmacSalt lp_hexString]);
    //    DLog(@"encKey: %@", [encKey lp_hexString]);
    //    DLog(@"hmacKey: %@", [hmacKey lp_hexString]);

    // generate iv
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, buffer+16);
#pragma clang diagnostic pop

    // encrypt
    size_t numBytesEncrypted = 0;
    CCCryptorStatus result = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     encKey.bytes,
                                     encKey.length,
                                     buffer + 16,           // iv
                                     data.bytes,            // input
                                     data.length,
                                     buffer + 32,           // output
                                     bufferSize - 64,       // output buffer size
                                     &numBytesEncrypted);

    // append hmac
    CCHmac(kCCHmacAlgSHA256,                    // algorithm
           hmacKey.bytes,                       // key
           hmacKey.length,                      // key length
           buffer,                              // data
           numBytesEncrypted + 32,              // data length
           buffer + numBytesEncrypted + 32);    // output buffer
                                                //    NSData *hmac = [NSData dataWithBytes:buffer+numBytesEncrypted+32 length:32];
                                                //    DLog(@"hmac: %@", [hmac lp_hexString]);

    // return data
    NSData *cipher = nil;
    if (result == kCCSuccess) {
        cipher = [NSData dataWithBytes:buffer length:numBytesEncrypted+64];
    }
    else {
        DLog(@"AES encrypt failed");
    }
    free(buffer);
    
    //    DLog(@"cipher: %@", [cipher lp_hexString]);
    DLog(@"exited");
    return cipher;
}

+ (NSData *)AESDecrypt:(NSString *)key data:(NSData *)data {
    DLog(@"entered");

    NSParameterAssert(key != nil);
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    // generate key, salt
    NSData *encSalt = [NSData dataWithBytes:data.bytes length:8];
    NSData *hmacSalt = [NSData dataWithBytes:data.bytes+8 length:8];
    NSData *encKey = [LPMTCrypto HKDF:keyData info:nil salt:encSalt outputSize:kCCKeySizeAES256];
    NSData *hmacKey = [LPMTCrypto HKDF:keyData info:nil salt:hmacSalt outputSize:kCCKeySizeAES256];
    //    DLog(@"encSalt: %@", [encSalt lp_hexString]);
    //    DLog(@"hmacSalt: %@", [hmacSalt lp_hexString]);
    //    DLog(@"encKey: %@", [encKey lp_hexString]);
    //    DLog(@"hmacKey: %@", [hmacKey lp_hexString]);

    // verify hmac
    NSMutableData *hmac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,        // algorithm
           hmacKey.bytes,           // key
           hmacKey.length,          // key length
           data.bytes,              // data
           data.length - 32,        // data length
           hmac.mutableBytes);      // output buffer
    NSData *hmacKnown = [data subdataWithRange:NSMakeRange(data.length-32, 32)];
    //    DLog(@"hmac: %@", [hmac lp_hexString]);
    //    DLog(@"hmacKnown: %@", [hmacKnown lp_hexString]);
    //    DLog(@"data: %@", [self lp_hexString]);
    if (! [hmac isEqualToData:hmacKnown]) {
        DLog(@"HMAC verify failed");
        DLog(@"exited");
        return nil;
    }

    // prepare buffer
    size_t bufferSize = data.length - 64;
    UInt8 *buffer = malloc(bufferSize);

    // decrypt
    size_t numBytesDecrypted = 0;
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     encKey.bytes,      // key
                                     encKey.length,     // key length
                                     data.bytes + 16,   // iv
                                     data.bytes + 32,   // data
                                     data.length - 64,  // data length
                                     buffer,            // output
                                     bufferSize,        // output buffer size
                                     &numBytesDecrypted);

    // return data
    NSData *plain = nil;
    if (result == kCCSuccess) {
        plain = [NSData dataWithBytes:buffer length:numBytesDecrypted];
    }
    else {
        DLog(@"AES decrypt failed");
    }
    free(buffer);
    
    DLog(@"exited");
    return plain;
}

+ (NSData *)HKDF:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(NSInteger)outputSize {
    char prk[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmac(kCCHmacAlgSHA256, salt.bytes, salt.length, seed.bytes, seed.length, prk);

    int iterations = (int)ceil((double)outputSize / (double)CC_SHA256_DIGEST_LENGTH);
    NSData *mixin = [NSData data];
    NSMutableData *results = [NSMutableData data];

    for (int i = 0; i < iterations; i++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA256, prk, CC_SHA256_DIGEST_LENGTH);
        CCHmacUpdate(&ctx, mixin.bytes, mixin.length);
        if (info != nil) {
            CCHmacUpdate(&ctx, info.bytes, info.length);
        }

        unsigned char c = i+1;
        CCHmacUpdate(&ctx, &c, 1);

        unsigned char T[CC_SHA256_DIGEST_LENGTH];
        memset(T, 0, CC_SHA256_DIGEST_LENGTH);
        CCHmacFinal(&ctx, T);
        NSData *stepResult = [NSData dataWithBytes:T length:sizeof(T)];
        [results appendData:stepResult];
        mixin = [stepResult copy];
    }

    return [NSData dataWithData:results];
}

@end
