//
//  FHHostPool.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHostPool.h"
#import "FHHostEntry.h"

volatile FHHostPool*    __fh_singletonPool = nil;
volatile int            __fh_singletonLock = 0;

#define kHostPoolClearThreshold     70
#define kHostPoolCleanupTimer       30.0

@implementation FHHostPool

#pragma mark -
#pragma mark Initialization

- (id) init
{
    if( self = [super init] )
    {
        lock = [[NSLock alloc] init];
        hosts = [[NSMutableDictionary alloc] init];
        timer = [[NSTimer scheduledTimerWithTimeInterval:kHostPoolCleanupTimer target:self selector:@selector( timerFired: ) userInfo:nil repeats:YES] retain];
    }
    return self;
}

- (void) dealloc
{
    [timer invalidate];
    timer = nil;
    FHRELEASE( hosts );
    FHRELEASE( lock );
    [super dealloc];
}

+ (FHHostPool*) sharedHostPool
{
    if( OSAtomicCompareAndSwapInt( 0, 1, &__fh_singletonLock ) == NO )
    {
        while( __fh_singletonPool == nil );
        return ( FHHostPool* )__fh_singletonPool;
    }
    __fh_singletonPool = [[FHHostPool alloc] init];
    return ( FHHostPool* )__fh_singletonPool;
}

#pragma mark -
#pragma mark Accessors

- (FHHostEntry*) hostForURL:(NSURL*)url
{
    NSString* hostName = [url host];
    if( hostName == nil )
        return nil;
    NSInteger port = 80;
    if( [url port] != nil )
        port = [[url port] integerValue];
    NSString* hostKey = [NSString stringWithFormat:@"%@:%d", hostName, port];
    
    [lock lock];
    FHHostEntry* entry = [[hosts objectForKey:hostKey] retain];
    if( entry == nil )
    {
        FHPROBE( FEMTOHTTP_HOSTPOOL_ADDED, CSTRING( hostName ), port );
        
        // Periodically clear all the hosts
        if( [hosts count] >= kHostPoolClearThreshold )
            [hosts removeAllObjects];
        
        entry = [[FHHostEntry alloc] initWithHostName:hostName andPort:port];
        [hosts setObject:entry forKey:hostKey];
    }
    [lock unlock];
    return [entry autorelease];
}

- (void) removeAllHosts
{
    [lock lock];
    [hosts removeAllObjects];
    [lock unlock];
}

#pragma mark -
#pragma mark Management

- (void) timerFired:(id)state
{
    [lock lock];
    NSArray* entries = [[hosts allValues] copy];
    [lock unlock];
    for( FHHostEntry* entry in entries )
        [entry closeDeadConnections];
}

@end
