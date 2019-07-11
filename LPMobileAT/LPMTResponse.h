//
//  LPMTAdResponse.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 12/10/14.
//  Copyright (c) 2014 LinkPrice. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPMTResponse : NSObject

@property (nonatomic) NSInteger result;
@property (nonatomic) NSString *message;
@property (nonatomic) NSDictionary *data;

- (id)init __attribute__((unavailable("init not available")));
- (id)initWithKey:(NSString *)key data:(NSData *)data;

@end
