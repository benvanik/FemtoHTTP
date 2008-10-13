//
//  FHHostPool.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHostPool.h"
#import "FHHostEntry.h"

FHHostPool*     __fh_singletonPool = nil;
volatile int    __fh_singletonLock = 0;

@implementation FHHostPool

#pragma mark -
#pragma mark Initialization

- (id) init
{
    if( self = [super init] )
    {
        lock = [[NSLock alloc] init];
        hosts = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    FHRELEASE( hosts );
    FHRELEASE( lock );
    [super dealloc];
}

+ (FHHostPool*) sharedHostPool
{
    if( OSAtomicCompareAndSwapInt( 0, 1, &__fh_singletonLock ) == NO )
    {
        while( __fh_singletonPool == nil );
        return __fh_singletonPool;
    }
    __fh_singletonPool = [[FHHostPool alloc] init];
    return __fh_singletonPool;
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

@end
