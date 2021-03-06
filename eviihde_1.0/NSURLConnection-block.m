//
//  NSURLConnection-block.m
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

#import "NSURLConnection-block.h"

@implementation NSURLConnection (block)

#pragma mark API
+ (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_
{
	[NSThread detachNewThreadSelector:@selector(backgroundSync:) toTarget:[NSURLConnection class]
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   request,@"request",
									   successBlock_,@"success",
									   failureBlock_,@"failure",
									   nil]];
}

#pragma mark Private
+ (void)backgroundSync:(NSDictionary *)dictionary
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	void(^success)(NSData *,NSURLResponse *) = [dictionary objectForKey:@"success"];
	void(^failure)(NSData *,NSError *) = [dictionary objectForKey:@"failure"];
	NSURLRequest *request = [dictionary objectForKey:@"request"];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if(error)
	{
		failure(data,error);
	}
	else
	{
		success(data,response);
	}
	[pool release];
}

@end
