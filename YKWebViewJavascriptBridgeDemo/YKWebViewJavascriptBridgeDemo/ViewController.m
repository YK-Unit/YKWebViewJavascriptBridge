//
//  ViewController.m
//  YKWebViewJavascriptBridgeDemo
//
//  Created by York on 2017/2/16.
//  Copyright © 2017年 YK-Unit. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "YKNativeBridgeEngine.h"

@interface ViewController ()
<WKUIDelegate>

@property (nonatomic,strong) WKWebView *webView;
@property (nonatomic,strong) YKNativeBridgeEngine *nativeBridgeEngine;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIButton *callJsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    callJsButton.frame = CGRectMake(10, 60, 200, 80);
    [callJsButton setTitle:@"发送定位给web" forState:UIControlStateNormal];
    [callJsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [callJsButton addTarget:self action:@selector(callJsButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callJsButton];
    
    [self initWKWebView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initWKWebView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = [WKUserContentController new];
    
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    preferences.minimumFontSize = 40.0;
    configuration.preferences = preferences;
    
    self.nativeBridgeEngine = [[YKNativeBridgeEngine alloc] initWithWebViewConfiguration:configuration];;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.height - 100) configuration:self.nativeBridgeEngine.configuration];
    [self.nativeBridgeEngine bridgeForWebView:self.webView];
    
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
    
    
//    NSString *urlStr = @"https://www.baidu.com/";
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
//    [self.webView loadRequest:request];
    
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:urlStr];
    [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    
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
    
    [self.nativeBridgeEngine addMessageHandler:@"GetLocation" handler:^(id  _Nullable data, YKResponseCallback _Nonnull responseCallback) {
        NSLog(@"data:%@",data);
    
        NSString *location = @"广州-网易大厦";
        
        responseCallback(location);
    }];
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网页提醒" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 
- (void)callJsButtonClicked
{
    [self.nativeBridgeEngine sendMessage:@"SetLocation" data:@"广州-方圆E时光" responseCallback:^(id  _Nullable responseData) {
        NSLog(@"responseData:%@",responseData);
    }];
}

@end
