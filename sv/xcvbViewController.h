//
//  xcvbViewController.h
//  sv
//
//  Created by Денис on 21.10.13.
//  Copyright (c) 2013 Денис. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTTP_Tunnel.h"

@interface xcvbViewController : UIViewController<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

gxThread_t *myTunnel_t;
HTTP_Tunnel myTunnel;
