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
