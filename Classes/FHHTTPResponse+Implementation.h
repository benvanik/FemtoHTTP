//
//  FHHTTPResponse+Implementation.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FHHTTPResponse.h"

@interface FHHTTPResponse (Implementation)

- (id) initWithURL:(NSURL*)url
           headers:(NSDictionary*)headers
        statusCode:(FHErrorCode)statusCode
      statusReason:(NSString*)statusReason
           content:(NSData*)content
    autoDecompress:(BOOL)autoDecompress;

- (void) setIsRedirectFrom:(NSURL*)originalURL;

@end
