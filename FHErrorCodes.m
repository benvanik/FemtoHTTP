//
//  FHErrorCodes.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHErrorCodes.h"

#pragma mark -
#pragma mark Error Table

typedef struct {
    FHErrorDomain   domain;
    FHErrorCode     code;
    NSString*       name;
    BOOL            isError;
    BOOL            canRetry;
} FHErrorEntry;

#define FHDEFINEERROR( domain, code, name, isError, canRetry ) { domain, code, name, isError, canRetry }

FHErrorEntry __fh_errorEntries[] = {

FHDEFINEERROR( FHErrorDomainUnknown,    FHErrorOK,                      @"FHErrorOK",                       NO,  YES ),

// -- FHErrorDomainInternal --

FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalUnknown,         @"FHErrorInternalUnknown",          YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalHostNotFound,    @"FHErrorInternalHostNotFound",     YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalOutOfMemory,     @"FHErrorInternalOutOfMemory",      YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalUnsupported,     @"FHErrorInternalUnsupported",      YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalAccessDenied,    @"FHErrorInternalAccessDenied",     YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalInvalidState,    @"FHErrorInternalInvalidState",     YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalInvalidArguments,@"FHErrorInternalInvalidArguments", YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalNotImplemented,  @"FHErrorInternalNotImplemented",   YES, NO  ),
FHDEFINEERROR( FHErrorDomainInternal,   FHErrorInternalUnableToParse,   @"FHErrorInternalUnableToParse",    YES, NO  ),

// -- FHErrorDomainSocket --

FHDEFINEERROR( FHErrorDomainSocket,     FHErrorSocketHostNotFound,      @"FHErrorSocketHostNotFound",       YES, NO  ),
FHDEFINEERROR( FHErrorDomainSocket,     FHErrorSocketNetworkDown,       @"FHErrorSocketNetworkDown",        YES, YES ),
FHDEFINEERROR( FHErrorDomainSocket,     FHErrorSocketHostUnreachable,   @"FHErrorSocketHostUnreachable",    YES, NO  ),
FHDEFINEERROR( FHErrorDomainSocket,     FHErrorSocketTimeout,           @"FHErrorSocketTimeout",            YES, YES ),
FHDEFINEERROR( FHErrorDomainSocket,     FHErrorSocketDisconnected,      @"FHErrorSocketDisconnected",       YES, YES ),

// -- FHErrorDomainHTTP --

FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPContinue,            @"FHErrorHTTPContinue",             NO,  YES ),

FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPOK,                  @"FHErrorHTTPOK",                   NO,  YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPOKNoContent,         @"FHErrorHTTPOKNoContent",          NO,  YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPOKPartialContent,    @"FHErrorHTTPOKPartialContent",     NO,  YES ),

FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPMovedPermanently,    @"FHErrorHTTPMovedPermanently",     NO,  YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPFound,               @"FHErrorHTTPFound",                NO,  YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPNotModified,         @"FHErrorHTTPNotModified",          NO,  YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPUseProxy,            @"FHErrorHTTPUseProxy",             YES, YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPTemporaryRedirect,   @"FHErrorHTTPTemporaryRedirect",    NO,  YES ),

FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPBadRequest,          @"FHErrorHTTPBadRequest",           YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPNotAuthorized,       @"FHErrorHTTPNotAuthorized",        YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPForbidden,           @"FHErrorHTTPForbidden",            YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPNotFound,            @"FHErrorHTTPNotFound",             YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPProxyAuthRequired,   @"FHErrorHTTPProxyAuthRequired",    YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPRequestTimeout,      @"FHErrorHTTPRequestTimeout",       YES, YES ),

FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPInternalServerError, @"FHErrorHTTPInternalServerError",  YES, YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPNotImplemented,      @"FHErrorHTTPNotImplemented",       YES, NO  ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPBadGateway,          @"FHErrorHTTPBadGateway",           YES, YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPServiceUnavailable,  @"FHErrorHTTPServiceUnavailable",   YES, YES ),
FHDEFINEERROR( FHErrorDomainHTTP,       FHErrorHTTPGatewayTimeout,      @"FHErrorHTTPGatewayTimeout",       YES, YES ),

};

#define FHErrorCount ( sizeof( __fh_errorEntries ) / sizeof( FHErrorEntry ) )

#pragma mark -
#pragma mark Accessors

FHErrorEntry* FHErrorEntryForCode( FHErrorCode errorCode )
{
    // TODO: sort so we can do a binary lookup
    FHErrorEntry* errorEntry = __fh_errorEntries;
    for( NSInteger n = 0; n < FHErrorCount; n++, errorEntry++ )
    {
        if( errorEntry->code == errorCode )
            return errorEntry;
    }
    return NULL;
}

FHErrorDomain FHErrorGetDomain( FHErrorCode code )
{
    FHErrorEntry* errorEntry = FHErrorEntryForCode( code );
    if( errorEntry == NULL )
        return FHErrorDomainUnknown;
    return errorEntry->domain;
}

NSString* FHErrorGetDomainName( FHErrorDomain domain )
{
    switch( domain )
    {
        default:
        case FHErrorDomainUnknown:
            return @"FHErrorDomainUnknown";
        case FHErrorDomainInternal:
            return @"FHErrorDomainInternal";
        case FHErrorDomainSocket:
            return @"FHErrorDomainSocket";
        case FHErrorDomainHTTP:
            return @"FHErrorDomainHTTP";
    }
}

NSString* FHErrorGetName( FHErrorCode code )
{
    FHErrorEntry* errorEntry = FHErrorEntryForCode( code );
    if( errorEntry == NULL )
        return [NSString stringWithFormat:@"Error %d (%x)", code, code];
    return errorEntry->name;
}

BOOL FHErrorIsFatal( FHErrorCode code )
{
    FHErrorEntry* errorEntry = FHErrorEntryForCode( code );
    if( errorEntry == NULL )
        return NO;
    return errorEntry->isError;
}

BOOL FHErrorCanRetry( FHErrorCode code )
{
    FHErrorEntry* errorEntry = FHErrorEntryForCode( code );
    if( errorEntry == NULL )
        return NO;
    return errorEntry->canRetry;
}

BOOL FHErrorIsHTTPOK( FHErrorCode code )
{
    switch( code )
    {
        case FHErrorHTTPOK:
        case FHErrorHTTPOKNoContent:
        case FHErrorHTTPOKPartialContent:
            return YES;
        default:
            return NO;
    }
}

BOOL FHErrorIsHTTPRedirect( FHErrorCode code )
{
    switch( code )
    {
        case FHErrorHTTPMovedPermanently:
        case FHErrorHTTPFound:
        case FHErrorHTTPTemporaryRedirect:
            return YES;
        default:
            return NO;
    }
}

BOOL FHErrorHTTPHasContent( FHErrorCode code )
{
    switch( code )
    {
        case FHErrorHTTPOKNoContent:
        case FHErrorHTTPNotModified:
            return NO;
        default:
            return YES;
    }
}
