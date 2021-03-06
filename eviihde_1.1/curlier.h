//
//  curlier.h
//  curlier
//
//  Created by Sami Siuruainen on 24.12.2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
*     * Neither the name of the Sami Siuruainen / eViihde.com nor the
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
