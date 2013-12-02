//
//  httpEngine.m
//  eViihde
//
//  Created by Sami Siuruainen on 16.1.2011.
//  Copyright 2011 Sami Siuruainen. All rights reserved.
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

#import "httpEngine.h"


@implementation httpEngine

- (id) init {
	self = [super init];
 	if ( self ) {
		//[ self openDB ];
	}
	return self;
}

- (id) initWithConfig:(cnfController *)cnfController cacheController:(httpCache *) httpCacheID {
	self = [super init];
 	if ( self ) {
		cnf = cnfController;
		/*
		cacheStorage = [[httpCache alloc] init];
		[cacheStorage openCache];	
		if ([cnf getBoolCnf:@"httpCacheEnabled"]) {
			[cacheStorage cacheOn];			
		} else {
			[cacheStorage cachePermanentOff];
		}
		*/ 
		cacheStorage = httpCacheID;
	}
	return self;
}

- (void) cacheOff
{
	[ cacheStorage cacheOff ];
}

- (void) cacheOn
{
	[ cacheStorage cacheOn ];
}

- (NSArray *) jsonHttpExec:(NSString *)url error:(NSError *)error {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSArray *response = nil;	
	NSString * responseString;

	@try {
		responseString = [ cacheStorage getContent:url ];
		if ( responseString == nil ) {
			NSData *data;  
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: [ cnf getIntCnf:@"cnfHTTPTimeout"]];      
			NSURLResponse *Uresponse; 

			data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
			responseString = [NSString stringWithCString:[data bytes] length:[data length]];  
			
			if (!error) {
				if ( [self checkJSONContent:responseString] == NO ) {
					NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
					[errorDetail setValue:@"CONTENT EXCEPTION" forKey:NSLocalizedDescriptionKey];
					error = [NSError errorWithDomain:@"httpEngine.jsonHttpExec" code:101 userInfo:errorDetail];								
					return response;
				}						
				[ cacheStorage setContent:url reqContent:responseString ];				
			}
		}
		error = nil;
		//SBJSON *parser = [[SBJSON alloc] init];
		SBJsonParser *parser = [ SBJsonParser new ];
		response = [ parser objectWithString:responseString ];
		//response = [parser objectWithString:responseString error:&error];				
	}
	@catch (NSException * e) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"FATAL EXCEPTION" forKey:NSLocalizedDescriptionKey];
		error = [NSError errorWithDomain:@"httpEngine.jsonHttpExec" code:100 userInfo:errorDetail];		
		return response;	
		[ pool drain ];		
	}
	@finally {
		return response;	
		[ pool drain ];		
	}
}

- (void) httpExec:(NSString *)url error:(NSError *)error {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: [ cnf getIntCnf:@"cnfHTTPTimeout"]];      
	NSURLResponse *Uresponse; 			
	@try {
		[NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
	}
	@catch (NSException * e) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"FATAL EXCEPTION" forKey:NSLocalizedDescriptionKey];
		error = [NSError errorWithDomain:@"httpEngine.httpExec" code:100 userInfo:errorDetail];		
		[ pool drain ];		
	}
	@finally {
		[ pool drain ];		
	}	
}

- (NSString *) httpGet:(NSString *)url error:(NSError *)error {
	NSString * responseString;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: [ cnf getIntCnf:@"cnfHTTPTimeout"]];
	NSURLResponse *Uresponse; 			
	NSData *data;  

	@try {
		//responseString = [ cacheStorage getContent:url ];
		//if (responseString == nil) {
			data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
			responseString = [NSString stringWithCString:[data bytes] length:[data length]];  			
		//	[ cacheStorage setContent:url reqContent:responseString ];
		//} else {
		//	NSLog(@"cached");
		//}
	}
	@catch (NSException * e) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"FATAL EXCEPTION" forKey:NSLocalizedDescriptionKey];
		error = [NSError errorWithDomain:@"httpEngine.httpGet" code:100 userInfo:errorDetail];		
		return responseString;
		[ pool drain ];		
	}
	@finally {
		return responseString;
		[ pool drain ];		
	}	
}

- (NSData *) httpGetData:(NSString *)url error:(NSError *)error  {
	NSData *data;  
	@try {
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: [cnf getIntCnf:@"cnfHTTPTimeout"]];      
		NSURLResponse *Uresponse;  
		data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
	}
	@catch (NSException * e) {
		//[ self addDynLog:[ NSString stringWithFormat:@"EXCEPTION: %@", e] entrySeverity:@"EXCEPTION" callerFunction:@"execHTTPData"];
	}
	@finally {
		//[ self hideProgress:[ NSString stringWithFormat:@"execHTTP: %@", urlString ] ];
		return data;	
	}
}

/** ASYNC Get method for HTTP(S) **
 [ httpEngine execAsyncGet:url
	success:^(NSData *data, NSURLResponse *response) {
		NSLog(@"Success!");
	}
	failure:^(NSData *data, NSError *error) {
		NSLog(@"Error! %@",[error localizedDescription]);
	}
	error:error ];
 */
- (void) execAsyncGet:(NSString *)url success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_ error:(NSError *)error{
	@try {
		[NSURLConnection 
		 asyncRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: url ]] 
		 success:successBlock_ 
		 failure:failureBlock_];			
		error = nil;
	} @catch (NSException * e) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:@"ASYNC EXCEPTION" forKey:NSLocalizedDescriptionKey];
		error = [NSError errorWithDomain:@"httpEngine.execAsyncGet" code:100 userInfo:errorDetail];		
	}
}

- (BOOL) checkJSONContent:(NSString *)content {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	BOOL response = NO;
	NSError *checkJSONError = nil;
	//SBJSON *parser = [[SBJSON alloc] init];
	SBJsonParser *parser = [ SBJsonParser new ];
	[parser objectWithString:content error:&checkJSONError];				
	if (!checkJSONError) {
		response = YES;
	}
	return response;
	[ pool drain ];
}

@end