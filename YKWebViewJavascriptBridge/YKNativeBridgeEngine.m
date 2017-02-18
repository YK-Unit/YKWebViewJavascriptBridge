//
//  YKNativeBridgeEngine.m
//  YKWebViewJavascriptBridgeDemo
//
//  Created by York on 2017/2/16.
//  Copyright © 2017年 YK-Unit. All rights reserved.
//

#import "YKNativeBridgeEngine.h"
#import "YKWebBridgeEngine.h"

@interface YKNativeBridgeEngine()
<WKScriptMessageHandler>

@property (nonatomic,readwrite,copy) WKWebViewConfiguration *configuration;
@property (nonatomic,weak) WKWebView *webView;

@property (nonatomic,strong) NSMutableDictionary *messageHandlerDict;
@property (nonatomic,strong) NSMutableDictionary *responseCallbackDict;
@property (nonatomic,assign) NSInteger uniqueId;

- (void)_bridgeEngineDidWriteData:(NSString * _Nonnull)jsonMessage;
- (void)_bridgeEngineDidReadData:(NSString * _Nonnull)jsonMessage;

@end

@implementation YKNativeBridgeEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.messageHandlerDict = [[NSMutableDictionary alloc] initWithCapacity:32];
        self.responseCallbackDict = [[NSMutableDictionary alloc] initWithCapacity:32];
    }
    return self;
}

- (instancetype)initWithWebViewConfiguration:(WKWebViewConfiguration *)configuration
{
    self = [self init];
    if (self) {
        if (configuration) {
            self.configuration = configuration;
        }else{
            WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
            configuration.userContentController = [[WKUserContentController alloc] init];
            
            self.configuration = configuration;
        }
        
        if (!self.configuration.userContentController) {
            self.configuration.userContentController = [WKUserContentController new];
        }
        
        //通过JS注入方式，初始化WebBridgeEngine
        NSString *js = YKWebBridgeEngine_js();
        WKUserScript *script = [[WKUserScript alloc] initWithSource:js
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:YES];
        [self.configuration.userContentController addUserScript:script];
        
        [self.configuration.userContentController addScriptMessageHandler:self name:@"NativeBridgeEngineDidReadData"];
    }
    return self;
}

- (void)bridgeForWebView:(WKWebView *)webView
{
    self.webView = webView;
}

- (void)addMessageHandler:(NSString *)messageName handler:(YKMessageHandler)messageHandler
{
    if (messageHandler && messageName) {
        YKMessageHandler handler = [messageHandler copy];
        [self.messageHandlerDict setObject:handler forKey:messageName];
    }
}

- (void)removeMessageHandlerForName:(NSString *)messageName
{
    if (messageName) {
        [self.messageHandlerDict removeObjectForKey:messageName];
    }
}

- (void)sendMessage:(NSString *)messgaeName data:(id)data responseCallback:(YKResponseCallback)responseCallback
{
    NSMutableDictionary *messgaeDict = [[NSMutableDictionary alloc] initWithCapacity:8];
    
    NSInteger reqId = ++self.uniqueId;
    
    [messgaeDict setObject:@(reqId) forKey:@"reqId"];
    
    [messgaeDict setObject:messgaeName forKey:@"name"];
    if (data) {
        [messgaeDict setObject:data forKey:@"data"];
    }
    
    if (responseCallback) {
        [self.responseCallbackDict setObject:[responseCallback copy] forKey:@(reqId)];
    }
    
    NSString *jsonMessage = [self serializeMessage:messgaeDict];
    
    [self _bridgeEngineDidWriteData:jsonMessage];
}

#pragma mark - JSON序列化和反序列化
- (NSString *)serializeMessage:(NSDictionary *)messgaeDict
{
    if (!messgaeDict) {
        return nil;
    }
    
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messgaeDict options:0 error:nil];
    NSString *jsonMessage = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
    return jsonMessage;
}

- (NSDictionary *)deserializeJSONMessage:(NSString *)jsonMessage
{
    if (!jsonMessage) {
        return nil;
    }
    
    NSData *messageData = [jsonMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingAllowFragments error:nil];
    
    if (![messageDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return messageDict;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"NativeBridgeEngineDidReadData"]) {
        [self _bridgeEngineDidReadData:message.body];
    }
}

#pragma mark - 通讯数据读写
- (void)_bridgeEngineDidWriteData:(NSString *)jsonMessage
{
    if (!jsonMessage) {
        return;
    }
    
    if (![jsonMessage isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSString *jsCode = [NSString stringWithFormat:@"YKWebBridgeEngine._bridgeEngineDidReadData('%@')",jsonMessage];
    [self.webView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"bridgeEngineDidWriteData:%@-%@",result,error);
    }];
}

- (void)_bridgeEngineDidReadData:(NSString *)jsonMessage
{
    if (!jsonMessage) {
        return;
    }
    
    if (![jsonMessage isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSDictionary *messgaeDict = [self deserializeJSONMessage:jsonMessage];
    if (!messgaeDict) {
        return;
    }
    
    NSArray *allKeys = messgaeDict.allKeys;
    
    //收到WebBridgeEngine发来的请求
    if ([allKeys containsObject:@"reqId"]) {
        NSInteger reqId = [[messgaeDict objectForKey:@"reqId"] integerValue];
        id data = [messgaeDict objectForKey:@"data"];
        NSString *name = [messgaeDict objectForKey:@"name"];
        
        if (!name) {
            return;
        }
        
        YKMessageHandler handler = [self.messageHandlerDict objectForKey:name];
        
        if (!handler) {
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        YKResponseCallback responseCallback = ^(id responseData) {
            NSMutableDictionary *respMessageDict = [[NSMutableDictionary alloc] initWithCapacity:8];
            [respMessageDict setObject:@(reqId) forKey:@"respId"];
            
            if (responseData) {
                [respMessageDict setObject:responseData forKey:@"data"];
            }
            
            NSString *jsonMessage = [weakSelf serializeMessage:respMessageDict];
            [weakSelf _bridgeEngineDidWriteData:jsonMessage];
        };
        
        handler(data,responseCallback);

    }
    //收到WebBridgeEngine返回的响应数据
    else if ([allKeys containsObject:@"respId"]) {
        NSInteger respId = [[messgaeDict objectForKey:@"respId"] integerValue];
        id responseData = [messgaeDict objectForKey:@"data"];
        YKResponseCallback responseCallback = [self.responseCallbackDict objectForKey:@(respId)];
        if (responseCallback) {
            responseCallback(responseData);
            [self.responseCallbackDict removeObjectForKey:@(respId)];
        }
    }
}

@end

