//
//  FHSharedObjects.h
//  FemtoHTTP
//
//  Created by Ben Vanik on 11/15/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSharedObjects : NSObject {
}

// Gets a per-thread date formatter instance with the format EEE, dd MMM yyyy HH:mm:ss zzz
+ (NSDateFormatter*) dateFormatter;

@end
