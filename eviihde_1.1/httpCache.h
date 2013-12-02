//
//  httpCache.h
//  eViihde
//
//  Created by Sami Siuruainen on 28.3.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface httpCache : NSObject {

}

- (bool) execSQLR:(NSString *) SQL;
- (bool) execSQLnR:(NSString *) SQL;
	
- (bool) openCache;
- (bool) isCacheActive;
- (void) cacheOff;
- (void) cacheOn;
- (void) cachePermanentOff;
- (bool) closeCache;
- (void) flushCache;
- (void) flushUrl:(NSString *)urlToFlush;
- (NSString *) getContent:(NSString *)reqURL;
- (void) setContent:(NSString *)reqURL reqContent:(NSString *)reqContent;

@end
