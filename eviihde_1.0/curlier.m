//
//  curlier.m
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


#import "curlier.h"

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    size_t written;
    written = fwrite(ptr, size, nmemb, stream);
	//downloaded = downloaded + written;
    return written;
}

int progress_func(void* ptr, double TotalToDownload, double NowDownloaded, double TotalToUpload, double NowUploaded)
{
	[ refToSelf setCurStatus:NowDownloaded fileSize:TotalToDownload ];
	//downloaded = NowDownloaded;
	//fileSize = TotalToDownload;
    // It's here you will write the code for the progress message or bar
	//NSLog(@"%g : %g", TotalToDownload, NowDownloaded);
	return 0;
}

@implementation curlier

- (CURL *) curl
{
	return mCURL;
}

- (void) setCurStatus:(double) _downloaded fileSize:(double) _fileSize {
	if (curlActive == YES) {
		long long dl_timediff = [NSDate timeIntervalSinceReferenceDate] - [ startedAt longValue ];
		float f_speed = (float) _downloaded/1024/1024/dl_timediff;
		float f_total = (float) _fileSize/1024/1024;
		float f_done = (float) _downloaded/1024/1024;
		[ _curStatus setString:[ [NSString alloc] initWithFormat:@"%.2f MB/%.2f MB %.2f MB/s", f_done, f_total, f_speed]];
	} else {
		[ _curStatus setString:[ NSMutableString stringWithFormat:@"Pysäytetty" ]];
	}	
}

- (id) init
{
	self = [super init];
	refToSelf = self;
	return self;
}

- (void) url:(NSMutableString *) url destinationPath:(NSMutableString *) destinationPath saveAs:(NSMutableString *) saveAs maxSpeed:(int) maxSpeed {
	self = [super init];
	
    if ( self ) {
		sourceURL = [ [ NSMutableString alloc] initWithString:url ];
		destinationFile = [ [NSMutableString alloc] initWithFormat:@"%@/%@", destinationPath, saveAs];
		_destinationPath = [ [ NSMutableString alloc] initWithString:destinationPath ];
		_destinationFile = [ [ NSMutableString alloc] initWithString:saveAs ];
		_maxSpeed = maxSpeed;
		_curStatus = [ [NSMutableString alloc] initWithString:@"" ];
		mCURL = curl_easy_init();
		
		[ self start ];
	}
	//return self;
}

- (void) start {
    refToSelf = self;
	[NSThread detachNewThreadSelector:@selector(curl_main:) toTarget:self withObject:nil];	
}

- (NSMutableString *) chkStat {	
	if (curlActive == YES) {
		NSFileManager *man = [[NSFileManager alloc] init];
		NSDictionary *attrs = [man attributesOfItemAtPath:[ NSString stringWithFormat:@"%@.download", destinationFile] error: NULL];
	
		long long avg_dl_timediff = [NSDate timeIntervalSinceReferenceDate] - [ startedAt longLongValue ];
		float avg_f_speed = [attrs fileSize]/avg_dl_timediff;
		
		long long dl_timediff = [NSDate timeIntervalSinceReferenceDate] - _lastUpdate;
		float f_speed = ([attrs fileSize] - _lastSize) / dl_timediff;		
		
		float floatSize = [attrs fileSize];
		floatSize = floatSize / 1024 / 1024;
		
		_lastUpdate = [NSDate timeIntervalSinceReferenceDate];
		_lastSize = [attrs fileSize];

		NSMutableString *dlPer = [ [NSString alloc] initWithFormat:@"%1.1f MB (%1.3f MB/s, avg: %1.3f MB/s)", floatSize, (f_speed/1024/1024), (avg_f_speed/1024/1024)];
		return dlPer;
	} else {
		return [ NSMutableString stringWithFormat:@"Pysäytetty" ];
	}
	
	/*
		NSMutableString *dlPer = [ [NSString alloc] initWithFormat:@"%.2f MB/%.2f MB %.2f MB/s", f_done, f_total, f_speed];
	}*/
}

- (NSMutableString *) getDestination {
	return _destinationFile;
}

- (NSMutableString *) getDestinationPath {
	return _destinationPath;
}

- (BOOL) stop {
	if (curlActive == YES) {
		curlActive = NO;
		curl_easy_reset([ self curl ]);
		unlink([ [ NSString stringWithFormat:@"%@.download", destinationFile] UTF8String]);
		return YES;
	}
	return NO;
}

- (BOOL) isActive {
	return curlActive;
}

- (BOOL) choke:(int) allowedSpeed {
	curl_easy_setopt([ self curl ], CURLOPT_MAX_RECV_SPEED_LARGE, allowedSpeed);
	return YES;
}

- (void) curl_main:(id)param {
	curlActive = YES;
    FILE *fp;
    CURLcode res;
	
    const char *url = [sourceURL UTF8String];
    const char * outfilename = [ [ NSString stringWithFormat:@"%@.download", destinationFile] UTF8String];
    if (mCURL) {
        fp = fopen(outfilename,"wb");
		if (fp) {
			curl_easy_setopt(mCURL, CURLOPT_URL, url);
			curl_easy_setopt(mCURL, CURLOPT_WRITEFUNCTION, write_data);
			curl_easy_setopt(mCURL, CURLOPT_NOPROGRESS, TRUE);
			curl_easy_setopt(mCURL, CURLOPT_FOLLOWLOCATION, TRUE);
			curl_easy_setopt(mCURL, CURLOPT_MAXREDIRS, 10); 
			//curl_easy_setopt(mCURL, CURLOPT_PROGRESSFUNCTION, progress_func);
			curl_easy_setopt(mCURL, CURLOPT_WRITEDATA, fp);
			curl_easy_setopt(mCURL, CURLOPT_MAX_RECV_SPEED_LARGE, _maxSpeed);
			startedAt = [ NSNumber numberWithLong: [NSDate timeIntervalSinceReferenceDate] ] ;

#ifdef DEBUG
 			FILE *headerfile = fopen([ [ NSString stringWithFormat:@"%@.download.log", destinationFile] UTF8String],"w");
			curl_easy_setopt(mCURL, CURLOPT_WRITEHEADER, headerfile);
#endif
			
			res = curl_easy_perform(mCURL);

#ifdef DEBUG
			long http_code;
			curl_easy_getinfo(mCURL, CURLINFO_RESPONSE_CODE, &http_code);
			NSLog(@"curlRes : %u / %lu", res, http_code);
			fclose(headerfile);
#endif
			curl_easy_cleanup(mCURL);
			fclose(fp);			
		} else {
			NSLog(@"file.open failure");
		}
    }
	if (curlActive == YES) {
		rename(outfilename, [ destinationFile UTF8String ]);		
	}
	//[ self chkStat:nil ];
	curlActive = NO;
	// move *.download to final file
	//NSLog(@"download complete, renaming...");
}

@end
