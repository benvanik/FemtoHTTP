//
//  FHHostEntry.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FHTCPSocket;

@interface FHHostEntry : NSObject {
    NSCondition*    lock;
    
    NSString*       hostName;
    NSInteger       port;
    BOOL            supportsPooling;
    NSInteger       maximumConnections;
    
    NSMutableArray* openedSockets;
    NSMutableArray* idleSockets;
}

@property (nonatomic, readonly) NSString* hostName;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic) BOOL supportsPooling;
@property (nonatomic) NSInteger maximumConnections;

@property (nonatomic, readonly) NSArray* openedSockets;
@property (nonatomic, readonly) NSArray* idleSockets;

- (id) initWithHostName:(NSString*)hostName andPort:(NSInteger)port;

- (FHTCPSocket*) openSocket:(BOOL)allowReuse errorCode:(FHErrorCode*)outErrorCode wasReused:(BOOL*)outWasReused;
- (void) closeSocket:(FHTCPSocket*)socket closeConnection:(BOOL)closeConnection;

- (void) closeDeadConnections;
- (void) closeAllConnections;

@end
