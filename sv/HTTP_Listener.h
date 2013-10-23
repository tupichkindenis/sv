//
// Created by Denis on 22.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//



#import "gxthread.h"

#ifndef __HTTP_Listener_H_
#define __HTTP_Listener_H_


typedef int SOCKET;

class HTTP_Listener: public gxThread {

public:
    HTTP_Listener()
    {
        pthread_mutex_init(&mutex, NULL);
        semaphore = dispatch_semaphore_create(0);
        pipe(fdpipe);
    }
    virtual ~HTTP_Listener() {}

private:
    // Base class interface
    void *ThreadEntryRoutine( gxThread_t *thread);
    void ThreadCleanupHandler(gxThread_t *thread);
    void ThreadExitRoutine(   gxThread_t *thread);


    // #tool functions
    void *GetInAddr(struct sockaddr *sa);


    // #
    SOCKET MakeServerListener( int iPort );

    int getPort() const {
        return iPort;
    }



protected:
    gxThread_t *tid;

    SOCKET hSocket;
public:

    int iPort;

    pthread_mutex_t      mutex;
    dispatch_semaphore_t semaphore;
    int fdpipe[2];
};


#endif //__HTTP_Listener_H_
