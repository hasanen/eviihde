//
//  curlier.h
//  curlier
//
//  Created by Sami Siuruainen on 24.12.2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

id refToSelf;

@interface curlier : NSObject {
	NSMutableString * sourceURL;
	NSMutableString * destinationFile;
	NSMutableString * _destinationPath;
	NSMutableString * _destinationFile;
	int _maxSpeed;
	CURL *mCURL;
	BOOL curlActive;	
	@private NSMutableString * _curStatus;
	long long downloaded;
	long long fileSize;
	NSNumber * startedAt;		

	long long _lastUpdate;
	float _lastSize;
}

//- (curlier *) url:(NSMutableString *) url destinationPath:(NSMutableString *) destinationPath saveAs:(NSMutableString *) saveAs maxSpeed:(int) maxSpeed;
- (void) url:(NSMutableString *) url destinationPath:(NSMutableString *) destinationPath saveAs:(NSMutableString *) saveAs maxSpeed:(int) maxSpeed;
- (id) init;
- (void) curl_main:(id)param;
- (NSMutableString *) chkStat;
- (BOOL) isActive;
- (BOOL) stop;
- (BOOL) choke:(int) allowedSpeed;
- (void) start;
- (NSMutableString *) getDestination;
- (NSMutableString *) getDestinationPath;
- (void) setCurStatus:(double) downloaded fileSize:(double) fileSize;
- (CURL *) curl;

//static size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream);
//static int progress_func(void* ptr, double TotalToDownload, double NowDownloaded, double TotalToUpload, double NowUploaded);

@end
