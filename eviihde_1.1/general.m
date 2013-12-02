//
//  general.m
//  eViihde
//
//  Created by Sami Siuruainen on 4.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

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
