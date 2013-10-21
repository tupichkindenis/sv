//
// Created by Денис on 21.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//



#include "gxthread.h"

#ifndef __SimpleThread_H_
#define __SimpleThread_H_


class SimpleThread : public gxThread
{
public:
    SimpleThread() { }
    ~SimpleThread() { }

private:
    // Base class interface
    void *ThreadEntryRoutine(gxThread_t *thread);
    void ThreadCleanupHandler(gxThread_t *thread);
    void ThreadExitRoutine(gxThread_t *thread);
};


#endif //__SimpleThread_H_
