//
//  cnfWindowDelegate.h
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

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "cnfController.h"
#import <WebKit/WebKit.h>

@interface cnfWindowDelegate : NSObject {
	IBOutlet NSBox *cnfOpenWinBox;
	IBOutlet NSPanel *configPanel;
	IBOutlet NSButton *cnfCBShowRecs;
	IBOutlet NSButton *cnfCBShowRecsToCome;
	IBOutlet NSButton *cnfCBShowChanList;
	IBOutlet NSButton *cnfCBShowTopList;
	IBOutlet NSButton *cnfCBKeepLogged;
	IBOutlet NSButton *cnfCBAutoLogin;
	IBOutlet NSButton *cnfUseVLC;
	IBOutlet NSButton *cnfVLCFullScreen;
	IBOutlet NSButton *cnfRecFolderSelect;
	IBOutlet NSButton *cnfAllowContRemoveFromInRecs;
	IBOutlet NSSlider *cnfHTTPTimeoutSlider;
	IBOutlet NSTextField *cnfHTTPTimeoutLabel;
	IBOutlet NSButton *cnfSingleView;
	IBOutlet NSButton *cnfhttpCacheEnabled;
	IBOutlet NSButton *cnfDisableFacebook;
	IBOutlet NSButton *cnfShowLatestOnlyUnwatched;
	IBOutlet NSButton *cnfPathFolderShowBytes;
	IBOutlet NSButton *cnfSyncServer;
	IBOutlet NSButton *cnfGuideSearch;
	IBOutlet NSButton *cnfAutoTrash;
	IBOutlet NSButton *cnfDisplaySmallInfoBox;
	IBOutlet NSButton *cnfEnableTrashCan;
	IBOutlet NSButton *cnfEnableTrashCanAutocreate;
	IBOutlet NSButton *cnfEnableVersionChecking;

	IBOutlet NSButton *cnfSaveLog;
	IBOutlet NSButton *cnfSelectLogFile;
	IBOutlet NSComboBox *cnfSelectLogLevel;
	IBOutlet NSTextField *cnfLogFile;
	IBOutlet NSArrayController *acLogLevels;
	NSMutableArray * maLogLevels;

	IBOutlet NSSlider *cnfHTTPDownloadSpeedSlider;
	IBOutlet NSTextField *cnfHTTPDownloadSpeedLabel;

	IBOutlet NSTabViewItem *tviTheme;
	IBOutlet NSTabViewItem *tviStartup;
	
	IBOutlet NSSegmentedControl *scProvider;
	
	IBOutlet NSTextField *downloadPath;

	IBOutlet NSComboBox *cbThemes;
	NSMutableArray* maThemeList;
	IBOutlet NSArrayController *acThemeList;
    
    IBOutlet NSComboBox *cbSidebarFontSize;
	NSMutableArray* maSidebarFontSize;
	IBOutlet NSArrayController *acSidebarFontSize;
    
    IBOutlet NSComboBox *cbRecordingFontSize;
	NSMutableArray* maRecordingFontSize;
	IBOutlet NSArrayController *acRecordingFontSize;
	
	IBOutlet NSButton *btSelectDownloadPath;
	
	IBOutlet NSSlider *slICalReminderTime;
	IBOutlet NSTextField *tfICalTimeText;
	
	NSMutableArray* maICalList;
	IBOutlet NSArrayController *acICalList;
	IBOutlet NSComboBox *cbICal;
	
	IBOutlet WebView *wbFaceBookLogin;
	
	IBOutlet NSTextField *cnfSaveAsTemplate;
	IBOutlet NSButton *btSaveAsHelp;
	IBOutlet NSPanel *npSaveAsHelp;
	IBOutlet NSTextField *lbSaveAsHelpText;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

- (IBAction)showSettings:(id)sender;
- (IBAction)chCnfCB:(id)sender;
- (IBAction)chTimeoutSlider:(id)sender;
- (IBAction)chDownloadSpeedSlider:(id)sender;
- (IBAction)chResetProgram:(id)sender;
- (IBAction)acSelectDownloadPath:(id)sender;

- (IBAction) themeSelect:(id)sender;

- (IBAction)serviceProviderSelector:(id)sender;

- (IBAction)chIcalReminder:(id)sender;
- (IBAction)cbICalSelect:(id)sender;

- (IBAction)btSaveAsHelp:(id)sender;
- (IBAction)cnfSaveAsTemplateChange:(id)sender;

- (IBAction) pickLogFile:(id)sender;
-(void)selectLogFileEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void*)ctx;
- (IBAction) logLevelSelect:(id)sender;

- (IBAction)selectSidebarFontSize:(id)sender;
- (IBAction)selectRecordingFontSize:(id)sender;

@property (copy) NSArray* maThemeList;
@property (copy) NSArray* maICalList;
@property (copy) NSArray* maLogLevels;

@end
