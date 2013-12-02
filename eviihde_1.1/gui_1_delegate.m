//
//  gui_1_delegate.m
//  eViihde
//
//  Created by Sami Siuruainen on 13.9.2010.
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

#import "gui_1_delegate.h"

// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.
kern_return_t FindEthernetInterfaces(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    CFMutableDictionaryRef	matchingDict;
    CFMutableDictionaryRef	propertyMatchDict;
    matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
	
    if (NULL == matchingDict) {
        //printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else {
        propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
													  &kCFTypeDictionaryKeyCallBacks,
													  &kCFTypeDictionaryValueCallBacks);
		
        if (NULL == propertyMatchDict) {
            //printf("CFDictionaryCreateMutable returned a NULL dictionary.\n");
        }
        else {
            CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue); 
            CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
            CFRelease(propertyMatchDict);
        }
    }
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, matchingServices);    
    if (KERN_SUCCESS != kernResult) {
        //printf("IOServiceGetMatchingServices returned 0x%08x\n", kernResult);
    }
	
    return kernResult;
}

kern_return_t GetMACAddress(io_iterator_t intfIterator, UInt8 *MACAddress, UInt8 bufferSize)
{
    io_object_t		intfService;
    io_object_t		controllerService;
    kern_return_t	kernResult = KERN_FAILURE;
    
	if (bufferSize < kIOEthernetAddressSize) {
		return kernResult;
	}
	
    bzero(MACAddress, bufferSize);
    while (intfService = IOIteratorNext(intfIterator))
    {
        CFTypeRef	MACAddressAsCFData;        
        kernResult = IORegistryEntryGetParentEntry(intfService,
												   kIOServicePlane,
												   &controllerService);
		
        if (KERN_SUCCESS != kernResult) {
            //printf("IORegistryEntryGetParentEntry returned 0x%08x\n", kernResult);
        }
        else {
            MACAddressAsCFData = IORegistryEntryCreateCFProperty(controllerService,
																 CFSTR(kIOMACAddress),
																 kCFAllocatorDefault,
																 0);
            if (MACAddressAsCFData) {
                CFShow(MACAddressAsCFData); // for display purposes only; output goes to stderr
                CFDataGetBytes(MACAddressAsCFData, CFRangeMake(0, kIOEthernetAddressSize), MACAddress);
                CFRelease(MACAddressAsCFData);
            }
            (void) IOObjectRelease(controllerService);
        }
        (void) IOObjectRelease(intfService);
    }
    return kernResult;
}

@implementation gui_1_delegate

cnfController *cnf;
httpCache *cH;

int progIsOpen;
int keeploggedErrorCounter;	
int selectedRecRow;
Boolean isLoggedIn;
NSImage* defaultThumbImageObj;
long lastRefreshUNIXTime;

NSString *themePath;
NSString *selectedRecID;
NSString *selectedRecInfo;
NSString *curFolderID;
NSString *curParentFolder;
NSString *activeFolderID;
NSString *activeFolderName;
NSString *selFavID;
NSString *mnCutRecordID;
NSString *modelKeyValue;
NSString *basePath;

NSString *curGuideLocation;
NSInteger *curGuideSelector;
NSString *inRecordList;

NSMutableData *responseData;
NSMutableArray *folderPathIDs;
NSMutableArray *folderPathNames;

NSMutableArray *serviceIconArray;
NSImage* defaultThumbImageObj;

NSMutableArray * activeDownloads;
NSMutableArray * latestRecs;

NSMutableString * latestDownloadUrl;
NSMutableString * latestReleaseNotesUrl;

NSString *trashFolderID;
BOOL trashFound;

NSTimer * dlViewTimer;


NSXMLParser *xmlParser;

NSMutableArray * statusScreenArray;

static int folderIconID = 0;
static int recordIconID = 1;
static int f_videoID = 2;
static int f_downloadsID = 3; 
static int f_favsID = 4;
static int f_linksID = 5; 
static int f_searchID = 6; 
static int f_trashID = 7;
//static int recordNewIconID = 8;
static int guide_itemID = 9;
static int timerID = 10;
static int guide_item_inrecID = 11;

int lastSearch;

watched_db * wDB;

/* Function objects for system */
general * gfunc;


/******************************************************************************
 * Wake up function
 ******************************************************************************/
- (NSImage *) loadImage:(NSString *) imagePath {
	return [ NSImage imageNamed:imagePath ];
}
/*
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ( aTableView == tvPathContents ) {
		if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
			if ([aCell isHighlighted]) {
				[aCell setTextColor: [NSColor whiteColor]]; //[aCell setTextColor: [ NSColor colorWithHexColorString:[ cnf getStringCnf:@"path_list_text_color_highlight"]]];
			} else {
				[aCell setTextColor: [ NSColor colorWithHexColorString:[ cnf getStringCnf:@"path_list_text_color"]]];
			}
		}
	} else if (aTableView == serviceTable) {
		if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
			if ([aCell isHighlighted]) {
				[aCell setTextColor: [NSColor whiteColor]];//[ NSColor colorWithHexColorString:[ cnf getStringCnf:@"service_list_text_color_highlight"]]];
			} else {
				[aCell setTextColor: [ NSColor colorWithHexColorString:[ cnf getStringCnf:@"service_list_text_color"]]];
			}
		}
	}	
}
*/
- (void)awakeFromNib {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	isLoggedIn = NO;
	
	@try {		
        
		trashFound = NO;
		
		statusScreenArray = [ [ NSMutableArray alloc ] init];
		lastSearch = 0;
		latestDownloadUrl = [[ NSMutableString alloc ] initWithString:@""];
		latestReleaseNotesUrl = [[ NSMutableString alloc ] initWithString:@""];
		trashFolderID = @"_";
		
		curLogLevel	= 9; // At Begin, there is no configuration, so LOG = DEBUG //
		
		[ [ dynLogController content ] removeAllObjects ];
		maDynLog  = [[NSMutableArray alloc] init];
		
		NSString *UserPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *UserThemePath = [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Themes/"];	
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if ([fileManager changeCurrentDirectoryPath: UserThemePath] == NO) {
			NSError * fmError = nil;
			[fileManager createDirectoryAtPath: [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/Themes"] withIntermediateDirectories:YES attributes: nil error:&fmError];		
		}
		
		cnf = [[cnfController alloc] init];
		[cnf createDefaultConf];
		
		cH = [[httpCache alloc] init];
		[cH openCache];	
		if ([cnf getBoolCnf:@"httpCacheEnabled"]) {
			[cH cacheOn];			
		} else {
			[cH cachePermanentOff];
		}
        
        if ([cnf getIntCnf:@"guiServiceFontSize"] == 0) 
        {
            [cnf setIntCnf:@"guiServiceFontSize" value:11];
            [cnf setIntCnf:@"guiRecordingsFontSize" value:12];        
        }
		
		htEngine = [httpEngine alloc ];
		[ htEngine initWithConfig:cnf cacheController: cH];
		
		curLogLevel = [ cnf getIntCnf:@"logLevel" ];
		logPath = [ cnf getStringCnf:@"logFile" ];
		writeLog = NO;
		
		if ( [ logPath length ] == 0 ) {
			logPath = [UserPath stringByAppendingPathComponent:@"Application Support/eViihde/eviihde.log"];	
			[ cnf setStringCnf:@"logFile" value:logPath ];
			[ self addDynLog:[ NSString stringWithFormat:@"Log set: %@", logPath] entrySeverity:@"INFO" callerFunction:@"awakeFromNib" ];
		}
		
		NSFileManager *filemgr;
		filemgr = [NSFileManager defaultManager];
		if ([filemgr fileExistsAtPath: logPath ] == YES) {
			if ([filemgr isWritableFileAtPath: logPath]  == YES) {
				writeLog = [ cnf getBoolCnf:@"saveLogToFile" ];	
			} else {
				writeLog = NO;					
			}
		} else {
			[filemgr createFileAtPath: logPath contents: nil attributes: nil];
			writeLog = [ cnf getBoolCnf:@"saveLogToFile" ];
		}
		
		gfunc = [ [general alloc] init ];
		
		NSDictionary *themeConfPLIST;
		NSString * DefaultPath;
		[ self addDynLog: [NSString stringWithFormat:@"activeThemePath: %@", [ cnf getStringCnf:@"activeThemePath" ]] entrySeverity:@"INFO" callerFunction:@"awakeFromNib"];
		
		if ( [ [ cnf getStringCnf:@"activeThemePath" ] length ] > 0 ) {
			DefaultPath = [ cnf getStringCnf:@"activeThemePath" ];
			NSString *DefaultFile = [DefaultPath stringByAppendingPathComponent:@"theme.plist"];	
			themeConfPLIST = [[NSDictionary dictionaryWithContentsOfFile:DefaultFile] retain];								
		} else {
			DefaultPath = [[NSBundle mainBundle] bundlePath];
			NSString *DefaultFile = [DefaultPath stringByAppendingPathComponent:@"Contents/Resources/theme.plist"];	
			themeConfPLIST = [[NSDictionary dictionaryWithContentsOfFile:DefaultFile] retain];				
			DefaultPath = [DefaultPath stringByAppendingPathComponent:@"Contents/Resources/"];
		}
		
		NSImage *folder = [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_general"]] ]; // @"f_general.png"];
		NSImage *record = [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_video"]] ]; // @"video.png"];
		NSImage *record_new = [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_video_new"]] ]; // @"video_new.png"];
		NSImage *f_video =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_video"]] ]; // @"f_video.png"]; 
		NSImage *f_downloads =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_downloads"]] ]; // @"f_downloads.png"]; 
		NSImage *f_favs =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_favs"]] ]; // @"f_favs.png"]; 
		NSImage *f_links =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_links"]] ]; // @"f_links.png"]; 
		NSImage *f_search =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_search"]] ]; // @"f_search.png"]; 
		NSImage *f_trash =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_f_trash"]] ]; // @"f_trash.png"]; 
		NSImage *guide_item =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_guide_item"]] ]; // @"f_trash.png"]; 
		NSImage *timer_icon =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_timer"]] ]; // @"f_trash.png"]; 
		NSImage *guide_item_inrec =[[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"icn_guide_item_inrec"]] ];
		
		serviceIconArray = [[NSArray alloc] initWithObjects:
							folder,
							record,
							f_video, 
							f_downloads, 
							f_favs, 
							f_links, 
							f_search, 
							f_trash,
							record_new, 
							guide_item,
							timer_icon,
							guide_item_inrec,
							nil];
		[ tbReloadButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_reload"]] ] ];
		[ tbPlayButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_play"]] ] ];
		[ tbDeleteButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_delete"]] ] ];
		[ tbInfoButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_props"]] ] ];
		[ tbAddButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_add"]] ] ];
		[ tbEditButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_edit"]] ] ];
		[ tbDownloadButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_download"]] ] ];
		[ tbIcalButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_ical"]] ] ];
		[ tbFacebookButton setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"btn_facebook"]] ] ];
		
		[ frmLoginLogo setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"logo_tickets"]] ] ];
		[ aboutIcon setImage: [[NSImage alloc] initWithContentsOfFile:[DefaultPath stringByAppendingPathComponent:[ themeConfPLIST objectForKey:@"logo_tickets"]] ] ];
		
		[cnf setStringCnf:@"rowColorEven" value:[ themeConfPLIST objectForKey:@"color_list_even_rows"]];
		[cnf setStringCnf:@"rowColorOdd" value:[ themeConfPLIST objectForKey:@"color_list_odd_rows"]];
		[serviceTable setBackgroundColor: [ NSColor colorWithHexColorString:[ themeConfPLIST objectForKey:@"service_table_background"]]];
		[currentPath setBackgroundColor: [ NSColor colorWithHexColorString:[ themeConfPLIST objectForKey:@"service_table_background"]]];
		[currentPathFiller setBackgroundColor:[ NSColor colorWithHexColorString:[ themeConfPLIST objectForKey:@"service_table_background"]]];
		[currentPath setTextColor:[ NSColor colorWithHexColorString:[ themeConfPLIST objectForKey:@"current_path_text_color"]]];
		
		//[cnf setStringCnf:@"service_list_text_color_highlight" value:[ themeConfPLIST objectForKey:@"service_list_text_color_highlight"]];
		//[cnf setStringCnf:@"service_list_text_color" value:[ themeConfPLIST objectForKey:@"service_list_text_color"]];
		//[cnf setStringCnf:@"path_list_text_color_highlight" value:[ themeConfPLIST objectForKey:@"path_list_text_color_highlight"]];
		//[cnf setStringCnf:@"path_list_text_color" value:[ themeConfPLIST objectForKey:@"path_list_text_color"]];
		
		[ serviceTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList ];
		[ tvPathContents setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList ];
		
		[ tbReloadButton setToolTip:@"Päivitä Näkymä" ];
		[ tbPlayButton setToolTip:@"Toista tallenne" ];
		[ tbInfoButton setToolTip:@"Info" ];
		[ tbDownloadButton setToolTip:@"Lataa tallenne" ];
		[ tbAddButton setToolTip:@"Lisää kansio" ];
		[ tbEditButton setToolTip:@"" ];
		[ tbDeleteButton setToolTip:@"Poista tallenne/kansio" ];
		[ tbIcalButton setToolTip:@"Lisää kalenterimerkintä" ];
		[ tbFacebookButton setToolTip:@"Facebook" ];
		
		latestRecs = [[NSMutableArray alloc] init];
		
		[ masterWindow setIsVisible: NO ];
		
		/** Forced SingleView since 0.7.0 **/
		[ cnf setBoolCnf:@"cnfSingleView" value:YES ];
		
		progIsOpen = 0;	
		
		if ( [cnf getIntCnf:@"cnfHTTPTimeout"] == 0 )
		{
			[cnf setIntCnf:@"cnfHTTPTimeout" value:30];
		}
		
		NSString *releaseType = @"";
#ifndef DEBUG
		releaseType = @"";
#endif
		
#ifdef DEBUG
		releaseType = @" (Debug)";
#endif
		
		/* 0.5.0 FEATURES */
		[versionTextPanel setStringValue: [NSString stringWithFormat:@"Version %@%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], releaseType]];
		
		lastRefreshUNIXTime = (long) [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]];
		
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
		{
			[ loginWindow setTitle: [NSString stringWithFormat:@"%@ (Elisa Viihde)", [ loginWindow title ]]];			
			basePath = @"http://api.elisaviihde.fi";
		} else {
			[ loginWindow setTitle: [NSString stringWithFormat:@"%@ (Saunavisio)", [ loginWindow title ]]];						
			basePath = @"https://www.saunavisio.fi";
		}
		
		[mnActions setHidden:YES];
		
		NSString *lastKnownUser = [cnf getStringCnf:@"lastUserName"];
		if ( [lastKnownUser length] > 0 ) {
			EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"eViihde.app" withUsername:lastKnownUser];
			NSString *password = keychainItem.password;
			if ( [password length] > 0 ) {
				[evUser setStringValue: lastKnownUser];
				[evPass setStringValue: password];
				[cbRemember setState:1];
				[loginWindow makeFirstResponder:evPass];
				if ( [cnf getBoolCnf:@"cbAutoLogin"] )
				{				
					[cbAutoLogin setState:(bool) [cnf getBoolCnf:@"cbAutoLogin"]];
					[self logIn:0 ];
				} else {
					[loginWindow setIsVisible:YES];
				}
			} else {
				[loginWindow setIsVisible:YES];
			}
		} else {
			[loginWindow setIsVisible:YES];
		}	
		[httpLoaderProgress setUsesThreadedAnimation:YES];
		curParentFolder = @"";
		curFolderID = @"";
		
		folderPathIDs = [[NSMutableArray alloc] init];
		folderPathNames = [[NSMutableArray alloc] init];
		
		[folderPathNames addObject:basePath];
		[currentPath setStringValue: [ self getRecPath ] ];
		
		NSString *json_copyright = @"JSON Framework (http://stig.github.com/json-framework/)\nCopyright © 2007-2010 Stig Brautaset. All rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\n* Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
		
		NSString *ig_comboBox_copyright = @"IGResizableComboBox (https://github.com/ilg/IGResizableComboBox/)\n© Copyright 2010-2011, Isaac Greenspan\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.";
		
		[aboutTextPanel setString:[NSString stringWithFormat:@"%@\n\n\nLegal:\n\n%@\n\n\n%@",
								   @"eViihde, Copyright © 2010-2011 Sami Siuruainen. All rights reserved.\nElisa Viihde, Elisa Oyj\nSaunaVisio, Saunalahti Group Oyj\n\nKiitokset:\n\twww.hopeinenomena.net\n\twww.elisaviihde.fi\n\twww.elisa.fi\n\t#elisaviihde (ircnet)\n\t#hopeinenomena.net (ircnet)\n\nOther trademarks are the property of their respective owners\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.	",
								   json_copyright, ig_comboBox_copyright]
		 ];
		keeploggedErrorCounter = 0;
		
		defaultThumbImageObj = [[NSImage alloc] initWithContentsOfFile:@"elisaviihde_logo.png"];				
		[dynLogTable setDoubleAction:@selector(acOpenLogItem:)];
		[ mnSetUnWatched setHidden:[ cnf getBoolCnf:@"cnfSyncServer" ]];		
		//[tvPathContents setTarget:self];
		
		if ( [ cnf getBoolCnf:@"cnfCheckVersion" ] == YES )
		{
			[ self checkLatestVersion:FALSE silentCheck:TRUE ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"awakeFromNib"];
	}
	@finally {
	}
	
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	NSString * downloadNotice = @"";
	
	int activeDownloadsInArray = 0;
	for (curlier * dlU in activeDownloads) {		
		if ( [ dlU isActive ] == YES ) {
			activeDownloadsInArray++;
		}
	}
	
	if ( activeDownloadsInArray > 0 ) {
		downloadNotice = [ NSString stringWithFormat:@"\n\n%i aktiivista latausta.\nKeskeneräiset lataukset poistetaan.", activeDownloadsInArray ];
	}
	
    if ( [ cnf getBoolCnf:@"cnfAutoTrash" ] ) {
        int autoTrashAnswer = NSRunAlertPanel(@"Roskakorin tyhjennys?", @"Automaattinen roskakorin tyhjennys on päällä, haluatko suorittaa tyhjennyksen, jossa poistetaan yli viikon vanhat tallenteet?",
                                              @"Kyllä", @"Ei", nil);
        if (autoTrashAnswer == NSAlertDefaultReturn) {
            [ self autoEmptyTrash ];								
        } else {
            int autoTrashOnOff = NSRunAlertPanel(@"Automaattinen roskakorin tyhjennys.", @"Automaattinen roskakorin tyhjennys on päällä, mutta ohitit sen. Kytketäänkö pysyvästi pois päältä?",
                                                 @"Kyllä", @"Ei", nil);					
            if (autoTrashOnOff == NSAlertDefaultReturn) {
                [ cnf setBoolCnf:@"cnfAutoTrash" value:NO ];
            }
        }
    }			
	
	if ( activeDownloadsInArray > 0 ) {
		downloadNotice = [ NSString stringWithFormat:@"\n\n%i aktiivista latausta.\nKeskeneräiset lataukset poistetaan.", activeDownloadsInArray ];
        int answer = NSRunAlertPanel(@"Suljetaan", [NSString stringWithFormat:@"Haluatko sulkea eViihteen?%@", downloadNotice],
                                     @"Kyllä", @"Ei", nil);
        if (answer == NSAlertDefaultReturn) {
            if (isLoggedIn == YES) {
                for (curlier * dlU in activeDownloads) {			
                    [ dlU stop ];
                }
            }
            return NSTerminateNow;
        } else {
            return NSTerminateCancel;
        }
    } else {
        return NSTerminateNow;
    }
}

/******************************************************************************
 * Login function, checks user-rights and initializes main view
 ******************************************************************************/
- (IBAction)logIn:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self addDynLog: [ NSString stringWithFormat: @"logIn called : %@",sender ] entrySeverity:@"DEBUG" callerFunction:@"logIn"];

	[ self showProgress:@"logIn:(id)sender" ];
	@try {

		if ( [ cnf getBoolCnf:@"disableFacebook" ] )
		{

		} else {
			if ( ![(NSString *) [ cnf getStringCnf:@"fb_access_token" ] length] )
			{
				NSString *response;	
				NSError *error = nil;				
				response = [ htEngine httpGet:@"https://graph.facebook.com/oauth/authorize?type=user_agent&scope=offline_access,publish_stream,create_event&client_id=[REMOVED]&redirect_uri=http://www.eviihde.com/fb_callback.php&display=touch" error:error ];
				
				if ( [[ response substringToIndex:7] compare:@"<script"] ) {
					[ self addDynLog: response entrySeverity:@"DEBUG" callerFunction:@"logIn"];
					[ cnf setStringCnf:@"fb_access_token" value:@"" ];
					NSRunAlertPanel(@"eViihde", @"Facebook asetuksia ei ole asetettu.\n\nVoit poistaa Facebookin käytöstä asetuksista, tai sallia Facebookin käytön eViihteen kautta.", @"Ok", nil, nil);
				} else {
					// We are authoriced, collect code=XXX
					[ self addDynLog: [ NSString stringWithFormat:@"new_token: %@", response] entrySeverity:@"DEBUG" callerFunction:@"logIn"];
					NSRange codeLocS=[response rangeOfString:@"access_token="];
					NSString * codeString = [ response substringFromIndex: codeLocS.location + 13 ];
					NSRange codeLocE = [ codeString rangeOfString:@"&expires"];
					codeString = [ codeString substringToIndex: codeLocE.location ];		
					[ self addDynLog: [NSString stringWithFormat:@"FB Access Token: %@", codeString] entrySeverity:@"DEBUG" callerFunction:@"logIn"];
					NSRange uidLocS = [ codeString rangeOfString:@"-" ];
					NSString * fbUID = [ codeString substringFromIndex: uidLocS.location + 1 ];
					NSRange uidLocE = [ fbUID rangeOfString:@"%" ];
					fbUID = [ fbUID substringToIndex:uidLocE.location ];
					[ self addDynLog: [ NSString stringWithFormat:@"fbUID:%@", fbUID] entrySeverity:@"DEBUG" callerFunction:@"logIn"];
					[ cnf setStringCnf:@"fb_access_token" value:codeString ];
					[ cnf setStringCnf:@"fb_uid" value:fbUID ];
				}				
			}
		}
		
		NSString* location;
		
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"elisaviihde.fi/etvrecorder" ] )
		{
			[cnf setStringCnf:@"httpServerAddress" value:@"api.elisaviihde.fi/etvrecorder"];
			[cnf setStringCnf:@"httpServerProtocol" value:@"http"];
		}
		
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
		{
			// ElisaViihde login.sl
			location= [NSString stringWithFormat: @"%@://%@/login.sl?username=%@&password=%@&savelogin=true&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [evUser stringValue], [evPass stringValue]];
		} else {			
			// SaunaVisio login thru Default.sl
			location= [NSString stringWithFormat: @"%@://%@/default.sl?username=%@&password=%@&savelogin=true&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [evUser stringValue], [evPass stringValue]];
		}		
		
		NSLog(@"%@", location);
		
		if (location) {
			NSError *error = nil;	
			NSString *response = [ htEngine httpGet:location error:error ];
			
			NSLog(@"%@", response);
			if (!error) {
				NSRange textRange = [[response lowercaseString] rangeOfString:[@"TRUE" lowercaseString]];
				if( textRange.location != NSNotFound ) {
					isLoggedIn = YES;
					activeFolderID = @"";
					activeFolderName = @"";
					
					if ( [cbRemember state] == NSOnState) {
						EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"eViihde.app" withUsername:[evUser stringValue]];
						if (keychainItem == nil) {
							[EMGenericKeychainItem addGenericKeychainItemForService:@"eViihde.app" withUsername:[evUser stringValue] password:[evPass stringValue]];												
						} else {
							keychainItem.password = [evPass stringValue];							
						}
						[cnf setStringCnf:@"lastUserName" value:[evUser stringValue]];
					} else {
						EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"eViihde.app" withUsername:[evUser stringValue]];
						keychainItem.password = @"";
						[cnf setStringCnf:@"lastUserName" value:@""];
					}
					
					[ loginWindow setIsVisible:NO ];

					[self checkTrashFolder];
					[self cleanUpTrashFolderMess];

					if ( [cnf getBoolCnf:@"cnfCBKeepLogged"] )
					{
						// Lauch keep-logged in loop (15 minutes) //900
						[NSTimer scheduledTimerWithTimeInterval:900
														 target:self
													   selector:@selector(keepLogged)
													   userInfo:nil
														repeats:YES];
						[NSTimer scheduledTimerWithTimeInterval:5
														 target:self
													   selector:@selector(checkLastKeep)
													   userInfo:nil
														repeats:YES];
						lastRefreshUNIXTime = [[NSDate date] timeIntervalSince1970];
					}

					// - (bool) checkLatestVersion:(bool)sendVersionData silentCheck:(bool)silentCheck
					if ( [ cnf getBoolCnf:@"cnfCheckVersion" ] )
					{
						[NSTimer scheduledTimerWithTimeInterval:3600
														 target:self
													   selector:@selector(autoVersionCheck)
													   userInfo:nil
														repeats:YES];						
					}
 
					[mnWindow setEnabled:YES];
										
					wDB = [ [ watched_db alloc ] init ];

					[serviceTable setEnabled:NO];
					[tvPathContents setEnabled:NO];
					
					[self loadServices];
					[tvPathContents setDoubleAction:@selector(pathViewDoubleClickAction:)];
					
					modelKeyValue = @"recs";
					[ masterWindow setIsVisible: YES ];
					
					curGuideLocation = @"c";
					curGuideSelector = 0;
					
					[self reloadContRecsFolders];
					[self reloadContRecsChannels];

					activeDownloads = [ [ NSMutableArray alloc ] init ];
					dlViewTimer = [NSTimer scheduledTimerWithTimeInterval:2
																   target:self
																 selector:@selector(populateDownload)
																 userInfo:nil
																  repeats:YES];
					
					NSString* IRlocation = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
					NSError *IRerror = nil;
					inRecordList = [ htEngine httpGet:IRlocation error:IRerror]; // [self execHTTP:IRlocation errorResp:IRerror];							
					[mnActions setHidden:NO];
										
					[tfRecID setStringValue:@""];
					[tfEditorProgID setStringValue:@""];
					[tfWildcardRecEdit setStringValue:@""];
					[cbIsWildcard setIntValue:0];
					[tfRecID setStringValue:@""];
					[tfEditorProgID setStringValue:@""];
					
					[ cH cacheOff ]; // cachePermanentOff ];
					[serviceTable setEnabled:YES];
					[tvPathContents setEnabled:YES];
					
					//[tvPathContents keyDown:@selector(keyDown:)];

					if ( [ cnf getBoolCnf:@"cnfCheckVersion" ] == YES )
					{
						[self checkLatestVersion];						
					}
					
					if ( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == NO ) {
						[ mnEmptyTrash setHidden: YES ];
					}

				} else {
					
					NSRange textFalseRange = [[response lowercaseString] rangeOfString:[@"FALSE" lowercaseString]];
					if( textFalseRange.location == NSNotFound ) {
						
						[self showErrorPopup:@"Palvelinvirhe." errorDescText:@"Palvelin vastasi virheellisesti, tarkista logista virheilmoitus."];
						[ self addDynLog:[ NSString stringWithFormat:@"Palvelinvirhe: %@", response] entrySeverity:@"ERROR" callerFunction:@"logIn"];
						
						[[serverErrorMessageWebView mainFrame] loadHTMLString:response baseURL:[ NSURL URLWithString:@"http://www.elisaviihde.fi/"]];
						[ serverErrorMessageWindow setTitle:[ NSString stringWithFormat:@"Palvelinvirhe: %@", @"http://www.elisaviihde.fi/"]];
						[ serverErrorMessageWindow setIsVisible:YES ];
						 
					} else {
						[self showErrorPopup:@"Kirjautuminen epäonnistui." errorDescText:@"Tarkista käyttäjätunnuksesi ja salasanasi."];
						[ self addDynLog: [ NSString stringWithFormat:@"Login failed..."] entrySeverity:@"USER" callerFunction:@"logIn"];
					}
					
					if ( [cnf getBoolCnf:@"cbAutoLogin"] )
					{				
						[loginWindow setIsVisible:YES];
					}
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Kirjautuessa kohdattiin virhe: %d\n\n%@\n\n", [error code],[error localizedDescription], response]];
				[ self addDynLog: [ NSString stringWithFormat:@"(%d) %@", 
								   [error code], 
								   [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"logIn"];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"logIn"];
	}
	@finally {
		[ self hideProgress:@"logIn:(id)sender" ];
		[pool drain];   	
	}
}

- (IBAction)enterLogin:(id)sender {
	[self logIn:sender];
}

- (IBAction)mnLogout:(id)sender {
	/* TODO: EMPTY SHELL */
}

-(void)keyDown:(NSEvent *)anEvent {
	/*
	unsigned short kc = [anEvent keyCode];
	NS//Log(@"%hu", kc);
	[super keyDown:anEvent];
	return;
	
	if ( kc == 36 ) { // ENTER
		if ([masterWindow firstResponder] == tvPathContents) {
			[ self pathViewDoubleClickAction:tvPathContents ];			
		} else if ([masterWindow firstResponder] == serviceTable) {
			[ self tvServiceListClick:serviceTable ];			
		} else {
			[super keyDown:anEvent];  // all other objects
			[ masterWindow keyDown:anEvent ];
		}		
	} else if ( kc == 49 ) { // SPACE
		if ([masterWindow firstResponder] == tvPathContents) {
			[ self mnInfo:tvPathContents ];			
		}
	} else if ( kc == 48 ) { // TAB
		if ([masterWindow firstResponder] == serviceTable) {
			[ masterWindow makeFirstResponder: tvPathContents ];
		} else if ([masterWindow firstResponder] == tvPathContents) {
			[ masterWindow makeFirstResponder: searchField ];
		} else if ([masterWindow firstResponder] == searchField) {
			[ masterWindow makeFirstResponder: serviceTable ];
		}
	} else if ( kc == 121 ) { // PGDOWN
		if ([masterWindow firstResponder] == tvPathContents) {
			[ tvPathContents selectRow: ([ tvPathContents selectedRow ] + 20) byExtendingSelection:NO ];			
		} else if ([masterWindow firstResponder] == serviceTable) {
			//[ serviceTable scrollPageDown:serviceTable ];			
		} else {
			[super keyDown:anEvent];  // all other objects
			//[ masterWindow keyDown:anEvent ];
		}				
	} else if ( kc == 116 ) { // PGUP
		if ([masterWindow firstResponder] == tvPathContents) {
			[ tvPathContents selectRow: ([ tvPathContents selectedRow ] - 20) byExtendingSelection:NO ];			
		} else if ([masterWindow firstResponder] == serviceTable) {
			//[ serviceTable scrollPageDown:serviceTable ];			
		} else {
			[super keyDown:anEvent];  // all other objects
			//[ masterWindow keyDown:anEvent ];
		}
	} else {
		[super keyDown:anEvent];  // all other keys
		//[ masterWindow keyDown:anEvent ];
	}
	 */
}

/******************************************************************************
 * Master Screen functions
 ******************************************************************************/
- (IBAction)masterButtonsClick:(id)sender {
	@try {
		int selectedSegment = [ sender tag ];
		NSArray *objects = [acPathContents arrangedObjects];
		NSString *rowid;
		NSString *rowtype;
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
#ifdef DEBUG
			[ self addDynLog: [ NSString stringWithFormat:@"%@", [ objects objectAtIndex: [ tvPathContents selectedRow]]] entrySeverity:@"DEBUG" callerFunction:@"masterButtonsClick"]; 
#endif
		}
		
		switch (selectedSegment) {
			case 0:
				// (@"Reload");
				[ self mnReload:0 ];
				break;
			case 1:
				// (@"Play");
				[ self mnPlay:0 ];
				break;
			case 2:
				// (@"Delete");
				[ self mnDelete:0 ];
				break;
			case 3:
				// (@"Properties");
				[ self mnInfo:0 ];
				break;
			case 4:
				// (@"Add");
				[ self mnAdd:0 ];
				break;
			case 5:
				// (@"Edit: %@ : %@", rowid, rowtype);
				[ self mnModify:0 ];
				break;
			case 6:
				// (@"Download");
				[ self mnDownload:0 ];
				break;
			case 7:
				// (@"Add iCal");
				[ self addToiCal ];
				break;
			case 8:
				NSLog(@"openFacebookToolbox");
				[ self openFacebookToolbox:[ objects objectAtIndex: [ tvPathContents selectedRow]]];
				break;
		}
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"masterButtonsClick"];
	}
}

/******************************************************************************
 * Facebook information functions (generating messages, not itself posting)
 ******************************************************************************/

- (IBAction)acRecAboutLaunchFacebook:(id)sender {
	@try {
		[ tfFacebookCommentProgram setStringValue:[ self getProgramProperty:[tfAboutRecID stringValue] progProperty:@"name"]  ];
		[ tfFacebookCommentTime setStringValue:[ self getProgramProperty:[tfAboutRecID stringValue] progProperty:@"start_time"] ];
		[ tfFacebookCommentChannel setStringValue:[ self getProgramProperty:[tfAboutRecID stringValue] progProperty:@"channel"] ];
		[ tfFacebookProgramID setStringValue:[tfAboutRecID stringValue] ];
		[ tfFacebookCommentComment setString:[ self getProgramProperty:[tfAboutRecID stringValue] progProperty:@"short_text"] ];
		[ pnFacebook setIsVisible:YES ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"acRecAboutLaunchFacebook:(id)sender"];
	}
}

- (void) openFacebookToolbox:(NSDictionary *) programDataDictionary {
	@try {
		[ self showProgress:@"openFacebookToolbox"];

		[ tfFacebookProgramID setStringValue:[programDataDictionary objectForKey:@"id"] ];
		
		NSTimeInterval defaultLength = 2 * 60 * 60;
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		[df setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
		NSDate *startDate = [df dateFromString:[ gfunc maxDate:[ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"start_time"] ] ];	
		NSDate *endDate;
		if ([startDate respondsToSelector:@selector(dateByAddingTimeInterval:)]) {
			endDate = [startDate dateByAddingTimeInterval:defaultLength];
		}
		else {
			endDate = [startDate addTimeInterval:defaultLength];
		}
		
		[ tfFacebookCommentProgram setStringValue:[ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"name"] ];
		[ tfFacebookCommentTime setStringValue:[ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"start_time"] ];
		[ tfFacebookCommentChannel setStringValue:[ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"channel"] ];
		[ tfFacebookCommentComment setString:[ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"short_text"] ];
		
		[ tfFacebookStatusComment setString: [NSString stringWithFormat:@"... %@ (%@, %@)", [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"name"], [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"channel"], [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"start_time"] ] ];
		
		[ tfFacebookEventName setStringValue:[ NSString stringWithFormat:@"Elokuva: %@ (%@ %@)", [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"name"], [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"channel"], [ self getProgramProperty:[programDataDictionary objectForKey:@"id"] progProperty:@"start_time"] ] ];
		
		[ tfFacebookEventDatePick setDateValue:startDate ];
		[ tfFacebookEventDatePickEnd setDateValue:endDate ];
		[ tfFacebookEventDescription setString:@"" ];

		[ pnFacebook setIsVisible:YES ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"openFacebookToolbox"];
	}	
	@finally {
		[ self hideProgress:@"openFacebookToolbox"];
	}
}

- (IBAction) facebookCommentCancel:(id)sender {
	@try {
		[ tfFacebookProgramID setStringValue:@"" ];
		
		[ tfFacebookCommentProgram setStringValue:@"" ];
		[ tfFacebookCommentTime setStringValue:@"" ];
		[ tfFacebookCommentChannel setStringValue:@"" ];
		[ tfFacebookCommentComment setString:@"" ];
		
		[ tfFacebookStatusComment setString:@"" ];
		
		[ tfFacebookEventName setStringValue:@"" ];
		[ tfFacebookEventLocation setStringValue:@"" ];
		[ tfFacebookEventDescription setString:@"" ];
		
		[ pnFacebook setIsVisible:NO ];		
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"facebookCommentCancel"];
	}
}

- (IBAction) facebookCommentOk:(id)sender {
	@try {
		[ self showProgress:@"facebookCommentOk"];

		facebook * fp = [ [facebook alloc] init ];
		
		[ self addDynLog: [ NSString stringWithFormat:@"%@", [ fp 
															  postToFeed:@"" 
															  fbLink:[ NSString stringWithFormat:@"http://elisaviihde.fi/etvrecorder/program.sl?programid=%@", [tfFacebookProgramID stringValue] ]
															  fbPicture:[ NSString stringWithFormat:@"http://tvmedia15.pa.saunalahti.fi/thumbnails/%@.jpg", [tfFacebookProgramID stringValue]] 
															  fbName:[tfFacebookCommentProgram stringValue] 
															  fbCaption:[ NSString stringWithFormat:@"%@ (%@)", [tfFacebookStatusChannel stringValue], [ tfFacebookStatusTime stringValue]] 
															  fbDescription:[tfFacebookCommentComment string]
															  ]] entrySeverity:@"DEBUG" callerFunction:@"facebookCommentOk"];
		[fp release];
		[ self facebookCommentCancel:0 ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"facebookCommentOk"];
	}
	@finally {
		[ self hideProgress:@"facebookCommentOk"];
	}
}

- (IBAction) facebookStatusOk:(id)sender {
	@try {
		[ self showProgress:@"facebookStatusOk"];

		facebook * fp = [ [ facebook alloc ] init ];
		[ self addDynLog: [ NSString stringWithFormat:@"%@", [ fp setStatus: [ tfFacebookStatusComment string ] ] ] entrySeverity:@"DEBUG" callerFunction:@"facebookStatusOk"];
		[ fp release ];
		[ self facebookCommentCancel:0 ];	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"facebookStatusOk"];
	}
	@finally {
		[ self hideProgress:@"facebookStatusOk"];
	}
}

- (IBAction) facebookEventOk:(id)sender {
	@try {
		[ self showProgress:@"facebookEventOk"];

		//2010-05-01T12:47:07+0000
		//2010-04-13T15:29:40+0000
		
		//NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		//[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
		//NSString *dateString = [dateFormatter stringFromDate:[tfFacebookEventDatePick dateValue]];
		
		//NSString *dateString = [NSString stringWithFormat:@"%f", [[ tfFacebookEventDatePick dateValue ] timeIntervalSince1970]];
		
		long ti = (long) [[ tfFacebookEventDatePick dateValue ] timeIntervalSince1970];
		NSString *dateString = [NSString stringWithFormat:@"%ld", ti + (16 * 60 * 60) + [[ tfFacebookEventDatePick timeZone ] secondsFromGMT] ];
		
		long eti = (long) [[ tfFacebookEventDatePickEnd dateValue ] timeIntervalSince1970];
		NSString *eDateString = [NSString stringWithFormat:@"%ld", eti + (16 * 60 * 60) + [[ tfFacebookEventDatePickEnd timeZone ] secondsFromGMT] ];
		
		facebook * fp = [ [ facebook alloc ] init ];
		[ self addDynLog:[NSString stringWithFormat:@"%@", [ fp 
															createEvent:[ tfFacebookEventName stringValue ] 
															fbDescription:[ tfFacebookEventDescription string ] 
															fbStart_time:dateString 
															fbEnd_time:eDateString
															fbLocation:[ tfFacebookEventLocation stringValue ] 
															fbPrivacy:@"SECRET" 
															]]  entrySeverity:@"DEBUG" callerFunction:@"facebookEventOk"];
		[ fp release ];
		NSRunAlertPanel(@"eViihde", @"Facebook tapahtuma luotu. Voit muokata tapahatuman tietoja, sekä kutsua osallistujat Facebookin kautta.", @"Ok", nil, nil);
		
		[ self facebookCommentCancel:0 ];	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"facebookEventOk"];
	}
	@finally {
		[ self hideProgress:@"facebookEventOk"];
	}
}


/******************************************************************************
 * Folder: getRecPath - get current active path
 ******************************************************************************/
- (NSString *) getRecPath {
	NSString * nsmPath = @"";

	@try {
		if ( ![ modelKeyValue compare:@"recs"] ) {
			NSEnumerator * enumerator = [folderPathNames objectEnumerator];
			id element;
		
			while(element = [enumerator nextObject])
			{
				nsmPath = [ nsmPath stringByAppendingString: [NSString stringWithFormat:@"%@/", element] ];
			}
		} else {
			nsmPath = [ NSString stringWithFormat:@"%@/", [ folderPathNames objectAtIndex:0 ] ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"getRecPath"];
	}
	@finally {
		return nsmPath;
	}
}

- (void) setPathPrefix:(NSString *) prefixText {
	@try {
		NSString *uBasePath = [NSString stringWithFormat:@"%@/%@",basePath, prefixText];
		[folderPathNames replaceObjectAtIndex:0 withObject:uBasePath];
		[ currentPath setStringValue:[ self getRecPath ] ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"setPathPrefix"];
	}
}

/******************************************************************************
 * Logging functions
 ******************************************************************************/

- (void) addDynLog:(NSString *) logEntry entrySeverity:(NSString *) entrySeverity callerFunction:(NSString *) callerFunction {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	@try {
		NSDateFormatter *format = [[NSDateFormatter alloc] init];
		[format setDateFormat:@"yyyy.MM.dd HH:mm.ss"];
		
		int intLogEntryLevel = 0;
		if ( entrySeverity == @"DEBUG" ) {		
			intLogEntryLevel = 9; // DEBUG
		} else if ( entrySeverity == @"INFO" ) {
			intLogEntryLevel = 6; // INFO
		} else if ( entrySeverity == @"ERROR" ) {
			intLogEntryLevel = 3; // ERRORS
		} else if (entrySeverity == @"FATAL" ) {
			intLogEntryLevel = 1;
		} else if ( entrySeverity == @"EXCEPTION" ) {
			intLogEntryLevel = 0; // EXCEPTIONS
		} else {
			NSLog(@"level of %@ ?", entrySeverity);
			intLogEntryLevel = 999; // DISCARD
		}
		
#ifdef DEBUG
		curLogLevel = 9;
		writeLog = YES;	
#endif
#ifndef DEBUG
		if (curLogLevel == nil) {
			curLogLevel = 6;
			writeLog = NO;
		}
#endif
		
		if ( curLogLevel >= intLogEntryLevel ) 
		{
			NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
								 [format stringFromDate:[NSDate date]], @"timeStamp",
								 entrySeverity, @"logLevel",
								 logEntry, @"logMessage",
								 callerFunction, @"callerFunction",
								 nil										 
								 ];
			[ dynLogController addObject:dict];				
			[ dynLogTable reloadData ];		
			
			/* Write DICT to file */
			if ( writeLog == YES ) {
				@try {
					NSString *fhLogEntry = [ NSString stringWithFormat:@"[%@][%@][%@]\t%@\n",  [format stringFromDate:[NSDate date]], entrySeverity, callerFunction, logEntry];
					NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath: logPath];
					[fh seekToEndOfFile];
					[fh writeData: [fhLogEntry dataUsingEncoding: NSASCIIStringEncoding]];
					[fh synchronizeFile];		
				}
				@catch (NSException * e) {
					NSLog(@"%@", e);
				}			
			}
		}
		
		if ( curLogLevel >= 9 ) NSLog(@"[%@][%@][%@] %@",  [format stringFromDate:[NSDate date]], entrySeverity, callerFunction, logEntry);
		
	}
	@catch (NSException * e) {
		NSLog(@"addDynLog.exception: %@", e);
	}
	@finally {
		[ pool drain ];
	}
}

- (IBAction) acEraseLog:(id)sender {
	@try {
		[ [ dynLogController content ] removeAllObjects ];
		maDynLog  = [[NSMutableArray alloc] init];
		[ dynLogTable reloadData ];
		[ self addDynLog:@"Log clear" entrySeverity:@"INFO" callerFunction:@"acEraseLog" ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"acEraseLog"];
	}
}

- (IBAction) acExportLog:(id)sender {
	@try {
		[ self addDynLog:@"acExportLog" entrySeverity:@"DEBUG" callerFunction:@"acExportLog" ];
		NSDateFormatter *format = [[NSDateFormatter alloc] init];
		[format setDateFormat:@"yyyyMMdd_HHmmss"];
		NSSavePanel* panel = [NSSavePanel savePanel];
		[panel
		 beginSheetForDirectory:nil
		 file:[ NSString stringWithFormat:@"eviihde_%@.html", [format stringFromDate:[NSDate date]] ]
		 modalForWindow:[NSApp mainWindow]
		 modalDelegate:self
		 didEndSelector:@selector(saveLogAsDidEnd:returnCode:contextInfo:)
		 contextInfo:nil
		 ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"acExportLog"];
	}
}

- (IBAction) acPrintLog:(id) sender {
	[ self addDynLog:@"acPrintLog" entrySeverity:@"DEBUG" callerFunction:@"acPrintLog" ];	
}

- (IBAction) acOpenLogItem:(id)sender {
	@try {
		NSArray *objects = [dynLogController arrangedObjects];			
		if ([dynLogTable selectedRow] > -1 ) {
			[errorInfoPanel setTitle:@"Logimerkintä"];
			[errorHeader setStringValue:[ NSString stringWithFormat:@"%@ (%@, %@)", 
										 [[ objects objectAtIndex:[dynLogTable selectedRow]] valueForKey:@"callerFunction"], 
										 [[ objects objectAtIndex:[dynLogTable selectedRow]] valueForKey:@"logLevel"], 
										 [[ objects objectAtIndex:[dynLogTable selectedRow]] valueForKey:@"timeStamp"]									 
										 ]];
			[errorDesc setString:
			 [ NSString stringWithFormat:@"%@", 
			  [[ objects objectAtIndex:[dynLogTable selectedRow]] valueForKey:@"logMessage"] 
			  ]
			 ];
			[errorInfoPanel setIsVisible:YES];		
		}
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"acOpenLogItem"];
	}
}

-(void)saveLogAsDidEnd:(NSOpenPanel*)panel
			returnCode:(int)rc contextInfo:(void*)ctx {
	@try {
		[ self showProgress:@"Tallennan logitiedostoa..."];
		if(rc != NSOKButton) {
			return;
		}		

		NSString *exportFilename = [ panel filename ];
		NSArray *objects = [dynLogController arrangedObjects];
		NSString *fileMode = @"";
		
		NSMutableString *content = [[ NSMutableString alloc] initWithString:@""];
		
		if ( [ exportFilename hasSuffix:@".html" ] ) {
			fileMode = @"html";
			[ content appendFormat:@"<HTML><HEAD><TITLE>Log : %@</TITLE></HEAD><BODY>\n<TABLE STYLE='width: 100%%; border: 1px solid;'>\n<TR STYLE='background-color: #33CCAA;'><TH>timeStamp</TH><TH>callerFunction</TH><TH>logLevel</TH><TH>logMessage</TH></TR>\n", [ NSDate date ] ];
		} else 	if ( [ exportFilename hasSuffix:@".elog" ] ) {
			fileMode = @"elog";
			[ content appendString:@"{\"eviihde_log\":[" ];
		} else 	if ( [ exportFilename hasSuffix:@".log" ] ) {
			fileMode = @"plain";
		} else {
			fileMode = @"plain";
		}
		
		NSString * rowStyle = @"";
		int rowOdd = 1;
		
		for (NSDictionary *dict in objects) {
			if ( fileMode == @"html" ) {
				if (rowOdd == 1) {
					rowStyle = @"#d0d0d0";
					rowOdd = 2;
				} else if ( rowOdd == 2 ) {
					rowStyle = @"#fafafa";
					rowOdd = 1;				
				}
				[ content appendFormat:@"<TR VALIGN=TOP STYLE='background-color: %@;'><TD WIDHT=120>%@</TD><TD WIDHT=170>%@</TD><TD WIDTH=100>%@</TD><TD>%@</TD></TR>\n", rowStyle, [ dict valueForKey:@"timeStamp" ], [ dict valueForKey:@"callerFunction" ], [ dict valueForKey:@"logLevel" ], [ dict valueForKey:@"logMessage" ]];
			} else if ( fileMode == @"elog" ) {
				[ content appendFormat:@"%@", dict ];
			} else if ( fileMode == @"plain") {
				[ content appendFormat:@"%@\t%@\t%@\t%@\n", [ dict valueForKey:@"timeStamp" ], [ dict valueForKey:@"callerFunction" ], [ dict valueForKey:@"logLevel" ], [ dict valueForKey:@"logMessage" ]];			
			}
		}
		
		
		if ( fileMode == @"html" ) {
			[ content appendString:@"</TABLE></BODY></HTML>" ];
		}
		
		if ( [ exportFilename hasSuffix:@"elog" ] ) {
			[ content appendString:@"]}" ];
		}
		
		NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
		[[NSFileManager defaultManager] createFileAtPath:exportFilename
												contents:fileContents
											  attributes:nil];	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"saveLogAsDidEnd"];
	}
	@finally {
		[ self hideProgress:@"Tallennan logitiedostoa..."];
	}
}

/******************************************************************************
 * Show progressbar window during use
 ******************************************************************************/
- (void) showProgress:(NSString *) requestorString {
	@try {
		if ( requestorString != @"" ) {
			[ statusScreenArray addObject:requestorString ];
			[httpLoaderProgress setUsesThreadedAnimation:YES];
			//[ httpLoaderScreen setIsVisible:NO ];
			NSMutableString * screenDump = [[NSMutableString alloc] initWithString:@""];
			for ( int logEntrys = 0; logEntrys < [ statusScreenArray count ]; logEntrys++)
			{
				[ screenDump appendFormat:@"%@\n", (NSString *)[ statusScreenArray objectAtIndex:logEntrys ]];
			}
			//[ httpTextField setStringValue:[NSString stringWithFormat:@"%@", (NSString *)[ statusScreenArray lastObject ]] ];
			[ httpTextField setStringValue:screenDump ];
			//[ httpLoaderScreen setIsVisible:YES ];
			[ httpTextField display];
			//[httpTextField setStringValue:[ NSString stringWithFormat:@"%@%@\n", [ httpTextField stringValue ], requestorString ]];
			[ self addDynLog: [ NSString stringWithFormat: @"%@ : Started", requestorString ] entrySeverity:@"DEBUG" callerFunction:@"showProgress"];
			[httpLoaderScreen update];
		}
		if ( progIsOpen == 0 ) {
			[httpLoaderScreen setIsVisible:YES];
			[httpLoaderProgress startAnimation:self];
		}
		progIsOpen++;	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"showProgress"];
	}
	@finally {
	}
}

- (void) showProgress {
	[ self showProgress:@"" ];
}

- (void) hideProgress:(NSString *) requestorString {
	progIsOpen--;	
	
	@try {
		if ( requestorString != @"" ) {
			
			/*
			NSMutableString *parsedStatus = [NSMutableString stringWithString:[ httpTextField stringValue ]];
			
			[ parsedStatus replaceOccurrencesOfString:[ NSString stringWithFormat:@"%@\n", requestorString ] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [parsedStatus length])];
			*/
			[ statusScreenArray removeLastObject ];
			if ( progIsOpen > 0 ) {				
				NSMutableString * screenDump = [[NSMutableString alloc] initWithString:@""];
				//[ httpLoaderScreen setIsVisible:NO ];
				for ( int logEntrys = 0; logEntrys < [ statusScreenArray count ]; logEntrys++)
				{
					[ screenDump appendFormat:@"%@\n", (NSString *)[ statusScreenArray objectAtIndex:logEntrys ]];
				}
				//[ httpTextField setStringValue:[NSString stringWithFormat:@"%@", (NSString *)[ statusScreenArray lastObject ]] ];
				[ httpTextField setStringValue:screenDump ];
				//[ httpLoaderScreen setIsVisible:YES ];
				[ httpTextField display];

			}
			[ self addDynLog: [ NSString stringWithFormat: @"%@ : Ended", requestorString ] entrySeverity:@"DEBUG" callerFunction:@"hideProgress"];
			//[httpTextField setStringValue:parsedStatus];
		}
		if ( progIsOpen < 0 ) {
			progIsOpen = 0;
		}
		
		if ( progIsOpen == 0 ) {
			[httpLoaderProgress stopAnimation:self];
			[httpLoaderScreen setIsVisible:NO];
		}	
		
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"hideProgress"];
	}
	@finally {
	}
}

- (void) cancelProgress {
	@try {
		progIsOpen = 0;
		[httpLoaderProgress stopAnimation:self];
		[httpLoaderScreen setIsVisible:NO];	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"cancelProgress"];
	}
}

- (void) hideProgress {
	@try {
		[ self hideProgress:@"" ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"hideProgress"];
	}
}

- (IBAction)mnDynLog:(id) sender {
	@try {
		if ( [dynLogWindow isVisible] == NO )
		{
			[ dynLogWindow setIsVisible:YES ];
		}	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnDynLog"];
	}
}

// Show manualy progressbar window
- (IBAction)mnShowStatusScreen:(id)sender {
	@try {
		if ( [httpLoaderScreen isVisible] == YES )
		{
			[mnShowStatusScreen setTitle:@"Näytä tilaruutu"];
			[ self hideProgress ];
		} else {
			[mnShowStatusScreen setTitle:@"Piilota tilaruutu"];
			[ self showProgress ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnShowStatusScreen"];
	}
}


/******************************************************************************
 * Show about screen
 ******************************************************************************/
- (IBAction)mnShowAbout:(id)sender {
	@try {
		[aboutPanel setIsVisible:YES ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnShowAbout"];
	}
}

- (IBAction) mnFacebook:(id)sender {
	@try {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.facebook.com/group.php?gid=121706797862360"]];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnFacebook"];
	}
}

- (IBAction) mnFacebookEV:(id)sender {
	@try {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.facebook.com/ElisaViihde"]];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnFacebookEV"];
	}
}

/******************************************************************************
 * Status screen functions (error popup)
 ******************************************************************************/
- (void) showErrorPopup:(NSString *)errorHeaderText errorDescText:(NSString *)errorDescText {
	@try {
		[ self cancelProgress ];
		[ self addDynLog:[ NSString stringWithFormat:@"%@\n\nVirhe suoritettaessa : %@", errorDescText, [ httpTextField stringValue ]]  entrySeverity:@"ERROR" callerFunction:@"showErrorPopup"];
		[errorInfoPanel setTitle:@"Virhe"];
		[errorHeader setStringValue:errorHeaderText];
		[errorDesc setString:[ NSString stringWithFormat:@"%@\n\nVirhe suoritettaessa : %@", errorDescText, [ httpTextField stringValue ]]];
		[errorInfoPanel setIsVisible:YES];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"showErrorPopup"];
	}
	@finally {
	}
}

- (IBAction)iaErrorOKButton:(id)sender {
	@try {
		[errorInfoPanel setTitle:@"Virhe"];
		[errorHeader setStringValue:@""];
		[errorDesc setString:@""];
		[errorInfoPanel setIsVisible:NO];	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"iaErrorOKButton"];
	}
	@finally {
	}
}

/******************************************************************************
 * Service view functions 
 ******************************************************************************/
- (IBAction)loadServices {
	[ self showProgress:@"loadServices" ];
	@try {
		[ [ acServiceList content ] removeAllObjects ];
		maServiceList  = [[NSMutableArray alloc] init];				
		NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
							 [serviceIconArray objectAtIndex:f_videoID], @"iconURL", 
							 @"Tallenteet", @"serviceText",
							 @"recs", @"modelKey",
							 nil
							 ];
		[ acServiceList addObject:dict];				
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
							[serviceIconArray objectAtIndex:f_linksID], @"iconURL", 
							@"Ohjelmakartta", @"serviceText",
							@"tvguide", @"modelKey",
							nil
							];
		[ acServiceList addObject:dict];				
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
							 [serviceIconArray objectAtIndex:f_linksID], @"iconURL", 
							 @"Tulevat tallenteet", @"serviceText",
							 @"recstocome", @"modelKey",
							 nil
							 ];
		[ acServiceList addObject:dict];				
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
							 [serviceIconArray objectAtIndex:f_favsID], @"iconURL", 
							 @"Aina tallentuvat", @"serviceText",
							 @"alwaysonrecs", @"modelKey",
							 nil
							 ];
		[ acServiceList addObject:dict];				
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
			   [serviceIconArray objectAtIndex:f_favsID], @"iconURL", 
			   @"Suositut ohjelmat", @"serviceText",
			   @"commonfavs", @"modelKey",
			   nil
			   ];
		[ acServiceList addObject:dict];				

		dict =[NSDictionary dictionaryWithObjectsAndKeys:
				   [serviceIconArray objectAtIndex:f_searchID], @"iconURL", 
				   @"Haku", @"serviceText",
				   @"search", @"modelKey",
				   nil
				   ];
		[ acServiceList addObject:dict];
		
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
			   [serviceIconArray objectAtIndex:f_downloadsID], @"iconURL", 
			   @"Latauksessa", @"serviceText",
			   @"indownload", @"modelKey",
			   nil
			   ];
		[ acServiceList addObject:dict];				
		dict =[NSDictionary dictionaryWithObjectsAndKeys:
			   [serviceIconArray objectAtIndex:f_videoID], @"iconURL", 
			   @"Uusimmat tallenteet", @"serviceText",
			   @"latestrecs", @"modelKey",
			   nil
			   ];
		[ acServiceList addObject:dict];				
		
		if ( ( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == YES ) && (trashFound == YES) ) {
			dict =[NSDictionary dictionaryWithObjectsAndKeys:
				   [serviceIconArray objectAtIndex:f_trashID], @"iconURL", 
				   @"Roskakori", @"serviceText",
				   @"trashcan", @"modelKey",
				   nil
				   ];
			[ acServiceList addObject:dict];							
		}
		
		[ serviceTable reloadData ];	
		
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
		{
			[ searchField setEnabled:YES ];
		} else {			
			[ searchField setStringValue:@"Ei hakua Saunavisiossa" ];
			[ searchField setEnabled:NO ];
		}		
		[ serviceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO ];
		[ self tvServiceListClick: serviceTable ];
        
        [ self changeFont:serviceTable size:[ cnf getIntCnf:@"guiServiceFontSize" ] ];

	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"EXCEPTION: on loadTops : %@", e] entrySeverity:@"EXCEPTION" callerFunction:@"loadServices"];
	}
	@finally {
		[ self hideProgress:@"loadServices" ];
	}
}

- (IBAction)tvServiceListClick:(id)sender {
	@try {
		[ prgInfoBox setHidden:YES ];

		NSArray *objects = [acServiceList arrangedObjects];			
		if ([serviceTable selectedRow] > -1 ) 
		{
			[ [ acPathContents content ] removeAllObjects ];
			[ tvPathContents reloadData ];
			[ tvPathContents setAllowsMultipleSelection:NO ];
			/*
			 if (modelKeyValue == @"indownload") {
			 [ dlViewTimer invalidate ];			
			 }
			 */
			[ mnRestore setHidden: YES ];
			[ mnMove setHidden: YES ];
			
			modelKeyValue = [ [ objects objectAtIndex: [serviceTable selectedRow] ] objectForKey:@"modelKey"];
			
			if ( ![ modelKeyValue compare:@"recs"] ) {
				[ tbAddButton setToolTip:@"Lisää kansio" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"Poista tallenne/kansio" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				if ([cnf getBoolCnf:@"pathFolderShowBytes"]) {
					[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Tallennusaika / Kansion koko"];					
				} else {
					[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Tallennusaika / Tallenteita"];					
				}
				[self setPathPrefix:@"Tallenteet"];
				[ tvPathContents setAllowsMultipleSelection:YES ];
				[ mnMove setHidden: NO ];
				
				[ cH cacheOff ];
				[ self loadPath:curFolderID parentFolder:curParentFolder ];
				[ cH cacheOn ];				
				
			} else if (![ modelKeyValue compare:@"tvguide"]) {
				[ tbAddButton setToolTip:@"Tallenna ohjelma" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
				[self setPathPrefix:@"Ohjelmaopas"];
				[masterStatusLabel setStringValue:@""];
				if (curGuideLocation == @"c") {
					[self initChanList];		
					[self reloadContRecsChannels ];
				} else {
					[self loadChanGuide:curGuideLocation];
				}
			} else if (![ modelKeyValue compare:@"recstocome" ]) {
				[ tbEditButton setToolTip:@"Muokkaa tallennusta" ];
				[ tbDeleteButton setToolTip:@"Poista tallennus" ];
				[ tbAddButton setToolTip:@"" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Tallennusaika"];
				[self setPathPrefix:@"Tulevat tallenteet"];
				[self loadInRecList];
				[masterStatusLabel setStringValue:@""];
			} else if (![ modelKeyValue compare:@"alwaysonrecs"]) {
				[ tbEditButton setToolTip:@"Muokkaa jatkuvaa tallennusta" ];
				[ tbDeleteButton setToolTip:@"Poista jatkuva tallennus" ];
				[ tbAddButton setToolTip:@"" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Kanava / Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Tallennuskansio"];
				[self setPathPrefix:@"Aina tallentuvat"];
				[ tvPathContents setAllowsMultipleSelection:YES ];
				[self loadContRecs];
				[masterStatusLabel setStringValue:@""];
			} else if (![ modelKeyValue compare:@"commonfavs" ]) {
				[ tbAddButton setToolTip:@"Tallenna ohjelma" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
				[self setPathPrefix:@"Suosikit"];
				[self loadTops];
				[masterStatusLabel setStringValue:@""];
			} else if (![ modelKeyValue compare:@"search" ]) {
				[ tbAddButton setToolTip:@"" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"Poista tallenne" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
				
				if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
				{
					if ( sender > 0 ) {
						[self launchSearch:searchField ];				
					}
				}				
				
				[self setPathPrefix:@"Haku"];
			} else if (![ modelKeyValue compare:@"indownload" ]) {
				[ tbAddButton setToolTip:@"" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"Keskeytä lataaminen" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Tila"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Latauskansio"];
				[ tvPathContents setAllowsMultipleSelection:YES ];
				
				[ self populateDownload ];
				/*
				 dlViewTimer = [NSTimer scheduledTimerWithTimeInterval:2
				 target:self
				 selector:@selector(populateDownload)
				 userInfo:nil
				 repeats:YES];
				 
				 */
				[self setPathPrefix:@"Latauksessa"];
			} else if (![ modelKeyValue compare:@"latestrecs" ]) {
				[ tbAddButton setToolTip:@"" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"Poista tallenne" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
				[ tvPathContents setAllowsMultipleSelection:YES ];
				
				[ self showProgress:@"loadLatestRecs" ];
				[ [ acPathContents content ] removeAllObjects ];		
				
				NSSortDescriptor *dateSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"start_time" ascending:NO selector:@selector(compare:)] autorelease];
				[latestRecs sortUsingDescriptors:[NSArray arrayWithObjects:dateSortDescriptor, nil]];
				
				/* Max 30 latest at time */
				int showCount = [ latestRecs count ];
				
				if ( [cnf getBoolCnf:@"showLatestOnlyUnwatched" ]) {
					int collectedCount = 0;
					for ( int lRecCount = 0; lRecCount < showCount; lRecCount++) {
						if ( ! [ wDB isWatched:[ [ latestRecs objectAtIndex:lRecCount ] objectForKey:@"id"] ] ) {
							[ acPathContents addObject: [ latestRecs objectAtIndex:lRecCount ] ];				
							collectedCount ++;
						}
						if ( collectedCount == 60 ) {
							break;
						}
					}
				} else {
					if ( showCount > 60 ) {
						showCount = 60;
					}
					for ( int lRecCount = 0; lRecCount < showCount; lRecCount++) {
						[ acPathContents addObject: [ latestRecs objectAtIndex:lRecCount ] ];				
					}
				}
				
				[ tvPathContents reloadData ];
				
				[ self hideProgress:@"loadLatestRecs" ];
				[masterStatusLabel setStringValue:@""];
				[self setPathPrefix:@"Uusimmat tallenteet"];
			} else if (![ modelKeyValue compare:@"trashcan" ]) {
				[ tbAddButton setToolTip:@"" ];
				[ tbEditButton setToolTip:@"" ];
				[ tbDeleteButton setToolTip:@"Poista tallenne" ];
				
				[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
				[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
				[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
				[self setPathPrefix:@"Roskakori"];
				[ tvPathContents setAllowsMultipleSelection:YES ];
				[ mnRestore setHidden:NO ];
				[ self loadPath:trashFolderID parentFolder:trashFolderID ];
			}
		}	
        [ self changeFont:serviceTable size:[ cnf getIntCnf:@"guiServiceFontSize" ] ];
        [ self changeFont:tvPathContents size:[ cnf getIntCnf:@"guiRecordingsFontSize" ] ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"tvServiceListClick"];
	}
}

/******************************************************************************
 * In-record list routines
 ******************************************************************************/

- (void) deleteContinousRec {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ cH cacheOff ];
	[ self showProgress:@"deleteContinousRec" ];
	@try {
		NSArray *objects = [acPathContents arrangedObjects];
		NSString* Wlocation = [NSString stringWithFormat: @"%@://%@/wildcards.sl?remover=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"id"] ];
		
		NSString *inRecID = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"rec_id"];
		NSString *chanListProgramName = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"name"];
		NSString *recRemovePrompt = @"";
		NSString *recRemoveDesc = @"";
		
		if ( ! [inRecID compare:@""] )
		{	
			recRemovePrompt = @"Poistetaanko toistuva tallennus?";
			recRemoveDesc = [NSString stringWithFormat:@"%@\n%@", 
							 chanListProgramName,
							 [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"]];
		} else {
			recRemovePrompt = @"Poistetaanko tuleva tallennus?";
			recRemoveDesc = [NSString stringWithFormat:@"%@\n%@, %@", 
							 chanListProgramName,
							 [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"],
							 [gfunc maxDate:[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"start_time"]]];
		}
		
		int alertReturn = NSRunInformationalAlertPanel(recRemovePrompt, recRemoveDesc, @"Kyllä", @"Ei", nil);
		
		if ( alertReturn == NSAlertDefaultReturn) {		
			if (Wlocation) {
				NSError *Werror = nil;
				NSString *Wresponse = [ htEngine httpGet:Wlocation error:Werror]; // [self execHTTP:Wlocation errorResp:Werror];
				if (!Werror) {
				} else {
					[ self hideProgress:@"deleteContinousRec" ];
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [Werror code],[Werror localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", Wresponse ]  entrySeverity:@"ERROR" callerFunction:@"deleteContinousRec"];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [Werror code], 
									  [Werror localizedDescription]]  entrySeverity:@"ERROR" callerFunction:@"deleteContinousRec"];			
				}	
			}
			[ self mnReload:0 ];			
		}			
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"deleteContinousRec"];	
	}
	@finally {
		[ self hideProgress:@"deleteContinousRec" ];
		[ cH cacheOn ];
		[ pool drain ];
		[ self mnReload: 0 ]; 
	}	
}

- (void) deleteSingleRec {
	@try {
		[ self deleteSingleRec:YES ];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"deleteSingleRec"];
	}
}

- (void) deleteSingleRec:(BOOL) shouldConfirm {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		[ cH cacheOff ];
		NSArray *objects = [acPathContents arrangedObjects];			
		if ([tvPathContents selectedRow] > -1 ) 
		{
			NSString *inRecID = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"rec_id"];
			NSString *chanListProgramName = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"name"];
			NSString *recRemovePrompt = @"";
			NSString *recRemoveDesc = @"";
			
			if ( ! [inRecID compare:@""] )
			{	
				recRemovePrompt = @"Poistetaanko toistuva tallennus?";
				recRemoveDesc = [NSString stringWithFormat:@"%@\n%@", 
								 chanListProgramName,
								 [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"]];
			} else {
				recRemovePrompt = @"Poistetaanko tuleva tallennus?";
				recRemoveDesc = [NSString stringWithFormat:@"%@\n%@, %@", 
								 chanListProgramName,
								 [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"],
								 [gfunc maxDate:[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"start_time"]]];
			}
			
			int alertReturn = NSAlertDefaultReturn;
			if (shouldConfirm) {
				alertReturn = NSRunInformationalAlertPanel(recRemovePrompt, recRemoveDesc, @"Kyllä", @"Ei", nil);				
			}
			
			if ( alertReturn == NSAlertDefaultReturn) {		
				if ( [inRecID length] != 0 )
				{
					NSString* location = [NSString stringWithFormat: @"%@://%@/program.sl?remover=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], inRecID ];

					
					if (location) {
						NSError *error = nil;
						//NSString *response = [self execHTTP:location errorResp:error];
						[htEngine httpExec:location error:error];
						if (!error) {
						} else {
							[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
							//[ self addDynLog:[ NSString stringWithFormat: @"HTTP-RESPONSE: %@", response ]  entrySeverity:@"ERROR" callerFunction:@"deleteSingleRec"];
							[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
											  [error code], 
											  [error localizedDescription]]  entrySeverity:@"ERROR" callerFunction:@"deleteSingleRec"];			
						}	
					}
				}	
			}
		}	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e]  entrySeverity:@"EXCEPTION" callerFunction:@"deleteSingleRec"];
	}
	@finally {
		[ cH cacheOn ];
		[ self mnReload: 0 ];
		[pool drain];
	}	
}

- (void) loadInRecList {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"initInRecList" ];
	
	@try {
		[ [ acPathContents content ] removeAllObjects ];
		maPathContents  = [[NSMutableArray alloc] init];
		int rowCount = 0;
		NSString* location = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError *error = nil;
			NSArray *inRecsData = [ htEngine jsonHttpExec:location error:error ];

			if (!error) {
				[ self addDynLog:[ NSString stringWithFormat:@"%@", inRecsData] entrySeverity:@"DEBUG" callerFunction:@"loadInRecsList"];
				NSArray *recordingsData = (NSArray *)[inRecsData valueForKey:@"recordings"];

				NSString * isWild = @"";
				for(NSArray *prgdata in recordingsData) {
					
					if ( [prgdata valueForKey:@"wild_card"]  )
					{	
						isWild = @"x";
					} else {
						isWild = @"";
					}
					
					NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
										 [serviceIconArray objectAtIndex:timerID], @"icon",
										 isWild, @"rec_is_wild",
										 [[prgdata valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
										 [[prgdata valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
										 [gfunc maxDate:[prgdata valueForKey:@"start_time" ]], @"start_time",
										 [[prgdata valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
										 [prgdata valueForKey:@"id"], @"rec_id",
										 @"g", @"type",
										 nil										 
										 ];

					rowCount++;
					[acPathContents addObject:dict];	
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]]  entrySeverity:@"ERROR" callerFunction:@"loadInRecsList"];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e]  entrySeverity:@"EXCEPTION" callerFunction:@"loadInRecsList"];
	}
	@finally {
		[tvPathContents reloadData ];
		[ self hideProgress:@"initInRecList" ];
		[pool drain]; 		
	}
}

- (BOOL) isInRec:(NSString *) progID {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {		
		NSString* location = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError *error = nil;
			[ cH cacheOn ];
			//NSString *response = [self execHTTP:location errorResp:error];
			NSString *response = [htEngine httpGet:location error:error];
			if (!error) {
				[ self addDynLog:response  entrySeverity:@"DEBUG" callerFunction:@"isInRec"];
				NSRange qRange = [ response rangeOfString:[ NSString stringWithFormat:@"\"%@\"", progID] ];
				if ( qRange.length > 0 ) {
					return YES;
				} else {					
					return NO;
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]]  entrySeverity:@"ERROR" callerFunction:@"isInRec"];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e]  entrySeverity:@"EXCEPTION" callerFunction:@"isInRec"];
	}
	@finally {
		[pool drain]; 		
	}
	return NO;
}


- (void)loadContRecs {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"reloadContRecsView" ];
	@try {
		[ [ acPathContents content ] removeAllObjects ];
		maPathContents = [[NSMutableArray alloc] init];
		int rowCount = 0;
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/wildcards.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError *error = nil;
			NSArray *inRecsData = [ htEngine jsonHttpExec:location error:error ];

			if (!error) {
				NSArray *recordingsData = (NSArray *)[inRecsData valueForKey:@"wildcardrecordings"];
				
				NSString * isWild = @"x";
				for(NSArray *prgdata in recordingsData) {
					
					NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
										 [serviceIconArray objectAtIndex:timerID], @"icon",
										 [[prgdata valueForKey:@"wild_card"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
										 [[prgdata valueForKey:@"wild_card_channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
										 [[prgdata valueForKey:@"folder"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"start_time",
										 [[prgdata valueForKey:@"recording_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
										 //[prgdata valueForKey:@"id"], @"rec_id",
										 isWild, @"rec_is_wild",
										 @"g", @"type",
										 nil										 
										 ];
					rowCount++;
					[acPathContents addObject:dict];				
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]]  entrySeverity:@"ERROR" callerFunction:@"loadContRecs"];
			}
		}
		[tvPathContents reloadData ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e ]  entrySeverity:@"EXCEPTION" callerFunction:@"loadContRecs"];	
	}
	@finally {
		[ self hideProgress:@"reloadContRecsView" ];	
		[pool drain]; 
	}
}

- (IBAction)btChangeContRecStatus:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSString * ssTfWildcardRecEdit = [ tfWildcardRecEdit stringValue ];
		if ( ![ [ cbIsWildcard stringValue ] compare:@"0"] ) {
			[ tfWildcardRecEdit setEnabled:NO ];
			[ cbChannelRecEdit setEnabled:NO ];
			if ( [[ ssTfWildcardRecEdit substringFromIndex: [ ssTfWildcardRecEdit length ] ] compare:@"*" ] ) {
				ssTfWildcardRecEdit = [ssTfWildcardRecEdit substringToIndex:[ssTfWildcardRecEdit length] - 1];
				[ tfWildcardRecEdit setStringValue:[ NSString stringWithFormat:@"%@", ssTfWildcardRecEdit ] ];
			}		
		} else {
			[ tfWildcardRecEdit setEnabled:YES ];
			[ cbChannelRecEdit setEnabled:YES ];
			
			NSString * ssTfWildcardRecEdit = [ tfWildcardRecEdit stringValue ];
			if ( [[ ssTfWildcardRecEdit substringFromIndex: [ ssTfWildcardRecEdit length ] ] compare:@"*" ] ) {
				[ tfWildcardRecEdit setStringValue:[ NSString stringWithFormat:@"%@*", ssTfWildcardRecEdit ] ];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btChangeContRecStatus"];
	}
	@finally {
		[ pool drain ];
	}	
}

- (IBAction)btSaveRecEditAct:(id)sender {
	// TODO : IMPLEMENT //
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ cH cacheOff ];
	[ self showProgress:@"btSaveContRecEditAct:(id)sender" ];
	
	@try {
		NSString* location = @"";
		NSArray *fobjects = [ acRecEditFolder arrangedObjects ];
		NSArray *objects = [ acRecEditChan arrangedObjects];
		
		if ( ([tfRecID stringValue] != @"") && ([tfEditorProgID stringValue] != @"") ) {
			location = [NSString stringWithFormat: @"%@://%@/wildcards.sl?edit_wildcard=%@&channel=%@&wildcard=%@&folderid=%@&ajax=true", 
						[cnf getStringCnf:@"httpServerProtocol"],
						[cnf getStringCnf:@"httpServerAddress"],
						[tfRecID stringValue],
						[gfunc urlEncode:[[ objects objectAtIndex: [ cbChannelRecEdit indexOfSelectedItem ] ] objectForKey:@"chanName"]],
						[gfunc urlEncode: [ tfWildcardRecEdit stringValue ] ],
						[[ fobjects objectAtIndex: [ cbFolderRecEdit indexOfSelectedItem ] ] objectForKey:@"folderID"]
						];					
		} else if ([tfEditorProgID stringValue] != @"") {
			/* Is new */
			if ( ![[cbIsWildcard stringValue] compare:@"1"] ) {
				if ( ([[ [acPathContents arrangedObjects] objectAtIndex: [tvPathContents selectedRow] ] valueForKey:@"rec_is_wild"] != @"x") && ( modelKeyValue == @"recstocome" ) ) {
					[ self deleteSingleRec:NO ];
				}
				
				location = [NSString stringWithFormat: @"%@://%@/wildcards.sl?channel=%@&folderid=%@&wildcard=%@&record=true&ajax=true", 
							[cnf getStringCnf:@"httpServerProtocol"],
							[cnf getStringCnf:@"httpServerAddress"],
							[gfunc urlEncode:[[ objects objectAtIndex: [ cbChannelRecEdit indexOfSelectedItem ] ] objectForKey:@"chanName"]],
							[gfunc urlEncode:[[ fobjects objectAtIndex: [ cbFolderRecEdit indexOfSelectedItem ] ] objectForKey:@"folderID"]],
							[gfunc urlEncode: [ tfWildcardRecEdit stringValue ] ]];
			} else {
				location = [NSString stringWithFormat: @"%@://%@/program.sl?programid=%@&record=%@&folderid=%@&ajax=true", 
							[cnf getStringCnf:@"httpServerProtocol"],
							[cnf getStringCnf:@"httpServerAddress"],
							[tfEditorProgID stringValue], 
							[tfEditorProgID stringValue], 
							[[ fobjects objectAtIndex: [ cbFolderRecEdit indexOfSelectedItem ] ] objectForKey:@"folderID"] 
							];
			}
		}
		
		if (location) {
			NSError *error = nil;
			NSString *response = [ htEngine httpGet:location error:error ]; //[NSString stringWithCString:[data bytes] length:[data length]];  
			
			if (!error) {
			} else {
				[self showErrorPopup:@"Virhe tallentaessa ajastusta" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"ERROR" callerFunction:@"btSaveRecEditAct"];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"btSaveRecEditAct"];	
			}	
			
		}
		[ tfWildcardRecEdit setStringValue:@"" ];
		[ cbChannelRecEdit selectItemAtIndex:0 ];
		[ cbFolderRecEdit selectItemAtIndex:0 ];
		[ tfRecID setStringValue: @""];
		[ self mnReload:self ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btSaveRecEditAct"];	
	}
	@finally {
		[ self hideProgress:@"btSaveContRecEditAct:(id)sender" ];
		[tfWildcardRecEdit setStringValue:@""];
		[cbIsWildcard setIntValue:0];
		[cbIsWildcard setEnabled:YES];
		[tfRecID setStringValue:@""];
		[tfEditorProgID setStringValue:@""];
		[wnRecView setIsVisible:NO];	
		[ cH cacheOn ];
		[pool drain];
	}	
}

- (IBAction)btCancelRecEditAct:(id)sender {
	@try {
		[tfRecID setStringValue:@""];
		[tfEditorProgID setStringValue:@""];
		[tfWildcardRecEdit setStringValue:@""];
		[cbIsWildcard setIntValue:0];
		[tfRecID setStringValue:@""];
		[tfEditorProgID setStringValue:@""];
		[wnRecView setIsVisible:NO];
		[cbIsWildcard setEnabled:YES];
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btCancelRecEditAct"];
	}
}

- (void) showCreateEditRecTimer {
	@try {
		NSArray *objects = [acPathContents arrangedObjects];
		NSArray *fobjects = [ acRecEditFolder arrangedObjects ];
		NSArray *cobjects = [ acRecEditChan arrangedObjects ];
		
		NSString *rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
		NSString *rowname = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"name"];
		NSString *rowtype = @"";
		NSString *rowiswild = @"";
		NSString *rowrecid = @"";
		NSString *rowfolder = @"";
		NSString *rowchan = @"";
		
		[tfWildcardRecEdit setStringValue:rowname];
		
		if ( modelKeyValue == @"alwaysonrecs" ) {
			[ cbIsWildcard setEnabled:NO ];
			
			if ( [ tvPathContents selectedRow] > -1 ) {
				rowrecid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"rec_id"];
				rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
				rowiswild = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"rec_is_wild"]; 
				rowfolder = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"start_time"]; 
				rowchan=[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"];				
			}		
			
			if (rowiswild == @"x") {
				[cbIsWildcard setIntValue:1];		
			} else {
				[cbIsWildcard setIntValue:0];		
			}	
			
			if ( rowrecid != nil) {
				[tfEditorProgID setStringValue:rowrecid];		
			} else {
				[tfEditorProgID setStringValue:@""];
			}
			
			if ( rowid != nil) {
				[tfRecID setStringValue:rowid];		
			} else {
				[tfRecID setStringValue:@""];
			}				
			
		} else if ( modelKeyValue == @"tvguide" ) {
			[ cbIsWildcard setEnabled:YES ];
			rowchan = curGuideLocation;
			[ cbFolderRecEdit selectItemAtIndex:0 ];
		} else if (modelKeyValue == @"commonfavs") {
			[ cbIsWildcard setEnabled:YES ];
			rowchan=[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"];
			[ cbFolderRecEdit selectItemAtIndex:0 ];		
		} else if ( modelKeyValue == @"recstocome" ) {
			[ cbIsWildcard setEnabled:YES ];
			rowchan=[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"];
			[ cbFolderRecEdit selectItemAtIndex:0 ];				
		} else if ( modelKeyValue == @"search" ) {
			[ cbIsWildcard setEnabled:YES ];
			rowchan=[[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"chan_size"];
			[ cbFolderRecEdit selectItemAtIndex:0 ];
		}
		
		if ( [rowfolder compare:@""] ) {
			for (int fID=0; fID < [ fobjects count ]; fID++){
				if ( ![[[fobjects objectAtIndex: fID ] objectForKey:@"unMaskedName"] compare:rowfolder] )
				{
					[ cbFolderRecEdit selectItemAtIndex:fID ];
				}
			}		
		} else {
			[cbFolderRecEdit selectItemAtIndex:0];
		}
		
		for (int fID=0; fID < [ cobjects count ]; fID++){
			if ( ![[[cobjects objectAtIndex: fID ] objectForKey:@"chanName"] compare:rowchan] )
			{
				[ cbChannelRecEdit selectItemAtIndex:fID ];
			}
		}	
		
		[tfEditorProgID setStringValue:rowid];
		
		if ( ![ [ cbIsWildcard stringValue ] compare:@"0"] ) {
			[ tfWildcardRecEdit setEnabled:NO ];
			[ cbChannelRecEdit setEnabled:NO ];
		} else {
			[ tfWildcardRecEdit setEnabled:YES ];
			[ cbChannelRecEdit setEnabled:YES ];		
		}
		
		[wnRecView setIsVisible:YES];	
	}
	@catch (NSException * e) {
		[ self addDynLog: [ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"showCreateEditRecTimer"];
	}
}

- (void) reloadContRecsFolders {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		
		latestRecs = [ [NSMutableArray alloc] init ];
		
		[ [ acRecEditFolder content ] removeAllObjects ];
		maRecFolder  = [[NSMutableArray alloc] init];
		
		NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
							 @"(oletus)", @"folderName",
							 @"(oletus)", @"unMaskedName",
							 @"", @"folderID",
							 nil
							 ];	
		[ acRecEditFolder addObject:dict];	
		[ self loadSubFolder:@"" toArray:acRecEditFolder deep:@"  " ];
		[ cbFolderRecEdit reloadData ];
		[ cbFolderTrashRestore reloadData ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"reloadContRecsFolders"];	
	}
	@finally {
		[pool drain];    
	}
}

- (void) loadSubFolder:(NSString *)folderID toArray:(NSArrayController *)folderController deep:(NSString *)fillerString {
	
	[ self showProgress:[ NSString stringWithFormat:@"loadSubFolder : %@ ", folderID] ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSError *error = nil;
		NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], folderID];
		
		if (location) {
			NSArray *folderCData = [ htEngine jsonHttpExec:location error:error ];

			if (!error) {
				NSArray *foldersData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"folders"];
				NSArray *recordingsData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"recordings"];
				for(NSArray *folderData in [foldersData objectAtIndex:0]) {
					if ( [(NSString *) [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:trashFolderID ] ) {
						NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSString stringWithFormat:@"%@%@", fillerString, [[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]], @"folderName",
											 [[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"unMaskedName",
											 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"folderID",
											 nil
											 ];	
						[ folderController addObject:dict];
						[self loadSubFolder:[[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] toArray:folderController 
									   deep:[NSString stringWithFormat:@"  %@", fillerString ]];
					}					
				}
				
				for(NSArray *recordData in [recordingsData objectAtIndex:0]) {
					
					if ([cnf getBoolCnf:@"cnfSyncServer"]) {
						/** Onko tallenne katsottu webin/digiboksin/eV:n kautta? Synkronoidaan tiedot **/
						if ( 
							( [ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) &&
							( [[[recordData valueForKey:@"viewcount"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] intValue] == 0 ) 
							) 
						{
							NSString* setWatchedLocation = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&view=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
							[ htEngine httpExec:setWatchedLocation error:nil ];
						}
						
						if ( 
							( ![ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) &&
							( [[[recordData valueForKey:@"viewcount"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] intValue] > 0 ) 
							) 
						{
							[ wDB setIsWatched:[[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
						}							
					}
					
					int recIcon = 8;
					if ( [ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) recIcon = 1;
					
					NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
										  [serviceIconArray objectAtIndex:recIcon], @"icon",
										  [[recordData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
										  [[recordData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
										  [gfunc maxDate:[[[recordData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] substringFromIndex:3]], @"start_time",
										  @"r", @"type",
										  [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
										  nil];
					[ latestRecs addObject:dictR];
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa tallennuksia: %d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"loadSubFolder"];
			}
		}			
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e ] entrySeverity:@"EXCEPTION" callerFunction:@"loadSubFolder"];	
	}
	@finally {
		[ self hideProgress:[ NSString stringWithFormat:@"loadSubFolder : %@ ", folderID] ];
		[pool drain]; 	
	}
}

- (void) reloadContRecsChannels {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		[ [ acRecEditChan content ] removeAllObjects ];
		maRecChan  = [[NSMutableArray alloc] init];
		
		[ cH cacheOff ];
		NSString* location = [NSString stringWithFormat:@"%@://%@/ajaxprograminfo.sl?channels", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError *error = nil;
			NSString *response = [ htEngine httpGet:location error:error]; //[self execHTTP:location errorResp:error];
			if (!error) {
				NSArray *prog_ids = [response componentsSeparatedByString: @"\n"];			
				NSArray *chanListAR = [ [ prog_ids objectAtIndex:1] componentsSeparatedByString: @","];
				
				for(NSString * myStr in chanListAR) {
					NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
										 [myStr stringByReplacingOccurrencesOfString:@"\"" withString:@"" ], @"chanName",
										 nil];
					
					[acRecEditChan addObject:dict];
					[cbChannelRecEdit reloadData ];
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"reloadContRecsChannels"];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"reloadContRecsChannels"];	
	}
	@finally {
		[ cH cacheOn ];
		[pool drain];    
	}
}

/******************************************************************************
 * Search routines
 ******************************************************************************/
- (IBAction)launchSearch:(id)sender {
	
	if ( [[sender stringValue] length] == 0 ) {
		return;
	}
	
	[serviceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:5] byExtendingSelection:NO];
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"launchSearch:(id)sender" ];
	@try {
		[ cH cacheOff ];
		
		NSMutableArray * acPathContentsCache = [[ NSMutableArray alloc] init];
		modelKeyValue = @"search";
		[ self setPathPrefix:@"Haku" ];
		[[[tvPathContents tableColumnWithIdentifier:@"name"] headerCell] setTitle:@"Nimi"];
		[[[tvPathContents tableColumnWithIdentifier:@"chan_size"] headerCell] setTitle:@"Kanava"];
		[[[tvPathContents tableColumnWithIdentifier:@"start_time"] headerCell] setTitle:@"Esitysaika"];
		
		[ [ acPathContents content ] removeAllObjects ];
		maPathContents  = [[NSMutableArray alloc] init];
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/ajaxsearch.sl?search_all=true&q=%@", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [ gfunc urlEncode:[sender stringValue]]];
		if (location) {
			NSError *error = nil;
			if (!error) {
				NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:[ htEngine httpGetData:location error:error ] options:0 error:&error];
				NSXMLNode *rootNode = [xml rootElement];
				int rootCount = [ rootNode childCount ];
				rootCount = rootCount - 4;
				
				[masterStatusLabel setStringValue:[ NSString stringWithFormat:@"Löytyi %i tallennetta.", rootCount]];
				
				for ( int progCount = 0; progCount < rootCount; progCount++) {
					
					int recIcon = 8;
					if ( [ wDB isWatched: [[[ rootNode childAtIndex:progCount ] childAtIndex:5] stringValue ] ] ) recIcon = 1;
					
					NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
										 [serviceIconArray objectAtIndex:recIcon], @"icon",
										 [[[ rootNode childAtIndex:progCount ] childAtIndex:1] stringValue], @"name",
										 [[[ rootNode childAtIndex:progCount ] childAtIndex:0] stringValue], @"chan_size",
										 [gfunc maxDate:[[[ rootNode childAtIndex:progCount ] childAtIndex:3] stringValue]], @"start_time",
										 [[[ rootNode childAtIndex:progCount ] childAtIndex:5] stringValue], @"id",
										 @"r", @"type",
										 nil
										 ];
					[acPathContentsCache addObject:dict]; //[acPathContents addObject:dict];				
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa Suosikki Ohjelmia: %d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"launchSearch"];
			}
		}
				
		/** Jos edellisestä hausta on alle tunti aikaa, ei ladata tietoja serveriltä **/
		if ( (lastSearch + 3600) < [[NSDate date] timeIntervalSince1970] ) {
			lastSearch = [[NSDate date] timeIntervalSince1970];
		} else {
			[ cH cacheOn ];
		}


		if ( [ cnf getBoolCnf:@"cnfGuideSearch" ] ) {
			/** Search thru all TV channels listed on guide **/
			NSString* IRlocation = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
			NSError *IRerror = nil;
			inRecordList = [ htEngine httpGet:IRlocation error:IRerror]; //[self execHTTP:IRlocation errorResp:IRerror];
			
			NSString* chanLocation = [NSString stringWithFormat:@"%@://%@/ajaxprograminfo.sl?channels", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
			if (chanLocation) {
				NSError *error = nil;
				NSString *response = [ htEngine httpGet:chanLocation error:error];
				if (!error) {
					NSArray *prog_ids = [response componentsSeparatedByString: @"\n"];			
					NSArray *chanListAR = [ [ prog_ids objectAtIndex:1] componentsSeparatedByString: @","];
					for(NSString * myStr in chanListAR) {
						NSString* chanContLocation = [NSString stringWithFormat: @"%@://%@/ajaxprograminfo.sl?channel=%@", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [ gfunc urlEncode:[myStr stringByReplacingOccurrencesOfString:@"\"" withString:@"" ]]];
						if (chanContLocation) {
							NSError *error = nil;
							NSArray *chanData = [ htEngine jsonHttpExec:chanContLocation error:error];
							NSArray *chanProgData = [ chanData valueForKey:@"programs" ];
							
							for(NSArray *prgdata in chanProgData) {
								
								NSString * progName = [[prgdata valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
								NSRange qRange = [ [progName lowercaseString] rangeOfString:[[sender stringValue] lowercaseString] ];
								
								if ( qRange.length > 0 ) {
									int icon_id = guide_itemID;
									NSRange inRecRange = [ [NSString stringWithFormat:@"%@", inRecordList] rangeOfString:[ NSString stringWithFormat:@"\"%@\"", [prgdata valueForKey:@"id"]] ];
									if ( inRecRange.length > 0 ) {
										icon_id = guide_item_inrecID;
									}
									NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
														 [serviceIconArray objectAtIndex:icon_id], @"icon",
														 [[prgdata valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
														 [myStr stringByReplacingOccurrencesOfString:@"\"" withString:@"" ], @"chan_size",
														 [gfunc maxDate:[prgdata valueForKey:@"start_time"]], @"start_time",
														 [prgdata valueForKey:@"id"], @"id",
														 @"g", @"type",
														 nil
														 ];
									[acPathContentsCache addObject:dict]; //[acPathContents addObject:dict];				
								}
							}
						}
					}
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"initChanList"];
				}
			}		
			/** Search thru all TV channels listed on guide **/			
		}
		
		NSSortDescriptor *dateSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"start_time" ascending:NO selector:@selector(compare:)] autorelease];
		[acPathContentsCache sortUsingDescriptors:[NSArray arrayWithObjects:dateSortDescriptor, nil]];
		
		for ( int lRecCount = 0; lRecCount < [ acPathContentsCache count]; lRecCount++) {
			[ acPathContents addObject: [ acPathContentsCache objectAtIndex:lRecCount ] ];				
		}				
		[ tvPathContents reloadData ];		
		[ cH cacheOn ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"launchSearch"];
	}
	@finally {
		[ self hideProgress:@"launchSearch:(id)sender" ];
		[pool drain];    
	}	
}

/******************************************************************************
 * Favorities routines
 ******************************************************************************/
- (IBAction)loadTops {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"loadTops:(id)sender" ];
	@try {
		[ cH cacheOff ];
		
		NSString* IRlocation = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		NSError *IRerror = nil;
		inRecordList = [ htEngine httpGet:IRlocation error:IRerror]; // [self execHTTP:IRlocation errorResp:IRerror];		
		
		[ [ acPathContents content ] removeAllObjects ];
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/default.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
																																						  
		if (location) {
			NSError *error = nil;
			NSArray *toplist = [ htEngine jsonHttpExec:location error:error ];
			
			if (!error) {
				NSArray *top_programs = (NSArray *)[toplist valueForKey:@"programs"];
				/* JSON Framework dataloader */
				for(NSArray *prgdata in top_programs) {
					
					int icon_id = guide_itemID;
					
					if (!IRerror) {
						NSRange qRange = [ inRecordList rangeOfString:[ NSString stringWithFormat:@"\"%@\"", [prgdata valueForKey:@"program_id"]] ];
						if ( qRange.length > 0 ) {
							icon_id = guide_item_inrecID;
						}
					}
					
					NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
										 [serviceIconArray objectAtIndex:icon_id], @"icon",
										 [[prgdata valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
										 [[[prgdata valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
										 [gfunc maxDate:[[prgdata valueForKey:@"start_time" ] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]], @"start_time",
										 [[prgdata valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
										 @"g", @"type",
										 nil
										 ];
					[acPathContents addObject:dict];				
				}
				[ tvPathContents reloadData ];
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa Suosikki Ohjelmia: %d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"loadTops"];
			}
		}
		[ cH cacheOn ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"loadTops"];
	}
	@finally {
		[ self hideProgress:@"loadTops:(id)sender" ];
		[pool drain];    
	}
}

/******************************************************************************
 * Setting-screen loader routines
 ******************************************************************************/
- (IBAction)mnShowSettings:(id)sender {
	// LOAD SETTINGS, APPLY TO SETTINGS SCREEN //
	[ self showProgress:@"mnShowSettings" ];
	@try {
		if (![NSBundle loadNibNamed:@"cnfWindow" owner:@"cnfWindowDelegate"])
		{
			[ self addDynLog:[ NSString stringWithFormat:@"Warning! Could not load myNib file.\n"] entrySeverity:@"FATAL" callerFunction:@"mnShowSettings"];
		}			
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnShowSettings"];
	}
	@finally {
		[ self hideProgress:@"mnShowSettings" ];
	}
}

/******************************************************************************
 * Login-screen routines
 ******************************************************************************/
- (IBAction)cbRememberClick:(id)sender {	
	@try {
		if ( [cbRemember integerValue] )
		{
			[cbAutoLogin setEnabled:YES];
			[cbAutoLogin setState: [cnf getBoolCnf:@"cbAutoLogin"]];
		} else {
			[cbAutoLogin setEnabled:NO];
			[cbAutoLogin setState: 0];		
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"cbRememberClick"];
	}
	@finally {
	}
}

- (IBAction)cbAutoLoginClick:(id)sender {
	@try {
		[cnf setBoolCnf:@"cbAutoLogin" value:[sender integerValue]];
		if ( [ sender integerValue ] == YES ) {
			[ cbRemember setState: 1 ];
			[ cbRemember setEnabled:NO ];
		} else {
			[ cbRemember setEnabled:YES ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"cbAutoLoginClick"];
	}
	@finally {
	}
}

/******************************************************************************
 * Record path routines
 ******************************************************************************/
- (IBAction) pathViewClick:(id) sender {
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int) rowIndex {	
	
	int keyCode = 0;
	if ( [[NSApp currentEvent] type ] == NSKeyDown) {
		keyCode = [[NSApp currentEvent] keyCode];
		if ( (keyCode != 125) && (keyCode != 126)) return NO;
	}
	
	if ( aTableView == tvPathContents ) {
		@try {
			NSArray *objects = [acPathContents arrangedObjects];			
			if (rowIndex > -1 ) 
			{
				NSString *rowType = [ [ objects objectAtIndex: rowIndex ] objectForKey:@"type"];
				
				//&& (! ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask))
				if ( (! ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)) && (! ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask))) {
					if ( [ cnf getBoolCnf:@"cnfDisplaySmallInfoBox" ]) {
						[ cH cacheOn ];
						
						if ( ( ( rowType == @"g" ) && ([modelKeyValue compare:@"alwaysonrecs"]))  || ( rowType == @"r")) {
							NSArray * prgDataArray = [ self getProgramPropertyArray:[ [ objects objectAtIndex: rowIndex ] objectForKey:@"id"]];
							
							[ prgInfoBox setHidden:NO ];
							[ prgInfoBox setTitle: [ [ objects objectAtIndex: rowIndex ] objectForKey:@"name"]];
							
							[ quickBoxPrgDateTimeChannel setStringValue:[ NSString stringWithFormat:@"%@ (%@)", [[ prgDataArray valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [[ prgDataArray valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
							[ quickBoxPrgInfo setStringValue: [[ prgDataArray valueForKey:@"short_text"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
							if ( ![(NSString *)[ prgDataArray valueForKey:@"has_ended"] compare:@"true"] )
							{
								NSURL *imageURL = [NSURL URLWithString: [[prgDataArray valueForKey:@"tn"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]; 
								NSData *imageData = [imageURL resourceDataUsingCache:NO];
								NSImage *imageFromBundle = [[NSImage alloc] initWithData:imageData];
								[quickBoxPrgImage setImage:imageFromBundle];
								[imageFromBundle release];				
							} else {
								NSString* imageName = [[NSBundle mainBundle] pathForResource:[ cnf getStringCnf:@"serviceIconName"] ofType:[ cnf getStringCnf:@"serviceIconFileType"]];	
								NSImage* imageObj = [[NSImage alloc] initWithContentsOfFile:imageName];
								[quickBoxPrgImage setImage:imageObj];
								[imageObj release];
							}									
						} else {
							[ prgInfoBox setHidden:YES ];
						}				
					} else {
						[ prgInfoBox setHidden:YES ];
					}					
				}				
				if ( ![ modelKeyValue compare:@"recs"] ) {
					if ( rowType == @"r" ) {
						[ tbDeleteButton setToolTip:@"Poista tallenne" ];				
						[ tbEditButton setToolTip:@"" ];
					} else if ( rowType == @"f" ) {
						[ tbDeleteButton setToolTip:@"Poista kansio" ];
						[ tbEditButton setToolTip:@"Nimeä kansio" ];
					}
				}		
			}
		}
		@catch (NSException * e) {
			[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"tableView:(NSTableView *)"];
		}
		@finally {
			[ cH cacheOff ];
		}		
	} else if ( aTableView == serviceTable) {
		//[ serviceTable selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO ];
		//[self tvServiceListClick:serviceTable ]; 
	}
	return YES;
}

- (IBAction)pathViewDoubleClickAction:(id)sender {	
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		if ([sender selectedRow] > -1 ) 
		{
			NSString *rowType = [ [ objects objectAtIndex: [sender selectedRow] ] objectForKey:@"type"];

			if (rowType == @"r") {
				[self acRecWatch:0];				
			} else if (rowType == @"f") {
				NSString *loadFolder = @"";
				activeFolderName = [[ objects objectAtIndex: [sender selectedRow] ] objectForKey:@"name"];
				activeFolderID = [[ objects objectAtIndex: [sender selectedRow] ] objectForKey:@"id"];
				
				loadFolder = activeFolderID;
				if ( [activeFolderName compare:@".."] )
				{
					[self pushFolder:curFolderID folderName:activeFolderName];
				} else {
					loadFolder = [self popFolder];
				}
				
				[ self loadPath:loadFolder parentFolder:curFolderID ];
			} else if ( rowType == @"c" ) {
				NSString *chanName = [[ objects objectAtIndex: [sender selectedRow] ] objectForKey:@"name"];
				if ( chanName == @".." ) {
					[self initChanList];
				} else {
					[self loadChanGuide:chanName];
				}
			} else if ( rowType == @"g" ) {
				if ((modelKeyValue == @"tvguide" ) || (modelKeyValue == @"recstocome")) {
					[ self acShowProgInfo:[[ objects objectAtIndex: [sender selectedRow] ] objectForKey:@"id"] ];
				} else if (modelKeyValue == @"alwaysonrecs") {
					[ self mnModify:0 ];
				} // recstocome
			}							
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"pathViewDoubleClickAction"];
	}
	@finally {
	}		
}

- (void) pushFolder:(NSString *)folderID folderName:(NSString *)folderName {
	[ self showProgress:@"pushFolder" ];

	@try {
		[folderPathIDs addObject:folderID];
		[folderPathNames addObject:folderName];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"pushFolder"];
	}
	@finally {
		[ self hideProgress:@"pushFolder" ];
	}
}

- (id) popFolder {
	[ self showProgress:@"popFolder" ];

	id lastPID = NULL;
	@try {
		lastPID = [[[folderPathIDs lastObject] retain] autorelease];
		if (lastPID) {
			[folderPathIDs removeLastObject];		
		}
		
		id lastPN = [[[folderPathNames lastObject] retain] autorelease];
		if (lastPN) {
			[folderPathNames removeLastObject];		
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"popFolder"];
	}
	@finally {
		[ self hideProgress:@"popFolder" ];
		return lastPID; //theParent;
	}
}

- (void) loadPath:(NSString *) folderID parentFolder:(NSString *)parentID
{
	[ cH cacheOff ];
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:[ NSString stringWithFormat:@"loadPath : %@ / %@", parentID, folderID] ];
	
	@try {
		[ [ acPathContents content ] removeAllObjects ];
		int recCount = 0;
		int folCount = 0;
		BOOL jsonFail = NO;
		if ( modelKeyValue == @"recs" ) {
			curParentFolder = parentID;
			curFolderID = folderID;
			[ tfCurDirID setStringValue:folderID ];			
		}
		
		if ( [ folderID compare:@"" ] ) {
			parentID = @"";
		}
		
		NSError *error = nil;

		if ( modelKeyValue == @"recs" ) {
			if ( ( [parentID compare:folderID] ) && ( [folderID compare:@""] ) )
			{
				NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
									 [serviceIconArray objectAtIndex:folderIconID], @"icon",
									 @"..", @"name",
									 @"", @"chan_size",
									 @"", @"start_time",
									 @"f", @"type",
									 parentID, @"id",
									 nil
									 ];	
				[ acPathContents addObject:dict];				
			}
		}				
		
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
		{
			// Elisa Viihde service style
			NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], folderID];

			if (location) {
				NSArray *folderCData = [ htEngine jsonHttpExec:location error:error ];
				if (!error) {
					NSArray *recordingsData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"recordings"];
					NSArray *foldersData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"folders"];

					if ( modelKeyValue == @"recs" ) {
						for(NSArray *folderData in [foldersData objectAtIndex:0]) {
							if  (
								( ( [[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:@"eviihde.trash"] ) || ( [ trashFolderID compare:[folderData valueForKey:@"id"]] ) )
								||
								( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == NO )
								)
							{								
								NSString * sizeString = @"";
								if ( [cnf getBoolCnf:@"pathFolderShowBytes"]) {
									sizeString =  [[folderData valueForKey:@"size"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
									if ( ![sizeString compare:@"0.00 B"] ) {
										sizeString = @"";
									}									
								} else {
									sizeString =  [[folderData valueForKey:@"recordings_count"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];									
								}
								
								NSMutableString * foundFolderName = [[ NSMutableString alloc] initWithString:[NSString stringWithString:[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];								
								if ( ![foundFolderName compare:@"eviihde.trash"])
								{
									[ foundFolderName appendString:[ NSString stringWithString:@" (ylimääräinen)"]];
								}
								
								
								
								NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
													 [serviceIconArray objectAtIndex:folderIconID], @"icon",
													 foundFolderName, @"name",
													 @"", @"chan_size",
													 sizeString, @"start_time",
													 @"f", @"type",
													 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
													 nil
													 ];	
								[ acPathContents addObject:dict];
								folCount++;							
							} else {
								if ( ![ trashFolderID compare:@"_"] ) {
									trashFolderID = [ [NSString alloc] initWithString:
													 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
													 ];					
									[ self addDynLog:[ NSString stringWithFormat:@"trash found : %@", trashFolderID] entrySeverity:@"INFO" callerFunction:@"loadPath"];										
								}
								trashFound = YES;
							}		
						}
					}					
					for(NSArray *recordData in [recordingsData objectAtIndex:0]) {
						
						if ([cnf getBoolCnf:@"cnfSyncServer"]) {
							/** Onko tallenne katsottu webin/digiboksin/eV:n kautta? Synkronoidaan tiedot **/
							if ( 
								( [ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) &&
								( [[[recordData valueForKey:@"viewcount"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] intValue] == 0 ) 
								) 
							{
								// Set ev.fi == watched : http://elisaviihde.fi/etvrecorder/program.sl?programid=[ID]&view=true
								NSString* setWatchedLocation = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&view=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
								[ htEngine httpExec:setWatchedLocation error:nil ];
							}
							
							if ( 
								( ![ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) &&
								( [[[recordData valueForKey:@"viewcount"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] intValue] > 0 ) 
								) 
							{
								// Set ev == watched
								[ wDB setIsWatched:[[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
							}							
						}
					 	
						int recIcon = 8;
						if ( [ wDB isWatched: [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ) recIcon = 1;
						
						NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
											  [serviceIconArray objectAtIndex:recIcon], @"icon",
											  [[recordData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
											  [[recordData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
											  [gfunc maxDate:[[[recordData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] substringFromIndex:3]], @"start_time",
											  @"r", @"type",
											  [[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
											  nil];	// [gfunc maxDate:
						[ acPathContents addObject:dictR];
						recCount++;
					}
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa tallennuksia: %d\n\n%@", [error code],[error localizedDescription]]];
					
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]]
					   entrySeverity:@"ERROR" callerFunction:@"loadPath"];
					
					jsonFail = YES;
				}
			}			
		} else {
			// Saunavisio service style...
			
			int stepOverCount = 0;
			BOOL doNextLoop = YES;
			
			while (doNextLoop == YES) {
				NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=%@&ajax=true&ppos=%u", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], folderID, stepOverCount ];
				
				if (location) {
					NSArray *folderCData = [ htEngine jsonHttpExec:location error:error ];
					if (!error) {
						int recCounterForParts = 0;
						NSArray *recordingsData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"recordings"];
						NSArray *foldersData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"folders"];
						
						if ( modelKeyValue == @"recs" ) {
							for(NSArray *folderData in [foldersData objectAtIndex:0]) {
								if ( ( [[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:@"eviihde.trash"] ) || ( [ trashFolderID compare:[folderData valueForKey:@"id"]] ) ){								
								//if ( [[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:@"eviihde.trash"] ) {
									NSString * sizeString =  [[folderData valueForKey:@"size"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
									if ( ![sizeString compare:@"0.00 B"] ) {
										sizeString = @"";
									}
									
									NSMutableString * foundFolderName = [[ NSMutableString alloc] initWithString:[NSString stringWithString:[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];								
									if ( ![foundFolderName compare:@"eviihde.trash"])
									{
										[ foundFolderName appendString:[ NSString stringWithString:@" (ylimääräinen)"]];
									}
									
									NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
														 [serviceIconArray objectAtIndex:folderIconID], @"icon",
														 foundFolderName, @"name",
														 @"", @"chan_size",
														 sizeString, @"start_time",
														 @"f", @"type",
														 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
														 nil
														 ];										
									[ acPathContents addObject:dict];
									folCount++;								
								} else {
									if ( ![ trashFolderID compare:@"_"] ) {
										trashFolderID = [ [NSString alloc] initWithString:
														 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
														 ];
										[ self addDynLog:[ NSString stringWithFormat:@"trash found : %@", trashFolderID] entrySeverity:@"INFO" callerFunction:@"loadPath"];										
									}
									trashFound = YES;
								}
								
							}
						}
						for(NSArray *recordData in [recordingsData objectAtIndex:0]) {
							NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
													[serviceIconArray objectAtIndex:recordIconID], @"icon",
													[[recordData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
													[[recordData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"chan_size",
													[gfunc maxDate:[[[recordData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] substringFromIndex:3]], @"start_time",
													@"r", @"type",
													[[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
													nil];	// [gfunc maxDate:
							[ acPathContents addObject:dictR];
							recCount++;
							recCounterForParts++;
						}				
						if ( recCounterForParts < 30 ) {
							doNextLoop = NO;
							break;
						} else {
							stepOverCount = stepOverCount + 30;
						}
					} else {
						[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa tallennuksia: %d\n\n%@", [error code],[error localizedDescription]]];
						[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
										  [error code], 
										  [error localizedDescription]]
								entrySeverity:@"ERROR" callerFunction:@"loadPath"];
						jsonFail = YES;
						break;
					}
				}
			}	
		}
		
		if (recCount == 0) {
			NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
								  @"", @"icon",
								  @"", @"name",
								  @"", @"chan_size",
								  @"", @"start_time",
								  @"", @"id",
								  nil
								  ];	
			[ acPathContents addObject:dictR];
			
		}

		[ tvPathContents reloadData ];
		[ masterStatusLabel setStringValue:[NSString stringWithFormat:@"Kansioita %d, Tallennuksia %d", folCount, recCount]];
		[ tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO ];
        [ self changeFont:tvPathContents size:[ cnf getIntCnf:@"guiRecordingsFontSize" ] ];

	}	
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"EXCEPTION: %@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"loadPath"];
	} 
	@finally {
		[ currentPath setStringValue:[ self getRecPath ] ];
		[ self hideProgress:[ NSString stringWithFormat:@"loadPath : %@/%@", parentID, folderID] ];
		[pool drain]; 
		[ cH cacheOn ];
	}		
}

- (void) checkTrashFolder
{
	if ( [ cnf getBoolCnf:@"cnfEnableTrashCan"] == YES ) {
		[ self showProgress:@"checkTrashFolder"];
		[ self addDynLog:@"checking for trash, creating one if not found." entrySeverity:@"DEBUG" callerFunction:@"checkTrashFolder"];
		
		if ( trashFound == NO) 
		{
			NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
			
			if (location) {
				NSError * error = nil;
				[ cH cacheOff ];
				NSArray *folderCData = [ htEngine jsonHttpExec:location error:error ];
				[ cH cacheOn ];
				if (!error) {
					NSArray *foldersData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"folders"];
					for(NSArray *folderData in [foldersData objectAtIndex:0]) {
						if ( ![[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:@"eviihde.trash"] ) {
							if ( ![ trashFolderID compare:@"_"] ) {
								trashFolderID = [ [NSString alloc] initWithString:
												 [[folderData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
												 ];					
								[ self addDynLog:[ NSString stringWithFormat:@"trash found : %@", trashFolderID] entrySeverity:@"INFO" callerFunction:@"checkTrashFolder"];										
							}
							trashFound = YES;
						}
					}
					
					// creation //
					if (trashFound == NO) {
						if ( [ cnf getBoolCnf:@"cnfEnableTrashCanAutocreate"] == YES ) {
							[ self addDynLog:@"no trash, creating one..." entrySeverity:@"INFO" callerFunction:@"checkTrashFolder"];
							[ self acFolCreate:@"eviihde.trash" ];
							[ self checkTrashFolder ];
						} else {
							int alertReturn = NSRunInformationalAlertPanel(@"eViihde ei löytänyt roskakoria, vaikka se on kytketty käyttöön.", @"Luodaanko uusi?", @"Kyllä", @"Ei", nil);
							if ( alertReturn == NSAlertDefaultReturn ) {
								[ self addDynLog:@"no trash, creating one..." entrySeverity:@"INFO" callerFunction:@"checkTrashFolder"];
								[ self acFolCreate:@"eviihde.trash" ];
								[ self checkTrashFolder ];
							} else {
								NSRunInformationalAlertPanel(@"eViihde ei luonut roskakoria käyttäjän pyynnöstä.", @"Roskakoritoiminne poistetaan käytöstä.", @"Ok", nil, nil);
								[ self addDynLog:@"trash not found, trashcan function active, user denied trashcan creation. Disabling trash functions." entrySeverity:@"INFO" callerFunction:@"checkTrashFolder"];									
								[ cnf setBoolCnf:@"cnfEnableTrashCan" value:NO ];
							}
						}

					} 			
				}
			}		
			[ self hideProgress:@"checkTrashFolder"];
		} else {
			[ self addDynLog:[ NSString stringWithFormat:@"trash already found, skipping entire lookup : %@", trashFolderID] entrySeverity:@"DEBUG" callerFunction:@"checkTrashFolder"];										
		}
	}

}

- (void) cleanUpTrashFolderMess
{
	if ( [ cnf getBoolCnf:@"cnfEnableTrashCan"] == YES ) {
		[ self showProgress:@"cleanUpTrashFolderMess"];

		[ self addDynLog:@"cleaning up eviihde.trash mess..." entrySeverity:@"DEBUG" callerFunction:@"cleanUpTrashFolderMess"];										
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError * error = nil;
			[ cH cacheOff ];
			NSArray *folderCData = [ htEngine jsonHttpExec:location error:error ];
			[ cH cacheOn ];
			if (!error) {
				NSArray *foldersData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"folders"];
				
				NSMutableString * foldersToBeRemoved = [ [NSMutableString alloc] init];
				[ foldersToBeRemoved appendString:@"Varmista että allaolevassa listassa on VAIN eviihde.trash nimisiä kansioita listattuna. Vaihtoehtoisesti ylimääräiset eviihde.trash kansiot voi poistaa myös ohjelman kautta.\n\n"];
				int extra_folders = 0;
				
				NSMutableArray *trashFolderIDs = [[NSMutableArray alloc] init];
				
				for(NSArray *folderData in [foldersData objectAtIndex:0]) {
					if ( ![[[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] compare:@"eviihde.trash"] ) {
						if ( [ trashFolderID compare:[folderData valueForKey:@"id"]] ) {
							[ self addDynLog:[ NSString stringWithFormat:@"not active trash folder, must go... id=%@", [folderData valueForKey:@"id"]] entrySeverity:@"DEBUG" callerFunction:@"cleanUpTrashFolderMess"];	
							[ trashFolderIDs addObject: [ NSString stringWithString:[folderData valueForKey:@"id"]]];
							extra_folders++;
							if (extra_folders <= 20) {
								[ foldersToBeRemoved appendFormat:@"%@ (%@)\n", [[folderData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [folderData valueForKey:@"id"]];							
							}
						} else {
							[ self addDynLog:[ NSString stringWithFormat:@"active trash, leaving id=%@", [folderData valueForKey:@"id"]] entrySeverity:@"DEBUG" callerFunction:@"cleanUpTrashFolderMess"];										
						}
					}
				}
				
				if ( extra_folders > 0)  {
					if (extra_folders > 20) {
						[ foldersToBeRemoved appendFormat:@"..." ];
					}
					int alertReturn = NSRunInformationalAlertPanel([NSString stringWithFormat:@"eViihde löysi %i kpl ylimääräisiä eviihde.trash kansioita, poistetaanko?", extra_folders], foldersToBeRemoved, @"Kyllä", @"Ei", nil);				
					
					if ( alertReturn == NSAlertDefaultReturn ) {
						NSLog(@"removing...");
						for ( int folderCount = 0; folderCount < [ trashFolderIDs count ]; folderCount++) {
							NSString *location = [NSString stringWithFormat:
												  @"%@://%@/ready.sl?delete_folder=%@&ajax=true",
												  [cnf getStringCnf:@"httpServerProtocol"], 
												  [cnf getStringCnf:@"httpServerAddress"],
												  [trashFolderIDs objectAtIndex:folderCount]
												  ];
							NSLog(@"deleting (%@): %@", [trashFolderIDs objectAtIndex:folderCount], location);
							if (location) {
								NSError *error = nil;
								[ cH cacheOff ];
								NSArray *response = [ htEngine jsonHttpExec:location error:error]; //[self execHTTP:location errorResp:error];
								[ cH cacheOn ];
								if (error) {
									[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
									
									[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
													  [error code], 
													  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"cleanUpTrashFolderMess"];
								}
							} 
						}					
					}
				}
			}
		}					
		[ self hideProgress:@"cleanUpTrashFolderMess"];
	}
}

/******************************************************************************
 * Folder related routines
 ******************************************************************************/

- (IBAction) folderCancel:(id)sender {
	[ self showProgress:@"folderCancel" ];
	@try {
		[ tfFolderName setStringValue:@"" ];
		[ tfFolderAction setStringValue:@"" ];
		[ pnFolderEditor setIsVisible:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"folderCancel"];
	}
	@finally {
		[ self hideProgress:@"folderCancel" ];
	}
}

- (IBAction) folderOk:(id)sender {
	[ self showProgress:@"folderOk" ];
	@try {
		if ( ![[ tfFolderAction stringValue ] compare:@"add" ] ) {
			[ self acFolCreate: [tfFolderName stringValue] ];
		} else if ( ![[ tfFolderAction stringValue ] compare:@"ren" ] ) {
			[ self acFolRename: [tfFolderName stringValue] ]; 
		}
		[ tfFolderName setStringValue:@"" ];
		[ tfFolderAction setStringValue:@"" ];
		[ pnFolderEditor setIsVisible:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"folderOk"];
	}
	@finally {
		[ self hideProgress:@"folderOk" ];

	}
}

- (void) showCreateFolder {
	[ self showProgress:@"showCreateFolder" ];
	
	@try {
		NSString * folderName = @"";
		[ pnFolderEditor setIsVisible: YES ];
		[ tfFolderName setStringValue:folderName ];
		[ tfFolderAction setStringValue:@"add" ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"showCreateFolder"];
	}
	@finally {
		[ self hideProgress:@"showCreateFolder" ];
	}
}

- (void) showRenameFolder {
	[ self showProgress:@"showRenameFolder" ];
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		if ([tvPathContents selectedRow] > -1 ) 
		{
			NSString *rowType = [ [ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"type"];
			NSString *rowName = [ [ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"name"];
			NSString *rowID = [ [ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"id"];
			
			if (! [rowType compare:@"f"] ) {
				if ( [rowName compare:@".."] ) {
					[ pnFolderEditor setIsVisible: YES ];
					[ tfFolderName setStringValue:rowName ];
					[ tfFolderAction setStringValue:@"ren" ];	
					[ tfFolderID setStringValue:rowID ];							
				} else {
					[ self addDynLog: [ NSString stringWithFormat:@"Cannot rename .. "] entrySeverity:@"ERROR" callerFunction:@"showRenameFolder"];
				}
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"showRenameFolder"];
	}
	@finally {
		[ self hideProgress:@"showRenameFolder" ];
	}
}

- (void) acFolRemove {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int selectedRow = [ tvPathContents selectedRow ];
	[ self showProgress:@"acFolRemove:(id)sender" ];
	@try {
		NSArray *objects = [acPathContents arrangedObjects];
		if ([tvPathContents selectedRow] > -1 ) 
		{
			NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];	
			int index = [indexSet firstIndex];				
			int alertReturn;

			NSMutableString * foldersToBeRemoved = [ [NSMutableString alloc] init];
			
			while (index > -1) 
			{
				[ foldersToBeRemoved appendFormat:@"%@\n", [[ objects objectAtIndex:index] objectForKey:@"name"]];
				index=[indexSet indexGreaterThanIndex:index];
			}
			
			index = [indexSet firstIndex];
			if ( [indexSet count] == 1 )  {
				alertReturn = NSRunInformationalAlertPanel(@"Poistetaanko kansio ja sen sisältö?", foldersToBeRemoved, @"Kyllä", @"Ei", nil);				
			} else {
				alertReturn = NSRunInformationalAlertPanel(@"Poistetaanko kansiot ja niiden sisältö?", foldersToBeRemoved, @"Kyllä", @"Ei", nil);
			}
			
			while (index > -1) 
			{
				NSString *selectedFolderID = [ [ objects objectAtIndex:index] objectForKey:@"id" ];
				NSString *selectedFolderName = [ [ objects objectAtIndex:index] objectForKey:@"name"];
				if ( ( [selectedFolderID compare:@""] ) && ( [selectedFolderName compare:@".."]) ) {					
					if ( alertReturn == NSAlertDefaultReturn) {
						NSString *location = [NSString stringWithFormat:
											  @"%@://%@/ready.sl?delete_folder=%@&ajax=true",
											  [cnf getStringCnf:@"httpServerProtocol"], 
											  [cnf getStringCnf:@"httpServerAddress"],
											  selectedFolderID
											  ];
						
						
						if (location) {
							NSError *error = nil;
							[ cH cacheOff ];
							NSString *response = [ htEngine httpGet:location error:error]; //[self execHTTP:location errorResp:error];
							[ cH cacheOn ];
							if (!error) {
								NSRange textRange;
								textRange = [[response lowercaseString] rangeOfString:[@"{\"ready_data\":" lowercaseString]];
								if (textRange.location != NSNotFound) {
								} else {
									[self showErrorPopup:@"Kansion poistossa virhe." errorDescText:
									 [NSString stringWithFormat: @"Kansion %@ poisto epäonnistui.\n\n%@", activeFolderName, response]
									 ];					
								}						
							} else {
								[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
								
								[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
												  [error code], 
												  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acFolRemove"];
							}
						} 
					}
				} else {
					[ self addDynLog:[ NSString stringWithFormat:@"Root/Parent folder cannot be removed"] entrySeverity:@"ERROR" callerFunction:@"acFolRemove"];
				}
				index=[indexSet indexGreaterThanIndex:index];
				if ([ objects count ] < index ) {
					break;
				}
			}
		}		
	}
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acFolRemove"];
	} 
	@finally {
		[ self hideProgress:@"acFolRemove:(id)sender" ];
		[ self loadPath:curFolderID parentFolder:curParentFolder ];
		[ self reloadContRecsFolders ];
		[ tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
		[pool drain];    
	}		
}

- (void) acFolRename:(NSString *) newFolderName {
	[ self showProgress:@"acFolRename" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		if ([tvPathContents selectedRow] > -1 ) 
		{
			NSString *selectedFolderID = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"id"];
			NSString *selectedFolderName = [[ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"name"];
			if ( ( [selectedFolderID compare:@""] ) && ( [selectedFolderName compare:@".."]) && ([newFolderName compare:@".."]) ) 
			{
				NSString *location = [NSString stringWithFormat:
									  @"%@://%@/ready.sl?name=%@&rename_folder=%@&folder=Uusi+alikansio&ajax=true",
									  [cnf getStringCnf:@"httpServerProtocol"], 
									  [cnf getStringCnf:@"httpServerAddress"],
									  [gfunc urlEncode:newFolderName],
									  selectedFolderID
									  ];
				NSError *error = nil;
				[ cH cacheOff ];
				NSString *response = [ htEngine httpGet:location error:error]; //[self execHTTP:location errorResp:error];
				[ cH cacheOn ];
				if (error) {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acFolRename"];
					[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"DEBUG" callerFunction:@"acFolRename"];
				}
				[ self loadPath:curFolderID parentFolder:curParentFolder ];
			}
		}
	}
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acFolRename"];
	} 
	@finally {
		[ self reloadContRecsFolders ];
		[ self hideProgress:@"acFolRename" ];
		[pool drain];		
	}	
}

- (void)acFolCreate:(NSString *) newFolderName {
	[ self showProgress:@"acFolCreate:(id)sender" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		if ( [newFolderName compare:@""] )
		{
			NSString* location;
			if  ( ![curFolderID compare:@""] ) //activeFolderID
			{
				location = [NSString stringWithFormat:@"%@://%@/ready.sl?folder=%@&create_subfolder=Luo&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"],[gfunc urlEncode:newFolderName]];
			} else {
				location = [NSString stringWithFormat:@"%@://%@/ready.sl?parent=%@&folder=%@&create_subfolder=Luo&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], curFolderID, [gfunc urlEncode:newFolderName]];
			}
			
			if (location) {
				NSError *error = nil;
				[ cH cacheOff ];
				NSString *response = [ htEngine httpGet:location error:error ]; // [self execHTTP:location errorResp:error];
				[ cH cacheOn ];
				if (!error) {
					NSRange textRange;
					textRange = [[response lowercaseString] rangeOfString:[@"{\"ready_data\":" lowercaseString]];
					if (textRange.location != NSNotFound) {
						[ self loadPath:curFolderID parentFolder:curParentFolder ];
					} else {
						[self showErrorPopup:@"Kansion luonnissa virhe." errorDescText:[NSString stringWithFormat: @"Kansion %@ luonti epäonnistui.\n\n%@", newFolderName, response]];					
					}						
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
										  [error code], 
										  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acFolCreate"];
				}
				[ self loadPath:curFolderID parentFolder:curParentFolder ];
			}
		}		
	}			
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acFolCreate"];
	} 
	@finally {
		[ self reloadContRecsFolders ];
		[ self hideProgress:@"acFolCreate:(id)sender" ];
		[pool drain];    
	}
}

/******************************************************************************
 * iPlayer related routines
 ******************************************************************************/
- (void) launchIPlayer:(NSString *) playUrl
{
	@try {
#ifndef VLCKITNOK
		iPlayer * ipC = [ [iPlayer alloc] initWithStream: playUrl ];
		[NSBundle loadNibNamed:@"iPlayer" owner:ipC];
#endif
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"lauchIPlayer"];
	}
}
/******************************************************************************
 * Record related routines
 ******************************************************************************/
- (IBAction)acRecDownload:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"acRecDownload:(id)sender" ];
	
	NSString *folder = [cnf getStringCnf:@"defaultDownloadLocation"]; //@"~/Downloads";
	if (folder == NULL) {
		folder = @"~/Downloads";
	}
	folder = [folder stringByExpandingTildeInPath];
	
	@try {
		[ htEngine cacheOff ];
		NSArray *objects = [acPathContents arrangedObjects];			
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];	
		
		signed int index = -1;
		if ([ indexSet count ] > 0) 
		{
			index = [indexSet firstIndex];				
		}
		
		while (index < ([ objects count] + 1) ) 
		{
			selectedRecID = [ [ objects objectAtIndex:index] objectForKey:@"id" ];
			NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], selectedRecID];

			if (location) {
				NSError *error = nil;
				NSArray *progData = [ htEngine jsonHttpExec:location error:error];
				
				if (!error) {
					NSMutableString * cnfSaveAs = [[ NSMutableString alloc ] init];
					[ cnfSaveAs appendString: [ cnf getStringCnf:@"downloadSaveAsTemplate" ]]; 					
					[ cnfSaveAs replaceOccurrencesOfString:@"{id}" withString:[[ progData valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{name}" withString:[[ progData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{channel}" withString:[[ progData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{short_text}" withString:[[ progData valueForKey:@"short_text"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{flength}" withString:[[ progData valueForKey:@"flength"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{start_time}" withString:[[ progData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs replaceOccurrencesOfString:@"{end_time}" withString:[[ progData valueForKey:@"end_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] options:NSCaseInsensitiveSearch range:(NSRange){0,[cnfSaveAs length]} ];
					[ cnfSaveAs appendString:@".ts" ];

					NSString *saveAs = [[[[[ cnfSaveAs stringByReplacingOccurrencesOfString:@" " withString:@"_" ] 
										stringByReplacingOccurrencesOfString:@"/" withString:@"-" ]
										stringByReplacingOccurrencesOfString:@"," withString:@"-" ]
										stringByReplacingOccurrencesOfString:@":" withString:@"." ]
										stringByReplacingOccurrencesOfString:@"\\" withString:@"-" ];

					int curlies = 0;
					for (curlier * dlU in activeDownloads) {		
						curlies++;
					}		
					curlies++;
					
					curlier * dlU = [[curlier alloc] init ];
					[dlU url:[ [ NSMutableString alloc] initWithString:[[ progData valueForKey:@"url"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] 
							destinationPath:[ [ NSMutableString alloc] initWithString:folder ] 
							saveAs:[ [ NSMutableString alloc] initWithString:saveAs ]
							maxSpeed:([ cnf getIntCnf:@"maxDownloadSpeed" ] / curlies )
							];
					
					[ activeDownloads addObject:dlU ];
					
					[ dlU release ];
					
					for (curlier * dlU in activeDownloads) {		
						if ( [ dlU isActive ] == YES ) {
							[ dlU choke:([ cnf getIntCnf:@"maxDownloadSpeed" ] / curlies ) ];
						}
					}					
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acRecDownload"];
				}
			}
			index=[indexSet indexGreaterThanIndex:index];
		}
	}
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acRecDownload"];
	} 
	@finally {
		[ htEngine cacheOn ];
		[pool drain];  
		[ self hideProgress:@"acRecDownload:(id)sender" ];
	}
}

- (IBAction)acRecCopyURL:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"acRecCopyURL:(id)sender" ];
	[ cH cacheOff ];
	
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		if ([tvPathContents selectedRow] > -1 ) 
		{
			selectedRecID = [ [ objects objectAtIndex: [tvPathContents selectedRow] ] objectForKey:@"id"];
		}	
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], selectedRecID];

		if (location) {
			NSError *error = nil;
			NSArray *progData = [ htEngine jsonHttpExec:location error:error ];
			if (!error) {
				NSPasteboard *pb = [NSPasteboard generalPasteboard];
				NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
				[pb declareTypes:types owner:self];
				[pb setString:[progData valueForKey:@"url"] forType:NSStringPboardType];
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acRecCopyURL"];
			}
		}
	}
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acRecCopyURL"];
	}
	@finally {
		[ cH cacheOn ];
		[ self hideProgress:@"acRecCopyURL:(id)sender" ];
		[pool drain];    
	}
}

- (IBAction)acRecWatch:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"acRecWatch:(id)sender" ];
	[ cH cacheOff ];
	
#ifdef VLCKITNOK
	[ cnf setBoolCnf:@"useVLC" value:YES ];
#endif	
	
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];	
		
		if ( [ cnf getBoolCnf:@"useVLC" ] ) {
			NSDictionary *scriptError = [[NSDictionary alloc] init]; 
			NSString *scriptSource = @"tell application \"VLC\"\rstop\rdelay 1.5\rend tell\r\r";
			
			NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 
			if(![appleScript executeAndReturnError:&scriptError]) 
			{						
				[ self addDynLog:[ NSString stringWithFormat:@"%@", [scriptError description]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"]; 
			} 			
			
		}
		NSString *isFullScreen = @"";
		if ([cnf getBoolCnf:@"cnfVLCFullScreen"]) { isFullScreen = @"\rfullscreen"; }
				
		int index = [indexSet firstIndex];
		while (index > -1) 
		{
			selectedRecID = [ [ objects objectAtIndex:index] objectForKey:@"id"];
			if ( ! [ wDB isWatched: selectedRecID ] ) [ wDB setIsWatched: selectedRecID];

			NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], selectedRecID];
			if (location) {
				NSError *error = nil;
				NSArray * progInfo = [ htEngine jsonHttpExec:location error:error ];
				if (!error) {
					
					if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
					{
						NSString* setWatchedLocation = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&view=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], selectedRecID];
						[ htEngine httpExec:setWatchedLocation error:nil ];
					}

					if ( [ cnf getBoolCnf:@"useVLC" ] ) {
						NSDictionary *scriptError = [[NSDictionary alloc] init]; 
						NSString *scriptSource = @"tell application \"VLC\"\rend tell\r";
						[ self addDynLog:[ NSString stringWithFormat:@"%@", scriptSource] entrySeverity:@"DEBUG" callerFunction:@"acRecWatch"]; 
						NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 						
						if(![appleScript executeAndReturnError:&scriptError]) 
						{						
							[ self addDynLog:[ NSString stringWithFormat:@"%@", [scriptError description]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"]; 
						} 
					}
					
					if ( [ cnf getBoolCnf:@"useVLC" ] == NO) {
						[ self launchIPlayer:[[ progInfo valueForKey:@"url" ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ];
					} else if ( [ cnf getBoolCnf:@"useVLC" ] ) {
						NSDictionary *scriptError = [[NSDictionary alloc] init]; 
						NSString *scriptSource = [NSString stringWithFormat:@"tell application \"VLC\"\rOpenUrl \"%@\"\rend tell\r", [[ progInfo valueForKey:@"url" ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ]; 
						[ self addDynLog:[ NSString stringWithFormat:@"%@", scriptSource] entrySeverity:@"DEBUG" callerFunction:@"acRecWatch"]; 
						
						NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 						
						if(![appleScript executeAndReturnError:&scriptError]) 
						{						
							[ self addDynLog:[ NSString stringWithFormat:@"%@", [scriptError description]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"]; 
						}
					}
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"];
				}
			}	
			index=[indexSet indexGreaterThanIndex:index];
			if ([ objects count ] < index ) {
				break;
			}
		}	
		if ( [ cnf getBoolCnf:@"useVLC" ] ) {
			NSDictionary *scriptError = [[NSDictionary alloc] init]; 
			NSString *scriptSource = [NSString stringWithFormat:@"tell application \"VLC\"\ractivate%@\rplay\rnext\rend tell\r", isFullScreen]; 
			NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 		
			if(![appleScript executeAndReturnError:&scriptError]) 
			{						
				[ self addDynLog:[ NSString stringWithFormat:@"%@", [scriptError description]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"]; 
			} 		
		}
	}	
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acRecWatch"];
	} 
	@finally {
		[ cH cacheOn ];
		[ self hideProgress:@"acRecWatch:(id)sender" ];
		[pool drain];   
	}
}

- (IBAction)btHideProgramInfo:(id)sender {
	@try {
		[ recInfoPanel setIsVisible:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btHideProgramInfo"];
	}
}

- (IBAction)btShowProgramInfo:(id)sender {
	[ self showProgress:@"btShowProgramInfo" ];

	@try {
		if ([masterWindow firstResponder] == tvPathContents) {
			[ self mnInfo:tvPathContents ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btShowProgramInfo"];
	}
	@finally {
		[ self hideProgress:@"btShowProgramInfo" ];
	}
}

- (IBAction)btReactEnter:(id)sender {
	@try {
		if ([masterWindow firstResponder] == tvPathContents) {
			[ self pathViewDoubleClickAction:tvPathContents ];			
		} else if ([masterWindow firstResponder] == serviceTable) {
			[ self tvServiceListClick:serviceTable ];			
		}	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btReactEnter"];
	}
}


- (void) acShowProgInfo:(NSString *) progID 
{
	[ self showProgress:@"fnShowProgInfo:(NSString *) progID" ];
	
	if ( [ cnf getBoolCnf:@"disableFacebook" ] )
	{
		[ fbButtonCaller setEnabled:NO ];
	} else {
		[ fbButtonCaller setEnabled:YES ];		
	}		
	
	@try {
		if ( [progID length] > 0 )
		{		
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], progID];
			
			NSString *recName = @"";
			NSString *recChannel = @"";
			NSString *recShortText = @"";
			NSString *recFLength = @"";
			NSString *recStartTime = @"";
			NSString *recHasEnded = @"";
			
			if (location) {
				NSError *error = nil;
				NSArray *progData = [ htEngine jsonHttpExec:location error:error ];
				
				if (!error) {
					recName = [[progData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					recChannel = [[progData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					recShortText = [[progData valueForKey:@"short_text"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					recFLength = [[progData valueForKey:@"flength"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					recStartTime = [[progData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					recHasEnded = [[progData valueForKey:@"has_ended"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
					
					[ tfAboutRecID setStringValue:progID ]; 

					[ wvFB setDrawsBackground: NO ];
					
					if ( ![recHasEnded compare:@"true"] )
					{
						NSURL *imageURL = [NSURL URLWithString: [[progData valueForKey:@"tn"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]; 
						NSData *imageData = [imageURL resourceDataUsingCache:NO];
						NSImage *imageFromBundle = [[NSImage alloc] initWithData:imageData];
						[recThumbImage setImage:imageFromBundle];
						[imageFromBundle release];				
					} else {
						NSString* imageName = [[NSBundle mainBundle] pathForResource:[ cnf getStringCnf:@"serviceIconName"] ofType:[ cnf getStringCnf:@"serviceIconFileType"]];	
						NSImage* imageObj = [[NSImage alloc] initWithContentsOfFile:imageName];
						[recThumbImage setImage:imageObj];
						[imageObj release];
					}					
					
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acShowProgInfo"];
				}
			}
			NSString *recComboInfo = [ NSString stringWithFormat:@"%@ %@ (%@)", recStartTime, recChannel, recFLength ];		
			[recInfoPanel setTitle: [NSString stringWithFormat:@"Tietoja : %@", recName ] ];
			[recDesc setStringValue: [NSString stringWithFormat:@"%@", recShortText]];
			[recDayChannel setStringValue: [NSString stringWithFormat:@"%@", recComboInfo]];
			[recProgName setStringValue: [NSString stringWithFormat:@"%@", recName]];
			[recInfoPanel setIsVisible:YES];
			
			[pool drain];   
		} 
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"acShowProgInfo"];	
	} 
	@finally {
		[ self hideProgress:@"fnShowProgInfo:(NSString *) progID" ];
	}
}

- (IBAction)acRecDelete:(id)sender {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ cH cacheOff ];
	[ self showProgress:@"acRecDelete:(id)sender" ];
	@try {
		int delCount = 0;
		int selectedRow = [tvPathContents selectedRow];
		NSArray *objects = [acPathContents arrangedObjects];			
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];
		NSMutableString *procsToRemove = [[NSMutableString alloc] init]; //@"";
		NSString *headerTitle = @"";
		if ( (modelKeyValue == @"trashcan" ) || ( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == NO ) )
		{
			if ( [indexSet count] == 1 ) 
			{
				headerTitle = @"Poistetaanko tallenne?";
			} else {
				headerTitle = @"Poistetaanko seuraavat tallenteet?";
			}			
		} else {
			if ( [indexSet count] == 1 ) 
			{
				headerTitle = @"Siirretäänkö tallenne roskakoriin?";
			} else {
				headerTitle = @"Siirretäänkö seuraavat tallenteet roskakoriin?";
			}			
		}
		int index = [indexSet firstIndex];
		while (index > -1) 
		{
			delCount ++;
            if (index <= [objects count]) {
                if (delCount <= 4) {
                    [ procsToRemove appendFormat:@"%@ (%@, %@)\n",
                     [[ objects objectAtIndex:index] objectForKey:@"name"],
                     [[ objects objectAtIndex:index] objectForKey:@"chan_size"],
                     [gfunc maxDate:[[ objects objectAtIndex:index] objectForKey:@"start_time"]]
                     ];
                }
			} else {
                break;
            }
			
			index=[indexSet indexGreaterThanIndex:index];
		}
		
		if (delCount > 4) {
			[ procsToRemove appendFormat:@"\nSekä %i muuta tallennetta\n",
			 delCount - 4
			 ];				
		}
		
		int alertReturn = NSRunInformationalAlertPanel(headerTitle, procsToRemove, @"Kyllä", @"Ei", nil);
		
		if ( alertReturn == NSAlertDefaultReturn) {
			NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];
			int index = [indexSet firstIndex];
			int runCount = 0;
			NSMutableString* mRlocation = [ NSMutableString stringWithFormat:@"%@://%@/", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];

			if ( ( modelKeyValue == @"trashcan" ) || ( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == NO ) )
			{
				[ mRlocation appendString:@"program.sl?remove=true&" ];
			} else {
				[ mRlocation appendFormat:@"ready.sl?move=true&destination=%@&", trashFolderID ];
			}
			
			NSLog(@"%@", mRlocation);
			
			while (index > -1) 
			{
                if (index <= [objects count]) 
                {
                    selectedRecID = [ [ objects objectAtIndex:index] objectForKey:@"id"];
                    if ( [ [ objects objectAtIndex:index] objectForKey:@"type"] == @"r" ) {
                        if ( ( modelKeyValue == @"trashcan" ) || ( [ cnf getBoolCnf:@"cnfEnableTrashCan" ] == NO ) )
                        {
                            [mRlocation appendFormat:@"removep=%@&", [ self viewIDbyProgID:selectedRecID]];
                        } else {
                            if ( ! [ wDB isWatched: selectedRecID ] ) [ wDB setIsWatched: selectedRecID];
                            [mRlocation appendFormat:@"programviewid=%@&", [ self viewIDbyProgID:selectedRecID]];
                        }
                        runCount++;
                    }                 
                } else {
                    break;
                }
				index=[indexSet indexGreaterThanIndex:index];
			}
			if ( (mRlocation) && (runCount > 0 )) {
				[ mRlocation appendString:@"ajax=true" ];
				[ self addDynLog:[ NSString stringWithFormat:@"%@", mRlocation] entrySeverity:@"DEBUG" callerFunction:@"acRecDelete"];
				NSError *Rerror = nil;
				NSString *Rresponse = [ htEngine httpGet:mRlocation error:Rerror]; // [self execHTTP:Rlocation errorResp:Rerror];
				if (!Rerror) {
					
				} else {
					[self showErrorPopup:@"Järjestelmävirhe" errorDescText:[NSString stringWithFormat:@"Something went wrong %d, %@\n\n%@", [Rerror code], [Rerror localizedDescription], Rresponse]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [Rerror code], 
									  [Rerror localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"acRecDelete"];
				}
			}			
		}
		[ cH cacheOff ];
		[ self tvServiceListClick: serviceTable ];
		[ cH cacheOn ];
		[ tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	} 
	@catch (id theException) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", theException] entrySeverity:@"EXCEPTION" callerFunction:@"acRecDelete"];
	} 
	@finally {
		[ self hideProgress:@"acRecDelete:(id)sender" ];
		[ cH cacheOn ];
		[pool drain]; 		
	}
}

/******************************************************************************
 * Download Management routines
 ******************************************************************************/
- (void) populateDownload {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		int curlies = 0;
		int active_curlies = 0;
		for (curlier * dlU in activeDownloads) {		
			curlies++;
			if ( [ dlU isActive ] == YES ) {
				active_curlies++;
			}
		}	
		
		if ( active_curlies == 0 ) {
			[[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];			
		} else {
			[[[NSApplication sharedApplication] dockTile] setBadgeLabel:[[NSNumber numberWithInt:active_curlies] stringValue]];
		}
				
		if (![ modelKeyValue compare:@"indownload" ]) {
			[ [ acPathContents content ] removeAllObjects ];
			maPathContents  = [[NSMutableArray alloc] init];
			NSInteger selRow = [ tvPathContents selectedRow ];			
			
			for (curlier * dlU in activeDownloads) {		
				if ( [ dlU isActive ] == YES ) {
					if ([ cnf getIntCnf:@"maxDownloadSpeed" ] > 0) {
						[ dlU choke:([ cnf getIntCnf:@"maxDownloadSpeed" ] / curlies ) ];					
					} else {
						[ dlU choke:0 ];					
					}
					NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
										  [serviceIconArray objectAtIndex:recordIconID] , @"icon",
										  [ dlU getDestination ], @"name",
										  [NSString stringWithString:[dlU chkStat ] ], @"chan_size",
										  [ dlU getDestinationPath ], @"start_time",
										  @"dl", @"type",
										  @"", @"id",
										  nil
										  ];	
					[acPathContents addObject:dictR];
				} 
			}
			[tvPathContents reloadData ];			
			[tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:selRow] byExtendingSelection:NO];			
			
			int deCurlId = 0;
			int remCurlId = -1;
			for (curlier * dlU in activeDownloads) {		
				if ( [ dlU isActive ] == NO ) {
					remCurlId = deCurlId;
					break;
				}
				deCurlId ++;
			}		
			
			if ( remCurlId > -1 ) [ activeDownloads removeObjectAtIndex:remCurlId ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"populateDownload"];
	}
	@finally {
		[pool drain];    
	}
}

/******************************************************************************
 * TV Guide routines
 ******************************************************************************/
- (void) initChanList {
	[ self showProgress:@"initChanList" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		[ [ acPathContents content ] removeAllObjects ];
		maPathContents  = [[NSMutableArray alloc] init];
		curGuideLocation = @"c";
		
		NSString* location = [NSString stringWithFormat:@"%@://%@/ajaxprograminfo.sl?channels", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		
		if (location) {
			NSError *error = nil;
			NSString *response = [ htEngine httpGet:location error:error]; // [self execHTTP:location errorResp:error];
			if (!error) {
				NSArray *prog_ids = [response componentsSeparatedByString: @"\n"];			
				NSArray *chanListAR = [ [ prog_ids objectAtIndex:1] componentsSeparatedByString: @","];
				
				for(NSString * myStr in chanListAR) {
					NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
										  [serviceIconArray objectAtIndex:folderIconID], @"icon",
										  [myStr stringByReplacingOccurrencesOfString:@"\"" withString:@"" ], @"name",
										  @"", @"chan_size",
										  @"", @"start_time",
										  @"c", @"type",
										  @"", @"id",
										  nil
										  ];	
					[acPathContents addObject:dictR];
					[tvPathContents reloadData ];
					[currentPath setStringValue: [ self getRecPath ]];
				}
			} else {
				[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"initChanList"];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"initChanList"];
	}
	@finally {
		[pool drain];    
		[ self hideProgress:@"initChanList" ];
	}
}

- (void)loadChanGuide:(NSString *) chanName {
	[ cH cacheOff ];
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self showProgress:@"chanListChange:(id)sender" ];
	@try {
		
		NSString* IRlocation = [NSString stringWithFormat:@"%@://%@/recordings.sl?ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
		NSError *IRerror = nil;
		inRecordList = [ htEngine httpGet:IRlocation error:IRerror];
		NSString *chanNameSelected = [chanName stringByReplacingOccurrencesOfString:@" " withString:@"%20"] ;
		
		if ([tvPathContents selectedRow] > -1 ) 
		{
			[ [ acPathContents content ] removeAllObjects ];			
			NSString* location = [NSString stringWithFormat: @"%@://%@/ajaxprograminfo.sl?channel=%@", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], chanNameSelected];
			
			curGuideLocation = chanName;
			
			if (location) {
				NSError *error = nil;
				NSArray *chanProgDataMaster = [ htEngine jsonHttpExec:location error:error]; 
				
				if (!error) {
					NSArray *chanProgData = [chanProgDataMaster valueForKey:@"programs"];
					NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
										  [serviceIconArray objectAtIndex:folderIconID], @"icon",
										  @"..", @"name",
										  @"", @"start_time",
										  @"", @"id",
										  @"c", @"type",
										  nil
										  ];	
					[ acPathContents addObject:dictR];
					
					for(NSArray *prgdata in chanProgData) {
						int icon_id = guide_itemID;
						
						if (!IRerror) {
							NSRange qRange = [ inRecordList rangeOfString:[ NSString stringWithFormat:@"\"%@\"", [prgdata valueForKey:@"id"]] ];
							if ( qRange.length > 0 ) {
								icon_id = guide_item_inrecID;
							}
						}
						NSDictionary *dictR =[NSDictionary dictionaryWithObjectsAndKeys:
											  [serviceIconArray objectAtIndex:icon_id], @"icon",
											  [[prgdata valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"name",
											  [gfunc maxDate:[[prgdata valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]], @"start_time",
											  [[prgdata valueForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding], @"id",
											  @"g", @"type",
											  nil
											  ];	
						[ acPathContents addObject:dictR];
					}
					[ tvPathContents reloadData ];
					[tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];	
					[currentPath setStringValue: [NSString stringWithFormat:@"%@%@/", [currentPath stringValue], chanName]];
				} else {
					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"loadChanGuide"];
				}
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"loadChanGuide"];	
	}
	@finally {
		[ self hideProgress:@"chanListChange:(id)sender" ];
		[pool drain]; 
		[ cH cacheOn ];
	}	
}


/******************************************************************************
 * HTTP(S) access routines
 ******************************************************************************/
/*
- (bool) checkIsResponseOk:(NSString *) response {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"DEBUG" callerFunction:@"checkIsResponseOk"];
	bool isOk = NO;	
	@try {		
		if ( [[response substringToIndex:1] compare:@"<"] )
		{
			isOk = YES;
		} else {
			NSRange textRange;
			textRange =[[response lowercaseString] rangeOfString:[@">500 Servlet Exception<" lowercaseString]];
			if(textRange.location != NSNotFound)						
			{
				isOk = YES;
				[ self addDynLog:[ NSString stringWithFormat:@"ELISAVIIHDE.FI : Servlet Error Detected!"] entrySeverity:@"ERROR" callerFunction:@"checkIsResponseOk"];
				[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"DEBUG" callerFunction:@"checkIsResponseOk"];
				[ self showErrorPopup:@"Palvelin : 500 Servlet Error" errorDescText:response ];
			} else {
				isOk = NO;
				[ self addDynLog:[ NSString stringWithFormat:@"Not 500 Servlet Error, but not correct JSON response either..."] entrySeverity:@"ERROR" callerFunction:@"checkIsResponseOk"];
				[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"DEBUG" callerFunction:@"checkIsResponseOk"];
				[ self showErrorPopup:@"Palvelin palautti virheellisen sanoman" errorDescText:response ];
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"checkIsResponseOk"];
		[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response] entrySeverity:@"DEBUG" callerFunction:@"checkIsResponseOk"];
	}
	@finally {
		[ pool drain ];
		return isOk;
	}
}
*/
- (void) checkLastKeep {
	@try {
		long CurrentUNIXTime = [[NSDate date] timeIntervalSince1970];	
		if ( CurrentUNIXTime > (lastRefreshUNIXTime + 901) ) 
		{
			[self keepLogged];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"EXCEPTION: %@", e] entrySeverity:@"EXCEPTION" callerFunction:@"checkLastKeep"];
	}
	@finally {
	}
}

- (void) keepLogged {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#ifdef DEBUG
	[ self addDynLog:@"keepLogged triggered"  entrySeverity:@"INFO" callerFunction:@"keepLogged"];
#endif
	@try {
		NSString* location;
		if ( ![[cnf getStringCnf:@"httpServerAddress" ] compare:@"api.elisaviihde.fi/etvrecorder" ] )
		{
			// ElisaViihde login.sl
			location= [NSString stringWithFormat: @"%@://%@/login.sl?username=%@&password=%@&savelogin=true&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [evUser stringValue], [evPass stringValue]];
		} else {			
			// SaunaVisio login thru Default.sl
			location= [NSString stringWithFormat: @"%@://%@/default.sl?username=%@&password=%@&savelogin=true&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [evUser stringValue], [evPass stringValue]];
		}		
		
		if (location) {
			NSError *error = nil;
			NSData *data;  
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: location ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: [cnf getIntCnf:@"cnfHTTPTimeout"]];      
			NSURLResponse *Uresponse;  
			data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
			NSString *response = [NSString stringWithCString:[data bytes] length:[data length]];  
			
			if (!error) {
				lastRefreshUNIXTime = [[NSDate date] timeIntervalSince1970];
				keeploggedErrorCounter = 0;
			} else {
				if (keeploggedErrorCounter = 5) {
					[self showErrorPopup:@"Virhe pidettäessä sessiota yllä" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					keeploggedErrorCounter = 0;
				} else {
					keeploggedErrorCounter++;
				}
				[ self addDynLog:[ NSString stringWithFormat: @"HTTP-RESPONSE: %@", response ] entrySeverity:@"DEBUG" callerFunction:@"keepLogged"];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"keepLogged"];			
			}	
			
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"keepLogged"];
	}
	@finally {
		[pool drain];
	}
}

/******************************************************************************
 * Version checker routines
 ******************************************************************************/
- (IBAction)mnCheckUpdatesAct:(id)sender {
	@try {
		NSString *moveIgnorant = [ cnf getStringCnf:@"cnfIgnoreVersionOf" ];
		[ cnf setStringCnf:@"cnfIgnoreVersionOf" value:@"-.-.-"];
		if ([self checkLatestVersion] == true) {
			NSRunInformationalAlertPanel(@"Käytössäsi on uusin versio", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"Ok", @"", nil);
		} 
		[ cnf setStringCnf:@"cnfIgnoreVersionOf" value:moveIgnorant ];	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnCheckUpdatesAct"];
	}
}

- (void) autoVersionCheck
{
	[ self checkLatestVersion:FALSE silentCheck:TRUE ];	
}

- (bool) checkLatestVersion {
	return [ self checkLatestVersion:TRUE ];
}

- (bool) checkLatestVersion:(bool)sendVersionData {
	return [ self checkLatestVersion:sendVersionData silentCheck:FALSE ];	
}

- (bool) checkLatestVersion:(bool)sendVersionData silentCheck:(bool)silentCheck {
	if (silentCheck == FALSE) {
		[ self showProgress:@"chekLatestVersion" ];		
	} else {
		[ self addDynLog:@"Silent versioncheck started." entrySeverity:@"INFO" callerFunction:@"checkLatestVersion:(bool)sendVersionData silentCheck:(bool)silentCheck" ];
	}

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	bool isLatest = true;
	NSError *error = nil;
	NSArray * versionCheck;

	@try {
		NSString * longVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		NSRange findSpace = [longVersion rangeOfString:@" "];
		NSString * shortVersion = [ longVersion substringToIndex: findSpace.location ];		
        
        NSProcessInfo *pinfo = [NSProcessInfo processInfo];
        NSString *OSXVersion = [pinfo operatingSystemVersionString];
        
        NSArray *OSXVersionChunks = [OSXVersion componentsSeparatedByString: @" "];        
        OSXVersion = [[ OSXVersionChunks objectAtIndex:1] substringToIndex:4];
		
		if (sendVersionData) 
		{
			if ( [ cnf getStringCnf:@"UUID" ] == NULL ) {
				// create a new UUID which you own
				CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
				NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
				[uuidString autorelease];
				CFRelease(uuid);
				//return uuidString;
				[ cnf setStringCnf:@"UUID" value:uuidString ];
			}
			
			/** *** **/
			NSString * nsBuiltInMacAddress;
			kern_return_t	kernResult = KERN_SUCCESS; // on PowerPC this is an int (4 bytes)
			io_iterator_t	intfIterator;
			UInt8			MACAddress[kIOEthernetAddressSize];
			kernResult = FindEthernetInterfaces(&intfIterator);		
			if (KERN_SUCCESS != kernResult) {
			}
			else {
				kernResult = GetMACAddress(intfIterator, MACAddress, sizeof(MACAddress));
				if (KERN_SUCCESS != kernResult) {
				}
				else {
					nsBuiltInMacAddress = [ NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
										   MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]];
				}
			}
			(void) IOObjectRelease(intfIterator);	// Release the iterator.
			/** *** **/
						
			versionCheck = [ htEngine jsonHttpExec:[NSString stringWithFormat:@"%@?sysid=%@&version=%@&hash=%@&uuid=%@&OSXVersion=%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appUpdatePath"], [ gfunc MD5Hash: nsBuiltInMacAddress ], shortVersion, [gfunc MD5Hash:[evUser stringValue]], [ cnf getStringCnf:@"UUID" ], OSXVersion ] error:error];			
		} else {
			versionCheck = [ htEngine jsonHttpExec:[NSString stringWithFormat:@"%@?version=%@&OSXVersion=%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appUpdatePath"], shortVersion, OSXVersion ] error:error ];						
		}
		

		NSString * curVersion_Short = [[ [ versionCheck valueForKey:@"curversion_short" ] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding ] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		NSString * curVersion = [[ [ versionCheck valueForKey:@"curversion" ] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding ] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		[ latestDownloadUrl setString:[ versionCheck valueForKey:@"download_url" ]];
		[ latestReleaseNotesUrl setString:[ versionCheck valueForKey:@"release_notes_url" ]];
		
		[ latestVersionShort setStringValue:curVersion_Short ];
		
		if ( [ cnf getStringCnf:@"cnfIgnoreVersionOf" ] == curVersion_Short ) {
			isLatest = TRUE;
		} else {
			NSLog(@"'%@' <-> '%@'", shortVersion, curVersion_Short);
			if ( ![shortVersion compare:curVersion_Short] )  //( ![curVersion compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] )
			{
				//(@"Same Version");
			} else {
				isLatest = false;
				//(@"Version differs");
				[ comparedVersions setStringValue: 
				 [NSString stringWithFormat:@"Käytössä: %@, Uusin: %@", 
				  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
				  curVersion ] 
				 ];
				[ releaseNotesText setString:[self getChangeLog: [ versionCheck valueForKey:@"release_notes_url" ] ]]; 
				[ releaseNotes setIsVisible:YES];	
				
				if ( ![[ versionCheck valueForKey:@"allow_run" ] compare:@"no"] ) {
					[ loginWindow setIsVisible:NO ];
					int doYouReally = NSRunAlertPanel(@"eViihde päivitys", @"Pakotettu päivitys, nykyistä käyttämääsi versiota ei suositella käytettäväksi.", @"Ok", @"Ok, jatka - ohita varoitus", nil); 
					if (doYouReally == NSAlertDefaultReturn) {
						[ self showErrorPopup:@"eViihde päivitys" errorDescText:@"Ole hyvä ja lataa uusin versio." ];
					} else if (doYouReally == NSAlertAlternateReturn) {
						[ loginWindow setIsVisible:YES ];
					}
				}
			}			
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"checkLatestVersion"];
	}
	@finally {
		if (silentCheck == FALSE) {
			[ self hideProgress:@"chekLatestVersion" ];
		}
		[pool drain]; 
		return isLatest;
	}
}

- (NSString *) getChangeLog:(NSString *) latestVersion {
	[ self showProgress:@"getChangeLog" ];

	NSString *response;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSString *url = latestVersion;
		NSError *error = nil;
		response = [ htEngine httpGet:url error:error];  	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"getChangeLog"];
	}
	@finally {
		[ self hideProgress:@"getChangeLog" ];
		return response;
		[pool drain]; 
	}
}

- (IBAction)doDownloadLatest:(id)sender {
	[ self showProgress:@"doDownloadLatest" ];

	@try {
		[ self addDynLog:[ NSString stringWithFormat:@"Downloading : %@", latestDownloadUrl] entrySeverity:@"INFO" callerFunction:@"doDownloadLatest"];
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:latestDownloadUrl]]; 
	}	
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"doDownloadLatest"];
	}
	@finally {
		[ self hideProgress:@"getChangeLog" ];
	}
}

- (IBAction)doIgnoreThisVersion:(id)sender {
	[ cnf setStringCnf:@"cnfIgnoreVersionOf" value: [ latestVersionShort stringValue ] ];
	[ releaseNotes setIsVisible:NO];	
}


/******************************************************************************
 * iCal action routines
 ******************************************************************************/

- (void) addToiCal {
	
#ifndef TIGER
	[ self showProgress:@"addToiCal" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString *rowid;
	NSString *rowtype;
	NSArray *objects = [acPathContents arrangedObjects];

	@try {
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		if ([ tvPathContents selectedRow] > -1) {
			if ( ( modelKeyValue==@"commonfavs" ) || ( modelKeyValue==@"tvguide" ) || ( modelKeyValue==@"search" ) ) {
				if ( rowtype==@"g" ) {
					NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], rowid];
					
					NSString *recName = @"";
					NSString *recChannel = @"";
					NSString *recShortText = @"";
					NSString *recFLength = @"";
					NSString *recStartTime = @"";
					NSString *recEndTime = @"";
					NSString *recHasEnded = @"";
					
					if (location) {
						NSError *error = nil;
						NSArray *progData = [ htEngine jsonHttpExec:location error:error ];
						
						if (!error) {
							recName = [[progData valueForKey:@"name"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recChannel = [[progData valueForKey:@"channel"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recShortText = [[progData valueForKey:@"short_text"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recFLength = [[progData valueForKey:@"length"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recStartTime = [[progData valueForKey:@"start_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recEndTime  = [[progData valueForKey:@"end_time"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							recHasEnded = [[progData valueForKey:@"has_ended"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
							
						} else {
							[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", progData] entrySeverity:@"DEBUG" callerFunction:@"addToiCal"];
							[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
							[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
											  [error code], 
											  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"addToiCal"];
						}
					}
					
					// Get the calendar
					// Note: you can change which calendar you're adding to by changing the index or by
					// using CalCalendarStore's -calendarWithUID: method
					
					NSArray *calendarsAll = [[CalCalendarStore defaultCalendarStore] calendars];
					int selectedCalendar = 0;
					int selectedCalendar_cnt = 0;
					for (CalCalendar *cal in calendarsAll) {
						if ( ![[cal uid] compare:[ cnf getStringCnf:@"ical_calendar_uid" ]] ) selectedCalendar = selectedCalendar_cnt;
						selectedCalendar_cnt++;
					}
					
					CalCalendarStore *store = [CalCalendarStore defaultCalendarStore];
					CalCalendar *calendar = [[store calendars] objectAtIndex:selectedCalendar];
					NSDateFormatter *df = [[NSDateFormatter alloc] init];
					[df setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
					NSDate *startDate = [df dateFromString:[ gfunc maxDate:recStartTime] ];					
					NSDate *endDate = [ df dateFromString:[ gfunc maxDate:recEndTime] ];					
					
					// Create a simple event.
					CalEvent *event = [CalEvent event];
					[ event setCalendar:calendar];
					[ event setTitle:[ NSString stringWithFormat:@"%@: %@", recChannel, recName]]; 
					[ event setNotes:recShortText];
					[ event setStartDate:startDate];
					[ event setEndDate:endDate];
					[ event setLocation:recChannel];
					
					// Add an alarm to a task.
					CalAlarm *alarm = [CalAlarm alarm];
					[ alarm setAction:@"CalAlarmActionSound"];
					[ alarm setSound:@"Basso"];
					[ alarm setRelativeTrigger:[ cnf getIntCnf:@"ical_before_start" ]*-60];
					[event addAlarm:alarm];		
					
					// Save task
					NSError *error = nil;                   
					[store saveEvent:event span:CalSpanThisEvent error:&error];
					if (error) {
						[ self addDynLog: [ NSString stringWithFormat:@"(%d) %@", [error code], [error localizedDescription] ] entrySeverity:@"ERROR" callerFunction:@"addToiCal"];
					}
				}
			}
		}
		
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"addToiCal"];
		[pool drain];
	}
	@finally {
		[ self hideProgress:@"addToiCal" ];
	}
		
#endif
}

/******************************************************************************
 * Menu action routines
 ******************************************************************************/
-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
	BOOL enable = NO;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSString *rowid, *rowtype;
		
		/** Valikoiden sisällön tarkistus **/
		[ mnSetUnWatched setHidden:[ cnf getBoolCnf:@"cnfSyncServer" ]];			
		
		NSArray *objects = [acPathContents arrangedObjects];	
		if ( ( [ tvPathContents selectedRow] >= 0 ) && ([ objects count ] > 0) ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		
		if (modelKeyValue == @"recs") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( ( toolbarItem == tbPlayButton) && (rowtype == @"r") ) enable = YES;
			if ( toolbarItem == tbDeleteButton) enable = YES;
			if ( ( toolbarItem == tbInfoButton) && (rowtype == @"r") ) enable = YES;
			if ( toolbarItem == tbAddButton) enable = YES;
			if ( ( toolbarItem == tbEditButton) && (rowtype == @"f") ) enable = YES;
			if ( ( toolbarItem == tbDownloadButton) && (rowtype == @"r") ) enable = YES;
			if ( ( toolbarItem == tbFacebookButton) && (rowtype == @"r") ) enable = YES;		
		}
		if (modelKeyValue == @"tvguide") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( ( toolbarItem == tbInfoButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbAddButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbIcalButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbFacebookButton) && ( rowtype == @"g") ) enable = YES;		
		}
		if (modelKeyValue == @"recstocome") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( toolbarItem == tbInfoButton) enable = YES;
			if ([tvPathContents selectedRow] > -1 ) 
			{
				if (( [[ [acPathContents arrangedObjects] objectAtIndex: [tvPathContents selectedRow] ] valueForKey:@"rec_is_wild"] != @"x") && ( toolbarItem == tbDeleteButton)) enable = YES;
				if (( [[ [acPathContents arrangedObjects] objectAtIndex: [tvPathContents selectedRow] ] valueForKey:@"rec_is_wild"] != @"x") && ( toolbarItem == tbEditButton)) enable = YES;
			}			
		}
		if (modelKeyValue == @"alwaysonrecs") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( toolbarItem == tbDeleteButton) enable = YES;
			if ( toolbarItem == tbEditButton) enable = YES;
		}
		if (modelKeyValue == @"commonfavs") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( toolbarItem == tbInfoButton) enable = YES;
			if ( toolbarItem == tbAddButton) enable = YES;
			if ( toolbarItem == tbIcalButton) enable = YES;
			if ( toolbarItem == tbFacebookButton) enable = YES;		
		}
		if (modelKeyValue == @"search") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( ( toolbarItem == tbPlayButton)  && (rowtype == @"r") ) enable = YES;
			if ( ( toolbarItem == tbDeleteButton) && (rowtype == @"r") ) enable = YES;
			if ( ( toolbarItem == tbInfoButton) && (rowtype == @"r") ) enable = YES;
			if ( ( toolbarItem == tbDownloadButton) && (rowtype == @"r") ) enable = YES;
			if ( ( toolbarItem == tbFacebookButton) && (rowtype == @"r") ) enable = YES;	
			
			if ( ( toolbarItem == tbInfoButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbAddButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbIcalButton) && (rowtype == @"g") ) enable = YES;
			if ( ( toolbarItem == tbFacebookButton) && ( rowtype == @"g") ) enable = YES;		
			
		}
		if (modelKeyValue == @"indownload") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( toolbarItem == tbDeleteButton) enable = YES;
		}
		if (modelKeyValue == @"latestrecs") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( toolbarItem == tbPlayButton) enable = YES;
			if ( toolbarItem == tbDeleteButton) enable = YES;
			if ( toolbarItem == tbInfoButton) enable = YES;
			if ( toolbarItem == tbDownloadButton) enable = YES;
			if ( toolbarItem == tbFacebookButton) enable = YES;				
		}
		if (modelKeyValue == @"trashcan") {
			if ( toolbarItem == tbReloadButton) enable = YES;
			if ( ( toolbarItem == tbPlayButton)  && (rowtype == @"r") ) enable = YES;
			if ( toolbarItem == tbDeleteButton) enable = YES;
			if ( toolbarItem == tbInfoButton) enable = YES;
		}
		
		if (( toolbarItem == tbFacebookButton) && ( [ cnf getBoolCnf:@"disableFacebook" ] ) ) enable = NO; 
		if ( toolbarItem == tbPrintLog) enable = YES;
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"validateToolbarItem"];
	}
	@finally {
		[pool drain];
	}
    return enable;
}

- (IBAction) mnSetWatched:(id)sender {
	[ self showProgress:@"mnSetWatched" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		int selectedPathRow = [ tvPathContents selectedRow ];		
		NSArray *objects = [acPathContents arrangedObjects];			
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];			
		int index = [indexSet firstIndex];
		while (index > -1) 
		{
			[ wDB setIsWatched: [ [ objects objectAtIndex:index] objectForKey:@"id"] ];
			index=[indexSet indexGreaterThanIndex:index];
			if ([ objects count ] < index ) {
				break;
			}
		}		
		[ self tvServiceListClick:serviceTable ];		
		[ tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedPathRow] byExtendingSelection:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnSetWatched"];
	}
	@finally {
		[ self hideProgress:@"mnSetWatched" ];
		[ pool drain ];
	}
}

- (IBAction) mnSetUnWatched:(id)sender {
	[ self showProgress:@"mnSetUnWatched" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		int selectedPathRow = [ tvPathContents selectedRow ];	
		NSArray *objects = [acPathContents arrangedObjects];			
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];	
		
		int index = [indexSet firstIndex];
		while (index > -1) 
		{
			[ wDB setIsNotWatched: [ [ objects objectAtIndex:index] objectForKey:@"id"] ];
			index=[indexSet indexGreaterThanIndex:index];
			if ([ objects count ] < index ) {
				break;
			}
		}		
		[ self tvServiceListClick:serviceTable ];		
		[ tvPathContents selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedPathRow] byExtendingSelection:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnSetUnWatched"];
	}
	@finally {
		[ self hideProgress:@"mnSetUnWatched" ];
		[ pool drain ];
	}
}

- (IBAction) mnReload:(id)sender {
	[ self showProgress:@"mnReload" ];
	
	@try {
		[ cH cacheOff ];
		if (modelKeyValue == @"latestrecs") {
			[ self showProgress:@"Ladataan kaikki kansiot ja tallenteet"];
			// Populate latestrecs/receditfolder list only when really needed. Causes load to Elisa //
			[ self reloadContRecsFolders ];
			[ self hideProgress:@"Ladataan kaikki kansiot ja tallenteet"];
		}
		[ self tvServiceListClick:serviceTable ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnReload"];
	}
	@finally {
		[ self hideProgress:@"mnReload" ];
		[ cH cacheOn ];				
	}
}

- (IBAction) mnPlay:(id)sender {
	[ self showProgress:@"mnPlay" ];

	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if (rowtype == @"r") {
			[self acRecWatch:tvPathContents];			
		} else if (rowtype == @"f" ) {
			// TODO: Play entire folder in once....
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnPlay"];
	}
	@finally {
		[ self hideProgress:@"mnPlay" ];
	}
}

- (IBAction) mnInfo:(id)sender {
	[ self showProgress:@"mnInfo" ];
	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ([ tvPathContents selectedRow] > -1) {
			if ( 
				( ![ modelKeyValue compare:@"recs"] ) || 
				( ![ modelKeyValue compare:@"tvguide"] ) || 
				( ![ modelKeyValue compare:@"search"] ) || 
				( ![ modelKeyValue compare:@"indownload"] ) || 
				( ![ modelKeyValue compare:@"recstocome"] ) || 
				( ![ modelKeyValue compare:@"commonfavs"] ) || 
				( ![ modelKeyValue compare:@"trashcan"] ) || 
				( ![ modelKeyValue compare:@"latestrecs"] ) 
				) 
			{
				if ( (![rowtype compare:@"r"]) || (![rowtype compare:@"g"]) ) {
					[ self acShowProgInfo:rowid ];								
				}
			} else if ( ![ modelKeyValue compare:@"alwaysonrecs"] ) {
				// None. Info != Editor //
			}
		}	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnInfo"];
	}
	@finally {
		[ self hideProgress:@"mnPlay" ];
	}
}

- (IBAction) mnDownload:(id)sender {
	[ self showProgress:@"mnDownload" ];
	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ( 
			( ( modelKeyValue == @"recs" ) && ( rowtype == @"r") ) ||
			( ( modelKeyValue == @"latestrecs" ) && ( rowtype == @"r") )
			)
		{
			[ self acRecDownload: tvPathContents ];
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnDownload"];
	}
	@finally {
		[ self hideProgress:@"mnDownload" ];
	}
}

- (IBAction) mnGoToDownloadFolder:(id)sender {
	[ self showProgress:@"mnGoToDownloadFolder" ];

	@try {
		NSDictionary *scriptError = [[NSDictionary alloc] init]; 
		NSString *scriptSource = [ NSString stringWithFormat:@"property the_path : \"%@\"\rset the_folder to (POSIX file the_path) as alias\rtell application \"Finder\"\ractivate\rreveal the_folder\rif window 1 exists then\rset target of window 1 to the_folder\relse\rreveal the_folder\rend if\rend tell",[ cnf getStringCnf:@"defaultDownloadLocation"]];
		
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 
		if(![appleScript executeAndReturnError:&scriptError]) 
		{						
			[ self addDynLog:[ NSString stringWithFormat:@"%@", [scriptError description]] entrySeverity:@"ERROR" callerFunction:@"acRecWatch"]; 
		} 				
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnGoToDownloadFolder"];
	}
	@finally {
		[ self hideProgress:@"mnGoToDownloadFolder" ];
	}
}

- (IBAction) mnCopyAddress:(id)sender {
	[ self showProgress:@"mnCopyAddress" ];
	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ( 
			( ( modelKeyValue == @"recs" ) && ( rowtype == @"r") ) ||
			( ( modelKeyValue == @"latestrecs" ) && ( rowtype == @"r") )
			)
		{
			[ self acRecCopyURL: tvPathContents ]; 
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnCopyAddress"];
	}
	@finally {
		[ self hideProgress:@"mnCopyAddress" ];
	}
}

- (IBAction) mnAdd:(id)sender {
	[ self showProgress:@"mnAdd" ];

	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ( modelKeyValue == @"recs" ) {
			[ self showCreateFolder ];
		} else if ( modelKeyValue == @"tvguide" ) {
			if ( rowtype == @"g") {
				[ self showCreateEditRecTimer ];
			}
		} else if ( modelKeyValue == @"search" ) {
			if ( rowtype == @"g") {
				[ self showCreateEditRecTimer ];
			}
		} else if ( modelKeyValue == @"commonfavs" ) { 
			[ self showCreateEditRecTimer ];
		} else if ( modelKeyValue == @"recstocome" ) { 
		} else if ( modelKeyValue == @"alwaysonrecs" ) {
		}	
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnAdd"];
	}
	@finally {
		[ self hideProgress:@"mnAdd" ];
	}
}

- (IBAction) mnModify:(id)seder {
	[ self showProgress:@"mnModify" ];

	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ( modelKeyValue == @"recs" ) {
			[ self showRenameFolder ];
		} else if ( modelKeyValue == @"tvguide" ) {
		} else if ( modelKeyValue == @"commonfavs" ) { 
		} else if ( modelKeyValue == @"recstocome" ) {
			[ self showCreateEditRecTimer ];
		} else if ( modelKeyValue == @"alwaysonrecs" ) {
			[ self showCreateEditRecTimer ];
		}		
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnModify"];
	}
	@finally {
		[ self hideProgress:@"mnModify" ];
	}
}

- (IBAction) mnDelete:(id)sender {
	[ self showProgress:@"mnDelete" ];
	@try {
		NSString *rowid;
		NSString *rowtype;
		NSArray *objects = [acPathContents arrangedObjects];
		
		if ( [ tvPathContents selectedRow] > -1 ) {
			rowid = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"id"];
			rowtype = [ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"type"];		
		}
		
		if ( modelKeyValue == @"recs" ) {
			if ( rowtype == @"r" ) {
				[ self acRecDelete:tvPathContents ];				
			} else if ( rowtype == @"f" ) {
				[ self acFolRemove ];
			}					
		} else if ( modelKeyValue == @"latestrecs" ) {
			if ( rowtype == @"r" ) {
				[ self acRecDelete:tvPathContents ];				
			}		
		} else if ( modelKeyValue == @"alwaysonrecs" ) {
			[ self deleteContinousRec ];
		} else if ( modelKeyValue == @"recstocome" ) {
			if ( [[ [ objects objectAtIndex: [ tvPathContents selectedRow]] objectForKey:@"rec_id"] compare:@"" ] ) {
				[ self deleteSingleRec ];
			}
		} else if (modelKeyValue == @"indownload" ) {
			if (rowtype == @"dl") {
				
				[[ activeDownloads objectAtIndex: [ tvPathContents selectedRow ] ] stop ];
				[ activeDownloads removeObjectAtIndex: [ tvPathContents selectedRow ] ];
				[ self populateDownload ];
			}
		} else 	if ( modelKeyValue == @"trashcan" ) {
			if ( rowtype == @"r" ) {
				[ self acRecDelete:tvPathContents ];				
			} 
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnDelete"];
	}
	@finally {
		[ self hideProgress:@"mnDelete" ];
	}
}

- (IBAction) mnRestore:(id)sender {
	[ self showProgress:@"mnRestore" ];

	@try {
		[ cbFolderTrashRestore selectItemAtIndex:0 ];
		if ( modelKeyValue == @"trashcan" ) {
			[ pnRestoreRec setTitle:@"Palautuskansio" ];
			[ btRestoreOk setTitle:@"Palauta" ];
		} else if ( modelKeyValue == @"recs" ) {
			[ pnRestoreRec setTitle:@"Siirrä kansioon..." ];
			[ btRestoreOk setTitle:@"Siirrä" ];
		}
		[ pnRestoreRec setIsVisible:YES ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnRestore"];
	}
	@finally {
		[ self hideProgress:@"mnRestore" ];
	}
}

/******************************************************************************
 * Trashcan routines
 ******************************************************************************/
- (IBAction) btRestore:(id)sender {
	[ self showProgress:@"btRestore" ];

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSArray *objects = [acPathContents arrangedObjects];			
		NSArray *fobjects = [ acRecEditFolder arrangedObjects ];
		NSIndexSet *indexSet = [tvPathContents selectedRowIndexes];	
		NSError *error = nil;	

		int runCount = 0;
		int index = [indexSet firstIndex];
		NSMutableString* mRlocation = [ NSMutableString stringWithFormat:@"%@://%@/ready.sl?move=true&destination=%@&", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], [[ fobjects objectAtIndex: [ cbFolderTrashRestore indexOfSelectedItem ] ] objectForKey:@"folderID"]];
		
		[ cH cacheOff ];
		while (index > -1) 
		{
			[mRlocation appendFormat:@"programviewid=%@&", [ self viewIDbyProgID:[ [objects objectAtIndex: index] valueForKey:@"id"]]];
			runCount++;
			index=[indexSet indexGreaterThanIndex:index];
			if ([ objects count ] < index ) {
				break;
			}
		}

		if ( (mRlocation) && (runCount > 0) ) {
			[ mRlocation appendString:@"ajax=true"];
			[ self addDynLog:[ NSString stringWithFormat:@"%@", mRlocation] entrySeverity:@"DEBUG" callerFunction:@"btRestore"];
			NSString *response = [ htEngine httpGet:mRlocation error:error]; // [self execHTTP:rlocation errorResp:error];
			if (!error) {
			} else {
				[ self addDynLog:[ NSString stringWithFormat:@"HTTP-RESPONSE: %@", response ] entrySeverity:@"DEBUG" callerFunction:@"btRestore"];
				[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
								  [error code], 
								  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"btRestore"];			
			}
		}
		
		[ self mnReload:tvPathContents ];	
		[ pnRestoreRec setIsVisible: NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnRestore"];
	}
	@finally {
		[ cH cacheOn ];		
		[ self hideProgress:@"btRestore" ];
		[ pool drain ];
	}
}

- (IBAction) btRestoreCancel:(id)sender {
	[ self showProgress:@"btRestoreCancel" ];

	@try {
		[ pnRestoreRec setIsVisible:NO ];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"btRestoreCancel"];
	}
	@finally {
		[ self hideProgress:@"btRestoreCancel" ];
	}
}

- (IBAction) mnEmptyTrash:(id)sender {
	if ( ( [ cnf getBoolCnf:@"cnfEnableTrashCan"] == YES ) && ( trashFound == YES) ) {
		@try {
			[ self showProgress:@"emptyTrash" ];
			
			[ self addDynLog:[NSString stringWithFormat: @"trashcan : %@", trashFolderID] entrySeverity:@"INFO" callerFunction:@"mnEmptyTrash"];
			int alertReturn = NSRunInformationalAlertPanel(@"eViihde", @"Haluatko tyhjentää roskakorin?", @"Kyllä", @"Ei", nil);
			
			if ( alertReturn == NSAlertDefaultReturn) {
				NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], trashFolderID];
				if (location) {
					NSError * error = nil;
					NSArray * folderCData = [ htEngine jsonHttpExec:location error:error];
					
					if (!error) {
						NSArray *recordingsData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"recordings"];
						
						int runCount = 0;
						NSMutableString* mRlocation = [ NSMutableString stringWithFormat:@"%@://%@/program.sl?remove=true&", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
						
						for(NSArray *recordData in [recordingsData objectAtIndex:0]) {
							[mRlocation appendFormat:@"removep=%@&", [ self viewIDbyProgID:[[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
							runCount++;
						}
						
						if ( (mRlocation) && (runCount > 0 )) {
							[ mRlocation appendString:@"ajax=true" ];
							[ self addDynLog:[ NSString stringWithFormat:@"%@", mRlocation] entrySeverity:@"DEBUG" callerFunction:@"mnEmptyTrash"];
							NSError *Rerror = nil;
							NSString *Rresponse = [ htEngine httpGet:mRlocation error:Rerror]; // [self execHTTP:Rlocation errorResp:Rerror];
							if (!Rerror) {
								
							} else {
								[self showErrorPopup:@"Järjestelmävirhe" errorDescText:[NSString stringWithFormat:@"Something went wrong %d, %@\n\n%@", [Rerror code], [Rerror localizedDescription], Rresponse]];
								[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
												  [Rerror code], 
												  [Rerror localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"mnEmptyTrash"];
							}
						}								
						
						if ( modelKeyValue == @"trashcan" ) {
							[ self mnReload:0 ];					
						}
					} else {
						[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa tallennuksia: %d\n\n%@", [error code],[error localizedDescription]]];
						[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
										  [error code], 
										  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"mnEmptyTrash"];
					}
				}			
			}			
		}
		@catch (NSException * e) {
			[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"mnEmptyTrash"];
		}
		@finally {
			[ self hideProgress:@"emptyTrash" ];
		}
	}
}

- (void) autoEmptyTrash {
	if ( ( [ cnf getBoolCnf:@"cnfEnableTrashCan"] == YES ) && ( trashFound == YES) && ( [cnf getBoolCnf:@"cnfAutoTrash"] == YES) ) {
		@try {
			if ( [ trashFolderID length ] > 1 )  {
				[ self showProgress:@"autoEmptyTrash" ];
				
				NSString* location = [NSString stringWithFormat:@"%@://%@/ready.sl?folderid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], trashFolderID];
				if (location) {
					NSError * error = nil;
					NSArray *folderCData = [ htEngine jsonHttpExec:location error:error];
					
					if (!error) {
						NSArray *recordingsData = (NSArray *)[[ folderCData valueForKey:@"ready_data"] valueForKey:@"recordings"];
						
						int runCount = 0;
						NSMutableString* mRlocation = [ NSMutableString stringWithFormat:@"%@://%@/program.sl?remove=true&", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"]];
						
						for(NSArray *recordData in [recordingsData objectAtIndex:0]) {
							NSDateFormatter *df = [[NSDateFormatter alloc] init];
							[df setDateFormat:@"yyyy.MM.dd HH:mm"]; // 2011.01.23 19:30
							NSDate *recordStartTime = [df dateFromString: [gfunc maxDate:[[recordData valueForKey:@"start_time" ] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
							NSCalendar *cal = [NSCalendar currentCalendar];
							NSDateComponents *components = [[NSDateComponents alloc] init];
							[components setWeek:1];
							recordStartTime = [cal dateByAddingComponents:components toDate:recordStartTime options:0];
							
							if ( [recordStartTime timeIntervalSince1970] < [ [NSDate date] timeIntervalSince1970] ) {
								
								[mRlocation appendFormat:@"removep=%@&", [ self viewIDbyProgID:[[recordData valueForKey:@"program_id"] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
								runCount++;
							}				
						}
						
						if ( (mRlocation) && (runCount > 0 )) {
							[ mRlocation appendString:@"ajax=true" ];
							[ self addDynLog:[ NSString stringWithFormat:@"%@", mRlocation] entrySeverity:@"DEBUG" callerFunction:@"autoEmptyTrash"];
							
							NSError *Rerror = nil;
							NSString *Rresponse = [ htEngine httpGet:mRlocation error:Rerror]; // [self execHTTP:Rlocation errorResp:Rerror];
							if (!Rerror) {
								
							} else {
								[self showErrorPopup:@"Järjestelmävirhe" errorDescText:[NSString stringWithFormat:@"Something went wrong %d, %@\n\n%@", [Rerror code], [Rerror localizedDescription], Rresponse]];
								[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
												  [Rerror code], 
												  [Rerror localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"autoEmptyTrash"];
							}
						}								
						
						if ( modelKeyValue == @"trashcan" ) {
							[ self mnReload:0 ];					
						}
					} else {
						[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"Ladattaessa tallennuksia: %d\n\n%@", [error code],[error localizedDescription]]];
						[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
										  [error code], 
										  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"mnEmptyTrash"];
					}
				}				
			}
		}
		@catch (NSException * e) {
			[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"autoEmptyTrash"];
		}
		@finally {
			[ self hideProgress:@"autoEmptyTrash" ];
		}
	}
}

/******************************************************************************
 * Generalized ElisaViihde routines
 ******************************************************************************/

- (NSString *) viewIDbyProgID:(NSString *) ProgID {
	[ self showProgress:@"viewIDbyProgID" ];

	NSString* restoreViewID = nil;
	@try {
		NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], ProgID];
		NSError *error = nil;
		
		if (location) {
			NSArray *recInfoData = [ htEngine jsonHttpExec:location error:error];
			if (!error) {
				restoreViewID = [NSString stringWithString:[recInfoData valueForKey:@"programviewid"]];
				return restoreViewID;
			}
		}
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"viewIDbyProgID"];
	}
	@finally {
		[ self hideProgress:@"viewIDbyProgID" ];
		return restoreViewID;
	}
}

- (NSArray *) getProgramPropertyArray:(NSString *) progID {
	[ cH cacheOn ];
	[ self showProgress:@"getProgramPropertyArray:(NSString *) progID" ];
	NSArray * Response;
	
	@try {
		if ( [progID length] > 0 )
		{		
			NSString* location = [NSString stringWithFormat:@"%@://%@/program.sl?programid=%@&ajax=true", [cnf getStringCnf:@"httpServerProtocol"], [cnf getStringCnf:@"httpServerAddress"], progID];
			
			if (location) {
				NSError *error = nil;
				Response = [ htEngine jsonHttpExec:location error:error]; //[self execHTTP:location errorResp:error];
				if (error) {					[self showErrorPopup:@"HTTP-Virhe" errorDescText:[NSString stringWithFormat:@"%d\n\n%@", [error code],[error localizedDescription]]];
					[ self addDynLog:[ NSString stringWithFormat:@"(%d) %@", 
									  [error code], 
									  [error localizedDescription]] entrySeverity:@"ERROR" callerFunction:@"getProgramPropertyArray"];
				}
			}
		} 
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"getProgramPropertyArray"];	
	} 
	@finally {
		[ self hideProgress:@"getProgramPropertyDictionary:(NSString *) progID" ];
	}
	return Response;	
}

- (NSString *) getProgramProperty:(NSString *)progID progProperty:(NSString *)progProperty {
	NSString * propertyValue = nil;
	@try {
		propertyValue = [ NSString stringWithString: [[ [self getProgramPropertyArray:progID ] valueForKey:progProperty ] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	}
	@catch (NSException * e) {
		[ self addDynLog:[ NSString stringWithFormat:@"%@", e] entrySeverity:@"EXCEPTION" callerFunction:@"viewIDbyProgID"];
	}
	@finally {
		return propertyValue;
	}
} 


/** Font Changer **/

- (void) changeFont:(id)tableView size:(CGFloat)fontSize
{
    /** Set Font Size **/
    NSFont *fnt = [NSFont systemFontOfSize:fontSize];
    NSEnumerator *enm = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *col;
    [tableView setRowHeight:fontSize+6];        
    while (col = [enm nextObject])
        //[[col dataCell] setHeightTracksTextView:YES];
        [[col dataCell] setFont:fnt];
    [tableView tile];
    /** Set Font Size **/
    
}

@synthesize wnRecView;
@synthesize loginWindow;
@synthesize masterWindow;
@synthesize releaseNotes;
@synthesize dynLogWindow;
@synthesize maServiceList;
@synthesize maPathContents;
@synthesize maRecChan;
@synthesize maRecFolder;


@end

@implementation NSColor (ColorChangingFun)

+ (NSColor*)colorWithHexColorString:(NSString*)inColorString
{
	NSColor* result    = nil;
	unsigned colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner* scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode]; // ignore error
	}
	redByte   = (unsigned char)(colorCode >> 16);
	greenByte = (unsigned char)(colorCode >> 8);
	blueByte  = (unsigned char)(colorCode);     // masks off high bits
	
	result = [NSColor
			  colorWithCalibratedRed:(CGFloat)redByte    / 0xff
			  green:(CGFloat)greenByte / 0xff
			  blue:(CGFloat)blueByte   / 0xff
			  alpha:1.0];
	return result;
}

+(NSArray*)controlAlternatingRowBackgroundColors
{
    return [NSArray arrayWithObjects:[ self colorWithHexColorString:[cnf getStringCnf:@"rowColorOdd"]], [ self colorWithHexColorString:[cnf getStringCnf:@"rowColorEven"]], nil];
}

@end