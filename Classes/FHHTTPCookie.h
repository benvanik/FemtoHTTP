//
//  FHHTTPCookie.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/13/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

/*! \file
 * \brief Structures related to HTTP cookies.
 */

/*!
 * An HTTP cookie.
 */
@interface FHHTTPCookie : NSObject {
    NSString*   name;
    NSString*   value;
    NSDate*     expires;
    NSString*   path;
    NSString*   domain;
    
    BOOL        isSecure;
    BOOL        isHTTPOnly;
}

/*!
 * The user-defined name for the cookie.
 */
@property (nonatomic, retain) NSString* name;
/*!
 * The user-defined value for the cookie.
 */
@property (nonatomic, retain) NSString* value;
/*!
 * The date the cookie expires or \c nil if it expires after the current session.
 */
@property (nonatomic, readonly) NSDate* expires;
/*!
 * The path the cookie applies to.
 */
@property (nonatomic, readonly) NSString* path;
/*!
 * The domain the cookie applies to.
 */
@property (nonatomic, readonly) NSString* domain;
/*!
 * \c YES if the cookie is only valid over HTTPS.
 */
@property (nonatomic, readonly) BOOL isSecure;
/*!
 * \c YES if the cookie is to be hidden from script.
 */
@property (nonatomic, readonly) BOOL isHTTPOnly;

/*!
 * Initialize a cookie.
 */
- (id) init;
/*!
 * Initializes a cookie with the given parameters.
 * @param name The name of the cookie.
 * @param value The value of the cookie.
 */
- (id) initWithName:(NSString*)name andValue:(NSString*)value;
/*!
 * Initializes a cookie with the given HTTP cookie.
 * @param httpCookie An HTTP cookie string, ex. <tt>name=newvalue; expires=date; path=/; domain=.example.org</tt>.
 */
- (id) initWithHTTPCookie:(NSString*)httpCookie;

/*!
 * Create and return a cookie with the given parameters.
 * @param name The name of the cookie.
 * @param value The value of the cookie.
 * @return A new cookie initialized with the given parameters.
 */
+ (FHHTTPCookie*) cookieWithName:(NSString*)name andValue:(NSString*)value;
/*!
 * Create and return a cookie with the given HTTP cookie.
 * @param httpCookie An HTTP cookie string, ex. <tt>name=newvalue; expires=date; path=/; domain=.example.org</tt>.
 * @return A new cookie initialized with the given parameters.
 */
+ (FHHTTPCookie*) cookieWithHTTPCookie:(NSString*)httpCookie;

/*!
 * The string contents of the cookie.
 * @return The HTTP cookie contents.
 */
- (NSString*) description;

@end
