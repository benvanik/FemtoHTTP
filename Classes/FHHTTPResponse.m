//
//  FHHTTPResponse.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHTTPResponse.h"

@implementation FHHTTPResponse

@synthesize headers;
@synthesize statusCode;
@synthesize statusReason;

@synthesize location;
@synthesize lastModified;
@synthesize contentType;

@synthesize content;

#pragma mark -
#pragma mark Initialization

- (id) initWithHeaders:(NSDictionary*)_headers
            statusCode:(FHErrorCode)_statusCode
          statusReason:(NSString*)_statusReason
               content:(NSData*)_content
{
    if( self = [super init] )
    {
        headers = [_headers retain];
        statusCode = _statusCode;
        statusReason = [_statusReason retain];
        content = [_content retain];
        
        // TODO: shared dateFormatter? NOTE: NSDateFormatter is NOT thread safe! Not sure anything can be done...
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        // Pull out interesting header bits
        id value = [headers objectForKey:@"location"];
        location = ( value == nil ) ? nil : [value retain];
        value = [headers objectForKey:@"last-modified"];
        lastModified = ( value == nil ) ? nil : [[dateFormatter dateFromString:value] retain];
        value = [headers objectForKey:@"content-type"];
        contentType = ( value == nil ) ? nil : [value retain];
        
        FHRELEASE( dateFormatter );
    }
    return self;
}

- (void) dealloc
{
    FHRELEASE( location );
    FHRELEASE( lastModified );
    FHRELEASE( contentType );
    
    FHRELEASE( headers );
    FHRELEASE( statusReason );
    FHRELEASE( content );
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSString*) valueForHeader:(NSString*)key
{
    return [headers objectForKey:[key lowercaseString]];
}

- (NSString*) mimeType
{
    if( contentType == nil )
        return nil;
    NSUInteger semicolon = [contentType rangeOfString:@";"].location;
    if( semicolon == NSNotFound )
        return contentType;
    else
        return [contentType substringToIndex:semicolon];
}

- (NSString*) contentAsString
{
    return [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease];
}

@end
