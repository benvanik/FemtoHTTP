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

@class FHHTTPCookie;

/*!
 * Defines options used by an \c FHHTTPRequest.
 */
typedef enum {
    /*! \brief Close the connection after the request finishes.
     * \detail When set, existing connections will not be used and the connection established
     * to handle the request will be closed as soon as the request is complete.
     */
    FHHTTPRequestSingleUse          = 0x01,
    /*! \brief Allow response content compression.
     * \detail Let the server know it can return compressed data. More processing power will
     * be required to decode the response.
     */
    FHHTTPRequestAllowCompression   = 0x02,
    /*! \brief Automatically decompress response content.
     * \detail If the response contains compressed content (because \c FHHTTPRequestAllowCompression is set),
     * automatically decompress it before returning the response to the caller. If this is not set,
     * the content will not be decompressed until the caller explicity calls \c -decompress on the response.
     * Use this to save CPU if you don't know if you'll be using the content or not.
     */
    FHHTTPRequestAutoDecompress     = 0x04,
    /*! \brief Ignore the response body.
     * \detail If set, the response body, regardless of status code, will be dropped. Use
     * if you are expecting a redirect or error.
     * \warning It's better to use \c FHHTTPMethodHead if you just want headers because even with this set
     * every byte of the body will be read.
     */
    FHHTTPRequestIgnoreResponseBody = 0x08,
    /*! \brief Automatically redirect if needed.
     * \detail If set and the server returns a redirect, the redirect will be handled. Check the response
     * \c -redirectedFrom property to detect a redirect.
     * @todo Implement auto redirection
     */
    FHHTTPRequestAutoRedirect       = 0x10,
    /*! \brief Wait for OK before sending response body.
     * \detail If the request contains content, the server will be required to OK the headers before
     * the client will send the body (100 Continue). This can save bandwidth at the cost of latency.
     * If you know you will be sending small packets, set this flag to reduce latency.
     */
    FHHTTPRequestWaitForAcknowledge = 0x20,
    
    FHHTTPRequestDefaultOptions     = FHHTTPRequestAllowCompression | FHHTTPRequestAutoDecompress | FHHTTPRequestWaitForAcknowledge,
} FHHTTPRequestOptions;

#define FHHTTPRequestOptionIsSet( request, option ) ( ( [request options] & option ) == option )

/*!
 * A mutable HTTP request used to issue a command.
 */
@interface FHHTTPRequest : NSObject {
    NSURL*                  proxy;
    NSURL*                  url;
    NSString*               method;
    NSMutableDictionary*    headers;
    NSMutableArray*         cookies;
    NSData*                 content;
    
    FHHTTPRequestOptions    options;
    NSInteger               timeout;
    
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
 * All the cookies that will be sent to the server.
 */
@property (nonatomic, readonly) NSArray* cookies;
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
 * The option flags detailing how the request should be made and the response should be handled.
 */
@property (nonatomic) FHHTTPRequestOptions options;
/*!
 * The timeout, in seconds, for the request. Defaults to \c FH_DEFAULT_TIMEOUT.
 * \warning Use a consistent value for this - the timeout is only guaranteed to take affect on new connections.
 * @todo Propigate timeout to socket - currently it only affects keep-alive.
 */
@property (nonatomic) NSInteger timeout;

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
 * Add a list of cookies to the request.
 * @param newCookies A list of cookies.
 */
- (void) addCookies:(NSArray*)newCookies;
/*!
 * Add a cookie to the request.
 * @param cookie The cookie to add.
 */
- (void) addCookie:(FHHTTPCookie*)cookie;
/*!
 * Get the cookie for the given name.
 * @param name The name of the cookie to look up.
 * @return The cookie with the given name or \c nil if not present.
 */
- (FHHTTPCookie*) cookieWithName:(NSString*)name;
/*!
 * Remove the given cookie from the request.
 * @param cookie The cookie to remove.
 */
- (void) removeCookie:(FHHTTPCookie*)cookie;
/*!
 * Remove all cookies from the request.
 */
- (void) removeAllCookies;

/*!
 * The string contents of the request.
 * @return The HTTP header contents.
 */
- (NSString*) description;

@end
