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

- (void) testRedirect
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://httpwatch.com/httpgallery/chunked/"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request" );
    STAssertTrue( FHErrorIsHTTPRedirect( [response statusCode] ) == YES, @"No redirect returned" );
}

- (void) testSingleBinaryFileContentLength
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://www.noxa.org/projects/phanfare/windowsclient/screenshots/WindowsClient-Albums.jpg"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request" );
    STAssertEquals( [[response content] length], ( NSUInteger )260441, @"Content lengths differ" );
    [[response content] writeToFile:@"testBinaryFile.jpg" atomically:YES];
}

- (void) testMultipleBinaryFileContentLength
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://www.noxa.org/projects/phanfare/windowsclient/screenshots/WindowsClient-Albums.jpg"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 1" );
    STAssertEquals( [[response content] length], ( NSUInteger )260441, @"Content lengths differ 1" );
    [[response content] writeToFile:@"testBinaryFile1.jpg" atomically:YES];
    errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
    STAssertEquals( errorCode, FHErrorOK, @"Error issuing request 2" );
    STAssertEquals( [[response content] length], ( NSUInteger )260441, @"Content lengths differ 2" );
    [[response content] writeToFile:@"testBinaryFile2.jpg" atomically:YES];
}

- (void) testMultipleVETiles
{
    FHHTTPRequest* request = [FHHTTPRequest requestWithURL:[NSURL URLWithString:@"http://a3.ortho.tiles.virtualearth.net/tiles/a033.jpeg?g=159"]];
    FHHTTPResponse* response;
    FHErrorCode errorCode;
    for( NSInteger n = 0; n < 10; n++ )
    {
        errorCode = [FHHTTPConnection issueRequest:request returningResponse:&response];
        STAssertEquals( errorCode, FHErrorOK, @"Error issuing request" );
        STAssertEquals( [[response content] length], ( NSUInteger )5255, @"Content lengths differ" );
        [[response content] writeToFile:[NSString stringWithFormat:@"testVE%d.jpg", n] atomically:YES];
    }
}

@end
