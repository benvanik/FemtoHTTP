//
//  FHErrorCodes.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FHErrorDomainUnknown,
    FHErrorDomainInternal,
    FHErrorDomainSocket,
    FHErrorDomainHTTP,
} FHErrorDomain;


typedef enum {
    
    FHErrorOK                       = 0,
    
    // -- FHErrorDomainInternal --
    
    FHErrorInternalUnknown          = -100,
    FHErrorInternalHostNotFound     = -101,
    FHErrorInternalOutOfMemory      = -102,
    FHErrorInternalUnsupported      = -103,
    FHErrorInternalAccessDenied     = -104,
    FHErrorInternalInvalidState     = -105,
    FHErrorInternalInvalidArguments = -106,
    FHErrorInternalNotImplemented   = -107,
    FHErrorInternalUnableToParse    = -108,
    
    // -- FHErrorDomainSocket --
    
    FHErrorSocketHostNotFound       = -200,
    FHErrorSocketNetworkDown        = -201,
    FHErrorSocketHostUnreachable    = -202,
    FHErrorSocketTimeout            = -203,
    FHErrorSocketDisconnected       = -204,
    
    // -- FHErrorDomainHTTP --
    
    FHErrorHTTPContinue             = 100,
    
    FHErrorHTTPOK                   = 200,
    FHErrorHTTPOKNoContent          = 204,
    FHErrorHTTPOKPartialContent     = 206,
    
    FHErrorHTTPMovedPermanently     = 301,
    FHErrorHTTPFound                = 302,
    FHErrorHTTPNotModified          = 304,
    FHErrorHTTPUseProxy             = 305,
    FHErrorHTTPTemporaryRedirect    = 307,
    
    FHErrorHTTPBadRequest           = 400,
    FHErrorHTTPNotAuthorized        = 401,
    FHErrorHTTPForbidden            = 403,
    FHErrorHTTPNotFound             = 404,
    FHErrorHTTPProxyAuthRequired    = 407,
    FHErrorHTTPRequestTimeout       = 408,
    
    FHErrorHTTPInternalServerError  = 500,
    FHErrorHTTPNotImplemented       = 501,
    FHErrorHTTPBadGateway           = 502,
    FHErrorHTTPServiceUnavailable   = 503,
    FHErrorHTTPGatewayTimeout       = 504,
    
} FHErrorCode;

FHErrorDomain FHErrorGetDomain( FHErrorCode code );
NSString* FHErrorGetDomainName( FHErrorDomain domain );
NSString* FHErrorGetName( FHErrorCode code );

BOOL FHErrorIsFatal( FHErrorCode code );
BOOL FHErrorCanRetry( FHErrorCode code );

BOOL FHErrorIsHTTPOK( FHErrorCode code );
BOOL FHErrorIsHTTPRedirect( FHErrorCode code );
BOOL FHErrorHTTPHasContent( FHErrorCode code );
