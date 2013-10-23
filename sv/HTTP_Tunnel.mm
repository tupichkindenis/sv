//
// Created by Denis on 22.10.13.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
#import <sys/socket.h>
#import <netdb.h>
#import <iostream>


#include "HTTP_Tunnel.h"
#include "gxshttpc.h"

// --------------------------------------------------------------
// Globals variable initialization
// --------------------------------------------------------------
ServerConfig ServerConfigSruct;
ServerConfig *servercfg = &ServerConfigSruct;
ServerConfig::ServerConfig()
{
    port = 8080;
    accept_clients = 1;
    display_is_locked = 0;
    client_request_pool = new thrPool;
}

ServerConfig::~ServerConfig()
{
    if(client_request_pool) delete client_request_pool;
}

// --------------------------------------------------------------
// Standalone functions
// --------------------------------------------------------------

int CheckThreadError(gxThread_t *thread, const char *mesg, int report_error)
// Test the thread for an error condition and report the message
// if the "report_error" variable is true. The "mesg" string is used
// display a message with the reported error. Returns true if an
// error was detected for false of no errors where detected.
{
    if(thread->GetThreadError() == gxTHREAD_NO_ERROR) {
        // No thread errors reported
        return 0;
    }
    if(report_error) { // Reporting the error to an output device
        if(mesg) {
            PrintMessage(mesg, "\n", thread->ThreadExceptionMessage());
        }
        else {
            PrintMessage(thread->ThreadExceptionMessage());
        }
    }
    return 1;
}


int CheckSocketError(gxSocket *s, const char *mesg, int report_error)
// Test the socket for an error condition and report the message
// if the "report_error" variable is true. The "mesg" string is used
// display a message with the reported error. Returns true if an
// error was detected for false of no errors where detected.
{
    if(s->GetSocketError() == gxSOCKET_NO_ERROR) {
        // No socket errors reported
        return 0;
    }
    if(report_error) { // Reporting the error to an output device
        if(mesg) {
            PrintMessage(mesg, "\n", s->SocketExceptionMessage());
        }
        else {
            PrintMessage(s->SocketExceptionMessage());
        }
    }
    return 1;
}

void ReportError(const char *s1, const char *s2, const char *s3)
// Thread safe error reporting function.
{
    PrintMessage(s1, s2, s3);
}

void PrintMessage(const char *s1, const char *s2, const char *s3)
// Thread safe write function that will not allow access to
// the critical section until the write operation is complete.
{
    servercfg->display_lock.MutexLock();

    // Ensure that all threads have finished writing to the device
    int num_try = 0;
    while(servercfg->display_is_locked != 0) {
        // Block this thread from its own execution if a another thread
        // is writing to the device
        if(++num_try < DISPLAY_THREAD_RETRIES) {
            servercfg->display_cond.ConditionWait(&servercfg->display_lock);
        }
        else {
            return; // Could not write string to the device
        }
    }

    // Tell other threads to wait until write is complete
    servercfg->display_is_locked = 1;

    // ********** Enter Critical Section ******************* //
    std::cout << "\n";
    if(s1) std::cout << s1;
    if(s2) std::cout << s2;
    if(s3) std::cout << s3;
    std::cout << "\n";
    std::cout.flush(); // Flush the ostream buffer to the stdio
    // ********** Leave Critical Section ******************* //

    // Tell other threads that this write is complete
    servercfg->display_is_locked = 0;

    // Wake up the next thread waiting on this condition
    servercfg->display_cond.ConditionSignal();
    servercfg->display_lock.MutexUnlock();
}


// --------------------------------------------------------------
// Tunnel
// --------------------------------------------------------------
int HTTP_Tunnel::MakeServerListener( int max_connections )
//
//
{
    if( InitSocketLibrary() == 0 )
    {
        if( InitSocket( SOCK_STREAM, servercfg->port ) < 0 ) return -1;
    }
    else
    {
        return -1;
    }

    // Bind the name to the socket
    if( Bind() < 0 )
    {
        CheckSocketError((gxSocket *)this, "Error initializing server");
        Close();
        return -1;
    }

    // Listen for connections with a specified backlog
    if( Listen(max_connections) < 0) {
        CheckSocketError((gxSocket *)this, "Error initializing server");
        Close();
        return -1;
    }

    return 0;
}

void *HTTP_Tunnel::ThreadEntryRoutine(gxThread_t *thread)
{
    NSLog(@"HTTP_Tunnel::ThreadEntryRoutine.begin(threadId=%d)", thread->GetObjectID() );

    // Create a server
    if( MakeServerListener(5) != 0 )
    {
        NSLog(@"HTTP_Tunnel::Error, Listener can not be executed!" );
        return NULL;
    }

    NSLog(@"HTTP-Tunnel: waiting for connections...");

    // Incoming connection accept loop
    for (;;)
    {
        // Block the server until a client requests service
        if( Accept() < 0 ) continue;

        // NOTE: Getting client info for statistical purposes only
        char client_name[gxsMAX_NAME_LEN];
        int r_port = -1;

        GetClientInfo(client_name, r_port);
        PrintMessage("Received client request from ", client_name);

        ClientSocket_t *s = new ClientSocket_t;

        if(!s)
        {
            ReportError("A fatal memory allocation error occurred\nShutting down the server.");
            break;
        }

        // Record the file descriptor assigned by the Operating System
        s->client_socket = GetRemoteSocket();

        // Destroy all the client threads that have exited
        RebuildThreadPool(servercfg->client_request_pool);

        // Create thread per cleint
        gxThread_t *rthread =
        request_thread.CreateThread(servercfg->client_request_pool, (void *)s);
        if( CheckThreadError(rthread, "Error starting client request thread"))
        {
            delete s;
            break;
        }
    }
//        // ===========================================
//        // %разбираем полученный запрос.
//
//
//        // вычленяем (тип запроса)
//        // вычленяем (адресс удаленного хоста)
//        // вычленяем (номер порта)
//        // модифицируем запрос
//
//        // ===========================================
//        // %устанавливаем соедиенение с удаленным сервером
//
//        // ===========================================
//        // %инициализируем потоки для отправки/получения данных
//
//        // ...поток для отправки данных...
//        // ___________________________________________
//        // - указывем тип потока (получение/отправка)
//        // - указывем сокет для приема
//        // - указывем сокет для отправки
//        // - указываем протокол
//
//        // ...поток для получения данных...
//        // ___________________________________________
//        // - указывем тип потока (получение/отправка)
//        // - указывем сокет для приема
//        // - указывем сокет для отправки
//        // - указываем протокол
//
//        // %запускаем потоки
//
//    }
//
//
//    closeSocket( _hSocket );
    NSLog(@"HTTP_Tunnel::ThreadEntryRoutine.done()");
    return NULL;
}

// -----------------------------------------------------------------------------------------------
void HTTP_Tunnel::ThreadCleanupHandler(gxThread_t *thread)
// Thread cleanup handler used in the event that the thread is
// canceled.
{
    CloseSocket(); // Close the server side socket
}

// -----------------------------------------------------------------------------------------------
void HTTP_Tunnel::ThreadExitRoutine(gxThread_t *thread)
// Thread exit function used to close the server thread.
{
    CloseSocket(); // Close the server side socket
}


// --------------------------------------------------------------
// ClientRequestThread
// --------------------------------------------------------------


void ClientRequestThread::ThreadExitRoutine(gxThread_t *thread)
// Thread exit function used to close the client thread.
{
    // Extract the client socket from the thread parameter
    ClientSocket_t *s = (ClientSocket_t *)thread->GetThreadParm();

    // Close the client socket and free its resources
    Close(s->client_socket);
    delete s;
}

void ClientRequestThread::ThreadCleanupHandler(gxThread_t *thread)
// Thread cleanup handler used in the event that the thread is
// canceled.
{
    // Extract the client socket from the thread parameter
    ClientSocket_t *s = (ClientSocket_t *)thread->GetThreadParm();

    // Close the client socket and free its resources
    Close(s->client_socket);
    delete s;
}

void ClientRequestThread::HandleClientRequest(ClientSocket_t *s)
// Function used to handle a client request.
{
    // NOTE: The demo processes a single HTTP GET request per client
    char request[__HTTP_PACKET_SIZE__];

    gxString header;

    // Block until the client sends some data
    int nRet = 0;
    int byte_count;
    int found_header = 0;
    int bytes_received = 0;

    while(recv_loop)
    {
        // Read the file header into the header string

        //ReadSelect(s->client_socket, time_out_sec, time_out_usec);
        //if(CheckSocketError((gxSocket *)this, "Error select client request")) {
        //    return;
        //}

        int nRet = RawRead( s->client_socket, request, __HTTP_PACKET_SIZE__);
        if(CheckSocketError((gxSocket *)this, "Error reading client request"))
        {
            return;
        }

        request[nRet] = '\0'; // Null terminate the receive buffer

        header += request;

        if(!found_header)
        {
            header.Cat(request, nRet);
            if((header.Find("\r\n\r\n") != -1) || (header.Find("\n\n") != -1))
            {
                found_header = 1; // Found the end of header marker

                // Remove everything after the end of header marker
                if(!header.DeleteAfter("\r\n\r\n"))
                {
                    header.DeleteAfter("\n\n");
                }

                // Parse the HTTP header
                gxsHTTPHeader hdr;
                ParseHTTPHeader( header, hdr);
                PrintHTTPHeader(hdr);
            }
        }

        // Exit if the server closed the connection
        if(nRet == 0) break;
    }

//    // 09/07/2001: Remove everything after the end of the header marker.
//    // Some Web server return the entire document when the header is
//    // requested.
//    header.DeleteAfter("\r\n\r\n");
//    gxsHTTPClient
//
//    // 10/03/2002: Reset the header before parsing it. This change was
//    // made for functions that reuse the header multiple times. In the
//    // event that the site does not return a header the status members
//    // will be reset rather than passing back the previous values.
//    gxsHTTPHeader hdr;
//    hdr.Reset();
//    ParseHTTPHeader(header, hdr);
//
//
//    // At this point we need to parse the client request and process it.
//    // For simplicity sake these operations have been omitted.
//    // ... (parsing operation)
//    // ... (processing operation)



    // Simply send a test page (with a header) back to the client.
    const char *test_page = "HTTP/1.0 200 OK\r\nServer: gxThread\r\nConnection: \
close\r\n\r\n<HTML>\n<HEAD>\n<TITLE> gxThread Test Page </TITLE>\n</HEAD>\
<BODY><CENTER><H1>gxThread Test Page</H1></CENTER><HR><PRE>Response from the \
multi-threaded HTTP server</PRE><HR><CENTER>End of document</CENTER>\n</BODY>\
\n</HTML>";

    // Blocking send that will not return until all bytes are written
    Send(s->client_socket, test_page, strlen(test_page));
    CheckSocketError((gxSocket *)this, "Error sending page to client");
}

void *ClientRequestThread::ThreadEntryRoutine(gxThread_t *thread)
{
    // Extract the client socket from the thread parameter
    ClientSocket_t *s = (ClientSocket_t *)thread->GetThreadParm();

    // Process the client request
    HandleClientRequest(s);

    return (void *)0;
}


int ClientRequestThread::ParseHTTPHeader(const gxString &header, gxsHTTPHeader &hdr)
// Parse an HTTP header passing back the header information in the
// "hdr" variable. Returns 0 if no errors occur.
{
    hdr.http_header = header;
    gxString dup_header(header);

    char status[1024], status2[1024], rest[1024];
    status[0] = status2[0] = rest[0] = 0;
    int offset, index;
    gxString sbuf, ibuf, atoibuf;

    // Read the headers status line
    sscanf(dup_header.c_str(), "HTTP/%f %d %[^\r\n]",
            &hdr.http_version, &hdr.http_status, status);

    if (hdr.http_status == gxsHTTP_STATUS_UNAUTHORIZED) {
        // The 401 (unauthorized) response message is used by an origin server
        // to challenge the authorization of a user agent. This response must
        // include a WWW-Authenticate header field containing at least one
        // challenge applicable to the requested resource.
        hdr.authentication_needed = 1;
    }
    else if (hdr.http_status == gxsHTTP_STATUS_FORBIDDEN) {
        hdr.authentication_scheme = hdr.realm = hdr.auth_cookie = "\0";
    }
    else if ((hdr.http_status >= 200) && (hdr.http_status <= 299)) {
        if (hdr.http_status == gxsHTTP_STATUS_NO_CONTENT) {
            hdr.no_cache = 1;
            hdr.length = 0;
        }
    }
    else if ((hdr.http_status >= 500) && (hdr.http_status <= 599)) {
        // Proxy error
    }
    else {
        hdr.not_found = 1;
    }

    // In HTTP/1.1 connections are assumed to be persistent
    // unless otherwise notified.
    if (hdr.http_version >= 1.1F)
        hdr.keep_alive = 1;
    else
        hdr.keep_alive = 0;

    // Get the rest of the header parameters
    offset = dup_header.IFind("Server:");
    if(offset != -1) {
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.current_server = status;
    }
    offset = dup_header.IFind("Location:");
    if(offset != -1) {
        // The Location response-header field defines the exact location of
        // the resource that was identified by the Request-URI. For 3xx
        // responses, the location must indicate the server's preferred URL
        // for automatic redirection to the resource. Only one absolute URL is
        // allowed.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.location = status;
    }
    offset = dup_header.IFind("Last-Modified:");
    if(offset != -1) {
        // The Last-Modified entity-header field indicates the date and time
        // at which the sender believes the resource was last modified.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.http_last_modified = status;
    }
    offset = dup_header.IFind("Date:");
    if(offset != -1) {
        // The Date general-header field represents the date
        // and time at which the message was originated.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.date = status;
    }
    offset = dup_header.IFind("Expires:");
    if(offset != -1) {
        // The Expires entity-header field gives the date/time after which
        // the entity should be considered stale. This allows information
        // providers to suggest the volatility of the resource, or a date
        // after which the information may no longer be valid. Applications
        // must not cache this entity beyond the date given.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.http_expires = status;
    }
    offset = dup_header.IFind("ETag:");
    if(offset != -1) {
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.etag = status;
    }
    offset = dup_header.IFind("Content-Encoding:");
    if(offset != -1) {
        // The Content-Encoding entity-header field is used as a modifier
        // to the media-type. When present, its value indicates what additional
        // content coding has been applied to the resource, and thus what
        // decoding mechanism must be applied in order to obtain the media-type
        // referenced by the Content-Type header field. The Content-Encoding is
        // primarily used to allow a document to be compressed without
        // losing the identity of its underlying media type.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.content_encoding = status;
    }
    offset = dup_header.IFind("WWW-Authenticate:");
    if(offset != -1) {
        // If a request is authenticated and a realm specified, the same
        // credentials should be valid for all other requests within this
        // realm.
        if(sscanf(dup_header.c_str()+offset, "%*[^:]: %s %[^\r\n]",
                status, status2) == 2) {
            hdr.authentication_scheme = status;
            hdr.realm = status2;
        }
    }
    offset = dup_header.IFind("Keep-Alive:");
    if((hdr.http_version == 1.0F) && (offset != -1)) {
        if(sscanf(dup_header.c_str()+offset, "%*[^:]: timeout=%d, max=%d",
                &hdr.timeout, &hdr.max_conns) == 2) {
            hdr.keep_alive = 1;
        }
        else if(sscanf(dup_header.c_str()+offset, "%*[^:]: max=%d, timeout=%d",
                &hdr.max_conns, &hdr.timeout) == 2) {
            hdr.keep_alive = 1;
        }
    }
    offset = dup_header.IFind("Connection:");
    if(offset != -1) {
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^,\r\n],%[^,\r\n]",
                status, status2);
        sbuf = status;
        offset = sbuf.IFind("keep-alive");
        if(offset != -1) hdr.keep_alive = 1;
        offset = sbuf.IFind("persist");
        if(offset != -1) hdr.keep_alive = 1;
        offset = sbuf.IFind("close");
        if(offset != -1) hdr.keep_alive = 0;

        sbuf = status2;
        offset = sbuf.IFind("keep-alive");
        if(offset != -1) hdr.keep_alive = 1;
        offset = sbuf.IFind("persist");
        if(offset != -1) hdr.keep_alive = 1;
        offset = sbuf.IFind("close");
        if(offset != -1) hdr.keep_alive = 0;
    }
    offset = dup_header.IFind("Content-Type:");
    if(offset != -1) {
        // The Content-Type entity-header field indicates the media type
        // of the Entity-Body sent to the recipient or, in the case of
        // the HEAD method, the media type that would have been sent had
        // the request been a GET.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^;\r\n]", status);
        char ext[256];
        sscanf(status, "%*[^/]/%[^;]", ext);
        hdr.file_extension = ".";
        hdr.file_extension += ext;

        hdr.content_type = hdr.mime_type = status;

#if defined(__DOS__) || defined(__WIN32__)
    if(hdr.mime_type == "audio/x-wav")
      hdr.file_extension = ".wav";
    else if(hdr.mime_type == "image/x-ms-bmp")
      hdr.file_extension = ".bmp";
    else if(hdr.mime_type == "application/x-msvideo")
      hdr.file_extension = ".avi";
#endif
    }
    offset = dup_header.IFind("Content-Length:");
    if(offset != -1) {
        // The Content-Length entity-header field
        // indicates the size of the Entity-Body.
        offset += strlen("Content-Length:");
        char *src = (char *)(dup_header.c_str()+offset);
        while(*src == ' ') src++;
        atoibuf = src;
        hdr.length = atoibuf.Atol();
    }

    offset = dup_header.IFind("Pragma:");
    if(offset != -1) {
        // The Pragma general-header field is used to include implementation-
        // specific directives that may apply to any recipient along the
        // request/response chain. All pragma directives specify optional
        // behavior from the viewpoint of the protocol; however, some systems
        // may require that behavior be consistent with the directives.
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.pragma = status;
        offset = hdr.pragma.IFind("no-cache");
        if(offset != -1) hdr.no_cache = 1;
    }

    offset = dup_header.IFind("Cache-Control:");
    if(offset != -1) {
        sscanf(dup_header.c_str()+offset, "%*[^:]: %[^\r\n]", status);
        hdr.cache_control = status;
        offset = hdr.cache_control.IFind("no-cache");
        if(offset != -1) hdr.no_cache = 1;
    }

    offset = dup_header.IFind("Accept-Ranges:");
    if(offset != -1) {
        sscanf(dup_header.c_str()+offset,"%*[^:]: %s", status);
        sbuf = status;
        if(CaseICmp(sbuf, "bytes") == 0) hdr.accept_ranges = 1;
    }

    offset = 0;
    sbuf = header;
    while(recv_loop) { // Parse all the cookies
        offset = sbuf.IFind("Set-Cookie:", offset);
        if((offset != -1) && (hdr.use_cookies)) {
            if(sscanf(dup_header.c_str()+offset, "%*[^:]: %[^=]=%[^;\r\n]; %[^\r\n]",
                    status, status2, rest) >= 2) {
                gxsNetscapeCookie citem;
                //citem.host = u.host;
                citem.name = status;
                citem.value = status2;
                citem.secure = 0;

                ibuf = rest;
                index = ibuf.IFind("Expires");
                if(index != -1) {
                    ibuf.DeleteAt(0, index);
                    ibuf.DeleteBeforeIncluding("=");
                    ibuf.DeleteAfterIncluding(";");
                    citem.expires = ibuf;
                }
                ibuf = rest;
                index = ibuf.IFind("Domain");
                if(index != -1) {
                    ibuf.DeleteAt(0, index);
                    ibuf.DeleteBeforeIncluding("=");
                    ibuf.DeleteAfterIncluding(";");
                    citem.domain = ibuf;
                }
                ibuf = rest;
                index = ibuf.IFind("Path");
                if(index != -1) {
                    ibuf.DeleteAt(0, index);
                    ibuf.DeleteBeforeIncluding("=");
                    ibuf.DeleteAfterIncluding(";");
                    citem.path = ibuf;
                }
                ibuf = rest;
                index = ibuf.IFind("Secure");
                if(index != -1) {
                    citem.secure = 1;
                }
                hdr.netscape_cookies.Insert(citem);
            }
        }
        if(offset == -1) break;
        offset++;
    }

    return 0;
}

using namespace std;
void PrintHTTPHeader(const gxsHTTPHeader &hdr)
{
    cout << "\n" << flush;
    cout << "<------ Document Header ------>" << "\n" << flush;
    cout << hdr.http_header.c_str();
    cout << "<----------------------------->" << "\n" << flush;
    cout << "\n" << flush;
    cout << "Press Enter to continue..." << "\n" << flush;

    cout << "Processing the header information..."    << "\n" << flush;
    cout << gxsHTTPStatusCodeMessage(hdr.http_status) << "\n" << flush;

    cout.setf(ios::showpoint | ios::fixed);
    cout.precision(1);
    cout << "HTTP version: " << hdr.http_version << "\n" << flush;
    cout << "Document status code: " << hdr.http_status << "\n"<< flush;

    if(hdr.current_server.length() > 0){
        cout << "Current Server: " << hdr.current_server.c_str() << "\n" << flush;
    }
    if(hdr.location.length() > 0){
        cout << "Location: " << hdr.location.c_str() << "\n" << flush;
    }
    if(hdr.http_last_modified.length() > 0){
        cout << "Date Document Last Modified: " << hdr.http_last_modified.c_str() << "\n" << flush;
    }
    if(hdr.date.length() > 0) {
        cout << "Date: " << hdr.date.c_str() << "\n" << flush;
    }
    if(hdr.http_expires.length() > 0) {
        cout << "Expires: " << hdr.http_expires.c_str() << "\n"
                << flush;
    }
    if(hdr.etag.length() > 0) {
        cout << "Entity tag: " << hdr.etag.c_str() << "\n" << flush;
    }
    if(hdr.authentication_needed) {
        cout << "Authentication required" << "\n" << flush;
    }
    if(hdr.authentication_scheme.length() > 0) {
        cout << "Authentication scheme: "
                << hdr.authentication_scheme.c_str() << "\n" << flush;
    }
    if(hdr.realm.length() > 0) {
        cout << "Authentication realm: " << hdr.realm.c_str() << "\n"
                << flush;
    }
    if(hdr.auth_cookie.length() > 0) {
        cout << "Authentication cookie: " << hdr.auth_cookie.c_str()
                << "\n" << flush;
    }
    if(hdr.content_encoding.length() > 0) {
        cout << "Content encoding: " << hdr.content_encoding.c_str()
                << "\n" << flush;
    }
    if(hdr.pragma.length() > 0) {
        cout << "Pragma: " << hdr.pragma.c_str() << "\n" << flush;
    }
    if(hdr.cache_control.length() > 0) {
        cout << "Cache control: " << hdr.cache_control.c_str() << "\n"
                << flush;
    }

    if(hdr.file_extension.length() > 0) {
        cout << "File extension: " << hdr.file_extension.c_str() << "\n"
                << flush;
    }
    if(hdr.length > -1) {
        cout << "Document length: " << hdr.length << "\n" << flush;
    }
    if(hdr.not_found) {
        cout << "The requested document was not found" << "\n"
                << flush;
    }
    if(!hdr.no_cache) {
        cout << "Using cached copy of the requested document" << "\n"
                << flush;
    }
    if(hdr.accept_ranges) {
        cout << "Accepting ranges" << "\n" << flush;
    }
    if(hdr.timeout > -1) {
        cout << "Timeout: " << hdr.timeout << "\n" << flush;
    }
    if(hdr.max_conns > -1) {
        cout << "Max connects: " << hdr.max_conns << "\n" << flush;
    }
    if(!hdr.keep_alive) {
        cout << "The server has closed this connection" << "\n"
                << flush;
    }

    gxListNode<gxsNetscapeCookie> *netscape_cookies = \
hdr.netscape_cookies.GetHead();
    if(netscape_cookies) {
        cout << "\n" << flush;
        cout << "Cookie information. Press Enter to continue..."
                << "\n" << flush;
        cin.get();

        while(netscape_cookies) {
            gxsNetscapeCookie citem(netscape_cookies->data);

            cout << "Hostname: " << citem.host.c_str() << "\n"
                    << flush;
            cout << "Name: " << citem.name.c_str() << "\n" << flush;
            cout << "Value: " << citem.value.c_str() << "\n" << flush;
            if(citem.expires.length() > 0) {
                cout << "Expires: " << citem.expires.c_str() << "\n"
                        << flush;
            }
            if(citem.domain.length() > 0) {
                cout << "Domain: " << citem.domain.c_str() << "\n"
                        << flush;
            }
            if(citem.path.length() > 0) {
                cout << "Path: " << citem.path.c_str() << "\n" << flush;
            }
            if(citem.secure) {
                cout << "This is a secure cookie" << "\n" << flush;
            }

            netscape_cookies = netscape_cookies->next;

            if(netscape_cookies) {
                cout << "\n" << flush;
                cout << "Cookie information. Press Enter to continue..."
                        << "\n" << flush;
                cin.get();
            }
        }
    }
}
