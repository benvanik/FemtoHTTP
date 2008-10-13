//
//  FHTCPSocket.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHTCPSocket.h"
#import <unistd.h>
#import <errno.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

@interface FHTCPSocket (Implementation)
- (FHErrorCode) readChunk:(NSInteger*)outBytesRead;
- (FHErrorCode) writeChunk:(const void*)bytes length:(NSInteger)length bytesWritten:(NSInteger*)outBytesWritten;
@end

@implementation FHTCPSocket

@synthesize hostName;
@synthesize port;
@synthesize timeout;
@synthesize singleUse;
@synthesize fd;
@synthesize errorCode;

#pragma mark -
#pragma mark Initialization

- (id) initWithHostName:(NSString*)_hostName andPort:(NSInteger)_port
{
    if( self = [super init] )
    {
        hostName = [_hostName retain];
        port = _port;
        timeout = FH_DEFAULT_TIMEOUT;
        singleUse = NO;
        fd = -1;
        errorCode = FHErrorOK;
        
        buffer = [[NSMutableData alloc] initWithCapacity:2048];
    }
    return self;
}

- (void) dealloc
{
    [self close];
    FHRELEASE( hostName );
    [super dealloc];
}

#pragma mark -
#pragma mark Host Lookup

+ (FHErrorCode) lookupHostName:(NSString*)hostName hostent:(struct hostent**)outHostent
{
    // TODO: convert to getaddrinfo
    // http://people.redhat.com/drepper/userapi-ipv6.html
    // NOTE: getaddrinfo may be slow on the iPhone if IPv6 enabled, so don't use it???
    struct hostent* host = gethostbyname( [hostName cStringUsingEncoding:NSASCIIStringEncoding] );
    if( host == NULL )
    {
        *outHostent = NULL;
        FHErrorCode errorCode = FHErrorSocketHostNotFound;
        switch( h_errno )
        {
            case HOST_NOT_FOUND:
                errorCode = FHErrorSocketHostNotFound;
                break;
            case NO_ADDRESS:
                errorCode = FHErrorSocketHostNotFound;
                break;
            case NO_RECOVERY:
                errorCode = FHErrorSocketHostNotFound;
                break;
            case TRY_AGAIN:
                // TODO: retry?
                errorCode = FHErrorSocketHostNotFound;
                break;
        }
        FHLOGERROR( errorCode, @"Unable to lookup host %@", hostName );
        return errorCode;
    }
    *outHostent = host;
    return FHErrorOK;
}

#pragma mark -
#pragma mark Control

- (FHErrorCode) open
{
    struct hostent* host;
    errorCode = [FHTCPSocket lookupHostName:hostName hostent:&host];
    if( errorCode != FHErrorOK )
        return errorCode;
    
    return [self openWithHostent:host];
}

- (FHErrorCode) openWithHostent:(struct hostent*)host
{
    // NOTE: this should work with IPv6, but is untested
    struct sockaddr_in addr;
    memset( &addr, 0, sizeof( struct sockaddr_in ) );
    addr.sin_len = sizeof( struct sockaddr_in );
    addr.sin_family = host->h_addrtype;
    addr.sin_port = htons( port );
    memcpy( &addr.sin_addr.s_addr, host->h_addr, host->h_length );

    fd = socket( addr.sin_family, SOCK_STREAM, IPPROTO_TCP );
    if( fd < 0 )
    {
        switch( errno )
        {
            default:
                errorCode = FHErrorInternalUnknown;
                break;
            case EAFNOSUPPORT:      // The implementation does not support the specified address family. 
            case EPROTONOSUPPORT:   // The protocol is not supported by the address family, or the protocol is not supported by the implementation.
            case EPROTOTYPE:        // The socket type is not supported by the protocol.
                errorCode = FHErrorInternalUnsupported;
                break;
            case EACCES:            // The process does not have appropriate privileges.
                errorCode = FHErrorInternalAccessDenied;
                break;
            case EMFILE:            // No more file descriptors are available for this process. 
            case ENFILE:            // No more file descriptors are available for the system. 
            case ENOBUFS:           // Insufficient resources were available in the system to perform the operation.
            case ENOMEM:            // Insufficient memory was available to fulfill the request.
                errorCode = FHErrorInternalOutOfMemory;
                break;
        }
        FHLOGERROR( errorCode, @"Unable to create socket to host %@:%d", hostName, port );
        return errorCode;
    }
    
    // Keep-Alive enabled
    int optval = ( singleUse == NO ) ? 1 : 0;
    setsockopt( fd, SOL_SOCKET, SO_KEEPALIVE, &optval, sizeof( int ) );
    
    // Linger enabled for 5s
    // TODO: see if we want lingering
//    struct linger lingerval;
//    lingerval.l_onoff = 1;
//    lingerval.l_linger = 5;
//    setsockopt( fd, SOL_SOCKET, SO_LINGER, &lingerval, sizeof( struct linger ) );

    optval = timeout;
    setsockopt( fd, SOL_SOCKET, SO_RCVTIMEO, &optval, sizeof( int ) );
    setsockopt( fd, SOL_SOCKET, SO_SNDTIMEO, &optval, sizeof( int ) );
    
    int connectResult = connect( fd, ( struct sockaddr* )&addr, sizeof( struct sockaddr ) );
    if( connectResult != 0 )
    {
        switch( errno )
        {
            default:
                errorCode = FHErrorInternalUnknown;
                break;
            case EADDRNOTAVAIL:     // The specified address is not available from the local machine.
            case EAFNOSUPPORT:      // The specified address is not a valid address for the address family of the specified socket.
            case EINVAL:            // The address_len argument is not a valid length for the address family; or invalid address family in the sockaddr structure.
            case EPROTOTYPE:        // The specified address has a different type than the socket bound to the specified peer address.
            case ENOTSOCK:          // The socket argument does not refer to a socket.
            case EBADF:             // The socket argument is not a valid file descriptor.
                errorCode = FHErrorInternalInvalidArguments;
                break;
            case EALREADY:          // A connection request is already in progress for the specified socket.
            case EISCONN:           // The specified socket is connection-mode and is already connected.
            case EADDRINUSE:        // Attempt to establish a connection that uses addresses that are already in use.
                errorCode = FHErrorInternalInvalidState;
                break;                
            case ENETDOWN:          // The local network interface used to reach the destination is down.
            case ENETUNREACH:       // No route to the network is present.
            case EHOSTUNREACH:      // The destination host cannot be reached (probably because the host is down or a remote router cannot reach it).
                errorCode = FHErrorSocketNetworkDown;
                break;
            case ECONNREFUSED:      // The target address was not listening for connections or refused the connection request.
            case ECONNRESET:        // Remote host reset the connection request.
                errorCode = FHErrorSocketHostUnreachable;
                break;
            case ETIMEDOUT:         // The attempt to connect timed out before a connection was made.
                errorCode = FHErrorSocketTimeout;
                break;
            case EACCES:            // Search permission is denied for a component of the path prefix; or write access to the named socket is denied.
                errorCode = FHErrorInternalAccessDenied;
                break;
            case ENOBUFS:           // No buffer space is available. 
                errorCode = FHErrorInternalOutOfMemory;
                break;
            // Shouldn't get these:
            case EOPNOTSUPP:        // The socket is listening and cannot be connected.
            case EINPROGRESS:       // O_NONBLOCK is set for the file descriptor for the socket and the connection cannot be immediately established; the connection shall be established asynchronously.
            case EINTR:             // The attempt to establish a connection was interrupted by delivery of a signal that was caught; the connection shall be established asynchronously.
                errorCode = FHErrorInternalUnknown;
                break;
        }
        
        [self close];
        FHLOGERROR( errorCode, @"Unable to connect socket to host %@:%d", hostName, port );
        return errorCode;
    }
    
    errorCode = FHErrorOK;
    return errorCode;
}

- (FHErrorCode) queryStatus
{
    if( fd == -1 )
    {
        errorCode = FHErrorSocketDisconnected;
        return FHErrorSocketDisconnected;
    }
    
    if( fd == -1 )
    {
        errorCode = FHErrorSocketDisconnected;
        return FHErrorSocketDisconnected;
    }
    
    errorCode = FHErrorOK;
    return errorCode;
}

- (FHErrorCode) waitUntilDataPresent
{
    struct timeval tm;
    fd_set fds;
    tm.tv_sec = timeout;
    tm.tv_usec = 0;
    FD_ZERO( &fds );
    FD_SET( fd, &fds );
    NSInteger n = select( fd + 1, &fds, NULL, NULL, &tm );
    if( n <= 0 )
    {
        [self close];
        errorCode = FHErrorSocketDisconnected;
        return errorCode;
    }
    else
    {
        errorCode = FHErrorOK;
        return errorCode;
    }
}

- (void) reset
{
    errorCode = FHErrorOK;
    [buffer setLength:0];
}

- (void) close
{
    if( fd != -1 )
    {
        close( fd );
        fd = -1;
    }
    FHRELEASE( buffer );
}

#pragma mark -
#pragma mark Socket IO

- (FHErrorCode) readChunk:(NSInteger*)outBytesRead
{
    if( outBytesRead != NULL )
        *outBytesRead = 0;
    if( fd == -1 )
    {
        errorCode = FHErrorSocketDisconnected;
        return errorCode;
    }
    
    char bytes[ 1024 ];
    NSInteger bytesRead = recv( fd, bytes, sizeof( bytes ), 0 );
    if( outBytesRead != NULL )
        *outBytesRead = bytesRead;
    if( bytesRead == 0 )
    {
        errorCode = FHErrorOK;
        return errorCode;
    }
    else if( bytesRead > 0 )
    {
        [buffer appendBytes:bytes length:bytesRead];
        errorCode = FHErrorOK;
        return errorCode;
    }
    else
    {
        switch( errno )
        {
            default:
                errorCode = FHErrorInternalUnknown;
                break;
            case EBADF:         // The socket argument is not a valid file descriptor.
            case EINVAL:        // The MSG_OOB flag is set and no out-of-band data is available.
            case ENOTSOCK:      // The socket argument does not refer to a socket.
            case EOPNOTSUPP:    // The specified flags are not supported for this socket type or protocol.
                errorCode = FHErrorInternalInvalidArguments;
                break;
            case EINTR:         // The recv() function was interrupted by a signal that was caught, before any data was available.
            case EAGAIN:        // The socket's file descriptor is marked O_NONBLOCK and no data is waiting to be received; or MSG_OOB is set and no out-of-band data is available and either the socket's file descriptor is marked O_NONBLOCK or the socket does not support blocking to await out-of-band data.
                // May not be real errors
                errorCode = FHErrorInternalInvalidState;
                break;
            case ECONNRESET:    // A connection was forcibly closed by a peer.
            case ENOTCONN:      // A receive is attempted on a connection-mode socket that is not connected.
            case EIO:           // An I/O error occurred while reading from or writing to the file system.
                errorCode = FHErrorSocketDisconnected;
                [self close];
                break;
            case ETIMEDOUT:     // The connection timed out during connection establishment, or due to a transmission timeout on active connection.
                errorCode = FHErrorSocketTimeout;
                [self close];
                break;
            case ENOBUFS:       // Insufficient resources were available in the system to perform the operation.
            case ENOMEM:        // Insufficient memory was available to fulfill the request.
                errorCode = FHErrorInternalOutOfMemory;
                break;
        }
#if defined( FH_DEBUG_OUTPUT )
        FHLOGERROR( errorCode, @"Unable to read from socket %@:%d", hostName, port );
#endif
        return errorCode;
    }
}

- (FHErrorCode) writeChunk:(const void*)bytes length:(NSInteger)length bytesWritten:(NSInteger*)outBytesWritten
{
    if( outBytesWritten != NULL )
        *outBytesWritten = 0;
    if( fd == -1 )
    {
        errorCode = FHErrorSocketDisconnected;
        return errorCode;
    }
    
    NSInteger bytesWritten = write( fd, bytes, length );
    if( outBytesWritten != NULL )
        *outBytesWritten = bytesWritten;
    if( bytesWritten == length )
    {
        errorCode = FHErrorOK;
        return errorCode;
    }
    else
    {
        switch( errno )
        {
            default:
                errorCode = FHErrorInternalUnknown;
                break;
            case EBADF:         // The socket argument is not a valid file descriptor.
            case EINVAL:        // The MSG_OOB flag is set and no out-of-band data is available.
            case ENOTSOCK:      // The socket argument does not refer to a socket.
            case EOPNOTSUPP:    // The specified flags are not supported for this socket type or protocol.
                errorCode = FHErrorInternalInvalidArguments;
                break;
            case EINTR:         // The recv() function was interrupted by a signal that was caught, before any data was available.
            case EAGAIN:        // The socket's file descriptor is marked O_NONBLOCK and no data is waiting to be received; or MSG_OOB is set and no out-of-band data is available and either the socket's file descriptor is marked O_NONBLOCK or the socket does not support blocking to await out-of-band data.
                // May not be real errors
                errorCode = FHErrorInternalInvalidState;
                break;
            case ECONNRESET:    // A connection was forcibly closed by a peer.
            case ENOTCONN:      // A receive is attempted on a connection-mode socket that is not connected.
            case EIO:           // An I/O error occurred while reading from or writing to the file system.
            case EPIPE:         // The socket is shut down for writing, or the socket is connection-mode and is no longer connected. In the latter case, and if the socket is of type SOCK_STREAM, the SIGPIPE signal is generated to the calling thread.
                errorCode = FHErrorSocketDisconnected;
                [self close];
                break;
            case ENETDOWN:      // The local network interface used to reach the destination is down.
            case ENETUNREACH:   // No route to the network is present.
                errorCode = FHErrorSocketNetworkDown;
                [self close];
                break;
            case EACCES:        // The calling process does not have the appropriate privileges.
                errorCode = FHErrorInternalAccessDenied;
                break;
            case EMSGSIZE:      // The message is too large to be sent all at once, as the socket requires.
            case ENOBUFS:       // Insufficient resources were available in the system to perform the operation.
                errorCode = FHErrorInternalOutOfMemory;
                break;
        }
#if defined( FH_DEBUG_OUTPUT )
        FHLOGERROR( errorCode, @"Unable to write %d bytes to socket %@:%d", length, hostName, port );
#endif
        return errorCode;
    }
}

#pragma mark -
#pragma mark Reading

- (FHErrorCode) skipBytes:(NSInteger)length
{
    while( [buffer length] < length )
    {
        NSInteger bytesRead;
        if( [self readChunk:&bytesRead] != FHErrorOK )
        {
            // Error reading - abort - error code is already set
            return errorCode;
        }
    }
    
    // Shrink buffer
    memmove( [buffer mutableBytes], [buffer mutableBytes] + length, [buffer length] - length );
    [buffer setLength:[buffer length] - length];
    
    errorCode = FHErrorOK;
    return errorCode;
}

- (NSString*) readLine
{
    while( YES )
    {
        char* start = [buffer mutableBytes];
        char* end = strchr( start, '\n' );
        NSInteger length = end - start + 1;
        if( ( end != NULL ) && ( length <= [buffer length] ) )
        {
            NSInteger stringLength = end - start;
            
            // May be \r\n, check for it
            if( ( end > start ) && ( end[ -1 ] == '\r' ) )
                stringLength--;
            
            // TODO: figure out what encoding to use
            NSString* string = [[NSString alloc] initWithBytes:start length:stringLength encoding:NSUTF8StringEncoding];

            // Shrink buffer
            memmove( [buffer mutableBytes], [buffer mutableBytes] + length, [buffer length] - length );
            [buffer setLength:[buffer length] - length];
            
            errorCode = FHErrorOK;
            return [string autorelease];
        }
        
        NSInteger bytesRead;
        if( [self readChunk:&bytesRead] != FHErrorOK )
        {
            // Error reading - abort
            return nil;
        }
    }
}

- (NSData*) readData:(NSInteger)length
{
    void* bytes = malloc( length );
    NSInteger realLength = [self readBytes:bytes length:length];
    if( errorCode != FHErrorOK )
    {
        free( bytes );
        return nil;
    }
    return [NSData dataWithBytesNoCopy:bytes length:realLength freeWhenDone:YES];
}

- (NSInteger) readBytes:(void*)bytes length:(NSInteger)length
{
    while( [buffer length] < length )
    {
        NSInteger bytesRead;
        if( [self readChunk:&bytesRead] != FHErrorOK )
        {
            // Error reading - abort - error code is already set
            return -1;
        }
    }
    
    // Copy to dest
    memcpy( bytes, [buffer bytes], length );
    
    // Shrink buffer
    memmove( [buffer mutableBytes], [buffer mutableBytes] + length, [buffer length] - length );
    [buffer setLength:[buffer length] - length];

    return length;
}

- (FHErrorCode) readIntoData:(NSMutableData*)data length:(NSInteger)length
{
    char bytes[ 1024 ];

    NSInteger remaining = length;
    while( remaining > 0 )
    {
        NSInteger bytesRead = [self readBytes:bytes length:MIN( remaining, sizeof( bytes ) )];
        if( bytesRead == -1 )
        {
            // Error reading - abort - error code is already set
            return errorCode;
        }
        else if( bytesRead > 0 )
        {
            [data appendBytes:bytes length:bytesRead];
            remaining -= bytesRead;
        }
    }
    
    errorCode = FHErrorOK;
    return errorCode;
}

#pragma mark -
#pragma mark Writing

- (FHErrorCode) writeNewLine
{
    static const char bytes[] = "\r\n";
    return [self writeBytes:&bytes length:2];
}

- (FHErrorCode) writeString:(NSString*)string
{
    NSInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    // NOTE: I'm doing this because the lifetime of the returned bytes is deterministic - if you do a cString the cached string is kept
    // in the NSString often until the string is released, which is a nice way to grow memory
    // TODO: make sure the above statement is true ;)
    char* bytes = malloc( length );
    NSInteger realLength;
    [string getBytes:bytes maxLength:length usedLength:( NSUInteger* )&realLength encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:NSMakeRange( 0, [string length] ) remainingRange:NULL];
    [self writeBytes:bytes length:realLength];
    free( bytes );
    return errorCode;
}

- (FHErrorCode) writeData:(NSData*)data
{
    return [self writeBytes:[data bytes] length:[data length]];
}

- (FHErrorCode) writeBytes:(const void*)bytes length:(NSInteger)length
{
    NSInteger bytesWritten;
    [self writeChunk:bytes length:length bytesWritten:&bytesWritten];
    return errorCode;
}

@end
