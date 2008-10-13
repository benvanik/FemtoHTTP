//
//  HTTPTests.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/13/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "HTTPTests.h"

@implementation HTTPTests

- (void) setUp
{
}

- (void) tearDown
{
}

- (void) testSimpleFetch
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://www.noxa.org"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request" );
}

- (void) testBackToBackChunkedFetches
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://news.google.com/"]];
    for( NSInteger n = 0; n < 10; n++ )
    {
        FHHTTPResponse* response;
        FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request %d", n );
    }
}

- (void) testBackToBackContentLengthFetches
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://www.noxa.org/"]];
    for( NSInteger n = 0; n < 10; n++ )
    {
        FHHTTPResponse* response;
        FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request %d", n );
    }
}

- (void) testManyDelayedChunkedFetches
{
    for( NSInteger n = 0; n < 2; n++ )
    {
        FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://news.google.com/"]];
        FHHTTPResponse* response1;
        FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response1];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 1" );
        [NSThread sleepForTimeInterval:10];
        FHHTTPResponse* response2;
        errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response2];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 2" );
    }
}

- (void) testManyDelayedContentLengthFetches
{
    for( NSInteger n = 0; n < 2; n++ )
    {
        FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://www.noxa.org/"]];
        FHHTTPResponse* response1;
        FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response1];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 1" );
        [NSThread sleepForTimeInterval:10];
        FHHTTPResponse* response2;
        errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response2];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 2" );
    }
}

- (void) testChunkedEncoding
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://news.google.com/"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request" );
    STAssertTrue( [[response contentAsString] rangeOfString:@"Select the entry for this HTML page and go to the"].location != NSNotFound, @"Unable to find footer string in contents" );
}

@end
