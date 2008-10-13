//
//  FHHTTPRequest.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

/*! \file
 * \brief Structures related to HTTP requests.
 */

/*!
 * A mutable HTTP request used to issue a command.
 */
@interface FHHTTPRequest : NSObject {
    NSURL*                  proxy;
    NSURL*                  url;
    NSString*               method;
    NSMutableDictionary*    headers;
    NSData*                 content;
    
    BOOL                    singleUse;
    
    NSDateFormatter*        dateFormatter;
}

/*!
 * The URL of the HTTP proxy to use for the request.
 */
@property (nonatomic, retain) NSURL* proxy;
/*!
 * The fully-qualified URL of the request.
 */
@property (nonatomic, retain) NSURL* url;
/*!
 * The HTTP method of the request. See \c FHHTTPMethodGet, \c FHHTTPMethodGet, or \c FHHTTPMethodPost.
 */
@property (nonatomic, retain) NSString* method;
/*!
 * All header/value pairs that will be sent to the server. Keys will be normalized before being sent.
 */
@property (nonatomic, readonly) NSDictionary* headers;
/*!
 * The data to send to the server.
 */
@property (nonatomic, retain) NSData* content;
/*!
 * The data to send to the server in string form.
 * \warning The result of this property requires conversion and may be slow.
 */
@property (nonatomic, retain) NSString* contentAsString;

/*!
 * YES if the connection should be thrown out after the request completes. Disables keep alives for the current request only.
 */
@property (nonatomic) BOOL singleUse;

/*!
 * The referer of the request.
 */
@property (nonatomic, retain) NSString* referer;
/*!
 * The content type (MIME type) of the request content.
 */
@property (nonatomic, retain) NSString* contentType;
/*!
 * If set, \c FHErrorHTTPNotModified will be returned if the content has not changed since the given date.
 */
@property (nonatomic, retain) NSDate* ifModifiedSince;

/*!
 * Initialize a request.
 */
- (id) init;
/*!
 * Initializes a request with the given parameters.
 * @param url The URL to make the request to.
 */
- (id) initWithURL:(NSURL*)url;
/*!
 * Initializes a request with the given parameters.
 * @param url The URL to make the request to.
 * @param content The content to include with the request.
 */
- (id) initWithURL:(NSURL*)url andContent:(NSData*)content;

/*!
 * Create and return a request with the given parameters.
 * @param url The URL to make the request to.
 * @return A new request initialized with the given parameters.
 */
+ (FHHTTPRequest*) requestWithURL:(NSURL*)url;
/*!
 * Create and return a request with the given parameters.
 * @param url The URL to make the request to.
 * @param content The content to include with the request.
 * @return A new request initialized with the given parameters.
 */
+ (FHHTTPRequest*) requestWithURL:(NSURL*)url andContent:(NSData*)content;

/*!
 * Add a list of headers to the request.
 * @param newHeaders A header list in key/value pairs to add.
 */
- (void) addHeaders:(NSDictionary*)newHeaders;
/*!
 * Add the given header to the request.
 * @param key The key for the header.
 * @param value The value of the header.
 */
- (void) addHeader:(NSString*)key withValue:(NSString*)value;
/*!
 * Get the value for the given header key.
 * @param key The key of the header to look up.
 * @return The value of the header with the given key or \c nil if not present.
 */
- (NSString*) valueForHeader:(NSString*)key;
/*!
 * Remove the given header from the request.
 * @param key The key of the header to remove.
 */
- (void) removeHeader:(NSString*)key;
/*!
 * Remove all headers from the request.
 */
- (void) removeAllHeaders;

/*!
 * The string contents of the request.
 * @return The HTTP header contents.
 */
- (NSString*) description;

@end
