//
//  LPMTAdResponse.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 12/10/14.
//  Copyright (c) 2014 LinkPrice. All rights reserved.
//

#import "LPMTResponse.h"
#import "NSDictionary+LPExtension.h"
#import "NSString+LPExtension.h"

@implementation LPMTResponse

- (id)initWithKey:(NSString *)key data:(NSData *)data {

    self = [super init];
    if (self) {

        // JSON to Dictionary
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:nil];
        DLog(@"response: %@", responseDict);
        if (responseDict == nil) {
            DLog(@"ERROR: Unable to parse json: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            return nil;
        }

        // Dictionary to Object
        self.result = [[responseDict valueForKey:@"result"] integerValue];
        self.message = [responseDict lpmt_stringForKey:@"msg"];

        // decrypt data section
        NSString *data_encrypted = [responseDict lpmt_stringForKey:@"data" nullAsEmptyString:NO];
        if (data_encrypted != nil) {
            self.data = [data_encrypted lpmt_decryptAES:key];
            DLog(@"response.data: %@", self.data);
        }
    }

    return self;
}

@end
