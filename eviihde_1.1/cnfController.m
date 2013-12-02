//
//  cnfController.m
//  eViihde
//
//  Created by Sami Siuruainen on 26.3.2010.
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

#import "cnfController.h"

@implementation cnfController

- (void) createDefaultConf {
	
	NSString *UserPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *UserFile = [UserPath stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
    NSFileManager *fileManager = [NSFileManager defaultManager];
	
    if (![fileManager fileExistsAtPath:UserFile]) {
		NSString *DefaultPath = [[NSBundle mainBundle] bundlePath];
		NSString *DefaultFile = [DefaultPath stringByAppendingPathComponent:@"Contents/Resources/app_config.plist"];	
		NSDictionary *plistData = [[NSDictionary dictionaryWithContentsOfFile:DefaultFile] retain];				
		[plistData writeToFile:UserFile atomically: YES];
	} else {
		NSString * verInfo = [ self getStringCnf:@"plistVersion" ];
		NSString * longVersion = [NSString stringWithString: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
		
		if ( ! [ verInfo isEqualToString: longVersion ] ) {
			NSLog(@"Version differs: ActiveConf:%@ != ApplicationVersion:%@", verInfo, longVersion );
			NSString *DefaultPath = [[NSBundle mainBundle] bundlePath];
			NSString *DefaultFile = [DefaultPath stringByAppendingPathComponent:@"Contents/Resources/app_config.plist"];	
			NSMutableDictionary *plistData = [[NSMutableDictionary alloc] initWithContentsOfFile:DefaultFile];
			NSMutableDictionary *userPlistData = [[NSMutableDictionary alloc] initWithContentsOfFile:UserFile];
			NSString *latestPlistVersion = [ NSString stringWithString:[ plistData valueForKey:@"plistVersion" ]];
			
			for (id key in userPlistData)
			{
				if ( key != @"plistVersion" ) {
					[plistData setValue:[ userPlistData valueForKey:key ] forKey:key];				
				}
			}	
			
			[plistData setValue:latestPlistVersion forKey:@"plistVersion"];

			NSLog(@"%@", plistData);
			@try {
				[plistData writeToFile:UserFile atomically: YES];
			} @catch (NSException * fileWriteError) {
			}
		}		
	}
}

- (int) getIntCnf:(NSString *)confKey {
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *finalPath = [path stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	NSDictionary *plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];		
	return [[plistData objectForKey:confKey] intValue];	
}

- (bool) isStringCnfNotNull:(NSString *)confKey {
	//NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	//NSString *finalPath = [path stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	//NSDictionary *plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];		
	/* TODO: Check problem? */
	return true;
}

- (NSString *) getStringCnf:(NSString *)confKey {
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *finalPath = [path stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	NSDictionary *plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];		
	
	/** FALL BACK, IF CONFIG FAILS ON THESE **/
	if ( ( confKey == @"httpServerAddress" ) && ([plistData objectForKey:confKey] == @"" )) {
		return @"api.elisaviihde.fi/etvrecorder"; 
	}

	if ( ( confKey == @"httpServerProtocol" ) && ([plistData objectForKey:confKey] == @"" )) {
		if ( [ plistData objectForKey:@"httpServerAddress" ] == @"api.elisaviihde.fi/etvrecorder" )
		{
			return @"http";
		} else {
			return @"https"; 			
		}
	}
	
	return [plistData objectForKey:confKey];
}

- (BOOL) getBoolCnf:(NSString *)confKey {
	BOOL response = NO;
	if ( [[self getStringCnf:confKey] intValue] )
	{
		response = YES;
	} else {
		response = NO;
	}
	return response;
}

- (void) setIntCnf:(NSString *)confKey value:(int)intValue {
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *finalPath = [filePath stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:finalPath];
	[plistDict setValue:[NSString stringWithFormat:@"%d", intValue] forKey:confKey];
	[plistDict writeToFile:finalPath atomically: YES];	
}

- (void) setStringCnf:(NSString *)confKey value:(NSString *)stringValue {	
	NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *finalPath = [filePath stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:finalPath];
	[plistDict setValue:stringValue forKey:confKey];
	[plistDict writeToFile:finalPath atomically: YES];
}

- (void) setBoolCnf:(NSString *)confKey value:(BOOL)boolValue {
	if ( boolValue )
	{
		[self setStringCnf:confKey value:@"1"];
	} else {
		[self setStringCnf:confKey value:@"0"];
	}
}

@end
