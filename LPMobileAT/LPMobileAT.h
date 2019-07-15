//
//  LPMobileAT.h
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/9/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for LPMobileAT.
FOUNDATION_EXPORT double LPMobileATVersionNumber;

//! Project version string for LPMobileAT.
FOUNDATION_EXPORT const unsigned char LPMobileATVersionString[];

// import all the public headers of your framework

// global constants
typedef NS_ENUM(NSInteger, LPEventType) {
    LPEventLaunch   = 1,
    LPEventCPS      = 2,
    LPEventCPA      = 3,
};

//// LPMobileAT protocol definition
//@protocol LPMobileATDelegate
//
//+ didReceiveDeferredDeepLink:(NSURL *)url;
//
//@end

// LPMobileAT class interface
@interface LPMobileAT : NSObject

+ (NSString *)apiVersion;
+ (NSString *)sdkVersion;
+ (NSString *)getLpinfo;

+ (void)initializeWithAppId:(NSString *)appId appKey:(NSString *)appKey;
+ (void)initializeWithAppId;
//+ (void)checkForDeferredDeepLink:(id<LPMobileATDelegate>)delegate;
+ (void)applicationDidOpenURL:(NSURL *)url;
+ (void)trackAppLaunch;
+ (void)trackEvent:(LPEventType)eventType withValues:(NSDictionary *)values;
+ (void)autoCpi:(NSString *)merchant_id ua:(NSString *)userAgent remoteAddr:(NSString *)remoteAddress;

@end
