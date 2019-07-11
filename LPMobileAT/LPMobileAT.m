//
//  LPMobileAT.m
//  LinkPrice
//
//  Created by Sungsoo Kim on 6/9/16.
//  Copyright © 2016 LinkPrice Co., Ltd. All rights reserved.
//

#import "LPMobileAT.h"
#import "LPMTKeychain.h"
#import "NSURL+queryItems.h"
#import "NSDictionary+LPExtension.h"
#import "NSString+LPExtension.h"
#import "LPMTResponse.h"
#import <AdSupport/ASIdentifierManager.h>

#define SDK_VERSION @"2.0"
#define API_VERSION @"2.0"
#define FRAMEWORK_VERSION_NUMBER 2.0
#define FRAMEWORK_VERSION_STRING "2.0"

#ifdef DEBUG
//#define LP_API_URL @"https://dpoint.linkprice.com/sdk/api/trackevent.php"

#define LP_API_URL @"https://service.linkprice.com/lppurchase_cpa_v4.php"
#define LP_CPS_URL @"https://service.linkprice.com/lppurchase_cps_v4.php"
#define LP_CPA_URL @"https://service.linkprice.com/lppurchase_cpa_v4.php"
#else
#define LP_API_URL @"https://service.linkprice.com/lppurchase_cpa_v4.php"
#define LP_CPS_URL @"https://service.linkprice.com/lppurchase_cps_v4.php"
#define LP_CPA_URL @"https://service.linkprice.com/lppurchase_cpa_v4.php"
#endif

// Keychain service name
#define kKeychainServiceName @"LPAdAPI"

// UserDefaults key name
#define kUserDefaultsKey @"LPMobileAT"
#define kFirstLaunchTime @"kFirstLaunchTime"
#define kAppVersion @"kAppVersion"
#define kAppBuild @"kAppBuild"

// events
#define kIsAppLaunched @"isAppLaunched"
#define kIsFirstLaunch @"isFirstLaunch"
#define kURL @"url"
#define kQueryItems @"queryItems"
#define kDeferredDeepLink @"deferredDeepLink"
#define kClickId @"lp_cid"
#define lpinfo @"lpinfo"

// server response
#define kDeepLink @"deep_link"

// shortcut to access singleton instance methods and properties
#define _tracker [LPMobileAT sharedTracker]

// framework version
double LPMobileATVersionNumber = FRAMEWORK_VERSION_NUMBER;
const unsigned char LPMobileATVersionString[] = FRAMEWORK_VERSION_STRING;

static NSString* urlDecode(NSString *str) {
    NSString *unescapedString = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return unescapedString;
}


@interface LPMobileAT ()

@property (nonatomic) NSString *appId;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSMutableDictionary *appEvents;
@property (nonatomic) NSMutableDictionary *serverEvents;

+ (NSString *)idfa;
+ (NSString *)uuid;

@end

@implementation LPMobileAT

# pragma mark - public class properties
+ (NSString *)apiVersion {
    return API_VERSION;
}

+ (NSString *)sdkVersion {
    return SDK_VERSION;
}

+ (NSString *)getLpinfo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [userDefaults stringForKey:@"lpinfo"];
}

# pragma mark - private class methods

+ (instancetype)sharedTracker {
    static LPMobileAT *_sharedTracker;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedTracker = [LPMobileAT new];
        _sharedTracker.appEvents = [NSMutableDictionary dictionary];
        _sharedTracker.serverEvents = [NSMutableDictionary dictionary];
    });

    return _sharedTracker;
}

+ (NSString *)idfa {
    static NSString *_idfa;
    
    @synchronized(LPMobileAT.sharedTracker) {
        // if idfa is not set
        if (_idfa == nil
            && NSClassFromString(@"ASIdentifierManager")   // AdSupport framework may not be included
            && [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled) {
            
            NSUUID *advertisingId = [[ASIdentifierManager sharedManager] advertisingIdentifier];
            _idfa = [advertisingId UUIDString];
        }
    }
    
    return _idfa;
}

+ (NSDictionary*)splitQuery:(NSString *)url {
    NSString *query = url;
    if(!query||[query length]==0) return nil;
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    for(NSString* parameter in [query componentsSeparatedByString:@"&"]) {
        NSRange range = [parameter rangeOfString:@"="];
        NSString *key = urlDecode([parameter substringToIndex:range.location]);
        NSString *val = @"";
        
        if(range.location!=NSNotFound)
            val = urlDecode([parameter substringFromIndex:range.location+range.length]);
        
        [params setValue:val forKey:key];
    }
    return params;
}

+ (NSString *)uuid {
    static NSString *_uuid;
    
    @synchronized(LPMobileAT.sharedTracker) {
        // if uuis is not set
        if (_uuid == nil) {
            // find uuid in the keychain
            NSString *key = @"UUID";
            LPMTKeychain *keychain = [[LPMTKeychain alloc] initWithService:kKeychainServiceName withGroup:nil];
            _uuid = [keychain stringForKey:key];
            
            // if not found, create and store in the keychain
            if (_uuid == nil) {
                DLog(@"Keychain data not found");
                _uuid = [[NSUUID UUID] UUIDString];
                BOOL result = [keychain insert:key string:_uuid];
                if (result) {
                    DLog(@"Keychain successfully added data");
                }
            }
        }
    }
    
    return _uuid;
}

# pragma mark - public class methods

// This is called from application:didFinishLaunchingWithOptions:
+ (void)initializeWithAppId:(NSString *)appId appKey:(NSString *)appKey {

    DLog(@"entered");
    NSParameterAssert(appId.length > 0);
    NSParameterAssert(appKey.length > 0);

    _tracker.appId = appId;
    _tracker.appKey = appKey;
    _tracker.appEvents[kIsAppLaunched] = @(YES);

    // check if the app launches for the first time after installed
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKey];
    if (dict == nil) {
        _tracker.appEvents[kIsFirstLaunch] = @(YES);

        /*
        id appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        id appBuild = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        dict = @{kAppVersion: appVersion, kAppBuild: appBuild};
         */
        dict = @{kFirstLaunchTime: @((long long)[[NSDate date] timeIntervalSince1970])};
        DLog(@"UserDefaults set key:%@, value:%@", kUserDefaultsKey, dict);
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kUserDefaultsKey];
    }
    else {
        _tracker.appEvents[kIsFirstLaunch] = @(NO);
    }

    DLog(@"exited");
}

// This is called from the following methods.
// - application:openURL:options:
// - application:continueUserActivity:restorationHandler:
// - application:openURL:sourceApplication:annotaiton:
+ (void)applicationDidOpenURL:(NSURL *)url {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    DLog(@"entered");
    NSParameterAssert(url != nil);

    if (_tracker.serverEvents[kDeferredDeepLink] != nil &&
        [url.absoluteString isEqualToString:((NSURL *)_tracker.serverEvents[kDeferredDeepLink]).absoluteString]) {
        DLog(@"ignored url: %@", url.absoluteString);
    }
    else {
        _tracker.appEvents[kURL] = url;
        _tracker.appEvents[kQueryItems] = [url lpmt_queryItems];
        DLog(@"saved url: %@", url.absoluteString);
        
        NSLog(@"queryItems: %@", _tracker.appEvents[kQueryItems]);
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = [_tracker.appEvents[kQueryItems][@"rd"] integerValue];
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *expiredDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
        
        NSDictionary *lp = @{
            @"lpinfo": _tracker.appEvents[kQueryItems][@"lpinfo"],
            @"date": expiredDate
        };
        
        [userDefaults setObject:lp forKey:(@"lpinfo")];
        [userDefaults synchronize];
        
        NSLog(@"lpinfo: %@", [userDefaults dictionaryForKey:@"lpinfo"]);
        
    }

    _tracker.serverEvents[kDeferredDeepLink] = nil;
    DLog(@"exited");
}

// This is called from applicationDidBecomeActive:
+ (void)trackAppLaunch {

    DLog(@"entered");
    NSAssert(_tracker.appId != nil, @"appId is not set.");
    NSAssert(_tracker.appKey != nil, @"appKey is not set.");

    // 이벤트가 발생한 경우에만 서버 호출
    if (_tracker.appEvents.count > 0) {
        // 서버 호출
        NSMutableDictionary *params = [NSMutableDictionary new];
        params[@"fingerprint"] = @{@"device_model": [[UIDevice currentDevice] model],
                                   @"os_ver": [[UIDevice currentDevice] systemVersion]};
        
        [LPMobileAT trackEvent:LPEventLaunch
                   withValues:params
            completionHandler:^(LPMTResponse *lpResponse) {
                DLog("completionHandler entered");

                // if deferred deep link is given
                if (_tracker.appEvents[kIsFirstLaunch]
                    && _tracker.appEvents[kURL] == nil
                    && lpResponse
                    && lpResponse.result == 0
                    && lpResponse.data[kDeepLink] != nil) {

                    DLog(@"call openURL - begin");
                    _tracker.serverEvents[kDeferredDeepLink] = [NSURL URLWithString:lpResponse.data[kDeepLink]];

                    // 원래 코드 by 김성수
                    // 아래 코드는 info.plist에 등록된 url scheme에 대해서만 동작한다.
                    // http://로 시작하면 웹페이지가 오픈된다.
                    //[[UIApplication sharedApplication] openURL:_tracker.serverEvents[kDeferredDeepLink]];

                    // NSLog(@"openURL :%@", _tracker.serverEvents[kDeferredDeepLink]);
                    // NSLog(@"openURL text :%@", ((NSURL *)_tracker.serverEvents[kDeferredDeepLink]).absoluteString);

                    // 개선된 코드 by 박영우
                    // url이 어떤 포멧이든 메인 앱의 함수를 호출한다.
                    NSURL *url = _tracker.serverEvents[kDeferredDeepLink];

                    UIApplication *application = [UIApplication sharedApplication];
                    id<UIApplicationDelegate> applicationDelegate = [[UIApplication sharedApplication] delegate];
                    [applicationDelegate application:application
                                             openURL:url
                                   sourceApplication:nil
                                          annotation:@{}];//딕셔너리 구조:혹시 전달할 추가 정보가 있으면 여기에 넣으면 됩니다.

                    DLog(@"call openURL - end");
                }

                // 이벤트 데이터 모두 삭제
                [_tracker.appEvents removeAllObjects];

                DLog("completionHandler exited");
            }
         ];
    }

    DLog(@"exited");
}

+ (void)autoCpi:(NSString *)merchant_id ua:(NSString *)userAgent remoteAddr:(NSString *)remoteAddress{
    
    DLog(@"entered");
    NSAssert(_tracker.appId != nil, @"appId is not set.");
    NSAssert(_tracker.appKey != nil, @"appKey is not set.");
    
    // 이벤트가 발생한 경우에만 서버 호출
    if (_tracker.appEvents.count > 0) {
        // 서버 호출
//        NSMutableDictionary *params = [NSMutableDictionary new];
//        params[@"fingerprint"] = @{@"device_model": [[UIDevice currentDevice] model],
//                                   @"os_ver": [[UIDevice currentDevice] systemVersion]};
        
        NSDictionary *cpiInfo = [NSDictionary new];
        NSDictionary *action = [NSDictionary new];
        NSDictionary *linkprice = [NSDictionary new];
        
        action = @{
                   @"unique_id": [LPMobileAT idfa],
                   @"final_paid_price": @0,
                   @"currency": @"KRW",
                   @"member_id": @"user",
                   @"action_code": @"install",
                   @"action_name": @"install",
                   @"category_code": @"install"
                   };
        
        linkprice = @{
                      @"merchant_id": merchant_id,
                      @"user_agent": userAgent,
                      @"remote_addr": remoteAddress
                      };
        
        cpiInfo = @{
                    @"action": action,
                    @"linkprice": linkprice
                    };
        
        // in v4 first_launch parameter is not used.
        if ([_tracker.appEvents[kIsFirstLaunch] boolValue]) {
//            NSLog(@"auto cpi data: %@", cpiInfo);
//            params[@"first_launch"] = _tracker.appEvents[kIsFirstLaunch];
            
            // send first launch data
            [LPMobileAT trackEvent:LPEventCPA withValues:cpiInfo completionHandler:nil];
            [_tracker.appEvents removeAllObjects];
        }
        
    }
    
    DLog(@"exited");
}



+ (void)trackEvent:(LPEventType)eventType withValues:(NSDictionary *)values {
    DLog(@"entered");
    [LPMobileAT trackEvent:eventType withValues:values completionHandler:nil];
    DLog(@"exited");
}

+ (void)trackEvent:(LPEventType)eventType
        withValues:(NSDictionary *)values
 completionHandler:(void(^)(LPMTResponse *))completionHandler {

    DLog(@"entered");
    NSParameterAssert(values != nil);
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *lp = [userDefaults dictionaryForKey:@"lpinfo"];
    
    if(lp != nil) {
        NSString *lpinfoValue = lp[@"lpinfo"];
        NSDate *now = [NSDate date];
        NSComparisonResult result = [lp[@"date"] compare:now];
        
        // prepare inner section
        NSMutableDictionary *data = [values mutableCopy];
        NSMutableDictionary *linkprice = [values[@"linkprice"] mutableCopy];
        
        if (lpinfoValue != nil && result != NSOrderedAscending) {
            linkprice[@"lpinfo"] = lpinfoValue;
            linkprice[@"device_type"] = @"app-ios";
            data[@"linkprice"] = linkprice;
            
            // prepare outer section
            NSDictionary *params = data;
            
            NSLog(@"data: %@", params);
            
            // call server
            [_tracker sendAsynchronousRequest:params
                            completionHandler:completionHandler];
            DLog(@"exited");
        }
    }
    
}

# pragma mark - private instance methods

- (void)sendAsynchronousRequest:(NSDictionary *)params
              completionHandler:(void(^)(LPMTResponse *))completionHandler {

    DLog(@"entered");
    
    NSError* error;
    // encrypt inner section
    DLog(@"params: %@", params);
    NSMutableDictionary *params_encrypted = [params mutableCopy];
//    params_encrypted[@"data"] = [params_encrypted[@"data"] lpmt_AESEncrypt:self.appKey];
//    DLog(@"params_encrypted: %@", params_encrypted);

    // prepare header and data
    NSURL *url = [NSURL URLWithString:LP_CPS_URL];
    
    // call lppurchase_cpa_v4
    if(params[@"action"] != nil) {
        url =[NSURL URLWithString:LP_CPA_URL];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:20];    // default: 60 seconds
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
//    NSData *params_data = [params_encrypted lpmt_JSONEncodedDataWithOptions:0];
    // send data as JSON type - shji
    NSData *params_data = [NSJSONSerialization dataWithJSONObject:params_encrypted options:NSJSONWritingPrettyPrinted error:&error];
    [request setValue:@(params_data.length).stringValue forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:params_data];
    
    // call server
    DLog(@"call server: %@", LP_API_URL);
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error) {

         LPMTResponse *lpResponse;
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

         if (error != nil) {
             DLog(@"ERROR: %@", error);
         }
         else if (httpResponse.statusCode != 200) {
             DLog(@"ERROR: HTTP Status: %ld", (long)httpResponse.statusCode);
             DLog(@"ERROR: Response Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         }
         else if ([data length] == 0) {
             DLog(@"ERROR: HTTP Status: %ld", (long)httpResponse.statusCode);
             DLog(@"ERROR: No Response Data");
         }
         else {
             // parse response data
//             lpResponse = [[LPMTResponse alloc] initWithKey:self.appKey data:data];
         }

         // run completionHandler
         if (completionHandler != nil) {
             DLog(@"run completionHandler");
             completionHandler(lpResponse);
         }
     }];

    DLog(@"exited");
}

@end
