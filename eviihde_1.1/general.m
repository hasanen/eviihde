//
//  general.m
//  eViihde
//
//  Created by Sami Siuruainen on 4.10.2010.
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

#import "general.h"


@implementation general

/******************************************************************************
 * General routines
 ******************************************************************************/
- (NSString*) maxDate:(NSString *)shortDate {
	//x.x.xxxx xx:xx >> xx.xx.xxxx xx:xx
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString *compiledDate = NULL;
	
	if ( [shortDate length] > 19 ) {
		shortDate = [ shortDate substringFromIndex:2 ];
	}
	
	@try {
		NSArray *dateTimeAR = [shortDate componentsSeparatedByString: @" "];
		NSString *dayPart = [ dateTimeAR objectAtIndex:0 ];
		NSString *clockPart = [ dateTimeAR objectAtIndex:1 ];
		if ( [ dateTimeAR count ] == 3) {
			dayPart = [ dateTimeAR objectAtIndex:1 ];
			clockPart = [ dateTimeAR objectAtIndex:2 ];
		}
		
		NSArray *dateAR = [ dayPart componentsSeparatedByString: @"."];
		NSString *dayStr = [dateAR objectAtIndex:0];
		NSString *monStr = [dateAR objectAtIndex:1];
		NSString *yearStr = [dateAR objectAtIndex:2];
		NSString *lDayStr = dayStr;
		NSString *lMonStr = monStr;
		
		if ( [dayStr length] == 1 ) {
			lDayStr = [NSString stringWithFormat: @"0%@", dayStr];
		}
		
		if ( [monStr length] == 1 ) {
			lMonStr = [NSString stringWithFormat: @"0%@", monStr];
		} 
		
		if ( [ clockPart length ] > 5 ) {
			clockPart = [ clockPart substringToIndex:5 ];
		}
		
		compiledDate = [NSString stringWithFormat: @"%@.%@.%@ %@", yearStr, lMonStr, lDayStr, clockPart];
	}
	@catch (NSException * e) {
		NSLog(@"EXCEPTION: on maxDate : %@", e);
	}
	@finally {
		return compiledDate;
		[pool drain];
	}
}

- (NSString*) urlEncode:(NSString *)stringToEncode {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * encoded = @"";
	@try {
		encoded = (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)stringToEncode,NULL,(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",kCFStringEncodingUTF8 );
	}
	@catch (NSException * e) {
		NSLog(@"EXCEPTION: on urlEncode : %@", e);
	}
	@finally {
		return encoded;
		[ pool drain ];
	}
}

- (NSString *) MD5Hash:(NSString*)concat {
    const char *concat_str = [concat UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
	
}

- (NSString *) returnMD5Hash:(NSString *)concat {
	return [ self MD5Hash:concat ];
}
@end
