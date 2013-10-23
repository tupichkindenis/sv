//
// Created by Denis on 22.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//


#include "HTTP_Listener.h"
#import <sys/socket.h>
#import <netdb.h>
#import <arpa/inet.h>


/*
 *
 */
void *HTTP_Listener::GetInAddr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET)
    {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }
    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

/*
 *
 */
void *HTTP_Listener::ThreadEntryRoutine(gxThread_t *thread)
{
    // Create a server
    hSocket = MakeServerListener(getPort());
    if (hSocket < 0)
    {
        fprintf(stderr, "Couldn't make proxy server listener on port %s\n", getPort());
        return NULL;
    }

    NSLog(@"HTTP-Tunnel: waiting for connections...");

    // Incoming connection accept loop
    for (;;)
    {
        struct sockaddr_storage their_addr; // connector's address information
        char s[INET6_ADDRSTRLEN];
        socklen_t sin_size = sizeof their_addr;

        // Accept connections
        SOCKET hClientSocket = accept(hSocket, (struct sockaddr *)&their_addr, &sin_size);
        if (hClientSocket == -1)
        {
            NSLog(@"HTTP-Tunnel: Some error happend wile accept incomming connections...");
            continue;
        }

        // Print out IP address
        inet_ntop(their_addr.ss_family, GetInAddr( (struct sockaddr *)&their_addr ), s, sizeof s);

        NSLog(@"HTTP-Tunnel: Got connection from %s", s );

        // To Activate HTTP-Connection
    }

    NSLog(@"Main thread of Tunnel has been completed.");
    return NULL;
}

/*
 *
 */
void HTTP_Listener::ThreadCleanupHandler(gxThread_t *thread)
{
    NSLog(@"HTTP_Listener::ThreadCleanupHandler.begin()");
    if( hSocket >= 0 )
    {
        NSLog(@"HTTP_Listener::ThreadCleanupHandler.closeSocket()");
        shutdown( hSocket, SHUT_RDWR );
        close( hSocket );
    }
    gxThread::ThreadCleanupHandler(thread);
    NSLog(@"HTTP_Listener::ThreadCleanupHandler.done()");
}

/*
 *
 */
void HTTP_Listener::ThreadExitRoutine(gxThread_t *thread)
{
    NSLog(@"HTTP_Listener::ThreadExitRoutine.begin()");
    if( hSocket >= 0 )
    {
        NSLog(@"HTTP_Listener::ThreadExitRoutine.closeSocket()");
        shutdown( hSocket, SHUT_RDWR );
        close( hSocket );
    }
    gxThread::ThreadExitRoutine(thread);
    NSLog(@"HTTP_Listener::ThreadExitRoutine.done()");
}

/*
 *
 */
SOCKET HTTP_Listener::MakeServerListener(int iPort)
{
    NSLog(@"HTTP_Listener::MakeServerListener.begin()");

    SOCKET hSocket = 0;

    struct sockaddr_in sin;

    memset( &sin, 0x00, sizeof(sin) );

    NSLog(@"Main thread of Tunnel has been executed.");

    if( ( hSocket = socket( PF_INET, SOCK_STREAM, 0 ) ) < 0 )
    {
        NSLog(@"HTTP-Tunnel: Error(%d), Socket can not be created.\n", errno );
        return -1;
    }

    // make addr/port reusable.
    int yes = 1;
    setsockopt( hSocket, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes) );
    setsockopt( hSocket, SOL_SOCKET, SO_REUSEPORT, &yes, sizeof(yes) );

    // configure socket
    sin.sin_len         = sizeof(sin);
    sin.sin_family      = AF_INET;
    sin.sin_port        = htons(iPort);
    sin.sin_addr.s_addr = INADDR_ANY;

    if ( bind( hSocket, (struct sockaddr *)&sin, sizeof(sin) ) < 0 )
    {
        NSLog(@"HTTP-Tunnel: Error(%d), Socket can not be binded to selected host/port.\n", errno );
        shutdown(hSocket, SHUT_RDWR);
        close(hSocket);
        return -2;
    }

    if( listen(hSocket, 5) )
    {
        NSLog(@"HTTP-Tunnel: Error(%d), Socket can not be marked as socket for incoming connection(s).\n", errno );
        shutdown(hSocket, SHUT_RDWR);
        close(hSocket);
        return -3;
    }

    NSLog(@"HTTP_Listener::MakeServerListener.done()");
    return hSocket;
}
