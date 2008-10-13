//
//  FHHTTPConnection.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FHHTTPRequest;
@class FHHTTPResponse;

@interface FHHTTPConnection : NSObject {

}

+ (FHErrorCode) issueRequest:(FHHTTPRequest*)request returningResponse:(FHHTTPResponse**)outResponse;

@end
