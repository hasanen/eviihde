//
//  watched_db.m
//  eViihde
//
//  Created by Sami Siuruainen on 20.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

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
