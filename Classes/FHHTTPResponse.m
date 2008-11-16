//
//  FHHTTPResponse.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

// GZIP and deflate decompressors taken from NSDataCategory here:
// http://www.cocoadev.com/index.pl?NSDataCategory

#import "FHHTTPResponse.h"
#import "FHHTTPCookie.h"
#import "FHSharedObjects.h"
#import <zlib.h>

@interface FHHTTPResponse (Implementation)
- (BOOL) decompressGZIP;
- (BOOL) decompressDeflate;
@end

@implementation FHHTTPResponse

@synthesize url;
@synthesize redirectedFrom;
@synthesize headers;
@synthesize statusCode;
@synthesize statusReason;
@synthesize cookies;

@synthesize location;
@synthesize lastModified;
@synthesize contentType;
@dynamic mimeType;

@synthesize contentEncoding;
@synthesize content;
@dynamic contentAsString;

#pragma mark -
#pragma mark Initialization

- (id) initWithURL:(NSURL*)_url
           headers:(NSDictionary*)_headers
        statusCode:(FHErrorCode)_statusCode
      statusReason:(NSString*)_statusReason
           content:(NSData*)_content
    autoDecompress:(BOOL)autoDecompress
{
    if( self = [super init] )
    {
        url = [_url retain];
        redirectedFrom = nil;
        headers = [_headers retain];
        statusCode = _statusCode;
        statusReason = [_statusReason retain];
        content = [_content retain];
        
        // Pull out interesting header bits
        id value = [headers objectForKey:@"location"];
        location = ( value == nil ) ? nil : [value retain];
        value = [headers objectForKey:@"last-modified"];
        if( value != nil )
        {
            NSDateFormatter* dateFormatter = [FHSharedObjects dateFormatter];
            lastModified = [[dateFormatter dateFromString:[value stringByReplacingOccurrencesOfString:@"-" withString:@" "]] retain];
        }
        else
            lastModified = nil;
        value = [headers objectForKey:@"content-type"];
        contentType = ( value == nil ) ? nil : [value retain];
        
        // Content encoding
        value = [headers objectForKey:@"content-encoding"];
        if( value != nil )
        {
            BOOL needsDecompress = NO;
            if( [value caseInsensitiveCompare:FHHTTPContentEncodingGZIP] == NSOrderedSame )
            {
                contentEncoding = [FHHTTPContentEncodingGZIP retain];
                needsDecompress = YES;
            }
            else if( [value caseInsensitiveCompare:FHHTTPContentEncodingDeflate] == NSOrderedSame )
            {
                contentEncoding = [FHHTTPContentEncodingDeflate retain];
                needsDecompress = YES;
            }
            else
                contentEncoding = [value retain];
            // Attempt to decompress - this may fail and stay in compressed form
            if( ( autoDecompress == YES ) && ( needsDecompress == YES ) )
            {
                FHPROBE( FEMTOHTTP_RESPONSE_AUTO_DECOMPRESS );
                [self decompress];
            }
                
        }
        else
            contentEncoding = [FHHTTPContentEncodingIdentity retain];
        
        // Pull out cookies
        NSMutableArray* cookieArray = [[NSMutableArray alloc] init];
        value = [headers objectForKey:@"set-cookie"];
        if( value != nil )
        {
            // We delimited the cookies from the server with newlines - split them up
            NSArray* allCookies = [value componentsSeparatedByString:@"\n"];
            for( NSString* cookie in allCookies )
                [cookieArray addObject:[FHHTTPCookie cookieWithHTTPCookie:cookie]];
        }
        cookies = cookieArray;
    }
    return self;
}

- (void) dealloc
{
    FHRELEASE( location );
    FHRELEASE( lastModified );
    FHRELEASE( contentType );
    
    FHRELEASE( url );
    FHRELEASE( redirectedFrom );
    FHRELEASE( headers );
    FHRELEASE( cookies );
    FHRELEASE( statusReason );
    FHRELEASE( contentEncoding );
    FHRELEASE( content );
    [super dealloc];
}

#pragma mark -
#pragma mark Internal Helpers

- (void) setIsRedirectFrom:(NSURL*)originalURL
{
    redirectedFrom = [originalURL retain];
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

#pragma mark -
#pragma mark Content

- (BOOL) isCompressed
{
    return ![contentEncoding isEqualToString:FHHTTPContentEncodingIdentity];
}

- (BOOL) decompress
{
    if( [contentEncoding isEqualToString:FHHTTPContentEncodingGZIP] == YES )
    {
        FHPROBE( FEMTOHTTP_RESPONSE_PRE_DECOMPRESS );
        NSInteger preLength = [content length];
        BOOL result = ( preLength == 0 ) || ( [self decompressGZIP] == YES );
        FHPROBE( FEMTOHTTP_RESPONSE_DECOMPRESS, preLength, [content length], result );
        if( result == YES )
        {
            FHRELEASE( contentEncoding );
            contentEncoding = [FHHTTPContentEncodingIdentity retain];
            return YES;
        }
        else
            return NO;
    }
    else if( [contentEncoding isEqualToString:FHHTTPContentEncodingDeflate] == YES )
    {
        FHPROBE( FEMTOHTTP_RESPONSE_PRE_DECOMPRESS );
        NSInteger preLength = [content length];
        BOOL result = ( preLength == 0 ) || ( [self decompressDeflate] == YES );
        FHPROBE( FEMTOHTTP_RESPONSE_DECOMPRESS, preLength, [content length], result );
        if( result == YES )
        {
            FHRELEASE( contentEncoding );
            contentEncoding = [FHHTTPContentEncodingIdentity retain];
            return YES;
        }
        else
            return NO;
    }
    else if( [contentEncoding isEqualToString:FHHTTPContentEncodingIdentity] == YES )
    {
        // Nothing to be done
        return YES;
    }
    else
    {
        // Unknown format
        FHLOGERROR( FHErrorInternalNotImplemented, @"The content encoding %@ is not supported", contentEncoding );
        return NO;
    }
}

- (BOOL) decompressGZIP
{
    NSUInteger contentLength = [content length];
    
    z_stream strm;
    strm.next_in = ( Bytef* )[content bytes];
    strm.avail_in = contentLength;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if( inflateInit2( &strm, ( 15 + 32 ) ) != Z_OK )
        return NO;
    
    NSUInteger fullLength = contentLength;
    NSUInteger halfLength = contentLength / 2;
    NSMutableData* decompressed = [[NSMutableData alloc] initWithLength:fullLength + halfLength];    
    
    BOOL done = NO;
    while( done == NO )
    {
        // Make sure we have enough room and reset the lengths
        if( strm.total_out >= [decompressed length] )
            [decompressed increaseLengthBy:halfLength];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        
        // Inflate another chunk
        int status = inflate( &strm, Z_SYNC_FLUSH );
        if( status == Z_STREAM_END )
            done = YES;
        else if( status != Z_OK )
            break;
    }
    if( inflateEnd( &strm ) != Z_OK )
    {
        FHRELEASE( decompressed );
        return NO;
    }
    
    // Set real length
    if( done == YES )
    {
        [decompressed setLength:strm.total_out];
        FHRELEASE( content );
        content = decompressed;
        return YES;
    }
    else
    {
        FHRELEASE( decompressed );
        return NO;
    }
}

- (BOOL) decompressDeflate
{
    NSUInteger contentLength = [content length];
    
    z_stream strm;
    strm.next_in = ( Bytef* )[content bytes];
    strm.avail_in = contentLength;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if( inflateInit( &strm ) != Z_OK )
        return NO;
    
    NSUInteger fullLength = contentLength;
    NSUInteger halfLength = contentLength / 2;
    NSMutableData* decompressed = [[NSMutableData alloc] initWithLength:fullLength + halfLength]; 
    
    BOOL done = NO;
    while( done == NO )
    {
        // Make sure we have enough room and reset the lengths
        if( strm.total_out >= [decompressed length] )
            [decompressed increaseLengthBy:halfLength];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        
        // Inflate another chunk
        int status = inflate( &strm, Z_SYNC_FLUSH );
        if( status == Z_STREAM_END )
            done = YES;
        else if( status != Z_OK )
            break;
    }
    if( inflateEnd( &strm ) != Z_OK )
    {
        FHRELEASE( decompressed );
        return NO;
    }
    
    // Set real length
    if( done == YES )
    {
        [decompressed setLength:strm.total_out];
        FHRELEASE( content );
        content = decompressed;
        return YES;
    }
    else
    {
        FHRELEASE( decompressed );
        return NO;
    }
}

- (NSString*) contentAsString
{
    if( [self isCompressed] == YES )
        [self decompress];
    return [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease];
}

@end
