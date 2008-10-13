//
//  FHHTTPRequest.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHHTTPRequest : NSObject {
    NSURL*                  url;
    NSString*               method;
    NSMutableDictionary*    headers;
    NSData*                 content;
    
    NSURL*                  proxy;
    NSString*               proxyUserName;
    NSString*               proxyPassword;
    
    BOOL                    singleUse;
    
    NSDateFormatter*        dateFormatter;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* method;
@property (nonatomic, readonly) NSDictionary* headers;
@property (nonatomic, retain) NSData* content;

@property (nonatomic, retain) NSURL* proxy;
@property (nonatomic, retain) NSString* proxyUserName;
@property (nonatomic, retain) NSString* proxyPassword;

@property (nonatomic) BOOL singleUse;

- (id) init;
- (id) initWithURL:(NSURL*)url;
- (id) initWithURL:(NSURL*)url andContent:(NSData*)content;

+ (FHHTTPRequest*) requestWithURL:(NSURL*)url;
+ (FHHTTPRequest*) requestWithURL:(NSURL*)url andContent:(NSData*)content;

- (void) addHeaders:(NSDictionary*)newHeaders;
- (void) addHeader:(NSString*)key withValue:(NSString*)value;
- (NSString*) valueForHeader:(NSString*)key;
- (void) removeHeader:(NSString*)key;
- (void) removeAllHeaders;

- (NSString*) referer;
- (void) setReferer:(NSString*)value;
- (NSString*) contentType;
- (void) setContentType:(NSString*)value;
- (NSDate*) ifModifiedSince;
- (void) setIfModifiedSince:(NSDate*)value;

- (NSString*) contentAsString;
- (void) setContentWithString:(NSString*)value;

- (NSString*) description;

@end
