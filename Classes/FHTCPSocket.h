//
//  FHTCPSocket.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHTCPSocket : NSObject {
    NSString*   hostName;
    NSInteger   port;
    NSInteger   timeout;
    BOOL        singleUse;
    int         fd;
    FHErrorCode errorCode;
    
    NSMutableData*  buffer;

@public
    // Used for dtrace probes
    NSInteger   identifier;
}

@property (nonatomic, readonly) NSString* hostName;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic) NSInteger timeout;
@property (nonatomic) BOOL singleUse;
@property (nonatomic, readonly) int fd;
@property (nonatomic, readonly) FHErrorCode errorCode;

// Does no heavy work - save inside locks
- (id) initWithHostName:(NSString*)hostName andPort:(NSInteger)port;

+ (FHErrorCode) lookupHostName:(NSString*)hostName hostent:(struct hostent**)outHostent;

- (FHErrorCode) open;
- (FHErrorCode) openWithHostent:(struct hostent*)host;
- (FHErrorCode) queryStatus;
- (FHErrorCode) waitUntilDataPresent;
- (void) reset;
- (void) close;

- (FHErrorCode) skipBytes:(NSInteger)length;
- (NSString*) readLine;
- (NSData*) readData:(NSInteger)length;
- (NSInteger) readBytes:(void*)bytes length:(NSInteger)length;
- (FHErrorCode) readIntoData:(NSMutableData*)data length:(NSInteger)length;

- (FHErrorCode) writeNewLine;
- (FHErrorCode) writeString:(NSString*)string;
- (FHErrorCode) writeData:(NSData*)data;
- (FHErrorCode) writeBytes:(const void*)bytes length:(NSInteger)length;

@end
