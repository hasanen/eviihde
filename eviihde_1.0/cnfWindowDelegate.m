//
//  cnfWindowDelegate.m
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


#import "cnfWindowDelegate.h"


@implementation cnfWindowDelegate

- (void)awakeFromNib {
	cnf = [[cnfController alloc] init];
	[cnf createDefaultConf];
	[ self showSettings:0 ];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	DOMDocument * wkDom = [ frame DOMDocument ];
	//NSLog(@"webview finnished: %@", [wkDom title]);	
	NSString *response = [[ wkDom documentElement ] textContent];

	NSLog(@"[ ---------------------------------------------------------------------------------------------------------------- ]");
	NSLog(@"%@\n", response);
	NSLog(@"[ ---------------------------------------------------------------------------------------------------------------- ]");

	NSRange scriptAuth = [response rangeOfString:@"window.location.href=\"http:\\/\\/www.eviihde.com\\/fb_callback.php"];

	if ( scriptAuth.location == NSNotFound ) {
	} else {
		// We are authoriced, collect code=XXX
		NSString * fbUID = [[NSMutableString alloc] init];
		NSString * codeString = [[NSMutableString alloc] init];
		
		NSRange codeLocS=[response rangeOfString:@"access_token="];
		codeString = [ response substringFromIndex: codeLocS.location + 13 ];
		NSRange codeLocE = [ codeString rangeOfString:@"&expires"];
		codeString = [ codeString substringToIndex: codeLocE.location ];		
		NSLog(@"FB Access code: %@", codeString);
		[ cnf setStringCnf:@"fb_access_token" value:codeString ];
		
		NSRange uidLocS = [ codeString rangeOfString:@"-" ];
		fbUID = [ codeString substringFromIndex: uidLocS.location + 1 ];
		NSRange uidLocE = [ fbUID rangeOfString:@"%" ];
		fbUID = [ fbUID substringToIndex:uidLocE.location ];
		NSLog(@"fbUID:%@", fbUID);
		
		[ cnf setStringCnf:@"fb_uid" value:fbUID ];
		[ cnf setStringCnf:@"fb_access_token" value:codeString ];			
		NSLog(@"[ ---------------------------------------------------------------------------------------------------------------- ]");
	}		
}

- (IBAction)showSettings:(id)sender {
	// LOAD SETTINGS, APPLY TO SETTINGS SCREEN //
	NSLog(@"LOAD SETTINGS, APPLY TO SETTINGS SCREEN");
	if ( [ cnf getBoolCnf:@"disableFacebook" ] )
	{
		[ wbFaceBookLogin setHidden:YES ];
	} else {
		if ( ![ (NSString *) [ cnf getStringCnf:@"fb_access_token" ] length] )
		{			
			[ wbFaceBookLogin setDrawsBackground: NO ];
			
			NSString *response;	
			NSURLResponse *Uresponse;	
			NSError *error = nil;
			NSData *data;  
			NSString * fbUID = [[NSMutableString alloc] init];
			//NSMutableString * fbCode = [[NSMutableString alloc] init];
			
			NSLog(@"[ authorize @ cnfDelegate/sS ]----------------------------------------------------------------------------------------------------------------");
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: @"https://graph.facebook.com/oauth/authorize?type=user_agent&scope=offline_access,publish_stream,create_event&client_id=106219119443269&redirect_uri=http://www.eviihde.com/fb_callback.php&display=popup" ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 30];      
			data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
			response = [NSString stringWithUTF8String:[data bytes]];  
			/*
			if ([Uresponse respondsToSelector:@selector(allHeaderFields)]) {
				NSLog(@"%@", response);
				NSDictionary *dictionary = [Uresponse allHeaderFields];
				NSLog(@"%@", [dictionary description]);
			}
			*/
			if ( [[ response substringToIndex:7] compare:@"<script"] ) {
				// No Authorization, loading....
				[ cnf setStringCnf:@"fb_access_token" value:@"" ];
				NSLog(@"[ authorize (to WebView) @ cnfDelegate/sS ]----------------------------------------------------------------------------------------------------------------");
				request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: @"https://graph.facebook.com/oauth/authorize?type=user_agent&scope=offline_access,publish_stream,create_event&client_id=106219119443269&redirect_uri=http://www.eviihde.com/fb_callback.php" ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 30];
				[request setHTTPShouldHandleCookies:YES];
				[[ wbFaceBookLogin mainFrame ] loadRequest:request];		
			} else {
				// We are authoriced, collect code=XXX
				NSRange codeLocS=[response rangeOfString:@"access_token="];
				NSString * codeString = [ response substringFromIndex: codeLocS.location + 13 ];
				NSRange codeLocE = [ codeString rangeOfString:@"&expires"];
				codeString = [ codeString substringToIndex: codeLocE.location ];		
				NSLog(@"FB Access code: %@", codeString);
				[ cnf setStringCnf:@"fb_access_token" value:codeString ];
				
				NSRange uidLocS = [ codeString rangeOfString:@"-" ];
				fbUID = [ codeString substringFromIndex: uidLocS.location + 1 ];
				NSRange uidLocE = [ fbUID rangeOfString:@"%" ];
				fbUID = [ fbUID substringToIndex:uidLocE.location ];
				NSLog(@"fbUID:%@", fbUID);
				
				[ cnf setStringCnf:@"fb_uid" value:fbUID ];
				[ cnf setStringCnf:@"fb_access_token" value:codeString ];			
			}		
		} else {
			[ wbFaceBookLogin setHidden:YES ];
		}
	}
	
	if ([ cnf getStringCnf:@"downloadSaveAsTemplate" ] == NULL) {
		[ cnf setStringCnf:@"downloadSaveAsTemplate" value:@"{name} ({channel} {start_time}-{end_time})" ];
	}
	[ cnfSaveAsTemplate setStringValue: [ cnf getStringCnf:@"downloadSaveAsTemplate" ]];
						
	[cnfDisplaySmallInfoBox setState:(bool) [cnf getBoolCnf:@"cnfDisplaySmallInfoBox"]];
	[cnfAutoTrash setState:(bool) [cnf getBoolCnf:@"cnfAutoTrash"]];
	[cnfGuideSearch setState:(bool) [cnf getBoolCnf:@"cnfGuideSearch"]];
	[cnfSyncServer setState:(bool) [cnf getBoolCnf:@"cnfSyncServer"]];
	[cnfCBShowRecs setState:(bool) [cnf getBoolCnf:@"cnfCBShowRecs"]];
	[cnfCBShowRecsToCome setState:(bool) [cnf getBoolCnf:@"cnfCBShowRecsToCome"]];
	[cnfCBShowChanList setState:(bool) [cnf getBoolCnf:@"cnfCBShowChanList"]];
	[cnfCBShowTopList setState:(bool) [cnf getBoolCnf:@"cnfCBShowTopList"]];
	[cnfCBKeepLogged setState:(bool) [cnf getBoolCnf:@"cnfCBKeepLogged"]];
	[cnfCBAutoLogin setState:(bool) [cnf getBoolCnf:@"cbAutoLogin"]];
	[cnfVLCFullScreen setState:(bool) [cnf getBoolCnf:@"cnfVLCFullScreen"]];
	[cnfUseVLC setState:(bool) [cnf getBoolCnf:@"useVLC"]];
	[cnfRecFolderSelect setState:(bool) [cnf getBoolCnf:@"cnfRecFolderSelect"]];
	[cnfAllowContRemoveFromInRecs setState:(bool) [ cnf getBoolCnf:@"cnfAllowContRemoveFromInRecs"]];
	[cnfSingleView setState:(bool) [ cnf getBoolCnf:@"cnfSingleView"]];
	[cnfEnableVersionChecking setState:(bool) [ cnf getBoolCnf:@"cnfCheckVersion"]];
	[cnfHTTPTimeoutSlider setIntValue:[cnf getIntCnf:@"cnfHTTPTimeout"]];
	[cnfHTTPTimeoutLabel setStringValue:[NSString stringWithFormat:@"%@ sec", [cnf getStringCnf:@"cnfHTTPTimeout"]]];
	
	[ cnfEnableTrashCan setState:(bool)[cnf getBoolCnf:@"cnfEnableTrashCan"]];
	[ cnfEnableTrashCanAutocreate setState:(bool)[cnf getBoolCnf:@"cnfEnableTrashCanAutocreate"]];
	if ( [cnf getBoolCnf:@"cnfEnableTrashCan"] == NO ) {
		[ cnfEnableTrashCanAutocreate setEnabled:NO ];
		[ cnfAutoTrash setEnabled:NO ];
	}

	[cnfHTTPDownloadSpeedSlider setIntValue:[cnf getIntCnf:@"maxDownloadSpeed"]];
	
	float floatSize = [cnf getIntCnf:@"maxDownloadSpeed"];
	floatSize = floatSize / 1024 / 1024;	
	[cnfHTTPDownloadSpeedLabel setStringValue:[NSString stringWithFormat:@"%1.3f MB/s", floatSize]];

	[cnfhttpCacheEnabled setState:(bool) [cnf getBoolCnf:@"httpCacheEnabled"]];
	[cnfDisableFacebook setState:(bool) [cnf getBoolCnf:@"disableFacebook"]];
	[cnfShowLatestOnlyUnwatched setState:(bool) [ cnf getBoolCnf:@"showLatestOnlyUnwatched"]]; 
	[cnfPathFolderShowBytes setState:(bool) [ cnf getBoolCnf:@"pathFolderShowBytes"]];
	[ downloadPath setStringValue: [ cnf getStringCnf:@"defaultDownloadLocation"]];
	[ slICalReminderTime setIntValue: [ cnf getIntCnf:@"ical_before_start" ] ];
	[tfICalTimeText setStringValue:[NSString stringWithFormat:@"%@ minuuttia",[cnf getStringCnf:@"ical_before_start"]]];
	
	[ cnfSaveLog setState: (bool) [ cnf getBoolCnf:@"saveLogToFile" ]]; 
	[ cnfLogFile setStringValue: [ cnf getStringCnf:@"logFile"] ];
	
	[ [ acLogLevels content ] removeAllObjects ];
	NSDictionary * ldict =[NSDictionary dictionaryWithObjectsAndKeys:
						  @"Exceptions", @"logLevelName",
							@"0", @"intValue",
						  nil
						  ];
	[ acLogLevels addObject:ldict];
	ldict =[NSDictionary dictionaryWithObjectsAndKeys:
			@"Errors", @"logLevelName",
			@"3", @"intValue",
			nil
			];
	[ acLogLevels addObject:ldict];	
	ldict =[NSDictionary dictionaryWithObjectsAndKeys:
			@"Info", @"logLevelName",
			@"6", @"intValue",
			nil
			];
	[ acLogLevels addObject:ldict];
	
	ldict =[NSDictionary dictionaryWithObjectsAndKeys:
			@"Debug", @"logLevelName",
			@"9", @"intValue",
			nil
			];
	[ acLogLevels addObject:ldict];	
	[ cnfSelectLogLevel reloadData ];
	NSLog(@"%@", [ cnf getStringCnf:@"logLevel"]);
	[ cnfSelectLogLevel selectItemAtIndex: (([ cnf getIntCnf:@"logLevel"]+1)/3) ];
		
	if ( [ cnf getStringCnf:@"activeTheme" ] == @"default" ) {
		[ cbThemes selectItemAtIndex:1 ];
	} 
	
	NSLog(@"%@", [ cnf getStringCnf:@"httpServerAddress" ]);
	if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
	{
		[scProvider setSelectedSegment:0];
	} else {
		[scProvider setSelectedSegment:1];
	}
	
	if ( [cnf getBoolCnf:@"cnfSingleView"] )
	{
		[ cnfOpenWinBox setHidden:YES ];
	}
	
	[ [ acThemeList content ] removeAllObjects ];
	NSDictionary * dict =[NSDictionary dictionaryWithObjectsAndKeys:
		   @"eViihde", @"themeName",
		   @"", @"themePath",
		   nil
		   ];
	[ acThemeList addObject:dict];
	
	/** Populate ... **/
	NSString *UserPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *UserThemePath = [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Themes/"];	
    NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager changeCurrentDirectoryPath: UserThemePath] == NO) {
		NSError * fmError = nil;
		[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Themes"] withIntermediateDirectories:YES attributes: nil error:&fmError];		
		//[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde"] attributes: nil];		
		//[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Themes"] attributes: nil];		
	}
	
	NSArray *themePaths;
	NSError * fmError = nil;
	themePaths = [fileManager contentsOfDirectoryAtPath:UserThemePath error: &fmError ];
	int count = [themePaths count];
	
	for (int i = 0; i < count; i++) {
        NSLog (@"%@", [ UserThemePath stringByAppendingPathComponent:[ NSString stringWithFormat:@"%@/theme.plist", [themePaths objectAtIndex: i]]]);
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[ UserThemePath stringByAppendingPathComponent:[ NSString stringWithFormat:@"%@/theme.plist", [themePaths objectAtIndex: i]]]] ) {
			
			NSDictionary *themePlist = [[NSDictionary dictionaryWithContentsOfFile:[ UserThemePath stringByAppendingPathComponent:[ NSString stringWithFormat:@"%@/theme.plist", [themePaths objectAtIndex: i]]] ] retain];
			
			dict =[NSDictionary dictionaryWithObjectsAndKeys:
				   [ themePlist valueForKey:@"theme_name"], @"themeName",
				   [ UserThemePath stringByAppendingPathComponent:[themePaths objectAtIndex: i]], @"themePath",
				   nil
				   ];
			[ acThemeList addObject:dict];					
		}
	}
	
	
	/** ...populate. **/	
	[ cbThemes reloadData ];	
	[ cbThemes selectItemWithObjectValue: [ cnf getStringCnf:@"activeThemeName" ] ];
	
	/** Populate iCal's **/

	//CalCalendarStore *store = [CalCalendarStore defaultCalendarStore];
	//CalCalendar *calendar = [[store calendars] objectAtIndex:0];	
	NSArray *calendarsAll = [[CalCalendarStore defaultCalendarStore] calendars];
	int selected_ical = 0;
	int ical_count = 0;
	for (CalCalendar *cal in calendarsAll) {
		if ( ![[ cal uid ] compare: [ cnf getStringCnf:@"ical_calendar_uid" ] ]) selected_ical = ical_count;
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
			   [ cal title ], @"title",
			   [ cal uid ], @"uid",
			   nil
			   ];
		[ acICalList addObject:dict];		
		ical_count++;
	}
	[ cbICal reloadData ];
	[ cbICal selectItemAtIndex: selected_ical ];
			
	//NSMutableArray *calendars = [[[[CalCalendarStore defaultCalendarStore] calendars] mutableCopy] autorelease];
	//NSArray *calendars = [[CalCalendarStore defaultCalendarStore] calendars];
	//calendars = [calendars filteredArrayUsingPredicate:myPredicate];
	
	/** ...till end. **/
	
	if ([cnf getIntCnf:@"guiServiceFontSize"] == 0) {
		[cnf setIntCnf:@"guiServiceFontSize" value:11];
		[cnf setIntCnf:@"guiRecordingsFontSize" value:12];
	}
	
	[cbSidebarFontSize selectItemAtIndex: [cnf getIntCnf:@"guiServiceFontSize"] - 11 ];
    [cbRecordingFontSize selectItemAtIndex: [cnf getIntCnf:@"guiRecordingsFontSize"] - 11 ];
	
	[configPanel setIsVisible:YES];
}

- (IBAction)cbICalSelect:(id)sender {
	NSArray *objects = [acICalList arrangedObjects];
	[ cnf setStringCnf:@"ical_calendar_title" value: [cbICal stringValue] ];
	[ cnf setStringCnf:@"ical_calendar_uid" value: [[ objects objectAtIndex: [ cbICal indexOfSelectedItem ] ] valueForKey:@"uid" ]];	
}

- (IBAction) themeSelect:(id)sender {
	NSArray *objects = [acThemeList arrangedObjects];
	[ cnf setStringCnf:@"activeThemeName" value: [cbThemes stringValue] ];
	[ cnf setStringCnf:@"activeThemePath" value: [[ objects objectAtIndex: [ cbThemes indexOfSelectedItem ] ] valueForKey:@"themePath" ]];	
	NSLog(@"%@", objects );
	NSLog(@"%@", [[ objects objectAtIndex:[ cbThemes indexOfSelectedItem ] ] valueForKey:@"themePath" ]);
}

- (IBAction)acSelectDownloadPath:(id)sender {
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:NO];
	[openDlg setCanChooseDirectories:YES];
	
	if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
	{
		//NSString *path = [openDlg filename];
		[ downloadPath setStringValue:[openDlg filename]];
		[ cnf setStringCnf:@"defaultDownloadLocation" value:[openDlg filename]];
	}
	
}

- (IBAction)chIcalReminder:(id)sender {
	[ tfICalTimeText setStringValue: [ NSString stringWithFormat:@"%d minuuttia", [sender intValue] ] ];
	[ cnf setIntCnf:@"ical_before_start" value:[sender intValue] ];
}

- (IBAction)chTimeoutSlider:(id)sender {
	[cnfHTTPTimeoutLabel setStringValue:[NSString stringWithFormat:@"%d sec", [sender intValue]]];
	[cnf setIntCnf:@"cnfHTTPTimeout" value:[sender intValue]];
}

- (IBAction)chDownloadSpeedSlider:(id)sender {
	float floatSize = [sender intValue];
	floatSize = floatSize / 1024 / 1024;
	[cnfHTTPDownloadSpeedLabel setStringValue:[NSString stringWithFormat:@"%1.3f MB/s", floatSize]];
	//[cnfHTTPDownloadSpeedLabel setStringValue:[NSString stringWithFormat:@"%d KBps", ([sender intValue]/1024)]];
	[cnf setIntCnf:@"maxDownloadSpeed" value:[sender intValue]];	
}


- (IBAction)chResetProgram:(id)sender {
	NSString *UUID = [ cnf getStringCnf:@"UUID" ];
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *finalPath = [path stringByAppendingPathComponent:@"Preferences/eViihde.plist"];	
	unlink([finalPath UTF8String]);
	[cnf createDefaultConf];
	[cnf setStringCnf:@"UUID" value:UUID ];
	exit(0);
}

- (IBAction)serviceProviderSelector:(id)sender {
	if ( [ scProvider selectedSegment] == 0 ) {
		NSLog(@"Setting eViihde");
		[ cnf setStringCnf:@"httpServerProtocol" value:@"http" ];
		[ cnf setStringCnf:@"httpServerAddress" value:@"api.elisaviihde.fi/etvrecorder" ];
		[ cnf setStringCnf:@"serviceIconName" value:@"elisaviihde_logo" ];
		[ cnf setStringCnf:@"serviceIconFileType" value:@"png" ];
	} else {
		NSLog(@"Setting Saunavisio");
		[ cnf setStringCnf:@"httpServerProtocol" value:@"https" ];
		[ cnf setStringCnf:@"httpServerAddress" value:@"www.saunavisio.fi/tvrecorder" ];
		[ cnf setStringCnf:@"serviceIconName" value:@"saunavisio_logo" ];
		[ cnf setStringCnf:@"serviceIconFileType" value:@"png" ];
	}
}

- (IBAction)chCnfCB:(id)sender {
	switch ( [sender tag] )
    {
        case 0:
			[cnf setBoolCnf:@"cnfCBShowRecs" value:[sender integerValue]];
            break;
			
        case 1:
			[cnf setBoolCnf:@"cnfCBShowRecsToCome" value:[sender integerValue]];
            break;
			
		case 2:
			[cnf setBoolCnf:@"cnfCBShowChanList" value:[sender integerValue]];
            break;
			
		case 3:
			[cnf setBoolCnf:@"cnfCBShowTopList" value:[sender integerValue]];
            break;
			
		case 4:
			[cnf setBoolCnf:@"cnfCBKeepLogged" value:[sender integerValue]];
            break;
			
		case 5:
			[cnf setBoolCnf:@"cbAutoLogin" value:[sender integerValue]];
            break;
			
		case 6:
			[cnf setBoolCnf:@"cnfVLCFullScreen" value:[sender integerValue]];
            break;
			
		case 7:
			[cnf setBoolCnf:@"cnfRecFolderSelect" value:[sender integerValue]];
            break;
			
		case 8:
			[cnf setBoolCnf:@"cnfAllowContRemoveFromInRecs" value:[sender integerValue]];
			/*
			if ( [sender integerValue] == YES )
			{
				[inrecRemoveTimer setEnabled:YES];			
			} else {
				[inrecRemoveTimer setEnabled:NO];			
			}
			 */
            break;
		case 9:
			[cnf setBoolCnf:@"cnfSingleView" value:[sender integerValue]];
			break;
			
		case 10:
			[cnf setBoolCnf:@"httpCacheEnabled" value:[sender integerValue]];
			break;
			
		case 11:
			[cnf setBoolCnf:@"useVLC" value:[sender integerValue]];
			break;
		
		case 12:
			[cnf setBoolCnf:@"disableFacebook" value:[sender integerValue]];
			[ wbFaceBookLogin setHidden: [ cnf getBoolCnf:@"disableFacebook" ] ];
			if ( [sender integerValue] == 1 ) {
				[ cnf setStringCnf:@"fb_access_token" value:@"" ];
				[ cnf setStringCnf:@"fb_uid" value:@"" ];
			}
			break;
		
		case 13:
			[cnf setBoolCnf:@"showLatestOnlyUnwatched" value:[sender integerValue]];
			break;			
			
		case 14:
			[cnf setBoolCnf:@"pathFolderShowBytes" value:[sender integerValue]];
			break;

		case 15:
			[cnf setBoolCnf:@"saveLogToFile" value:[sender integerValue]];
			break;
		case 16:
			[cnf setBoolCnf:@"cnfSyncServer" value:[sender integerValue]];
			break;
		case 17:
			[cnf setBoolCnf:@"cnfGuideSearch" value:[sender integerValue]];
			break;
		case 18:
			[cnf setBoolCnf:@"cnfAutoTrash" value:[sender integerValue]];
			break;
		case 19:
			[cnf setBoolCnf:@"cnfDisplaySmallInfoBox" value:[sender integerValue]];
			break;
		case 20:
			[cnf setBoolCnf:@"cnfEnableTrashCan" value:[sender integerValue]];
			
			if ( [sender integerValue] == 0 ) {
				[ cnfEnableTrashCanAutocreate setEnabled:NO ];
				[ cnfAutoTrash setEnabled:NO ];
			} else {
				[ cnfEnableTrashCanAutocreate setEnabled:YES ];
				[ cnfAutoTrash setEnabled:YES ];				
			}
			
			break;
		case 21:
			[cnf setBoolCnf:@"cnfEnableTrashCanAutocreate" value:[sender integerValue]];
			break;
		case 22:
			[cnf setBoolCnf:@"cnfCheckVersion" value:[sender integerValue]];
			break;
	}
}

- (IBAction)btSaveAsHelp:(id)sender {
	[ npSaveAsHelp setIsVisible: YES ];
}

- (IBAction)cnfSaveAsTemplateChange:(id)sender {
	[ cnf setStringCnf:@"downloadSaveAsTemplate" value:[ sender stringValue ] ];
}

- (IBAction) pickLogFile:(id)sender {
	NSSavePanel* panel = [NSSavePanel savePanel];
	//[ panel setDirectory:[ cnf getStringCnf:@"logFile" ]];
	[panel
	 beginSheetForDirectory:nil
	 file:[ cnf getStringCnf:@"logFile" ]
	 modalForWindow: configPanel
	 modalDelegate:self
	 didEndSelector:@selector(selectLogFileEnd:returnCode:contextInfo:)
	 contextInfo:nil
	 ];
	
}

-(void)selectLogFileEnd:(NSOpenPanel*)panel
			returnCode:(int)rc contextInfo:(void*)ctx {
	if(rc != NSOKButton) {
		return;
	}
	[ cnfLogFile setStringValue:[ panel filename ] ];
	[ cnf setStringCnf:@"logFile" value:[panel filename]];
}

- (IBAction) logLevelSelect:(id)sender {
	NSArray *objects = [acLogLevels arrangedObjects];
	//[ cnf setStringCnf:@"activeThemeName" value: [cbThemes stringValue] ];
	//[ cnf setStringCnf:@"activeThemePath" value: [[ objects objectAtIndex: [ cbThemes indexOfSelectedItem ] ] valueForKey:@"themePath" ]];	
	NSLog(@"%@", objects );
	NSLog(@"%@", [[ objects objectAtIndex:[ cnfSelectLogLevel indexOfSelectedItem ] ] valueForKey:@"intValue" ]);
	[ cnf setIntCnf:@"logLevel" value:[[[ objects objectAtIndex:[ cnfSelectLogLevel indexOfSelectedItem ] ] valueForKey:@"intValue" ] intValue] ];
}

- (IBAction)selectSidebarFontSize:(id)sender {
    //NSLog(@"selectSidebarFontSize: %@", [cbSidebarFontSize objectValueOfSelectedItem]);
    [cnf setIntCnf:@"guiServiceFontSize" value:[[cbSidebarFontSize objectValueOfSelectedItem] intValue]];
}

- (IBAction)selectRecordingFontSize:(id)sender {
    //NSLog(@"selectRecordingFontSize: %@", [cbRecordingFontSize objectValueOfSelectedItem]);    
    [cnf setIntCnf:@"guiRecordingsFontSize" value:[[cbRecordingFontSize objectValueOfSelectedItem] intValue]];
}

@synthesize maThemeList;
@synthesize maICalList;
@synthesize maLogLevels;
@end
