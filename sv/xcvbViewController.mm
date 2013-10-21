//
//  xcvbViewController.m
//  sv
//
//  Created by Денис on 21.10.13.
//  Copyright (c) 2013 Денис. All rights reserved.
//

#import "xcvbViewController.h"
#import "SimpleThread.h"
#include <iostream>
using namespace std; // Use unqualified names for Standard C++ library

@interface xcvbViewController ()

@end

@implementation xcvbViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    SimpleThread t;

    gxThread_t *thread = t.CreateThread();

    // Wait until we realize the thread needs to be canceled
    t.sSleep(5);
    t.CancelThread(thread);

    // Wait for the thread to complete, and release its resources
    t.JoinThread(thread);

    if(thread->GetThreadState() == gxTHREAD_STATE_CANCELED) {

        cout << "The thread was canceled" << "\n" << flush;
    }
    else {
        cout << "The thread was not canceled" << "\n" << flush;
    }

    delete thread; // Prevent memory leaks
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end