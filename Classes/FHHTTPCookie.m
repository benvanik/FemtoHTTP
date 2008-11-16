//
//  FHHTTPCookie.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/13/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHTTPCookie.h"
#import "FHSharedObjects.h"

@implementation FHHTTPCookie

@synthesize name;
@synthesize value;
@synthesize expires;
@synthesize path;
@synthesize domain;
@synthesize isSecure;
@synthesize isHTTPOnly;

#pragma mark -
#pragma mark Initialization

- (id) init
{
    if( self = [super init] )
    {
        name = nil;
        value = nil;
        expires = nil;
        path = nil;
        domain = nil;
    }
    return self;
}

- (id) initWithName:(NSString*)_name andValue:(NSString*)_value
{
    // Calls above -init
    if( self = [self init] )
    {
        name = [_name retain];
        value = [_value retain];
    }
    return self;
}

- (id) initWithHTTPCookie:(NSString*)httpCookie
{
    // Calls above -init
    if( self = [self init] )
    {
        // Scan
        // name=newvalue; expires=date; path=/; domain=.example.org
        NSArray* pairs = [httpCookie componentsSeparatedByString:@";"];
        for( NSString* pair in pairs )
        {
            NSString* cleanPair = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSInteger equalsIndex = [cleanPair rangeOfString:@"="].location;
            NSString* leftSide;
            NSString* rightSide = nil;
            if( equalsIndex == NSNotFound )
                leftSide = cleanPair;
            else
            {
                leftSide = [cleanPair substringToIndex:equalsIndex];
                rightSide = [cleanPair substringFromIndex:equalsIndex + 1];
            }
            NSString* leftSideLower = [leftSide lowercaseString];
            if( [leftSideLower isEqualToString:@"expires"] == YES )
            {
                NSDateFormatter* dateFormatter = [FHSharedObjects dateFormatter];
                expires = [[dateFormatter dateFromString:[rightSide stringByReplacingOccurrencesOfString:@"-" withString:@" "]] retain];
            }
            else if( [leftSideLower isEqualToString:@"path"] == YES )
                path = [rightSide retain];
            else if( [leftSideLower isEqualToString:@"domain"] == YES )
                domain = [rightSide retain];
            else if( [leftSideLower isEqualToString:@"secure"] == YES )
                isSecure = YES;
            else if( [leftSideLower isEqualToString:@"httponly"] == YES )
                isHTTPOnly = YES;
            else
            {
                name = [leftSide retain];
                if( [rightSide length] != 0 )
                    value = [rightSide retain];
            }
        }
    }
    return self;
}

- (void) dealloc
{
    FHRELEASE( name );
    FHRELEASE( value );
    FHRELEASE( expires );
    FHRELEASE( path );
    FHRELEASE( domain );
    [super dealloc];
}

#pragma mark -
#pragma mark Allocation Helpers

+ (FHHTTPCookie*) cookieWithName:(NSString*)name andValue:(NSString*)value
{
    return [[[FHHTTPCookie alloc] initWithName:name andValue:value] autorelease];
}

+ (FHHTTPCookie*) cookieWithHTTPCookie:(NSString*)httpCookie
{
    return [[[FHHTTPCookie alloc] initWithHTTPCookie:httpCookie] autorelease];
}

#pragma mark -
#pragma mark Description

- (NSString*) description
{
    return [NSString stringWithFormat:@"%@=%@", name, ( value != nil ) ? value : @""];
}

@end
