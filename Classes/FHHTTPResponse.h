//
//  FHHTTPResponse.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHHTTPResponse : NSObject {
    NSDictionary*   headers;
    FHErrorCode     statusCode;
    NSString*       statusReason;
    
    NSString*       location;
    NSDate*         lastModified;
    NSString*       contentType;

    NSData*         content;
}

// all headers are lowercase - values are whatever they were
@property (nonatomic, readonly) NSDictionary* headers;
@property (nonatomic, readonly) FHErrorCode statusCode;
@property (nonatomic, readonly) NSString* statusReason;

// used for redirects 3xx
@property (nonatomic, readonly) NSString* location;
@property (nonatomic, readonly) NSDate* lastModified;
// may contain extra after ;, use mimeType for just mime type
@property (nonatomic, readonly) NSString* contentType;

@property (nonatomic, readonly) NSData* content;

- (NSString*) valueForHeader:(NSString*)key;
- (NSString*) mimeType;
- (NSString*) contentAsString;

@end
