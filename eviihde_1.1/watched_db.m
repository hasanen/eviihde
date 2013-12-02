//
//  watched_db.m
//  eViihde
//
//  Created by Sami Siuruainen on 20.10.2010.
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

#import "watched_db.h"


@implementation watched_db

- (id) init {
	self = [super init];
 	if ( self ) {
		[ self openDB ];
	}
	return self;
}

- (bool) openDB {
	NSString *UserPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *dbFileNS = [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Watched.db"];	
    NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager changeCurrentDirectoryPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde"] ] == NO) {
		NSError * fmError = nil;
		[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde"] withIntermediateDirectories:YES attributes: nil error:&fmError];		
		//[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde"] attributes: nil];		
	}

    if (![fileManager fileExistsAtPath:dbFileNS]) {
		if( !sqlite3_open( [ dbFileNS UTF8String ], &dbConnInternal) ) {
			/* No CACHE DB, creating new one */
			[ self execSQLnR:@"create table watched ( video_id string, watched_stamp string );" ];
			sqlite3_close(dbConnInternal);
		}
	}		
	
	if( sqlite3_open( [ dbFileNS UTF8String ], &dbConnInternal) ){
		NSLog(@"Can't open database: %s", sqlite3_errmsg(dbConnInternal));
		sqlite3_close(dbConnInternal);
		return false;
	}	
	return true;
}

- (bool) closeDB {
	sqlite3_close(dbConnInternal);
	return true;
}

- (BOOL) isWatched:(NSString *) recID {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self execSQLR:[NSString stringWithFormat:@"select video_id from watched where video_id='%@';", recID]];
	if ( resContent != nil) return true;
	return false;
	[ pool drain ];
}

- (void) setIsWatched:(NSString *) recID {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self execSQLnR:[NSString stringWithFormat:@"insert into watched (video_id, watched_stamp) values ('%@', '%@');", recID, [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]]]];	
	[ pool drain ];
}

- (void) setIsNotWatched:(NSString *) recID {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self execSQLnR:[NSString stringWithFormat:@"delete from watched where video_id='%@';", recID] ];	
	[ pool drain ];	
}

- (bool) execSQLR:(NSString *) SQL {
	/* 0.7.0 FEATURE */
    char *zErrMsg;
    char **result;
    int rc;
    int nrow,ncol;	
	const char *sqlStatement =[SQL UTF8String];
	rc = sqlite3_get_table(
						   dbConnInternal,              /* An open database */
						   sqlStatement,       /* SQL to be executed */
						   &result,       /* Result written to a char *[]  that this points to */
						   &nrow,             /* Number of result rows written here */
						   &ncol,          /* Number of result columns written here */
						   &zErrMsg          /* Error msg written here */
						   );
	if (( rc == SQLITE_OK ) && ( nrow != 0)) {
		resContent = [NSString stringWithUTF8String:(result[ncol+0])];
	} else {
		resContent = nil;
	}	
	return true;
}

- (bool) execSQLnR:(NSString *) SQL {
	/* 0.7.0 FEATURE */
	char *zErrMsg = 0;
	int rc;
	resPointer = 0;
	rc = sqlite3_exec(dbConnInternal, [ SQL UTF8String], nil, 0, &zErrMsg);
	if( rc!=SQLITE_OK ){
		return false;
	}
	return true;
}


@end
