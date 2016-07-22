//
//  LinkPrice.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/9/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for LinkPrice.
FOUNDATION_EXPORT double LinkPriceVersionNumber;

//! Project version string for LinkPrice.
FOUNDATION_EXPORT const unsigned char LinkPriceVersionString[];

// import all the public headers of your framework

// global constants
typedef NS_ENUM(NSInteger, LPEventType) {
    LPEventLaunch   = 1,
    LPEventCPS      = 2,
    LPEventCPA      = 3,
};

//// LinkPrice protocol definition
//@protocol LinkPriceDelegate
//
//+ didReceiveDeferredDeepLink:(NSURL *)url;
//
//@end

// LinkPrice class interface
@interface LPMobileAT : NSObject

+ (NSString *)apiVersion;
+ (NSString *)sdkVersion;

+ (void)initializeWithAppId:(NSString *)appId appKey:(NSString *)appKey;
//+ (void)checkForDeferredDeepLink:(id<LinkPriceDelegate>)delegate;
+ (void)applicationDidOpenURL:(NSURL *)url;
+ (void)trackAppLaunch;
+ (void)trackEvent:(LPEventType)eventType withValues:(NSDictionary *)values;

@end
