//
//  ViewController.m
//  JSSample
//
//  Created by 冯 鸿杰 on 14-3-18.
//  Copyright (c) 2014年 掌淘科技. All rights reserved.
//

#import "ViewController.h"
#import "ShareSDKJSBridge.h"

@interface ViewController ()
{
@private
    ShareSDKJSBridge *_bridge;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Sample" ofType:@"html"];
    NSURL *htmlURL = [NSURL fileURLWithPath:path];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.delegate = self;
    [self.view addSubview:webView];
    [webView loadRequest:[NSURLRequest requestWithURL:htmlURL]];
    [webView release];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return ![[ShareSDKJSBridge sharedBridge] captureRequest:request webView:webView];
}

@end
