//
//  FHSharedObjects.m
//  FemtoHTTP
//
//  Created by Ben Vanik on 11/15/08.
//  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
//

#import "FHSharedObjects.h"

@implementation FHSharedObjects

+ (NSDateFormatter*) dateFormatter
{
    NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter* dateFormatter = [dictionary objectForKey:@"FHDateFormatter"];
    if( dateFormatter == nil )
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dictionary setObject:dateFormatter forKey:@"FHDateFormatter"];
        [dateFormatter autorelease];
    }
    return dateFormatter;
}

@end
