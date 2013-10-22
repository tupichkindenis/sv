//
//  xcvbViewController.m
//  sv
//
//  Created by Денис on 21.10.13.
//  Copyright (c) 2013 Денис. All rights reserved.
//

#import "xcvbViewController.h"
#import "SimpleThread.h"
#import "HTTP_Tunnel.h"
#include <iostream>
using namespace std; // Use unqualified names for Standard C++ library

@interface xcvbViewController ()
@end

@implementation xcvbViewController

@synthesize webView = _webView;

- (void)viewDidLoad{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _webView.delegate = self;
}
// --------------------------------------------------------------------------
- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"shouldStartLoadWithRequest:URL: \n%@", request );
    return TRUE;
}
// --------------------------------------------------------------------------
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"shouldStartLoadWithRequest:Error: \n%@", error);
}
// --------------------------------------------------------------------------
- (void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"webViewDidStartLoad");
}
// --------------------------------------------------------------------------
- (void)webViewDidFinishLoad:(UIWebView *)webView;{
    NSLog(@"webViewDidFinishLoad");
}
// --------------------------------------------------------------------------
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// --------------------------------------------------------------------------
- (IBAction)stopTunnelbutton:(id)sender {
    myTunnel.CloseThread(myTunnel_t);
    myTunnel.JoinThread(myTunnel_t);
}
// --------------------------------------------------------------------------
- (IBAction)startTunnelButton:(id)sender {
    myTunnel_t = myTunnel.CreateThread();
}
// --------------------------------------------------------------------------
- (IBAction)goButton:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:8080?url=www.ru"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView setScalesPageToFit:YES];
    [self.webView loadRequest:request];
}


@end