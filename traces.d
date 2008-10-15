#!/usr/bin/env dtrace -qs
/*
If trying to view data/headers, adjust strsize (default is 256)
#!/usr/bin/env dtrace -x strsize=4096 -qs
*/

/*
 *  traces.d
 *  FemtoHTTP
 *
 *  Created by Ben Vanik on 10/14/08.
 *  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
 *
 */
 
/* Global counters:
@count_chunks[ read/written ]
@count_bytes[ read/written ]
@avg_chunkSize[ read/written ]
*/

BEGIN
{
    printf( "Tracing... Hit Ctrl-C to end.\n" );
}






/*
@count_test[probefunc, probename] = count();

pre:
self->ts[probefunc] = timestamp;
post:
@func_time[probename] = sum( timestamp - self->ts[probefunc] );
*/


/* new host added to the pool
 * $0: (char*) host name
 * $1: (int) host port
 */
femtohttp$1:::hostpool-added {
}




/* new connection created
 * $0: (int) socket identifier
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::host-new-connection {
}

/* obtained a connection
 * $0: (int) socket identifier
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) isReused
 */
femtohttp$1:::host-new-connection {
}

/* killed a dead idle connection
 * $0: (int) socket identifier
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::host-killed-idle {
}

/* closed a connection - wasDead flag denotes whether it was closed because it failed or because it was no longer needed
 * $0: (int) socket identifier
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) allowReuse
 * $4: (int) wasDead
 */
femtohttp$1:::host-close-connection {
}

/* failed to open a new connection
 * $0: (int) socket identifier
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::host-new-failed {
}

/* had to wait for a host to become free
 * $0: (char*) host name
 * $1: (int) host port
 */
femtohttp$1:::host-pre-wait-for-socket {
}
/* had to wait for a host to become free
 * $0: (char*) host name
 * $1: (int) host port
 */
femtohttp$1:::host-wait-for-socket {
}





/* look up a host name
 * $0: (char*) name
 */
femtohttp$1:::socket-pre-hostname-lookup {
}
/* look up a host name
 * $0: (char*)name
 */
femtohttp$1:::socket-hostname-lookup {
}

/* a host name lookup failed
 * $0: (char*) host name
 * $1: (int) error
 */
femtohttp$1:::socket-hostname-lookup-failed {
}





/* opened/connected a socket
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-pre-open {
}
/* opened/connected a socket
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-open {
}

/* socket closed
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-close {
}

/* queried socket status
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-pre-querystatus {
}
/* queried socket status
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-querystatus {
}

/* waited until data present
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-pre-waituntildatapresent {
}
/* waited until data present
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-waituntildatapresent {
}

/* read a chunk of data
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 */
femtohttp$1:::socket-pre-readchunk {
}
/* read a chunk of data
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) lengthRead
 */
femtohttp$1:::socket-readchunk {
    @count_chunks["chunks read"] = count();
    @count_bytes["bytes read"] = sum( args[3] );
    @avg_chunkSize["avg chunk read size"] = avg( args[3] );
}

/* write a chunk of data
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) length
 */
femtohttp$1:::socket-pre-writechunk {
}
/* write a chunk of data
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) lengthWritten
 */
femtohttp$1:::socket-writechunk {
    @count_chunks["chunks written"] = count();
    @count_bytes["bytes written"] = sum( args[3] );
    @avg_chunkSize["avg chunk write size"] = avg( args[3] );
}



/* socket errors */

/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-open-failed {
}
/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-connect-failed {
}
/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-querystatus-failed {
}
/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-waituntildatapresent-failed {
}
/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-readchunk-failed {
}
/* 
 * $0: (int) socket id
 * $1: (char*) host name
 * $2: (int) host port
 * $3: (int) error code (errno, etc)
 */
femtohttp$1:::socket-writechunk-failed {
}




/* NOTE: assume all http- as being only usable on a single thread, so it's safe to store the url from
 * http-begin in thread state and pull it on subsequent calls */
self string url;
self int handlingUrl;
self int socketId;

/* http request begin
 * $0: (char*) url
 */
femtohttp$1:::http-begin {
    self->url = copyinstr( (user_addr_t)args[0] );
    self->handlingUrl = 1;
    
    printf( "== HTTP begin: %s\n", stringof( self->url ) );
}
/* http request end
 * no args
 */
femtohttp$1:::http-end /self->handlingUrl/ {
    printf( "== HTTP end: %s\n", stringof( self->url ) );
    
    self->url = NULL;
    self->handlingUrl = 0;
    self->socketId = 0;
}

/* http transaction obtained the given socket
 * $0: (int) socket id
 */
femtohttp$1:::http-using-socket /self->handlingUrl/ {
    self->socketId = args[0];
    printf( "   request for %s using socket id %d\n", stringof( self->url ), self->socketId );
}





/* needed to retry a socket (was idle and dead, so need to get another)
 * no args
 */
femtohttp$1:::http-socket-retry /self->handlingUrl/ {
}





/* wrote header
 * $0: (int) length
 */
femtohttp$1:::http-pre-header-write /self->handlingUrl/ {
}
/* wrote header
 * $0: (int) length
 */
femtohttp$1:::http-header-write /self->handlingUrl/ {
}
/* wrote header data (slow)
 * $0: (char*) headerData
 */
femtohttp$1:::http-header-write-data /self->handlingUrl/ {
}

/* wrote request content
 * $0: (int) length
 */
femtohttp$1:::http-pre-content-write /self->handlingUrl/ {
}
/* wrote request content
 * $0: (int) length
 */
femtohttp$1:::http-content-write /self->handlingUrl/ {
}
/* wrote request content data (slow)
 * $0: (char*) data as string
 */
femtohttp$1:::http-content-write-data /self->handlingUrl/ {
}

/* read header
 * no args
 */
femtohttp$1:::http-pre-header-read /self->handlingUrl/ {
}
/* read header
 * $0: ~length (off by a few bytes)
 */
femtohttp$1:::http-header-read /self->handlingUrl/ {
}
/* read header data (slow)
 * $0: (char*) headerData
 */
femtohttp$1:::http-header-read-data /self->handlingUrl/ {
    printf( "%s\n", copyinstr( (user_addr_t)args[0] ) );
}
/* read header status code
 * $0: (int) statusCode
 * $1: (char*) statusReason
 */
femtohttp$1:::http-header-status-code /self->handlingUrl/ {
}

/* content read - flag denotes whether it is a single read or a chunked read
 * $0: (int) isChunked
 */
femtohttp$1:::http-pre-content-read /self->handlingUrl/ {
}
/* content read
 * $0: (int) length
 */
femtohttp$1:::http-content-read /self->handlingUrl/ {
}
/* content read data (slow)
 * $0: (char*) data
 */
femtohttp$1:::http-content-read-data /self->handlingUrl/ {
}
/* content chunk read
 * no args
 */
femtohttp$1:::http-pre-content-chunk /self->handlingUrl/ {
}
/* content chunk read
 * $0: (int) chunkLength
 */
femtohttp$1:::http-content-chunk /self->handlingUrl/ {
}





/* got a redirect
 * $0: (int) statusCode
 * $1: (char*) targetUrl
 */
femtohttp$1:::http-redirect /self->handlingUrl/ {
}






/* response will automatically decompress content
 * no args
 */
femtohttp$1:::response-auto-decompress {
}
/* decompressed content from the server
 * $0: 
 */
femtohttp$1:::response-pre-decompress {
}
/* decompressed content from the server
 * $0: (int) preLength
 * $1: (int) postLength
 * $2: (int) succeeded
 */
femtohttp$1:::response-decompress {
}






END
{
    printf( "Tracing complete!\n" );
    
    printa( @count_chunks );
    printa( @count_bytes );
    printa( @avg_chunkSize );
}
