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

/**
 初始化YKNativeBridgeEngine

 @param configuration WKWebViewConfiguration，可为nil
 @return YKNativeBridgeEngine实例
 */
- (instancetype _Nullable)initWithWebViewConfiguration:(WKWebViewConfiguration * _Nullable)configuration;

/**
 为WKWebView激活与web层通讯功能

 @param webView <#webView description#>
 */
- (void)bridgeForWebView:(WKWebView * _Nonnull)webView;

/**
 添加供JS调用的OC方法

 @param messageName <#messageName description#>
 @param messageHandler <#messageHandler description#>
 */
- (void)addMessageHandler:(NSString * _Nonnull)messageName handler:(YKMessageHandler _Nonnull)messageHandler;

/**
 移除供JS调用的OC方法

 @param messageName <#messageName description#>
 */
- (void)removeMessageHandlerForName:(NSString * _Nonnull)messageName;

/**
 发送消息，调用JS方法

 @param messgaeName JS的方法名称
 @param data 传递给JS方法的数据
 @param responseCallback 响应回调
 */
- (void)sendMessage:(NSString * _Nonnull)messgaeName data:(id _Nullable)data responseCallback:(YKResponseCallback _Nullable)responseCallback;

@end

