//
//  watched_db.h
//  eViihde
//
//  Created by Sami Siuruainen on 20.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

@interface watched_db : NSObject {
	sqlite3 *dbConnInternal;
	int resPointer;
	NSString *resContent;
	
}

- (bool) execSQLR:(NSString *) SQL;
- (bool) execSQLnR:(NSString *) SQL;
- (bool) openDB;
- (bool) closeDB;

- (BOOL) isWatched:(NSString *) recID;
- (void) setIsWatched:(NSString *) recID;
- (void) setIsNotWatched:(NSString *) recID;
	

@end
