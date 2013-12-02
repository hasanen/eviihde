//
//  httpCache.m
//  eViihde
//
//  Created by Sami Siuruainen on 28.3.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

/**
* Copyright (c) 2009-, Sami Siuruainen / eViihde.com
* All rights reserved.
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the University of California, Berkeley nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "httpCache.h"


@implementation httpCache

sqlite3 *dbConnInternal;
int resPointer;
NSString *resContent;

bool cachePermanentDisable;
bool cacheStatus;
long bytesFromServer;
long bytesFromCache;
long totalRequests;
long cacheResponses;
long serverResponses;

- (void) cachePermanentOff {
	//NSLog(@"cache Permanently off");
	cachePermanentDisable = true;
	cacheStatus = false;
}

- (bool) isCacheActive {
	return cacheStatus;
}

- (void) cacheOff {
	cacheStatus = false;
}

- (void) cacheOn {
	if (cachePermanentDisable == true) {
		//NSLog(@"Cache Remains Off");
	} else {
		cacheStatus = true;
		//NSLog(@"cache is on");		
	}
}

- (bool) openCache {
	/* 0.7.0 FEATURE */
	NSString *UserPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *dbFileNS = [UserPath stringByAppendingPathComponent:@"Caches/eViihde.cache"];	
    NSFileManager *fileManager = [NSFileManager defaultManager];
	
    if (![fileManager fileExistsAtPath:dbFileNS]) {
		if( !sqlite3_open( [ dbFileNS cString ], &dbConnInternal) ) {
			/* No CACHE DB, creating new one */
			[ self execSQLnR:@"create table cache ( url string, content string, expire long);" ];
			sqlite3_close(dbConnInternal);
		} else {
			/* Failed to open cache file for creation, using internal DB */
			NSString *DefaultPath = [[NSBundle mainBundle] bundlePath];		
			dbFileNS = [DefaultPath stringByAppendingPathComponent:@"Contents/Resources/httpReqCache.db"];
		}
	}		
	
	if( sqlite3_open( [ dbFileNS cString ], &dbConnInternal) ){
		//NSLog(@"Can't open database: %s", sqlite3_errmsg(dbConnInternal));
		sqlite3_close(dbConnInternal);
		return false;
	}
	
	[ self execSQLR:[NSString stringWithFormat:@"delete from cache where expire < %@;", [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]]]];
	
	cacheStatus = true;
	bytesFromServer = 0;
	bytesFromCache = 0;
	totalRequests = 0;
	cacheResponses = 0;
	serverResponses = 0;
	return true;
}

- (bool) closeCache {
	/* 0.7.0 FEATURE */
	sqlite3_close(dbConnInternal);
	return true;
}

- (void) flushCache {
	[ self execSQLnR:@"delete * from cache;" ];
}

- (void) flushUrl:(NSString *)urlToFlush {
	[ self execSQLnR:[NSString stringWithFormat:@"delete from cache where url='%@';", urlToFlush] ];
}

- (NSString *) getContent:(NSString *)reqURL {
	/* 0.7.0 FEATURE */
	
	//NSLog(@"%d/%d/%d/%d/%d",bytesFromServer,bytesFromCache,totalRequests,cacheResponses,serverResponses);
	
	totalRequests++;
	if ( cacheStatus == true ) {
		[ self execSQLR:[NSString stringWithFormat:@"select content from cache where url='%@' and expire > %@;", reqURL, [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]]]];
		if ( resContent != nil) {
			cacheResponses++;
			bytesFromCache += [ resContent length ];
			return [ resContent stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		}
	}
	serverResponses++;
	return nil;
}

- (void) setContent:(NSString *)reqURL reqContent:(NSString *)reqContent {
	/* 0.7.0 FEATURE */
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString *reqContentEncoded = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)reqContent,NULL,(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",kCFStringEncodingUTF8 );
	NSString * maxAge = @"3600"; // (1h cache)
	// @"1209600"; // 14d
	//@"3600"; // 1h 
	[ self flushUrl:reqURL ];
	[ self execSQLnR:[NSString stringWithFormat:@"insert into cache (url, content, expire) values ('%@', '%@', %@+%@);", reqURL, reqContentEncoded, [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]], maxAge]];	
	bytesFromServer += [ reqContent length ];
	[ pool drain ];
	
	//char *zErrMsg;
	//char **result;
	//int rc;
	//int nrow,ncol;	
	//const char *sqlStatement =[reqURL cString];
	//rc = sqlite3_get_table(
	//					   dbConnInternal,              /* An open database */
	//					   sqlStatement,       /* SQL to be executed */
	//					   &result,       /* Result written to a char *[]  that this points to */
	//					   &nrow,             /* Number of result rows written here */
	//					   &ncol,          /* Number of result columns written here */
	//					   &zErrMsg          /* Error msg written here */
	//					   );
}

- (bool) execSQLR:(NSString *) SQL {
	/* 0.7.0 FEATURE */
	if (!dbConnInternal) {
		[self openCache];
	}
    char *zErrMsg;
    char **result;
    int rc;
    int nrow,ncol;	
	const char *sqlStatement =[SQL cString];
	rc = sqlite3_get_table(
						   dbConnInternal,              /* An open database */
						   sqlStatement,       /* SQL to be executed */
						   &result,       /* Result written to a char *[]  that this points to */
						   &nrow,             /* Number of result rows written here */
						   &ncol,          /* Number of result columns written here */
						   &zErrMsg          /* Error msg written here */
						   );
	if (( rc == SQLITE_OK ) && ( nrow != 0)) {
		//NSLog(@"%d", nrow);
		//NSLog(@"%@", [[NSString stringWithCString:(result[ncol+0])] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]);
		resContent = [NSString stringWithCString:(result[ncol+0])]; //[NSString stringWithUTF8String:(result[ncol+0])];
	} else {
		resContent = nil;
	}	
	return true;
}

- (bool) execSQLnR:(NSString *) SQL {
	/* 0.7.0 FEATURE */
	if (!dbConnInternal) {
		[self openCache];
	}
	char *zErrMsg = 0;
	int rc;
	resPointer = 0;
	rc = sqlite3_exec(dbConnInternal, [ SQL cString], nil, 0, &zErrMsg);
	if( rc!=SQLITE_OK ){
		return false;
	}
	return true;
}


@end
