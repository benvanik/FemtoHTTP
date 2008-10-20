//
//  FHHostEntry.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHostEntry.h"
#import "FHTCPSocket.h"
#import <netdb.h>

@implementation FHHostEntry

@synthesize hostName;
@synthesize port;
@synthesize supportsPooling;
@synthesize maximumConnections;

@synthesize openedSockets;
@synthesize idleSockets;

#pragma mark -
#pragma mark Initialization

- (id) initWithHostName:(NSString*)_hostName andPort:(NSInteger)_port
{
    if( self = [super init] )
    {
        lock = [[NSCondition alloc] init];
        
        hostName = [_hostName retain];
        port = _port;
        supportsPooling = YES;
        maximumConnections = FH_DEFAULT_MAXIMUM_CONNECTIONS;
        
        openedSockets = [[NSMutableArray alloc] init];
        idleSockets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [self closeAllConnections];
    FHRELEASE( openedSockets );
    FHRELEASE( idleSockets );
    FHRELEASE( hostName );
    FHRELEASE( lock );
    [super dealloc];
}

#pragma mark -
#pragma mark Connection Control

- (FHTCPSocket*) openSocket:(BOOL)allowReuse errorCode:(FHErrorCode*)outErrorCode wasReused:(BOOL*)outWasReused
{
    if( outErrorCode != NULL )
        *outErrorCode = FHErrorOK;
    if( outWasReused != NULL )
        *outWasReused = NO;
    
    FHTCPSocket* socket = nil;
    BOOL needsOpen = NO;
    
    [lock lock];
    while( YES )
    {
        // Try to reuse an existing idle connection if allowed
        if( allowReuse == YES )
        {
            if( [idleSockets count] > 0 )
            {
                // TODO: investigate whether or not we should be taking the oldest (head) instead of the newest (tail)
                socket = [[idleSockets lastObject] retain];
                if( socket != nil )
                {
                    [idleSockets removeLastObject];
                    
                    // NOTE: do this outside of the lock
                    [lock unlock];
                    if( [socket queryStatus] != FHErrorOK )
                    {
                        // Socket is closed/etc - need a new one!
                        FHPROBE( FEMTOHTTP_HOST_KILLED_IDLE, socket->identifier, CSTRING( hostName ), port );
                        [openedSockets removeObject:socket];
                        FHRELEASE( socket );
                    }
                    else if( outWasReused != NULL )
                        *outWasReused = YES;
                    [lock lock];
                }
            }
            if( socket != nil )
                break;
        }
        
        // Try to open a new connection, if under the limit
        if( [openedSockets count] < maximumConnections )
        {
            // Allowed to open
            socket = [[FHTCPSocket alloc] initWithHostName:hostName andPort:port];
            [openedSockets addObject:socket];
            needsOpen = YES;
            break;
        }
        
        // Wait until a connection is closed/etc
        FHPROBE( FEMTOHTTP_HOST_PRE_WAIT_FOR_SOCKET, CSTRING( hostName ), port );
        [lock wait];
        FHPROBE( FEMTOHTTP_HOST_WAIT_FOR_SOCKET, CSTRING( hostName ), port );
    }
    [lock unlock];
    
    // Open the socket if needed
    if( needsOpen == YES )
    {
        FHErrorCode errorCode = [socket open];
        if( outErrorCode != NULL )
            *outErrorCode = errorCode;
        if( errorCode != FHErrorOK )
        {
            // Failed - remove from list
            FHPROBE( FEMTOHTTP_HOST_NEW_FAILED, socket->identifier, CSTRING( hostName ), port );
            [lock lock];
            [openedSockets removeObject:socket];
            [lock signal];
            [lock unlock];
            FHRELEASE( socket );
            return nil;
        }
        else
        {
            FHPROBE( FEMTOHTTP_HOST_NEW_CONNECTION, socket->identifier, CSTRING( hostName ), port );
        }
    }

    FHPROBE( FEMTOHTTP_HOST_OBTAIN_CONNECTION, socket->identifier, CSTRING( hostName ), port, !needsOpen );
 
#if defined( FH_DEBUG_OUTPUT )
    if( ( outWasReused != NULL ) && ( *outWasReused == YES ) )
        FHLOG( @"reusing connection to %@:%d", hostName, port );
    else
        FHLOG( @"new connection to %@:%d", hostName, port );
#endif
    
    return [socket autorelease];
}

- (void) closeSocket:(FHTCPSocket*)socket closeConnection:(BOOL)closeConnection
{
    FHPROBE( FEMTOHTTP_HOST_CLOSE_CONNECTION, socket->identifier, CSTRING( hostName ), port, closeConnection, [socket fd] == -1 );
    
    if( closeConnection == YES )
    {
        [lock lock];
        [openedSockets removeObject:socket];
        [lock signal];
        [lock unlock];
        [socket close];
    }
    else
    {
        [socket reset];
        [lock lock];
        [idleSockets addObject:socket];
        [lock signal];
        [lock unlock];
    }
}

- (void) closeAllConnections
{
    [lock lock];
    NSArray* socketsToKill = [openedSockets copy];
    [lock unlock];
    for( FHTCPSocket* socket in socketsToKill )
        [self closeSocket:socket closeConnection:YES];
    FHRELEASE( socketsToKill );
    [lock lock];
    [lock broadcast];
    [lock unlock];
}

@end
