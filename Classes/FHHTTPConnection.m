//
//  FHHTTPConnection.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHHTTPConnection.h"
#import "FHHTTPRequest+Implementation.h"
#import "FHHTTPResponse+Implementation.h"
#import "FHHostPool.h"
#import "FHHostEntry.h"
#import "FHTCPSocket.h"

@interface FHHTTPConnection (Implementation)
+ (NSInteger) parseChunkSize:(NSString*)line;
+ (FHErrorCode) readHeaders:(NSMutableDictionary*)headers statusReason:(NSString**)outStatusReason fromSocket:(FHTCPSocket*)socket isFooter:(BOOL)isFooter;
@end

#define DTRACE_HTTP_END() if( FEMTOHTTP_HTTP_END_ENABLED() ) FEMTOHTTP_HTTP_END()

@implementation FHHTTPConnection

#pragma mark -
#pragma mark Calls

+ (FHErrorCode) issueRequest:(FHHTTPRequest*)request returningResponse:(FHHTTPResponse**)outResponse
{
    FHErrorCode errorCode = FHErrorOK;
    if( outResponse != NULL )
        *outResponse = nil;
    
    // TODO: validate input
    
    if( FEMTOHTTP_HTTP_BEGIN_ENABLED() )
        FEMTOHTTP_HTTP_BEGIN( CSTRING( [[request url] absoluteString] ) );
    
    // Switch for proxy - send all requests through target proxy server
    NSURL* hostUrl = ( [request proxy] != nil ) ? [request proxy] : [request url];
    
    // Lookup host
    FHHostEntry* hostEntry = [[FHHostPool sharedHostPool] hostForURL:hostUrl];
    if( hostEntry == nil )
    {
        DTRACE_HTTP_END();
        errorCode = FHErrorInternalInvalidArguments;
        FHLOGERROR( errorCode, @"Unable to get host entry for URL %@", [hostUrl absoluteString] );
        return errorCode;
    }
    
    // -- destination for when a socket is dead (only if the socket was idle)
deadSocket:
    errorCode = FHErrorOK;
    
    // Build headers
    // NOTE: the result is retained, not autoreleased so that we can free it as soon as possible
    NSString* requestHeader = [request generate];
    if( requestHeader == nil )
    {
        DTRACE_HTTP_END();
        errorCode = FHErrorInternalInvalidArguments;
        FHLOGERROR( errorCode, @"Unable to generate request for URL %@", [[request url] absoluteString] );
        return errorCode;
    }
    
    // Get a socket
    BOOL wasReused;
    FHTCPSocket* socket = [hostEntry openSocket:YES errorCode:&errorCode wasReused:&wasReused];
    if( socket == nil )
    {
        DTRACE_HTTP_END();
        FHRELEASE( requestHeader );
        errorCode = FHErrorInternalInvalidArguments;
        FHLOGERROR( errorCode, @"Unable to obtain socket for URL %@", [hostUrl absoluteString] );
        return errorCode;
    }
    if( FEMTOHTTP_HTTP_USING_SOCKET_ENABLED() )
        FEMTOHTTP_HTTP_USING_SOCKET( socket->identifier );
    
    // Write request headers
    if( FEMTOHTTP_HTTP_PRE_HEADER_WRITE_ENABLED() )
        FEMTOHTTP_HTTP_PRE_HEADER_WRITE( [requestHeader length] );
    if( FEMTOHTTP_HTTP_HEADER_WRITE_DATA_ENABLED() )
        FEMTOHTTP_HTTP_HEADER_WRITE_DATA( CSTRING( requestHeader ) );
    errorCode = [socket writeString:requestHeader];
    if( FEMTOHTTP_HTTP_HEADER_WRITE_ENABLED() )
        FEMTOHTTP_HTTP_HEADER_WRITE( [requestHeader length] );
    FHRELEASE( requestHeader );
    if( errorCode != FHErrorOK )
    {
        DTRACE_HTTP_END();
        [hostEntry closeSocket:socket closeConnection:YES];
        FHLOGERROR( errorCode, @"Unable to write request header for URL %@", [[request url] absoluteString] );
        return errorCode;
    }
    
    // NOTE: we write the request body below, as we are waiting for a 100 Continue and need to read it first
    
    // Wait until data ready - this will fail if we are a now-closed reused connection
    errorCode = [socket waitUntilDataPresent];
    if( errorCode != FHErrorOK )
    {
        [hostEntry closeSocket:socket closeConnection:YES];
        if( ( errorCode == FHErrorSocketDisconnected ) && ( wasReused == YES ) )
        {
            // Now-disconnected idle socket - try again
            if( FEMTOHTTP_HTTP_SOCKET_RETRY_ENABLED() )
                FEMTOHTTP_HTTP_SOCKET_RETRY();
            FHLOG( @"waitUntilDataPresent killed bad idle socket - retrying" );
            goto deadSocket;
        }
        DTRACE_HTTP_END();
        FHLOGERROR( errorCode, @"Error waiting for data for URL %@", [[request url] absoluteString] );
        return errorCode;
    }
    
    NSMutableDictionary* responseHeaders = [NSMutableDictionary dictionary];
    FHErrorCode statusCode = 0;
    NSString* statusReason = nil;
    NSData* content = nil;
    BOOL closeConnection = FHHTTPRequestOptionIsSet( request, FHHTTPRequestSingleUse );
    
    while( YES )
    {
        // Consume an infinite number of 100's
        [responseHeaders removeAllObjects];
        statusCode = [FHHTTPConnection readHeaders:responseHeaders statusReason:&statusReason fromSocket:socket isFooter:NO];
        if( statusCode == FHErrorHTTPContinue )
        {
            // Was waiting to write the contents, so write them!
            if( [request content] != nil )
            {
                if( FEMTOHTTP_HTTP_PRE_CONTENT_WRITE_ENABLED() )
                    FEMTOHTTP_HTTP_PRE_CONTENT_WRITE( [[request content] length] );
                if( FEMTOHTTP_HTTP_CONTENT_WRITE_DATA_ENABLED() )
                    FEMTOHTTP_HTTP_CONTENT_WRITE_DATA( CSTRING( [request contentAsString] ) );
                errorCode = [socket writeData:[request content]];
                if( FEMTOHTTP_HTTP_CONTENT_WRITE_ENABLED() )
                    FEMTOHTTP_HTTP_CONTENT_WRITE( [[request content] length] );
                if( errorCode != FHErrorOK )
                {
                    [hostEntry closeSocket:socket closeConnection:YES];
                    DTRACE_HTTP_END();
                    FHLOGERROR( errorCode, @"Unable to write request body for URL %@", [[request url] absoluteString] );
                    return errorCode;
                }
                
                // Write trailing newline - I think this is required
                errorCode = [socket writeNewLine];
                if( errorCode != FHErrorOK )
                {
                    [hostEntry closeSocket:socket closeConnection:YES];
                    DTRACE_HTTP_END();
                    FHLOGERROR( errorCode, @"Unable to write request body trailer for URL %@", [[request url] absoluteString] );
                    return errorCode;
                }
            }
            
            // Continue waiting for the real response
            continue;
        }
        if( ( statusCode != FHErrorOK ) && ( FHErrorGetDomain( statusCode ) != FHErrorDomainHTTP ) )
        {
            // Internal/socket errors
            [hostEntry closeSocket:socket closeConnection:YES];
            if( ( statusCode == FHErrorSocketDisconnected ) && ( wasReused == YES ) )
            {
                // Now-disconnected idle socket - try again
                if( FEMTOHTTP_HTTP_SOCKET_RETRY_ENABLED() )
                    FEMTOHTTP_HTTP_SOCKET_RETRY();
                FHLOG( @"readHeaders killed bad idle socket - retrying" );
                goto deadSocket;
            }
            DTRACE_HTTP_END();
            FHLOGERROR( statusCode, @"Unable to read response headers for URL %@", [[request url] absoluteString] );
            return statusCode;
        }
        
        // I know the docs say that if Connection is omitted you should assume that it's going to be kept alive, but that doesn't seem to be the case!
        id value = [responseHeaders objectForKey:@"connection"];
        if( ( value != nil ) && ( [value caseInsensitiveCompare:@"close"] == NSOrderedSame ) )
            closeConnection = YES;
        
        // NOTE: even if the statusCode is not successful, it may contain a body, so make sure to read it out!
        
        // Ready body if present
        value = [responseHeaders objectForKey:@"content-length"];
        NSInteger contentLength = ( value == nil ) ? -1 : [value integerValue];
        value = [responseHeaders objectForKey:@"transfer-encoding"];
        BOOL isChunked = ( value != nil ) && ( [value caseInsensitiveCompare:@"chunked"] == NSOrderedSame );
        BOOL bodyPresent = ( ( contentLength > 0 ) || isChunked ) && FHErrorHTTPHasContent( statusCode );
        if( ( statusCode == 200 ) && ( [[request method] isEqualToString:FHHTTPMethodHead] == YES ) )
            bodyPresent = NO;
        if( bodyPresent == YES )
        {
            if( FEMTOHTTP_HTTP_PRE_CONTENT_READ_ENABLED() )
                FEMTOHTTP_HTTP_PRE_CONTENT_READ( isChunked );
            
            if( isChunked == YES )
            {
                NSMutableData* chunkedContent = [[NSMutableData alloc] init];
                while( YES )
                {
                    if( FEMTOHTTP_HTTP_PRE_CONTENT_CHUNK_ENABLED() )
                        FEMTOHTTP_HTTP_PRE_CONTENT_CHUNK();
                    
                    // Read chunk size
                    // 1a; ignore-stuff-here
                    NSString* chunkLine = [socket readLine];
                    if( chunkLine == nil )
                    {
                        // Error reading data
                        FHRELEASE( chunkedContent );
                        errorCode = [socket errorCode];
                        [hostEntry closeSocket:socket closeConnection:YES];
                        DTRACE_HTTP_END();
                        FHLOGERROR( errorCode, @"Unable to read chunked response header line data for URL %@", [[request url] absoluteString] );
                        return errorCode;
                    }
                    NSInteger chunkSize = [FHHTTPConnection parseChunkSize:chunkLine];
                    if( chunkSize == -1 )
                    {
                        // Error reading data
                        FHRELEASE( chunkedContent );
                        [hostEntry closeSocket:socket closeConnection:YES];
                        errorCode = FHErrorInternalUnableToParse;
                        DTRACE_HTTP_END();
                        FHLOGERROR( errorCode, @"Unable to parse chunked response header line data for URL %@", [[request url] absoluteString] );
                        return errorCode;
                    }
                    if( chunkSize == 0 )
                    {
                        // Done with chunks - footer may follow
                        break;
                    }
                    
                    // Read chunkSize bytes
                    errorCode = [socket readIntoData:chunkedContent length:chunkSize];
                    if( errorCode != FHErrorOK )
                    {
                        // Error reading data
                        FHRELEASE( chunkedContent );
                        [hostEntry closeSocket:socket closeConnection:YES];
                        DTRACE_HTTP_END();
                        FHLOGERROR( errorCode, @"Unable to read chunked response data for URL %@", [[request url] absoluteString] );
                        return errorCode;
                    }
                    
                    // If content ignored, don't grow the buffer
                    if( FHHTTPRequestOptionIsSet( request, FHHTTPRequestIgnoreResponseBody ) == YES )
                        [chunkedContent setLength:0];
                    
                    // Skip newline
                    [socket readLine];
                    
                    if( FEMTOHTTP_HTTP_CONTENT_CHUNK_ENABLED() )
                        FEMTOHTTP_HTTP_CONTENT_CHUNK( chunkSize );
                }

                // Ignore content if requested
                if( FHHTTPRequestOptionIsSet( request, FHHTTPRequestIgnoreResponseBody ) == YES )
                    FHRELEASE( chunkedContent );
                
                content = chunkedContent;
                
                // Read footer headers - merge into our existing ones - an empty line ends us, so if there are no footers this should return right away and we should be done
                errorCode = [FHHTTPConnection readHeaders:responseHeaders statusReason:NULL fromSocket:socket isFooter:YES];
                if( errorCode != FHErrorOK )
                {
                    [hostEntry closeSocket:socket closeConnection:YES];
                    DTRACE_HTTP_END();
                    FHLOGERROR( statusCode, @"Unable to read chunked response footer headers for URL %@", [[request url] absoluteString] );
                    return errorCode;
                }
            }
            else
            {
                // Read content length? What if not present?
                if( contentLength == -1 )
                {
                    [hostEntry closeSocket:socket closeConnection:YES];
                    errorCode = FHErrorInternalNotImplemented;
                    DTRACE_HTTP_END();
                    FHLOGERROR( errorCode, @"HTTP non-chunked with no content length not yet implemented - connection is now hosed!" );
                    return errorCode;
                }
                
                if( FHHTTPRequestOptionIsSet( request, FHHTTPRequestIgnoreResponseBody ) == YES )
                {
                    // Skip contents
                    errorCode = [socket skipBytes:contentLength];
                    if( errorCode != FHErrorOK )
                    {
                        [hostEntry closeSocket:socket closeConnection:YES];
                        DTRACE_HTTP_END();
                        FHLOGERROR( errorCode, @"Unable to skip response data for URL %@", [[request url] absoluteString] );
                        return errorCode;
                    }
                }
                else
                {
                    content = [[socket readData:contentLength] retain];
                    if( content == nil )
                    {
                        // Error reading data
                        errorCode = [socket errorCode];
                        [hostEntry closeSocket:socket closeConnection:YES];
                        DTRACE_HTTP_END();
                        FHLOGERROR( errorCode, @"Unable to read response data for URL %@", [[request url] absoluteString] );
                        return errorCode;
                    }
                }
            }
            
            if( FEMTOHTTP_HTTP_CONTENT_READ_ENABLED() )
                FEMTOHTTP_HTTP_CONTENT_READ( [content length] );
        }
        
        break;
    }
    
    // Cleanup
    [hostEntry closeSocket:socket closeConnection:closeConnection];
    
    if( FHErrorIsHTTPRedirect( statusCode ) == YES )
    {
        // Need to redirect - just call ourselves?
        // TODO: implement auto redirects
        FHLOG( @"Received %d (%@) for URL %@ - would auto redirect here to %@", statusCode, FHErrorGetName( statusCode ), [[request url] absoluteString], [responseHeaders objectForKey:@"location"] );
        //[hostEntry closeSocket:socket closeConnection:YES];
        //errorCode = FHErrorInternalNotImplemented;
        //FHLOGERROR( errorCode, @"HTTP redirects not yet implemented - connection is now hosed!" );
        //return errorCode;
        if( FEMTOHTTP_HTTP_REDIRECT_ENABLED() )
            FEMTOHTTP_HTTP_REDIRECT( statusCode, CSTRING( [responseHeaders objectForKey:@"location"] ) );
    }
    
    // Build response
    BOOL autoDecompress = FHHTTPRequestOptionIsSet( request, FHHTTPRequestAutoDecompress );
    if( outResponse != NULL )
    {
        *outResponse = [[[FHHTTPResponse alloc] initWithURL:[request url]
                                                    headers:responseHeaders
                                                 statusCode:statusCode
                                               statusReason:statusReason
                                                    content:content
                                             autoDecompress:autoDecompress] autorelease];
        
        // Do this here so we can get the pretty data
        if( FEMTOHTTP_HTTP_CONTENT_READ_DATA_ENABLED() )
            FEMTOHTTP_HTTP_CONTENT_READ_DATA( CSTRING( [*outResponse contentAsString] ) );
    }
    
    FHRELEASE( content );
    
    DTRACE_HTTP_END();
    return FHErrorOK;
}

+ (NSInteger) parseChunkSize:(NSString*)line
{
    // Note that there may be whitespace after the value, or a semicolon - ignore both
    NSUInteger value;
    NSScanner* scanner = [[NSScanner alloc] initWithString:line];
    BOOL found = [scanner scanHexInt:&value];
    FHRELEASE( scanner );
    if( found == YES )
        return value;
    else
        return -1;
}

+ (FHErrorCode) readHeaders:(NSMutableDictionary*)headers statusReason:(NSString**)outStatusReason fromSocket:(FHTCPSocket*)socket isFooter:(BOOL)isFooter
{
    if( outStatusReason != NULL )
        *outStatusReason = nil;
    FHErrorCode statusCode = FHErrorOK;
    
    if( ( isFooter == NO ) && FEMTOHTTP_HTTP_PRE_HEADER_READ_ENABLED() )
        FEMTOHTTP_HTTP_PRE_HEADER_READ();
    
    // If a footer, then don't try to read status line
    BOOL hasReadFirstLine = isFooter;
    NSCharacterSet* colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
    
    // If logging data, we need to keep it
    NSMutableString* headerData = nil;
    if( ( isFooter == NO ) && FEMTOHTTP_HTTP_HEADER_READ_DATA_ENABLED() )
        headerData = [[NSMutableString alloc] init];
    
    NSInteger length = 0;
    while( YES )
    {
        NSString* line = [socket readLine];
        if( line == nil )
        {
            // Error reading line
            statusCode = [socket errorCode];
            break;
        }
        else if( [line length] == 0 )
        {
            // Empty line - end of header
            break;
        }
        length += [line length];
        if( headerData != nil )
        {
            // for dtrace - usually not enabled
            [headerData appendString:line];
            [headerData appendString:@"\n"];
        }
        
        BOOL errorScanning = NO;
        NSScanner* scanner = [[NSScanner alloc] initWithString:line];
        if( hasReadFirstLine == NO )
        {
            // Status line
            // HTTP/1.1 200 OK
            if( [scanner scanString:@"HTTP/1.1" intoString:NULL] &&
                [scanner scanInteger:&statusCode] )
            {
                *outStatusReason = [[line substringFromIndex:[scanner scanLocation] + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if( FEMTOHTTP_HTTP_HEADER_STATUS_CODE_ENABLED() )
                    FEMTOHTTP_HTTP_HEADER_STATUS_CODE( statusCode, CSTRING( *outStatusReason ) );
            }
            else
                errorScanning = YES;
            hasReadFirstLine = YES;
        }
        else
        {
            // Header line
            // Header-Name: something
            // TODO: support multi-line headers (any whitespace before the line; content is tagged onto the end of the previous line)
            NSString* headerKey = nil;
            if( [scanner scanUpToCharactersFromSet:colonSet intoString:&headerKey] )
            {
                headerKey = [headerKey lowercaseString];
                NSString* headerValue = [[line substringFromIndex:[scanner scanLocation] + 2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if( [headerKey isEqualToString:@"set-cookie"] == YES )
                {
                    // There may be multiple set-cookie headers, so merge if we already have one
                    NSString* existingValue = [headers objectForKey:headerKey];
                    if( existingValue != nil )
                    {
                        // Delimit with newline, as that shouldn't be valid inside a cookie
                        headerValue = [NSString stringWithFormat:@"%@\n%@", existingValue, headerValue];
                        [headers setObject:headerValue forKey:headerKey];
                    }
                    else
                        [headers setObject:headerValue forKey:headerKey];
                }
                else
                    [headers setObject:headerValue forKey:headerKey];
            }
            else
                errorScanning = YES;
        }
        FHRELEASE( scanner );
        
        if( errorScanning == YES )
        {
            statusCode = FHErrorInternalUnableToParse;
            break;
        }
    }
    
    if( ( isFooter == NO ) && FEMTOHTTP_HTTP_HEADER_READ_ENABLED() )
        FEMTOHTTP_HTTP_HEADER_READ( length );
    if( ( isFooter == NO ) && FEMTOHTTP_HTTP_HEADER_READ_DATA_ENABLED() )
        FEMTOHTTP_HTTP_HEADER_READ_DATA( CSTRING( headerData ) );
    FHRELEASE( headerData );
    
    return statusCode;
}

#pragma mark -
#pragma mark Engine Control

+ (void) shutdown
{
    [[FHHostPool sharedHostPool] removeAllHosts];
}

@end
