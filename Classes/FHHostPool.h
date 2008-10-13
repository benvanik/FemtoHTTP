//
//  FHHostPool.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 10/12/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FHHostEntry;

@interface FHHostPool : NSObject {
    NSLock*                 lock;
    NSMutableDictionary*    hosts;
}

+ (FHHostPool*) sharedHostPool;

- (FHHostEntry*) hostForURL:(NSURL*)url;
- (void) removeAllHosts;

@end
