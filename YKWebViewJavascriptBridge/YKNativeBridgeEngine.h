//
//  YKNativeBridgeEngine.h
//  YKWebViewJavascriptBridgeDemo
//
//  Created by York on 2017/2/16.
//  Copyright © 2017年 YK-Unit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

typedef void (^YKResponseCallback)(id _Nullable responseData);
typedef void (^YKMessageHandler)(id _Nullable data, YKResponseCallback _Nonnull responseCallback);

@interface YKNativeBridgeEngine : NSObject

@property (nonatomic,readonly,copy) WKWebViewConfiguration * _Nonnull configuration;

- (instancetype _Nullable)initWithWebViewConfiguration:(WKWebViewConfiguration * _Nullable)configuration;

- (void)bridgeForWebView:(WKWebView * _Nonnull)webView;

- (void)addMessageHandler:(NSString * _Nonnull)messageName handler:(YKMessageHandler _Nonnull)messageHandler;

- (void)removeMessageHandlerForName:(NSString * _Nonnull)messageName;

- (void)sendMessage:(NSString * _Nonnull)messgaeName data:(id _Nullable)data responseCallback:(YKResponseCallback _Nullable)responseCallback;

@end

