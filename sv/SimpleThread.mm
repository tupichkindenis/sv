//
// Created by Денис on 21.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//


#include "SimpleThread.h"

#include <iostream>
using namespace std; // Use unqualified names for Standard C++ library

void *SimpleThread::ThreadEntryRoutine(gxThread_t *thread)
{
    cout << "\n" << flush;
    cout << "Executing thread..." << "\n" << flush;
    int i = 0;
    while (i<2) {
        cout << "Thread: Looping through a long running request" << "\n" << flush;
        sSleep(1);
        i++;
    }
    return 0;
}

void SimpleThread::ThreadCleanupHandler(gxThread_t *thread)
{
    cout << "Executing clean up routine..." << "\n" << flush;
    cout << "\n" << flush;
}

void SimpleThread::ThreadExitRoutine(gxThread_t *thread) {
    cout << "Executing ThreadExitRoutine..." << "\n" << flush;
    cout << "\n" << flush;
    gxThread::ThreadExitRoutine(thread);
}
