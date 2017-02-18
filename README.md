# YKWebViewJavascriptBridge
基于`WKWebView`+`messageHandler`+`自定义协议` 搭建的`WebViewJavascriptBridge`

---

# Usage
1. 初始化 `YKNativeBridgeEngine` 
	
	``` objc
	WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = [WKUserContentController new];

    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    preferences.minimumFontSize = 40.0;
    configuration.preferences = preferences;

    // 1、根据WKWebViewConfiguration生成nativeBridgeEngine实例
    self.nativeBridgeEngine = [[YKNativeBridgeEngine alloc] initWithWebViewConfiguration:configuration];;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.height - 100) configuration:self.nativeBridgeEngine.configuration];
    // 2、绑定具体的WKWebView实例
    [self.nativeBridgeEngine bridgeForWebView:self.webView];

	
	```
2. Native 层和 Web 层添加 `messageHandler`

	- Native 层添加`messageHandler`
	
		``` objc 
		__weak typeof(self) weakSelf = self;
	    [self.nativeBridgeEngine addMessageHandler:@"SetViewColor" handler:^(id _Nullable data, YKResponseCallback _Nonnull responseCallback) {
	        NSLog(@"data:%@",data);
	        
	        NSArray *params = (NSArray *)data;
	        if (![params isKindOfClass:[NSArray class]]) {
	            return;
	        }
	        
	        if (params.count < 4) {
	            return;
	        }
	        
	        CGFloat r = [[params objectAtIndex:0] floatValue];
	        CGFloat g = [[params objectAtIndex:1] floatValue];
	        CGFloat b = [[params objectAtIndex:2] floatValue];
	        CGFloat a = [[params objectAtIndex:3] floatValue];
	        
	        weakSelf.view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
	        
	        responseCallback(nil);
	    }];
		
		```
	
	- Web 层添加 `messageHandler`
		
		``` js
		var webBridgeEngine = window.YKWebBridgeEngine;
		
		webBridgeEngine.addMessageHandler('SetLocation',
                                     function(data, responseCallback) {
                                     setLocation(data);
                                     var respData = {"result":"set location success"}
                                     responseCallback(respData);
                                    })
		```
3. 在 Web 层中调用 Native API
	
	``` js
	var webBridgeEngine = window.YKWebBridgeEngine;
	
	function colorClick() {
                var r = Math.random();
                var g = Math.random();
                var b = Math.random();
                var a = Math.random();
                webBridgeEngine.sendMessage('SetViewColor',[r,g,b,a],function(response) {

                                            });
            }
	
	```
4. 在 Native 层中调用 Web API

	``` objc
	[self.nativeBridgeEngine sendMessage:@"SetLocation" data:@"广州-方圆E时光" responseCallback:^(id  _Nullable responseData) {
	        NSLog(@"responseData:%@",responseData);
	    }];
	
	```

5. 更多使用详情，请看Demo。 enjoy~😘

---

# 设计思路

关于 `YKWebViewJavascriptBridge` 的设计思路，可以看我写的blog[《YKWebViewJavascriptBridge设计思路总结》](http://www.jianshu.com/p/63b3783829b2)
