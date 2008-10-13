//
//  FHHTTPConnection.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

/*! \file
 * \brief HTTP connection control.
 */

@class FHHTTPRequest;
@class FHHTTPResponse;

/*!
 * Utility class for issuing HTTP commands.
 */
@interface FHHTTPConnection : NSObject {

}

/*!
 * Issue an HTTP request and synchronously receive a response.
 * @param request The request to issue.
 * @param[out] outResponse The response returned, if successful.
 * @return An error code; if \c FHErrorOK the call was successful, otherwise it failed.
 * \warning The caller may reuse the request but only after the call returns.
 */
+ (FHErrorCode) issueRequest:(FHHTTPRequest*)request returningResponse:(FHHTTPResponse**)outResponse;

@end
