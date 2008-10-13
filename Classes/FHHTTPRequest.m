//
//  FHHTTPRequest.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHTTPRequest.h"
#import "FHHTTPRequest+Implementation.h"
#import "FHHTTPCookie.h"

@implementation FHHTTPRequest

@synthesize proxy;
@synthesize url;
@synthesize method;
@synthesize headers;
@synthesize cookies;
@synthesize content;
@dynamic contentAsString;

@synthesize singleUse;

@dynamic referer;
@dynamic contentType;
@dynamic ifModifiedSince;

#pragma mark -
#pragma mark Initialization

- (id) init
{
    if( self = [super init] )
    {
        proxy = nil;
        url = nil;
        method = [FHHTTPMethodGet retain];
        headers = [[NSMutableDictionary alloc] init];
        cookies = [[NSMutableArray alloc] init];
        content = nil;
        
        singleUse = NO;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return self;
}

- (id) initWithURL:(NSURL*)_url
{
    return [self initWithURL:_url andContent:nil];
}

- (id) initWithURL:(NSURL*)_url andContent:(NSData*)_content
{
    // Calls above -init
    if( self = [self init] )
    {
        url = [_url retain];
        content = [_content retain];
    }
    return self;
}

- (void) dealloc
{
    FHRELEASE( dateFormatter );
    FHRELEASE( url );
    FHRELEASE( method );
    FHRELEASE( headers );
    FHRELEASE( cookies );
    FHRELEASE( content );
    FHRELEASE( proxy );
    [super dealloc];
}

#pragma mark -
#pragma mark Allocation Helpers

+ (FHHTTPRequest*) requestWithURL:(NSURL*)url
{
    return [[[FHHTTPRequest alloc] initWithURL:url] autorelease];
}

+ (FHHTTPRequest*) requestWithURL:(NSURL*)url andContent:(NSData*)content
{
    return [[[FHHTTPRequest alloc] initWithURL:url andContent:content] autorelease];
}

#pragma mark -
#pragma mark Headers

- (void) addHeaders:(NSDictionary*)newHeaders
{
    for( NSString* key in newHeaders )
    {
        NSString* value = [newHeaders objectForKey:key];
        [headers setObject:value forKey:key];
    }
}

- (void) addHeader:(NSString*)key withValue:(NSString*)value
{
    [headers setObject:value forKey:key];
}

- (NSString*) valueForHeader:(NSString*)key
{
    return ( NSString* )[headers objectForKey:key];
}

- (void) removeHeader:(NSString*)key
{
    [headers removeObjectForKey:key];
}

- (void) removeAllHeaders
{
    [headers removeAllObjects];
}

#pragma mark -
#pragma mark Cookies

- (void) addCookies:(NSArray*)newCookies
{
    [cookies addObjectsFromArray:newCookies];
}

- (void) addCookie:(FHHTTPCookie*)cookie
{
    [cookies addObject:cookie];
}

- (FHHTTPCookie*) cookieWithName:(NSString*)name
{
    for( FHHTTPCookie* cookie in cookies )
    {
        if( [[cookie name] isEqualToString:name] == YES )
            return cookie;
    }
    return nil;
}

- (void) removeCookie:(FHHTTPCookie*)cookie
{
    [cookies removeObject:cookie];
}

- (void) removeAllCookies
{
    [cookies removeAllObjects];
}

#pragma mark -
#pragma mark Header Accessors

- (NSString*) referer
{
    return [headers objectForKey:@"Referer"];
}

- (void) setReferer:(NSString*)value
{
    if( value != nil )
        [headers setObject:value forKey:@"Referer"];
    else
        [headers removeObjectForKey:@"Referer"];
}

- (NSString*) contentType
{
    return [headers objectForKey:@"Content-Type"];
}

- (void) setContentType:(NSString*)value
{
    if( value != nil )
        [headers setObject:value forKey:@"Content-Type"];
    else
        [headers removeObjectForKey:@"Content-Type"];
}

- (NSDate*) ifModifiedSince
{
    NSString* value = [headers objectForKey:@"If-Modified-Since"];
    if( value != nil )
        return [dateFormatter dateFromString:[value stringByReplacingOccurrencesOfString:@"-" withString:@" "]];
    else
        return nil;
}

- (void) setIfModifiedSince:(NSDate*)value
{
    if( value != nil )
    {
        NSString* string = [dateFormatter stringFromDate:value];
        [headers setObject:string forKey:@"If-Modified-Since"];
    }
    else
        [headers removeObjectForKey:@"If-Modified-Since"];
}

- (NSString*) contentAsString
{
    if( content == nil )
        return nil;
    return [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease];
}

- (void) setContentWithString:(NSString*)value
{
    FHRELEASE( content );
    content = [[value dataUsingEncoding:NSUTF8StringEncoding] retain];
}

#pragma mark -
#pragma mark Description

- (NSString*) description
{
    return [[self generate] autorelease];
}

- (NSString*) generate
{
    NSMutableString* value = [[NSMutableString alloc] init];
    
    // Opening line
    NSString* massagedUrl = [url path]; // TODO: make absolute again (add scheme/host/port) - recommended, but not needed
    if( [massagedUrl length] == 0 )
        massagedUrl = @"/";
    [value appendFormat:@"%@ %@ HTTP/1.1\r\n", method, massagedUrl];
    
    // User headers
    BOOL hasUA = NO;
    BOOL hasHost = NO;
    BOOL hasAcceptCharset = NO;
    BOOL hasConnection = NO;
    BOOL hasCookies = NO;
    BOOL hasExpect = NO;
    for( NSString* key in headers )
    {
        [value appendFormat:@"%@: %@\r\n", key, [headers objectForKey:key]];
        NSString* lowerKey = [key lowercaseString];
        if( [lowerKey isEqualToString:@"user-agent"] == YES )
            hasUA = YES;
        else if( [lowerKey isEqualToString:@"host"] == YES )
            hasHost = YES;
        else if( [lowerKey isEqualToString:@"accept-charset"] == YES )
            hasAcceptCharset = YES;
        else if( [lowerKey isEqualToString:@"connection"] == YES )
            hasConnection = YES;
        else if( [lowerKey isEqualToString:@"cookie"] == YES )
            hasCookies = YES;
        else if( [lowerKey isEqualToString:@"expect"] == YES )
            hasExpect = YES;
    }
    
    // Add any missing headers
    if( hasUA == NO )
    {
        // TODO: pull real platform names
        NSString* platformName;
#if defined( FH_IPHONE )
        platformName = @"iPhone";
#else
        platformName = @"Mac OS X";
#endif
        [value appendFormat:@"User-Agent: FemtoHTTP/1.0 (%@)\r\n", platformName];
    }
    if( hasHost == NO )
        [value appendFormat:@"Host: %@:%@\r\n", [url host], ( [url port] != nil ) ? [url port] : @"80"];
    if( hasAcceptCharset == NO )
        [value appendString:@"Accept-Charset: UTF-8; q=1.0, US-ASCII; q=0.9, ISO-8859-1; q=0.9, ISO-10646-UCS-2; q=0.6\r\n"];
    if( hasConnection == NO )
    {
        if( singleUse == YES )
            [value appendString:@"Connection: close\r\n"];
        else
            [value appendString:@"Connection: keep-alive\r\n"];
    }
    if( ( hasCookies == NO ) && ( [cookies count] > 0 ) )
    {
        [value appendString:@"Cookie: "];
        for( FHHTTPCookie* cookie in cookies )
        {
            [value appendString:[cookie description]];
            [value appendString:@"; "];
        }
        [value appendString:@"\r\n"];
    }
    if( ( hasExpect == NO ) && ( [content length] > 0 ) )
        [value appendString:@"Expect: 100-continue\r\n"];
    
    // Proxy headers
    if( proxy != nil )
    {
        // TODO: proxy authentication
    }
    
    // Content
    if( content != nil )
        [value appendFormat:@"Content-Length: %d\r\n\r\n", [content length]];
    else
        [value appendString:@"\r\n"];
    
    // NOTE: retained - must be freed by caller
    return value;
}

@end
