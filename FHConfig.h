//
//  FHConfig.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

/*! \file
 * \brief Configuration options used to build FemtoHTTP.
 * \details Changing these has no affect on an already compiled library.
 */

/*!
 * \def FH_DEBUG_OUTPUT
 * If defined, tons of debug spew will be produced.
 */
#define FH_DEBUG_OUTPUT

/*!
 * \def FH_DEFAULT_MAXIMUM_CONNECTIONS
 * The default number of maximum connections for a given host.
 */
#define FH_DEFAULT_MAXIMUM_CONNECTIONS  5

/*!
 * \def FH_DEFAULT_TIMEOUT
 * The default timeout (in seconds).
 */
#define FH_DEFAULT_TIMEOUT              120
