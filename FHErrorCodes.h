//
//  FHErrorCodes.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

/*! \file
 * \brief Error codes and helper routines.
 */

/*!
 * An error domain, denoting the general category of an error.
 */
typedef enum {
    FHErrorDomainUnknown,           /*!< Generic, unknown error domain. */
    FHErrorDomainInternal,          /*!< Internal/application error. */
    FHErrorDomainSocket,            /*!< Socket-related (IP/TCP/etc) error. */
    FHErrorDomainHTTP,              /*!< HTTP protocol related error. */
} FHErrorDomain;

/*!
 * A recognized error code value.
 */
typedef enum {
    
    FHErrorOK                       = 0,        /*!< Success - no error occurred. */
    
    FHErrorInternalUnknown          = -100,     /*!< An unknown error occurred. */
    FHErrorInternalOutOfMemory      = -101,     /*!< An allocation failed do to low memory/resources. */
    FHErrorInternalUnsupported      = -102,     /*!< The operation is unsupported by the underlying system. */
    FHErrorInternalAccessDenied     = -103,     /*!< Access is denied to the requested resource. */
    FHErrorInternalInvalidState     = -104,     /*!< The system is in an invalid state to perform the given request. */
    FHErrorInternalInvalidArguments = -105,     /*!< The arguments given are invalid. */
    FHErrorInternalNotImplemented   = -106,     /*!< The requested action is not yet implemented. */
    FHErrorInternalUnableToParse    = -107,     /*!< A parsing error occured (malformed data?). */
    
    FHErrorSocketHostNotFound       = -200,     /*!< The given host name could not be resolved. */
    FHErrorSocketNetworkDown        = -201,     /*!< The local network is down. */
    FHErrorSocketHostUnreachable    = -202,     /*!< The given host is unreachable. */
    FHErrorSocketTimeout            = -203,     /*!< A timeout occurred while trying to perform the requested operation. */
    FHErrorSocketDisconnected       = -204,     /*!< The target socket is disconnected. */
    
    FHErrorHTTPContinue             = 100,      /*!<  */
    
    FHErrorHTTPOK                   = 200,      /*!<  */
    FHErrorHTTPOKNoContent          = 204,      /*!<  */
    FHErrorHTTPOKPartialContent     = 206,      /*!<  */
    
    FHErrorHTTPMovedPermanently     = 301,      /*!<  */
    FHErrorHTTPFound                = 302,      /*!<  */
    FHErrorHTTPNotModified          = 304,      /*!<  */
    FHErrorHTTPUseProxy             = 305,      /*!<  */
    FHErrorHTTPTemporaryRedirect    = 307,      /*!<  */
    
    FHErrorHTTPBadRequest           = 400,      /*!<  */
    FHErrorHTTPNotAuthorized        = 401,      /*!<  */
    FHErrorHTTPForbidden            = 403,      /*!<  */
    FHErrorHTTPNotFound             = 404,      /*!<  */
    FHErrorHTTPProxyAuthRequired    = 407,      /*!<  */
    FHErrorHTTPRequestTimeout       = 408,      /*!<  */
    
    FHErrorHTTPInternalServerError  = 500,      /*!<  */
    FHErrorHTTPNotImplemented       = 501,      /*!<  */
    FHErrorHTTPBadGateway           = 502,      /*!<  */
    FHErrorHTTPServiceUnavailable   = 503,      /*!<  */
    FHErrorHTTPGatewayTimeout       = 504,      /*!<  */
    
} FHErrorCode;

/*!
 * Get the domain the given error code is in.
 * @param code The error code to look up.
 * @return The domain the error code is in or \c FHErrorDomainUnknown if not found.
 */
FHErrorDomain FHErrorGetDomain( FHErrorCode code );

/*!
 * Get a human-readable name for the given error domain.
 * @param domain The error domain to look up.
 * @return The name of the domain.
 */
NSString* FHErrorGetDomainName( FHErrorDomain domain );

/*!
 * Get a human-readable name for the given error code.
 * @param code The error code to look up.
 * @return The name of the error code or \c nil if not found.
 */
NSString* FHErrorGetName( FHErrorCode code );

/*!
 * Determine whether or not the given error code is fatal.
 * @param code The error code to look up.
 * @return YES if the error is fatal.
 */
BOOL FHErrorIsFatal( FHErrorCode code );

/*!
 * Determine if the request can be retried after receiving the given error code.
 * @param code The error code to look up.
 * @return YES if the requst can be retried.
 */
BOOL FHErrorCanRetry( FHErrorCode code );

/*!
 * Check to see if the given HTTP status code is a success.
 * @param code The error code to look up.
 * @return YES if the given code is an HTTP success.
 */
BOOL FHErrorIsHTTPOK( FHErrorCode code );
 
/*!
 * Check to see if the given HTTP status code indicates that a redirect is required.
 * @param code The error code to look up.
 * @return YES if the given code indicates that an HTTP redirect is required.
 */
BOOL FHErrorIsHTTPRedirect( FHErrorCode code );

/*!
 * Determine if the HTTP response may have content based on the status code.
 * @param code The error code to look up.
 * @return YES if there's a good chance the response will have content.
 */
BOOL FHErrorHTTPHasContent( FHErrorCode code );
