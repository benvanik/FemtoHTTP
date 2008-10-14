//
//  FHConstants.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

/*! \file
 * \brief Constant values exported by FemtoHTTP.
 */

#define FEMTOHTTP_EXPORT    extern

/*!
 * \var NSString* const FHHTTPMethodGet
 * The HTTP 'GET' method.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPMethodGet;

/*!
 * \var NSString* const FHHTTPMethodPost
 * The HTTP 'POST' method.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPMethodPost;

/*!
 * \var NSString* const FHHTTPMethodHead
 * The HTTP 'HEAD' method.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPMethodHead;

/*!
 * \var NSString* const FHHTTPContentEncodingIdentity
 * \brief HTTP 'identity' Content-Encoding header value.
 * \details Denotes that the content is in its original form.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPContentEncodingIdentity;

/*!
 * \var NSString* const FHHTTPContentEncodingGZIP
 * \brief HTTP 'gzip' Content-Encoding header value.
 * \details Denotes that the content is gzip compressed.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPContentEncodingGZIP;

/*!
 * \var NSString* const FHHTTPContentEncodingDeflate
 * \brief HTTP 'deflate' Content-Encoding header value.
 * \details Denotes that the content is deflated.
 */
FEMTOHTTP_EXPORT NSString* const FHHTTPContentEncodingDeflate;
