//
//  FHHTTPRequest+Implementation.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FHHTTPRequest.h"

@interface FHHTTPRequest (Implementation)

// result is retained, not autoreleased!
- (NSString*) generate;

@end
