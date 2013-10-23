//
// Created by Denis on 22.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
#ifndef __HTTP_Tunnel_H_
#define __HTTP_Tunnel_H_

#include "gxstypes.h"
#include "gxsocket.h"
#include "gxthread.h"
#include "gxmutex.h"
#include "gxcond.h"
#include "gxsurl.h"
#include "gxshttp.h"


// --------------------------------------------------------------
// Constants
// --------------------------------------------------------------
// Thread constants
const int DISPLAY_THREAD_RETRIES = 3;
// --------------------------------------------------------------

// __[Server configuration]______________________________________
struct  ServerConfig {
    ServerConfig();
    ~ServerConfig();

    // Server configuration variables
    gxsPort_t port;     // Server's port number
    int accept_clients; // True while accepting

    // gxThread variables
    thrPool *client_request_pool; // Worker threads processing client requests

    // gxThread synchronization interface
    gxMutex display_lock;      // Mutex object used to lock the display
    gxCondition display_cond;  // Condition variable used with the display lock
    int display_is_locked;     // Display lock Boolean predicate
};

// __[ClientSocket_t     ]______________________________________
// Client socket type used to associate client sockets other
// data types.
struct ClientSocket_t
{
    gxsSocket_t client_socket; // Client socket
};

// __[ClientRequestThread]______________________________________
class ClientRequestThread:
public gxSocket, public gxThread {
public:
     ClientRequestThread() {
         recv_loop     = 1;
         time_out_sec  = __HTTP_RECV_TIMEOUT_SECS__;
         time_out_usec = __HTTP_RECV_TIMEOUT_USECS__;
     }
    ~ClientRequestThread() { }

public:
    // Client routines
    void HandleClientRequest(ClientSocket_t *s);

private: // gxThread Interface
    void *ThreadEntryRoutine(gxThread_t *thread);
    void ThreadExitRoutine(gxThread_t *thread);
    void ThreadCleanupHandler(gxThread_t *thread);

    int ParseHTTPHeader(const gxString &header, gxsHTTPHeader &hdr);
public:
    void SetTimeOut(int seconds = __HTTP_RECV_TIMEOUT_SECS__,
                    int useconds =  __HTTP_RECV_TIMEOUT_USECS__) {
        time_out_sec  = seconds;
        time_out_usec = useconds;
    }
    void TerminateRecv() { recv_loop = 0; }
    void ResetRecv()     { recv_loop = 1; }
    void ResetTimeOut()  {
        time_out_sec = __HTTP_RECV_TIMEOUT_SECS__;
        time_out_usec = __HTTP_RECV_TIMEOUT_SECS__;
    }

protected:
    int recv_loop;     // Used to break receive loops
    int time_out_sec;  // Number of seconds before a blocking timeout
    int time_out_usec; // Number of microseconds before a blocking timeout
};

// __[HTTP_Tunnel]_______________________________________________
class HTTP_Tunnel:
public gxSocket, public gxThread {

public:
     HTTP_Tunnel(){};
    ~HTTP_Tunnel(){};
private:
    // Base class interface
    void *ThreadEntryRoutine(   gxThread_t *thread );
    void  ThreadCleanupHandler( gxThread_t *thread );
    void  ThreadExitRoutine(    gxThread_t *thread );

    //
    int MakeServerListener( int max_connections );

protected:
    ClientRequestThread request_thread;
};

// --------------------------------------------------------------
// Globals configuration variables
// --------------------------------------------------------------
extern ServerConfig ServerConfigSruct;
extern ServerConfig *servercfg;
// --------------------------------------------------------------
// Standalone functions
// --------------------------------------------------------------
void PrintMessage(const char *s1 = " ", const char *s2 = " ",
        const char *s3 = " ");
void ReportError(const char *s1 = " ", const char *s2 = " ",
        const char *s3 = " ");
int CheckSocketError(gxSocket *s, const char *mesg = 0,
        int report_error = 1);
int CheckThreadError(gxThread_t *thread, const char *mesg = 0,
        int report_error = 1);

void PrintHTTPHeader(const gxsHTTPHeader &hdr);


#endif //__HTTP_Tunnel_H_
